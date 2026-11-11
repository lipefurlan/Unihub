import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_models/shared_models.dart';

import '../../domain/access_rules.dart';
import '../providers.dart';
import '../widgets/common.dart';
import '../widgets/rating_sheet.dart';
import 'challenge_screen.dart' show ChallengeCard;

class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final student = ref.watch(authProvider).value;
    final stats = ref.watch(myStatsProvider);
    final gyms = ref.watch(gymsProvider);
    final favorites = ref.watch(favoritesProvider).value ?? const <Gym>[];
    // Última visita sem nota nos últimos 3 dias: pede a avaliação
    final toRate = ref.watch(myCheckinsProvider).value?.where((c) =>
        c.rating == null && DateTime.now().difference(c.timestamp).inDays < 3).firstOrNull;
    ref.watch(userLocationProvider); // redesenha quando a localização chega

    return Scaffold(
      appBar: AppBar(title: const UniHubWordmark()),
      body: RefreshIndicator(
        color: UniHubColors.accent,
        onRefresh: () async {
          ref.invalidate(myCheckinsProvider);
          ref.invalidate(myStatsProvider);
          ref.invalidate(favoritesProvider);
          ref.invalidate(myChallengesProvider);
          ref.invalidate(gymsProvider);
          await ref.read(authProvider.notifier).refreshProfile();
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(UniHubSpacing.x6),
          children: [
            Text(
              'Olá, ${student?.name.split(' ').first ?? ''}',
              style: UniHubFonts.display(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            Text(
              student?.university ?? '',
              style: const TextStyle(fontSize: 14, color: UniHubColors.textSecondary),
            ),
            if (student != null && !student.isVerified) ...[
              const SizedBox(height: UniHubSpacing.x6),
              _VerifyEmailBanner(single: student.singleEmail),
            ],
            const SizedBox(height: UniHubSpacing.x8),
            _PlanSection(student: student),
            if (toRate != null) ...[
              const SizedBox(height: UniHubSpacing.x4),
              _RateLastVisit(checkin: toRate),
            ],
            const SizedBox(height: UniHubSpacing.x8),
            SectionTitle(
              'Sua semana',
              action: TextButton(
                onPressed: () => showWeeklyGoalPicker(context, ref, student?.weeklyGoal ?? 3),
                child: const Text('Mudar meta'),
              ),
            ),
            const SizedBox(height: UniHubSpacing.x3),
            stats.when(
              loading: () => const LinearProgressIndicator(minHeight: 2),
              error: (e, _) => Text('$e',
                  style: const TextStyle(color: UniHubColors.textSecondary, fontSize: 13)),
              data: (st) => _WeekGoalCard(stats: st),
            ),
            const SizedBox(height: UniHubSpacing.x8),
            const ChallengeCard(),
            if (favorites.isNotEmpty) ...[
              const SizedBox(height: UniHubSpacing.x8),
              const SectionTitle('Suas favoritas'),
              for (final (i, gym) in favorites.indexed) ...[
                if (i > 0) const Divider(),
                GymTile(
                  gym: gym,
                  covered: planCoversGym(student, gym),
                  onTap: () => context.push('/gyms/${gym.id}'),
                ),
              ],
            ],
            const SizedBox(height: UniHubSpacing.x8),
            SectionTitle(
              'Academias próximas',
              action: TextButton(
                onPressed: () => context.go('/explore'),
                child: const Text('Ver todas'),
              ),
            ),
            gyms.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: UniHubSpacing.x4),
                child: LinearProgressIndicator(minHeight: 2),
              ),
              error: (e, _) => Text('$e',
                  style: const TextStyle(color: UniHubColors.textSecondary, fontSize: 13)),
              data: (list) {
                final nearest = sortByDistance(list).take(3).toList();
                return Column(
                  children: [
                    for (final (i, gym) in nearest.indexed) ...[
                      if (i > 0) const Divider(),
                      GymTile(
                        gym: gym,
                        covered: planCoversGym(student, gym),
                        onTap: () => context.push('/gyms/${gym.id}'),
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Card do plano: bloco laranja com textura de papel, o botão de check-in
/// dentro e a cortina de meias-luas na borda de baixo (a peça mais forte da
/// tela, como no manual).
class _PlanSection extends ConsumerWidget {
  const _PlanSection({required this.student});

  final Student? student;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscription = student?.subscription;
    const onOrange = Colors.white;
    final soft = Colors.white.withValues(alpha: 0.86);

    final whiteButton = FilledButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: UniHubColors.accentPressed,
    ).copyWith(
      overlayColor: WidgetStatePropertyAll(UniHubColors.accentSoft.withValues(alpha: 0.5)),
    );

    if (subscription == null) {
      // Estudante recém-cadastrado: precisa escolher um plano
      return BrandBlock(
        outline: const Positioned(right: -70, top: -40, child: SymbolOutline(height: 190)),
        footer: const HalfMoonCurtain(radius: 10, onOrange: true),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BrandLabel('Meu plano', color: onOrange),
            const SizedBox(height: UniHubSpacing.x2),
            Text(
              'Escolha seu plano e treine perto do campus',
              style: UniHubFonts.display(fontSize: 22, fontWeight: FontWeight.w800, color: onOrange),
            ),
            const SizedBox(height: UniHubSpacing.x5),
            FilledButton(
              style: whiteButton,
              onPressed: () => context.push('/plans'),
              child: const Text('Escolher plano'),
            ),
          ],
        ),
      );
    }

    final plan = subscription.plan;
    final paused = subscription.status == 'paused';
    return BrandBlock(
      outline: const Positioned(right: -70, top: -40, child: SymbolOutline(height: 190)),
      // Pausado: bloco preto café, sem o laranja de "vamos treinar"
      color: paused ? UniHubColors.textPrimary : UniHubColors.accent,
      footer: HalfMoonCurtain(radius: 10, onOrange: !paused),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              BrandLabel(paused ? 'Plano pausado' : 'Meu plano', color: onOrange),
              const Spacer(),
              InkWell(
                borderRadius: UniHubRadius.brPill,
                onTap: () => context.push('/plans'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    children: [
                      Text('Gerenciar',
                          style: UniHubFonts.text(
                              fontSize: 13, fontWeight: FontWeight.w700, color: onOrange)),
                      const Icon(LucideIcons.chevronRight, size: 16, color: onOrange),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: UniHubSpacing.x2),
          Text(
            plan.name,
            style: UniHubFonts.display(fontSize: 26, fontWeight: FontWeight.w900, color: onOrange),
          ),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                formatBRL(subscription.amount),
                style: UniHubStyles.money(size: 17, weight: FontWeight.w800, color: onOrange),
              ),
              Text(' por mês', style: UniHubFonts.text(fontSize: 13, color: soft)),
              const Spacer(),
              Text(
                paused ? 'Sem cobrança' : 'Renova em ${formatDate(subscription.renewalDate)}',
                style: UniHubFonts.text(fontSize: 12.5, color: soft),
              ),
            ],
          ),
          if (plan.hasRunningCoach) ...[
            const SizedBox(height: UniHubSpacing.x2),
            Text(
              'Inclui plano de treino mensal com assessoria de corrida',
              style: UniHubFonts.text(fontSize: 13, fontWeight: FontWeight.w600, color: onOrange),
            ),
          ],
          const SizedBox(height: UniHubSpacing.x5),
          if (paused)
            Text(
              'Sem check-in até você retomar o plano.',
              style: UniHubFonts.text(fontSize: 13, color: soft),
            )
          else
            FilledButton.icon(
              style: whiteButton,
              onPressed: () => context.go('/checkin'),
              icon: const Icon(LucideIcons.scanLine, size: 18),
              label: const Text('Fazer check-in'),
            ),
        ],
      ),
    );
  }
}


/// Meta da semana em bolinhas, sequência de semanas e resumo do mês.
class _WeekGoalCard extends StatelessWidget {
  const _WeekGoalCard({required this.stats});

  final StudentStats stats;

  @override
  Widget build(BuildContext context) {
    final done = stats.weekCheckins;
    final goal = stats.weeklyGoal;
    final remaining = (goal - done).clamp(0, goal);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Treino feito vira o símbolo: os dois lados se encontram
            for (var i = 0; i < goal; i++)
              Padding(
                padding: const EdgeInsets.only(right: UniHubSpacing.x2),
                child: i < done
                    ? const UniHubSymbol(height: 28)
                    : Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: UniHubColors.border, width: 1.5),
                        ),
                      ),
              ),
            const Spacer(),
            if (stats.streakWeeks > 0)
              Row(
                children: [
                  const Icon(LucideIcons.flame, size: 18, color: UniHubColors.accent),
                  const SizedBox(width: 4),
                  Text(
                    '${stats.streakWeeks} ${stats.streakWeeks == 1 ? 'semana' : 'semanas'}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: UniHubSpacing.x2),
        Text(
          remaining == 0
              ? 'Meta da semana batida: $done de $goal treinos.'
              : 'Faltam $remaining ${remaining == 1 ? 'treino' : 'treinos'} para a meta de $goal na semana.',
          style: const TextStyle(fontSize: 13, color: UniHubColors.textSecondary),
        ),
        const SizedBox(height: UniHubSpacing.x4),
        // Últimas semanas: barra cheia = meta batida
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final w in stats.lastWeeks)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Container(
                    height: 6 + 30 * (w.checkins / (goal == 0 ? 1 : goal)).clamp(0, 1.4),
                    decoration: BoxDecoration(
                      color: w.goalMet ? UniHubColors.accent : UniHubColors.accentSoft,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Últimas 8 semanas',
          style: TextStyle(fontSize: 11, color: UniHubColors.textSecondary),
        ),
        const SizedBox(height: UniHubSpacing.x6),
        Row(
          children: [
            Expanded(child: StatBlock(value: '${stats.monthCheckins}', label: 'Treinos no mês')),
            Expanded(child: StatBlock(value: '${stats.monthGyms}', label: 'Academias no mês')),
          ],
        ),
        if (stats.monthTopGym != null) ...[
          const SizedBox(height: UniHubSpacing.x3),
          Text(
            'Mais frequentada: ${stats.monthTopGym}',
            style: const TextStyle(fontSize: 13, color: UniHubColors.textSecondary),
          ),
        ],
      ],
    );
  }
}

