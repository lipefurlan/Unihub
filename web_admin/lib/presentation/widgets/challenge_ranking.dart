import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';

/// Ranking em barras: usado no detalhe do painel e no placar público
/// ([dark] para projetar na TV).
class ChallengeRanking extends StatelessWidget {
  const ChallengeRanking({super.key, required this.challenge, this.dark = false, this.large = false});

  final Challenge challenge;
  final bool dark;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final c = challenge;
    if (c.ranking.isEmpty) {
      return Text(
        c.betweenCourses
            ? 'Nenhum aluno com curso informado tem assinatura ativa ainda.'
            : 'Nenhuma faculdade com assinantes ativos ainda.',
        style: TextStyle(color: dark ? Colors.white70 : UniHubColors.textSecondary),
      );
    }
    final top = c.ranking.first.score;
    final primary = dark ? Colors.white : UniHubColors.textPrimary;
    final secondary = dark ? Colors.white60 : UniHubColors.textSecondary;
    final track = dark ? Colors.white12 : UniHubColors.divider;
    final nameSize = large ? 22.0 : 14.0;

    return Column(
      children: [
        for (final row in c.ranking)
          Padding(
            padding: EdgeInsets.symmetric(vertical: large ? UniHubSpacing.x3 : UniHubSpacing.x2),
            child: Row(
              children: [
                SizedBox(
                  width: large ? 56 : 32,
                  child: Text(
                    '${row.position}º',
                    style: TextStyle(
                      fontSize: nameSize,
                      fontWeight: FontWeight.w800,
                      color: row.position == 1 ? UniHubColors.accent : secondary,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              row.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: nameSize, fontWeight: FontWeight.w700, color: primary),
                            ),
                          ),
                          Text(
                            c.formatScore(row.score),
                            style: TextStyle(
                              fontSize: nameSize,
                              fontWeight: FontWeight.w800,
                              fontFeatures: UniHubStyles.tabularNumbers,
                              color: row.position == 1 ? UniHubColors.accent : primary,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: large ? UniHubSpacing.x2 : 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: top <= 0 ? 0 : row.score / top,
                          minHeight: large ? 14 : 8,
                          backgroundColor: track,
                          color: row.position == 1 ? UniHubColors.accent : (dark ? Colors.white70 : UniHubColors.textPrimary),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${row.participants} ${row.participants == 1 ? 'aluno' : 'alunos'} · '
                        '${row.checkins} check-ins · '
                        '${row.activeStudents} treinando toda semana',
                        style: TextStyle(fontSize: large ? 15 : 12, color: secondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
