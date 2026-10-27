import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_models/shared_models.dart';

import '../providers.dart';
import '../widgets/common.dart';

String _daysLeftLabel(Challenge c) => c.daysLeft <= 0 ? 'último dia' : 'faltam ${c.daysLeft} dias';

String _standing(Challenge c) {
  final mine = c.myRow;
  if (mine == null) return 'Treine para ${c.betweenCourses ? 'seu curso' : 'sua faculdade'} pontuar.';
  return '${mine.name} em ${mine.position}º de ${c.ranking.length}';
}

/// Card dos desafios na tela inicial: onde o curso e a faculdade do aluno estão.
class ChallengeCard extends ConsumerWidget {
  const ChallengeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challenges = ref.watch(myChallengesProvider).value ?? const <Challenge>[];
    if (challenges.isEmpty) return const SizedBox.shrink();
    // Copa de cursos primeiro: é a disputa mais próxima do aluno
    final sorted = [...challenges]..sort((a, b) => (b.betweenCourses ? 1 : 0) - (a.betweenCourses ? 1 : 0));
    final main = sorted.first;
    return InkWell(
      borderRadius: UniHubRadius.brMd,
      onTap: () => context.push('/desafio'),
      child: Container(
        padding: const EdgeInsets.all(UniHubSpacing.x5),
        decoration: BoxDecoration(borderRadius: UniHubRadius.brMd, color: UniHubColors.textPrimary),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${sorted.length == 1 ? 'DESAFIO' : '${sorted.length} DESAFIOS'} · ${_daysLeftLabel(main)}'
                        .toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: UniHubColors.accent,
                    ),
                  ),
                  const SizedBox(height: UniHubSpacing.x2),
                  Text(
                    main.title,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  for (final c in sorted.take(2))
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '${c.betweenCourses ? 'Curso' : 'Faculdade'}: ${_standing(c)}',
                        style: const TextStyle(fontSize: 13, color: Colors.white70),
                      ),
                    ),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, color: Colors.white70),
          ],
        ),
      ),
    );
  }
}

