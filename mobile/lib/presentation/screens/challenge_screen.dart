import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_models/shared_models.dart';

import '../providers.dart';
import '../widgets/common.dart';

/// Card do desafio do mês na tela inicial: posição da faculdade do aluno.
class ChallengeCard extends ConsumerWidget {
  const ChallengeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challenge = ref.watch(challengeProvider).value;
    if (challenge == null || challenge.ranking.isEmpty) return const SizedBox.shrink();
    final mine = challenge.myRow;
    final daysLeft = challenge.endsOn.difference(DateTime.now()).inDays + 1;
    return InkWell(
      borderRadius: UniHubRadius.brMd,
      onTap: () => context.push('/desafio'),
      child: Container(
        padding: const EdgeInsets.all(UniHubSpacing.x5),
        decoration: BoxDecoration(
          borderRadius: UniHubRadius.brMd,
          color: UniHubColors.textPrimary,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DESAFIO DO MÊS · ${daysLeft == 1 ? 'último dia' : 'faltam $daysLeft dias'}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: UniHubColors.accent,
                    ),
                  ),
                  const SizedBox(height: UniHubSpacing.x2),
                  const Text(
                    'Qual faculdade treina mais?',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    mine == null
                        ? 'Assine e treine para sua faculdade entrar no ranking.'
                        : '${mine.university} está em ${mine.position}º de ${challenge.ranking.length}. '
                            'Você já fez ${challenge.myCheckins} check-ins no mês.',
                    style: const TextStyle(fontSize: 13, color: Colors.white70),
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

/// Ranking completo do desafio entre faculdades.
class ChallengeScreen extends ConsumerWidget {
  const ChallengeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challengeAsync = ref.watch(challengeProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Desafio do mês')),
      body: challengeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(icon: LucideIcons.wifiOff, message: '$e'),
        data: (c) {
          final top = c.ranking.isEmpty ? 1.0 : c.ranking.first.score;
          return ListView(
            padding: const EdgeInsets.all(UniHubSpacing.x6),
            children: [
              const Icon(LucideIcons.trophy, size: 36, color: UniHubColors.accent),
              const SizedBox(height: UniHubSpacing.x3),
              Text(c.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: UniHubSpacing.x2),
              Text(
                '${c.description} Termina em ${formatDate(c.endsOn)}.',
                style: const TextStyle(fontSize: 14, color: UniHubColors.textSecondary),
              ),
              const SizedBox(height: UniHubSpacing.x8),
              for (final row in c.ranking) ...[
                _RankingRow(row: row, top: top, mine: row.universityId == c.myUniversityId),
                const SizedBox(height: UniHubSpacing.x4),
              ],
              const SizedBox(height: UniHubSpacing.x4),
              Text(
                'Cada check-in seu soma para a sua faculdade. Você fez ${c.myCheckins} neste mês.',
                style: const TextStyle(fontSize: 13, color: UniHubColors.textSecondary),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RankingRow extends StatelessWidget {
  const _RankingRow({required this.row, required this.top, required this.mine});

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
                mine ? '${row.university} (sua)' : row.university,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: color),
              ),
            ),
            Text(
              '${row.score.toStringAsFixed(1).replaceAll('.', ',')} por aluno',
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
            '${row.checkins} check-ins · ${row.subscribers} ${row.subscribers == 1 ? 'assinante' : 'assinantes'}',
            style: const TextStyle(fontSize: 12, color: UniHubColors.textSecondary),
          ),
        ),
      ],
    );
  }
}
