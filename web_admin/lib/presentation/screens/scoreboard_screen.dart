import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';

import '../providers.dart';
import '../widgets/challenge_ranking.dart';

/// Placar público do desafio: tela cheia e escura para projetar na TV da
/// faculdade ou abrir pelo link no grupo da turma. Não pede login e se
/// atualiza sozinho.
class ScoreboardScreen extends ConsumerStatefulWidget {
  const ScoreboardScreen({super.key, required this.token});

  final String token;

  @override
  ConsumerState<ScoreboardScreen> createState() => _ScoreboardScreenState();
}

class _ScoreboardScreenState extends ConsumerState<ScoreboardScreen> {
  static const _refreshEvery = Duration(seconds: 60);
  static const _background = Color(0xFF111113);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(_refreshEvery, (_) => ref.invalidate(scoreboardProvider(widget.token)));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final boardAsync = ref.watch(scoreboardProvider(widget.token));
    final wide = MediaQuery.sizeOf(context).width >= 760;

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: boardAsync.when(
          // Na atualização automática mantém o placar anterior na tela
          skipLoadingOnRefresh: true,
          loading: () => const Center(child: CircularProgressIndicator(color: UniHubColors.accent)),
          error: (e, _) => Center(
            child: Text(
              e is ApiException ? e.message : 'Placar indisponível.',
              style: const TextStyle(color: Colors.white70, fontSize: 18),
            ),
          ),
          data: (c) {
            final status = switch (c.status) {
              'upcoming' => 'Começa em ${formatDate(c.startDate)}',
              'ended' => c.ranking.isNotEmpty && c.totalCheckins > 0
                  ? 'Encerrado · campeão: ${c.ranking.first.name}'
                  : 'Encerrado',
              _ => c.daysLeft == 0 ? 'Último dia!' : 'Faltam ${c.daysLeft} dias',
            };
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: ListView(
                  padding: EdgeInsets.all(wide ? UniHubSpacing.x12 : UniHubSpacing.x6),
                  children: [
                    Row(
                      children: [
                        const Text.rich(
                          TextSpan(children: [
                            TextSpan(text: 'UniHub'),
                            TextSpan(text: '.', style: TextStyle(color: UniHubColors.accent)),
                          ]),
                          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: UniHubSpacing.x3, vertical: 6),
                          decoration: BoxDecoration(
                            color: c.isActive ? UniHubColors.accent : Colors.white12,
                            borderRadius: UniHubRadius.brMd,
                          ),
                          child: Text(
                            status,
                            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: wide ? UniHubSpacing.x10 : UniHubSpacing.x8),
                    Text(
                      c.title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: wide ? 44 : 28,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: UniHubSpacing.x3),
                    Text(
                      [
                        if (c.universityName != null) c.universityName!,
                        c.metricLabel,
                        '${c.participants} alunos',
                        '${c.totalCheckins} check-ins',
                      ].join('  ·  '),
                      style: TextStyle(color: Colors.white60, fontSize: wide ? 18 : 14),
                    ),
                    if (c.description != null) ...[
                      const SizedBox(height: UniHubSpacing.x2),
                      Text(c.description!, style: TextStyle(color: Colors.white70, fontSize: wide ? 18 : 14)),
                    ],
                    SizedBox(height: wide ? UniHubSpacing.x10 : UniHubSpacing.x8),
                    ChallengeRanking(challenge: c, dark: true, large: wide),
                    const SizedBox(height: UniHubSpacing.x10),
                    Text(
                      'Treine pelo app UniHub e some pontos para o seu ${c.betweenCourses ? 'curso' : 'time'}.'
                      ' Placar atualizado a cada minuto.',
                      style: const TextStyle(color: Colors.white38, fontSize: 13),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
