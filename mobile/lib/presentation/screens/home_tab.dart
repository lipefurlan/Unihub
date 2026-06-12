import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_models/shared_models.dart';

import '../../domain/access_rules.dart';
import '../providers.dart';
import '../widgets/common.dart';

class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final student = ref.watch(authProvider).value;
    final checkins = ref.watch(myCheckinsProvider);
    final gyms = ref.watch(gymsProvider);

    return Scaffold(
      appBar: AppBar(title: const UniHubWordmark()),
      body: RefreshIndicator(
        color: UniHubColors.accent,
        onRefresh: () async {
          ref.invalidate(myCheckinsProvider);
          ref.invalidate(gymsProvider);
          await ref.read(authProvider.notifier).refreshProfile();
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(UniHubSpacing.x6),
          children: [
            Text(
              'Olá, ${student?.name.split(' ').first ?? ''}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            Text(
              student?.university ?? '',
              style: const TextStyle(fontSize: 14, color: UniHubColors.textSecondary),
            ),
            const SizedBox(height: UniHubSpacing.x8),
            _PlanSection(student: student),
            const SizedBox(height: UniHubSpacing.x8),
            FilledButton.icon(
              onPressed: () => context.go('/checkin'),
              icon: const Icon(LucideIcons.scanLine, size: 18),
              label: const Text('Fazer check-in'),
            ),
            const SizedBox(height: UniHubSpacing.x8),
            const SectionTitle('Seu mês'),
            const SizedBox(height: UniHubSpacing.x4),
            checkins.when(
              loading: () => const LinearProgressIndicator(minHeight: 2),
              error: (e, _) => Text('$e',
                  style: const TextStyle(color: UniHubColors.textSecondary, fontSize: 13)),
              data: (list) {
                final now = DateTime.now();
                final monthCheckins = list
                    .where((c) => c.timestamp.year == now.year && c.timestamp.month == now.month)
                    .toList();
                final visited = monthCheckins.map((c) => c.gym.id).toSet().length;
                return Row(
                  children: [
                    Expanded(
                      child: StatBlock(value: '${monthCheckins.length}', label: 'Check-ins no mês'),
                    ),
                    Expanded(
                      child: StatBlock(value: '$visited', label: 'Academias visitadas'),
                    ),
                  ],
                );
              },
            ),
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

class _PlanSection extends ConsumerWidget {
  const _PlanSection({required this.student});

  final Student? student;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscription = student?.subscription;

    if (subscription == null) {
      // Estudante recém-cadastrado: precisa escolher um plano
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('Meu plano'),
          const SizedBox(height: UniHubSpacing.x3),
          const Text(
            'Você ainda não tem um plano ativo.',
            style: TextStyle(fontSize: 14, color: UniHubColors.textSecondary),
          ),
          const SizedBox(height: UniHubSpacing.x3),
          OutlinedButton(
            onPressed: () => context.push('/plans'),
            child: const Text('Escolher plano'),
          ),
        ],
      );
    }

    final plan = subscription.plan;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          'Meu plano',
          action: TextButton(
            onPressed: () => context.push('/plans'),
            child: const Text('Gerenciar'),
          ),
        ),
        const SizedBox(height: UniHubSpacing.x2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(right: UniHubSpacing.x2),
              decoration: BoxDecoration(
                color: Color(int.parse(plan.color.replaceFirst('#', '0xFF'))),
                shape: BoxShape.circle,
              ),
            ),
            Text(
              plan.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: UniHubSpacing.x3),
            Text(
              '${formatBRL(plan.monthlyPrice)}/mês',
              style: UniHubStyles.money(size: 14, weight: FontWeight.w500,
                  color: UniHubColors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: UniHubSpacing.x1),
        Text(
          'Renova em ${formatDate(subscription.renewalDate)}',
          style: const TextStyle(fontSize: 13, color: UniHubColors.textSecondary),
        ),
        if (plan.hasRunningCoach) ...[
          const SizedBox(height: UniHubSpacing.x2),
          const Text(
            'Inclui plano de treino mensal com assessoria de corrida',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: UniHubColors.accent,
            ),
          ),
        ],
      ],
    );
  }
}