/// Desafios em que o aluno está: ranking, posição do grupo e quanto ele já somou.
class ChallengeScreen extends ConsumerWidget {
  const ChallengeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challengesAsync = ref.watch(myChallengesProvider);
    final student = ref.watch(authProvider).value;
    return Scaffold(
      appBar: AppBar(title: const Text('Desafios')),
      body: challengesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(icon: LucideIcons.wifiOff, message: '$e'),
        data: (challenges) => RefreshIndicator(
          onRefresh: () => ref.refresh(myChallengesProvider.future),
          child: ListView(
            padding: const EdgeInsets.all(UniHubSpacing.x6),
            children: [
              if (student != null && student.course == null) ...[
                _CourseCallout(onTap: () => pickCourse(context, ref, null)),
                const SizedBox(height: UniHubSpacing.x6),
              ],
              if (challenges.isEmpty)
                const EmptyState(
                  icon: LucideIcons.trophy,
                  message: 'Nenhum desafio em andamento agora. Fique de olho: sua faculdade pode lançar um a qualquer momento.',
                ),
              for (final (i, c) in challenges.indexed) ...[
                if (i > 0) ...[
                  const SizedBox(height: UniHubSpacing.x6),
                  const Divider(),
                  const SizedBox(height: UniHubSpacing.x6),
                ],
                _ChallengeSection(challenge: c),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CourseCallout extends StatelessWidget {
  const _CourseCallout({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: UniHubRadius.brMd,
      child: Container(
        padding: const EdgeInsets.all(UniHubSpacing.x4),
        decoration: BoxDecoration(
          borderRadius: UniHubRadius.brMd,
          border: Border.all(color: UniHubColors.accent),
        ),
        child: const Row(
          children: [
            Icon(LucideIcons.graduationCap, color: UniHubColors.accent),
            SizedBox(width: UniHubSpacing.x3),
            Expanded(
              child: Text(
                'Informe seu curso para seus treinos valerem pontos na copa entre cursos.',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
            Icon(LucideIcons.chevronRight, size: 18, color: UniHubColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _ChallengeSection extends StatelessWidget {
  const _ChallengeSection({required this.challenge});

  final Challenge challenge;

  @override
  Widget build(BuildContext context) {
    final c = challenge;
    final top = c.ranking.isEmpty ? 1.0 : c.ranking.first.score;
    final mine = c.myRow;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${c.betweenCourses ? 'ENTRE CURSOS · ${c.universityName}' : 'ENTRE FACULDADES'} · ${_daysLeftLabel(c)}'
              .toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: UniHubColors.accent,
          ),
        ),
        const SizedBox(height: UniHubSpacing.x2),
        Text(c.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        if (c.description != null) ...[
          const SizedBox(height: 4),
          Text(c.description!, style: const TextStyle(fontSize: 14, color: UniHubColors.textSecondary)),
        ],
        const SizedBox(height: UniHubSpacing.x4),
        Row(
          children: [
            Expanded(
              child: _Stat(
                label: c.betweenCourses ? 'Seu curso' : 'Sua faculdade',
                value: mine == null ? '—' : '${mine.position}º',
                detail: mine?.name ?? c.myGroup ?? '',
              ),
            ),
            Expanded(
              child: _Stat(
                label: 'Você somou',
                value: '${c.myCheckins}',
                detail: c.myCheckins == 1 ? 'check-in' : 'check-ins',
              ),
            ),
            Expanded(
              child: _Stat(
                label: 'Pontuação',
                value: mine == null ? '—' : c.formatScore(mine.score),
                detail: c.sharePercent ? 'da turma ativa' : 'por aluno',
              ),
            ),
          ],
        ),
        const SizedBox(height: UniHubSpacing.x6),
        for (final row in c.ranking) ...[
          _RankingRow(challenge: c, row: row, top: top, mine: row.name == c.myGroup),
          const SizedBox(height: UniHubSpacing.x4),
        ],
        Text(
          c.sharePercent
              ? 'Conta a parte da turma com ao menos um treino por semana. Chame os colegas!'
              : 'Conta a média de check-ins por aluno: grupo pequeno também pode ganhar.',
          style: const TextStyle(fontSize: 12, color: UniHubColors.textSecondary),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.detail});

  final String label;
  final String value;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: UniHubColors.textSecondary)),
        const SizedBox(height: 2),
        Text(value, style: UniHubStyles.money(size: 22, weight: FontWeight.w800)),
        Text(
          detail,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, color: UniHubColors.textSecondary),
        ),
      ],
    );
  }
}

class _RankingRow extends StatelessWidget {
  const _RankingRow({required this.challenge, required this.row, required this.top, required this.mine});

  final Challenge challenge;
  final ChallengeRow row;
  final double top;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final color = mine ? UniHubColors.accent : UniHubColors.textPrimary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 30,
              child: Text(
                '${row.position}º',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color),
              ),
            ),
            Expanded(
              child: Text(
                mine ? '${row.name} (você)' : row.name,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: color),
              ),
            ),
            Text(
              challenge.formatScore(row.score),
              style: UniHubStyles.money(size: 13, weight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 30),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: top == 0 ? 0 : row.score / top,
              minHeight: 6,
              backgroundColor: UniHubColors.surface,
              color: mine ? UniHubColors.accent : UniHubColors.textSecondary,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 30, top: 4),
          child: Text(
            '${row.checkins} check-ins · ${row.participants} ${row.participants == 1 ? 'aluno' : 'alunos'}',
            style: const TextStyle(fontSize: 12, color: UniHubColors.textSecondary),
          ),
        ),
      ],
    );
  }
}

/// Escolha do curso (perfil e desafios): entra na copa entre cursos da faculdade.
Future<void> pickCourse(BuildContext context, WidgetRef ref, String? current) async {
  final List<String> courses;
  try {
    courses = await ref.read(coursesProvider.future);
  } catch (e) {
    if (context.mounted) showApiError(context, e);
    return;
  }
  if (!context.mounted) return;
  final picked = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: UniHubColors.background,
    builder: (sheetContext) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.75),
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(UniHubSpacing.x6, UniHubSpacing.x6, UniHubSpacing.x6, UniHubSpacing.x2),
              child: Text('Qual é o seu curso?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ),
            for (final course in courses)
              ListTile(
                title: Text(course),
                trailing: course == current
                    ? const Icon(LucideIcons.check, color: UniHubColors.accent, size: 18)
                    : null,
                onTap: () => Navigator.of(sheetContext).pop(course),
              ),
            const SizedBox(height: UniHubSpacing.x4),
          ],
        ),
      ),
    ),
  );
  if (picked == null || picked == current) return;
  try {
    await ref.read(apiClientProvider).updateMyProfile(course: picked);
    await ref.read(authProvider.notifier).refreshProfile();
    ref.invalidate(myChallengesProvider);
  } catch (e) {
    if (context.mounted) showApiError(context, e);
  }
}
