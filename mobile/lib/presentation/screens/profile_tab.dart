import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_models/shared_models.dart';

import '../providers.dart';
import '../widgets/common.dart';
import '../widgets/rating_sheet.dart';
import 'challenge_screen.dart' show pickCourse;
import 'home_tab.dart' show showWeeklyGoalPicker;

class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final student = ref.watch(authProvider).value;
    final checkinsAsync = ref.watch(myCheckinsProvider);
    final achievements = ref.watch(achievementsProvider).value;

    if (student == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: ListView(
        padding: const EdgeInsets.all(UniHubSpacing.x6),
        children: [
          Row(
            children: [
              InitialsAvatar(name: student.name, photoUrl: student.photoUrl, radius: 28),
              const SizedBox(width: UniHubSpacing.x4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.name,
                      style: UniHubFonts.display(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      student.university,
                      style: const TextStyle(fontSize: 13, color: UniHubColors.textSecondary),
                    ),
                    Text(
                      student.email,
                      style: const TextStyle(fontSize: 13, color: UniHubColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (achievements != null) ...[
            const SizedBox(height: UniHubSpacing.x6),
            _AchievementsSection(achievements: achievements),
          ],
          const SizedBox(height: UniHubSpacing.x6),
          const Divider(),
          _ProfileAction(
            icon: LucideIcons.creditCard,
            label: 'Carteirinha digital',
            onTap: () => context.push('/card'),
          ),
          const Divider(),
          _ProfileAction(
            icon: LucideIcons.repeat,
            label: 'Gerenciar plano',
            subtitle: student.subscription?.plan.name ?? 'Sem plano ativo',
            onTap: () => context.push('/plans'),
          ),
          const Divider(),
          _ProfileAction(
            icon: LucideIcons.target,
            label: 'Meta semanal',
            subtitle: '${student.weeklyGoal} treinos',
            onTap: () => showWeeklyGoalPicker(context, ref, student.weeklyGoal),
          ),
          const Divider(),
          _ProfileAction(
            icon: LucideIcons.graduationCap,
            label: 'Curso',
            subtitle: student.course ?? 'Informar para entrar na copa de cursos',
            onTap: () => pickCourse(context, ref, student.course),
          ),
          const Divider(),
          _ProfileAction(
            icon: LucideIcons.house,
            label: 'Cidade natal',
            subtitle: student.homeCity ?? 'Escolher',
            onTap: () => _pickHomeCity(context, ref, student.homeCity),
          ),
          const Divider(),
          _ProfileAction(
            icon: LucideIcons.logOut,
            label: 'Sair',
            onTap: () => ref.read(authProvider.notifier).logout(),
          ),
          const Divider(),
          const SizedBox(height: UniHubSpacing.x8),
          const SectionTitle('Histórico de check-ins'),
          const SizedBox(height: UniHubSpacing.x2),
          checkinsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: UniHubSpacing.x4),
              child: LinearProgressIndicator(minHeight: 2),
            ),
            error: (e, _) =>
                Text('$e', style: const TextStyle(color: UniHubColors.textSecondary)),
            data: (checkins) => checkins.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: UniHubSpacing.x4),
                    child: Text(
                      'Nenhum check-in ainda. Que tal começar hoje?',
                      style: TextStyle(fontSize: 14, color: UniHubColors.textSecondary),
                    ),
                  )
                : Column(
                    children: [
                      for (final (i, c) in checkins.take(30).indexed) ...[
                        if (i > 0) const Divider(),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: UniHubSpacing.x3),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      c.gym.name,
                                      style: const TextStyle(
                                          fontSize: 14, fontWeight: FontWeight.w600),
                                    ),
                                    Text(
                                      formatDateTime(c.timestamp),
                                      style: const TextStyle(
                                          fontSize: 12.5, color: UniHubColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              // Nota dada, ou atalho para avaliar
                              c.rating != null
                                  ? InkWell(
                                      onTap: () => showRatingSheet(context, ref, c),
                                      child: StarsRow(stars: c.rating!),
                                    )
                                  : TextButton(
                                      onPressed: () => showRatingSheet(context, ref, c),
                                      child: const Text('Avaliar'),
                                    ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
          const SizedBox(height: UniHubSpacing.x12),
          const _AboutFooter(),
          const SizedBox(height: UniHubSpacing.x6),
        ],
      ),
    );
  }
}

/// Rodapé com o símbolo. Easter egg: 5 toques seguidos no símbolo abrem
/// o card de quem fez o UniHub.
class _AboutFooter extends StatefulWidget {
  const _AboutFooter();

  @override
  State<_AboutFooter> createState() => _AboutFooterState();
}

class _AboutFooterState extends State<_AboutFooter> {
  int _taps = 0;
  DateTime _last = DateTime(2000);

  void _tap() {
    final now = DateTime.now();
    _taps = now.difference(_last) > const Duration(seconds: 2) ? 1 : _taps + 1;
    _last = now;
    if (_taps >= 5) {
      _taps = 0;
      showDialog<void>(context: context, builder: (_) => const _FoundersCard());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: _tap,
          behavior: HitTestBehavior.opaque,
          child: const Padding(
            padding: EdgeInsets.all(UniHubSpacing.x2),
            child: UniHubSymbol(height: 22),
          ),
        ),
        const SizedBox(height: UniHubSpacing.x1),
        Text(
          'UniHub · feito na FACAMP',
          style: UniHubFonts.text(fontSize: 12, color: UniHubColors.textTertiary),
        ),
      ],
    );
  }
}

class _FoundersCard extends StatelessWidget {
  const _FoundersCard();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.all(UniHubSpacing.x6),
      shape: RoundedRectangleBorder(borderRadius: UniHubRadius.brLg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 16 / 10,
                child: Image.asset('assets/fundadores.jpg', fit: BoxFit.cover),
              ),
              const Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: HalfMoonCurtain(radius: 9),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(UniHubSpacing.x5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const BrandLabel('Você achou'),
                const SizedBox(height: UniHubSpacing.x1),
                Text(
                  'Quem fez o UniHub',
                  style: UniHubFonts.display(fontSize: 22, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: UniHubSpacing.x2),
                Text(
                  'Alunos da FACAMP que queriam treinar entre uma aula e outra '
                  'e resolveram fazer isso caber na rotina de todo universitário.',
                  style: UniHubFonts.text(fontSize: 14, color: UniHubColors.textSecondary),
                ),
                const SizedBox(height: UniHubSpacing.x4),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Bora treinar'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Totais, card da sequência e selos (estilo apps de hábito).
class _AchievementsSection extends StatelessWidget {
  const _AchievementsSection({required this.achievements});

  final Achievements achievements;

  static const _icons = {
    'first': LucideIcons.footprints,
    'checkins_10': LucideIcons.dumbbell,
    'checkins_50': LucideIcons.medal,
    'explorer': LucideIcons.compass,
    'streak_4': LucideIcons.flame,
    'streak_12': LucideIcons.trophy,
    'early': LucideIcons.sunrise,
    'reviewer': LucideIcons.star,
  };

  @override
  Widget build(BuildContext context) {
    final a = achievements;
    // Conquistados primeiro, depois os mais perto de sair
    final badges = [...a.badges]
      ..sort((x, y) => x.achieved != y.achieved
          ? (x.achieved ? -1 : 1)
          : (y.progress / y.target).compareTo(x.progress / x.target));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: StatBlock(value: '${a.totalCheckins}', label: 'Check-ins')),
            Expanded(child: StatBlock(value: '${a.gymsVisited}', label: 'Academias visitadas')),
          ],
        ),
        const SizedBox(height: UniHubSpacing.x5),
        // Laranja chapado com textura de papel (o manual não usa degradê)
        BrandBlock(
          outline: const Positioned(right: -40, top: -50, child: SymbolOutline(height: 170)),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.currentStreak == 0
                          ? 'Comece uma sequência'
                          : 'Sequência de ${a.currentStreak} ${a.currentStreak == 1 ? 'semana' : 'semanas'}',
                      style: UniHubFonts.display(
                          fontSize: 21, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      a.currentStreak == 0
                          ? 'Bata a meta desta semana para começar.'
                          : 'Melhor marca: ${a.bestStreak} semanas. Continue assim!',
                      style: const TextStyle(fontSize: 13, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const Icon(LucideIcons.flame, size: 40, color: Colors.white),
            ],
          ),
        ),
        const SizedBox(height: UniHubSpacing.x6),
        Text(
          'Conquistas · ${a.badges.where((b) => b.achieved).length} de ${a.badges.length}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: UniHubSpacing.x3),
        SizedBox(
          height: 118,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: badges.length,
            separatorBuilder: (_, _) => const SizedBox(width: UniHubSpacing.x3),
            itemBuilder: (context, i) {
              final b = badges[i];
              return Tooltip(
                message: b.description,
                child: SizedBox(
                  width: 84,
                  child: Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: b.achieved ? UniHubColors.accent : UniHubColors.surface,
                        ),
                        child: Icon(
                          _icons[b.code] ?? LucideIcons.award,
                          size: 26,
                          color: b.achieved ? Colors.white : UniHubColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        b.title,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: b.achieved ? UniHubColors.textPrimary : UniHubColors.textSecondary,
                        ),
                      ),
                      if (!b.achieved)
                        Text(
                          '${b.progress}/${b.target}',
                          style: const TextStyle(fontSize: 11, color: UniHubColors.textSecondary),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Cidade natal: o Explorar mostra as academias de lá primeiro (feriados e férias).
Future<void> _pickHomeCity(BuildContext context, WidgetRef ref, String? current) async {
  final List<String> cities;
  try {
    cities = await ref.read(gymCitiesProvider.future);
  } catch (e) {
    if (context.mounted) showApiError(context, e);
    return;
  }
  if (!context.mounted) return;
  final picked = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: UniHubColors.background,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(UniHubSpacing.x6, UniHubSpacing.x6, UniHubSpacing.x6, UniHubSpacing.x2),
            child: Text(
              'Onde você passa as férias?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: UniHubSpacing.x6),
            child: Text(
              'Cidades com academias parceiras',
              style: TextStyle(fontSize: 13, color: UniHubColors.textSecondary),
            ),
          ),
          for (final city in cities)
            ListTile(
              title: Text(city),
              trailing: city == current
                  ? const Icon(LucideIcons.check, color: UniHubColors.accent, size: 18)
                  : null,
              onTap: () => Navigator.of(sheetContext).pop(city),
            ),
          const SizedBox(height: UniHubSpacing.x4),
        ],
      ),
    ),
  );
  if (picked == null || picked == current) return;
  try {
    await ref.read(apiClientProvider).updateMyProfile(homeCity: picked);
    await ref.read(authProvider.notifier).refreshProfile();
  } catch (e) {
    if (context.mounted) showApiError(context, e);
  }
}

class _ProfileAction extends StatelessWidget {
  const _ProfileAction({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: UniHubSpacing.x4),
        child: Row(
          children: [
            Icon(icon, size: 20, color: UniHubColors.textSecondary),
            const SizedBox(width: UniHubSpacing.x4),
            Expanded(
              child: Text(label,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
            if (subtitle != null)
              Text(subtitle!,
                  style: const TextStyle(fontSize: 13, color: UniHubColors.textSecondary)),
            const SizedBox(width: UniHubSpacing.x2),
            const Icon(LucideIcons.chevronRight, size: 16, color: UniHubColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
