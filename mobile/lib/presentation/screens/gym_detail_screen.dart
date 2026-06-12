import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_models/shared_models.dart';

import '../../domain/access_rules.dart';
import '../providers.dart';
import '../widgets/common.dart';
import 'checkin_flow.dart';

class GymDetailScreen extends ConsumerWidget {
  const GymDetailScreen({super.key, required this.gymId});

  final int gymId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final student = ref.watch(authProvider).value;
    final gymAsync = ref.watch(gymDetailProvider(gymId));

    return Scaffold(
      appBar: AppBar(title: const Text('Academia')),
      body: gymAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(icon: LucideIcons.wifiOff, message: '$e'),
        data: (gym) {
          final covered = planCoversGym(student, gym);
          return ListView(
            padding: const EdgeInsets.all(UniHubSpacing.x6),
            children: [
              if (gym.photoUrl != null)
                ClipRRect(
                  borderRadius: UniHubRadius.brMd,
                  child: Image.network(
                    gym.photoUrl!,
                    height: 180,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      height: 180,
                      color: UniHubColors.surface,
                      child: const Icon(LucideIcons.dumbbell,
                          size: 40, color: UniHubColors.textSecondary),
                    ),
                  ),
                ),
              const SizedBox(height: UniHubSpacing.x6),
              Text(gym.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: UniHubSpacing.x2),
              AccessBadge(covered: covered, minTier: gym.minPlanTier),
              const SizedBox(height: UniHubSpacing.x6),
              _InfoRow(
                icon: LucideIcons.mapPin,
                text: '${gym.address} · ${gymDistanceKm(gym).toStringAsFixed(1)} km',
              ),
              const SizedBox(height: UniHubSpacing.x3),
              _InfoRow(icon: LucideIcons.clock, text: gym.openingHours),
              const SizedBox(height: UniHubSpacing.x3),
              _InfoRow(icon: LucideIcons.users, text: 'Capacidade para ${gym.capacity} alunos'),
              const SizedBox(height: UniHubSpacing.x6),
              const Divider(),
              const SizedBox(height: UniHubSpacing.x6),
              const SectionTitle('Modalidades'),
              const SizedBox(height: UniHubSpacing.x3),
              Wrap(
                spacing: UniHubSpacing.x2,
                runSpacing: UniHubSpacing.x2,
                children: [
                  for (final m in gym.modalities)
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: UniHubSpacing.x3, vertical: 5),
                      decoration: BoxDecoration(
                        borderRadius: UniHubRadius.brSm,
                        border: Border.all(color: UniHubColors.border),
                      ),
                      child: Text(
                        m,
                        style:
                            const TextStyle(fontSize: 13, color: UniHubColors.textSecondary),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: UniHubSpacing.x8),
              if (covered)
                FilledButton.icon(
                  onPressed: () => startCheckinFlow(context, ref, gym),
                  icon: const Icon(LucideIcons.scanLine, size: 18),
                  label: const Text('Fazer check-in aqui'),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Esta academia está disponível a partir do Plano ${gym.minPlanTier}.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, color: UniHubColors.textSecondary),
                    ),
                    const SizedBox(height: UniHubSpacing.x3),
                    OutlinedButton(
                      onPressed: () => context.push('/plans'),
                      child: const Text('Ver planos'),
                    ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: UniHubColors.textSecondary),
        const SizedBox(width: UniHubSpacing.x3),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 14)),
        ),
      ],
    );
  }
}
