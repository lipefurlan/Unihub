import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_models/shared_models.dart';

import '../providers.dart';
import '../widgets/common.dart';

/// Visão geral da plataforma para a operação UniHub.
class AdminOverviewScreen extends ConsumerWidget {
  const AdminOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewAsync = ref.watch(adminOverviewProvider);

    return overviewAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text('$e', style: const TextStyle(color: UniHubColors.textSecondary)),
      ),
      data: (o) => ListView(
        padding: const EdgeInsets.all(UniHubSpacing.x8),
        children: [
          PageTitle(
            'Visão geral',
            subtitle: 'A plataforma no mês corrente',
            action: IconButton(
              onPressed: () => ref.invalidate(adminOverviewProvider),
              icon: const Icon(LucideIcons.refreshCw, size: 18, color: UniHubColors.textSecondary),
              tooltip: 'Atualizar',
            ),
          ),
          const SizedBox(height: UniHubSpacing.x8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: MetricBlock(
                  label: 'Estudantes ativos',
                  value: '${o.activeStudents}',
                  detail: 'assinaturas vigentes',
                ),
              ),
              Expanded(
                child: MetricBlock(
                  label: 'Receita de assinaturas',
                  value: formatBRL(o.subscriptionRevenue),
                  detail: 'por mês',
                ),
              ),
              Expanded(
                child: MetricBlock(
                  label: 'Repasses do mês',
                  value: formatBRL(o.monthPayoutTotal),
                  detail: '${o.monthCheckins} check-ins',
                ),
              ),
              Expanded(
                child: MetricBlock(
                  label: 'Margem estimada',
                  value: formatBRL(o.estimatedMargin),
                  detail: 'assinaturas − repasses',
                  highlight: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: UniHubSpacing.x10),
          const Divider(),
          const SizedBox(height: UniHubSpacing.x8),
          Text(
            'Academias mais usadas no mês — ${o.activeGyms} parceiras ativas',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: UniHubSpacing.x4),
          if (o.topGyms.isEmpty)
            const Text(
              'Nenhum check-in registrado neste mês ainda.',
              style: TextStyle(fontSize: 14, color: UniHubColors.textSecondary),
            )
          else
            Column(
              children: [
                for (final (i, g) in o.topGyms.indexed) ...[
                  if (i > 0) const Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: UniHubSpacing.x3),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 28,
                          child: Text(
                            '${i + 1}º',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: i == 0 ? UniHubColors.accent : UniHubColors.textSecondary,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            g.gymName,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ),
                        Text(
                          '${g.checkins} check-ins',
                          style: UniHubStyles.money(size: 14, weight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}
