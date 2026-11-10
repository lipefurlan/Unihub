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
    final isFavorite = ref.watch(favoritesProvider).value?.any((g) => g.id == gymId) ?? false;
    final busyAsync = ref.watch(gymBusyHoursProvider(gymId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Academia'),
        actions: [
          IconButton(
            tooltip: isFavorite ? 'Tirar das favoritas' : 'Favoritar',
            icon: Icon(
              LucideIcons.heart,
              color: isFavorite ? UniHubColors.accent : UniHubColors.textSecondary,
              fill: isFavorite ? 1 : 0,
            ),
            onPressed: () async {
              try {
                await ref.read(apiClientProvider).setFavorite(gymId, !isFavorite);
                ref.invalidate(favoritesProvider);
              } catch (e) {
                if (context.mounted) showApiError(context, e);
              }
            },
          ),
        ],
      ),
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
              busyAsync.maybeWhen(
                data: (busy) => _BusyHours(busy: busy),
                orElse: () => const SizedBox.shrink(),
              ),
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


/// Movimento por hora (check-ins UniHub) e a faixa mais tranquila.
class _BusyHours extends StatelessWidget {
  const _BusyHours({required this.busy});

  final GymBusyHours busy;

  @override
  Widget build(BuildContext context) {
    if (busy.quietestStart == null) return const SizedBox.shrink();
    final peak = busy.peak == 0 ? 1 : busy.peak;
    final hours = busy.checkinsByHour.keys.toList()..sort();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Movimento'),
        const SizedBox(height: UniHubSpacing.x2),
        Text(
          'Mais tranquilo entre ${busy.quietestStart}h e ${busy.quietestEnd}h',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: UniHubSpacing.x4),
        SizedBox(
          height: 56,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final h in hours)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1.5),
                    child: Container(
                      height: 4 + 52 * busy.checkinsByHour[h]! / peak,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: h >= busy.quietestStart! && h < busy.quietestEnd!
                            ? UniHubColors.accent
                            : UniHubColors.border,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${hours.first}h', style: const TextStyle(fontSize: 11, color: UniHubColors.textSecondary)),
            Text('${hours.last + 1}h', style: const TextStyle(fontSize: 11, color: UniHubColors.textSecondary)),
          ],
        ),
        const SizedBox(height: 2),
        const Text(
          'Check-ins de alunos UniHub nos últimos 30 dias',
          style: TextStyle(fontSize: 11, color: UniHubColors.textSecondary),
        ),
        const SizedBox(height: UniHubSpacing.x6),
        const Divider(),
        const SizedBox(height: UniHubSpacing.x6),
      ],
    );
  }
}