/// Escolha da meta semanal (1 a 7 treinos).
Future<void> showWeeklyGoalPicker(BuildContext context, WidgetRef ref, int current) async {
  final goal = await showModalBottomSheet<int>(
    context: context,
    backgroundColor: UniHubColors.background,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(UniHubSpacing.x6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Quantos treinos por semana?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: UniHubSpacing.x4),
            Wrap(
              spacing: UniHubSpacing.x2,
              children: [
                for (var g = 1; g <= 7; g++)
                  ChoiceChip(
                    label: Text('$g'),
                    selected: g == current,
                    onSelected: (_) => Navigator.of(sheetContext).pop(g),
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  if (goal == null || goal == current) return;
  try {
    await ref.read(apiClientProvider).updateMyProfile(weeklyGoal: goal);
    ref.invalidate(myStatsProvider);
    await ref.read(authProvider.notifier).refreshProfile();
  } catch (e) {
    if (context.mounted) showApiError(context, e);
  }
}


/// "Como foi o treino na X?" com atalho para dar as estrelas.
class _RateLastVisit extends ConsumerWidget {
  const _RateLastVisit({required this.checkin});

  final CheckIn checkin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      borderRadius: UniHubRadius.brMd,
      onTap: () => showRatingSheet(context, ref, checkin),
      child: Container(
        padding: const EdgeInsets.all(UniHubSpacing.x4),
        decoration: BoxDecoration(
          borderRadius: UniHubRadius.brMd,
          border: Border.all(color: UniHubColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Como foi o treino na ${checkin.gym.name}?',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  const StarsRow(stars: 0),
                ],
              ),
            ),
            const Text(
              'Avaliar',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: UniHubColors.accent),
            ),
          ],
        ),
      ),
    );
  }
}


/// Aviso enquanto o aluno não confirmou os e-mails (não consegue assinar).
class _VerifyEmailBanner extends StatelessWidget {
  const _VerifyEmailBanner({required this.single});

  final bool single; // um e-mail só (o da faculdade)

  @override
  Widget build(BuildContext context) {
    return Material(
      color: UniHubColors.accentSoft,
      borderRadius: BorderRadius.circular(UniHubRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(UniHubRadius.md),
        onTap: () => context.push('/confirmar-email'),
        child: Padding(
          padding: const EdgeInsets.all(UniHubSpacing.x4),
          child: Row(
            children: [
              const Icon(LucideIcons.mailCheck, color: UniHubColors.accent),
              const SizedBox(width: UniHubSpacing.x3),
              Expanded(
                child: Text(
                  single
                      ? 'Confirme o e-mail da faculdade com o código que enviamos para poder assinar um plano.'
                      : 'Confirme seus e-mails com os códigos que enviamos para poder assinar um plano.',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              const Icon(LucideIcons.chevronRight, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
