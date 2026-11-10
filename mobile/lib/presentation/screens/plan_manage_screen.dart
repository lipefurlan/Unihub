import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_models/shared_models.dart';

import '../providers.dart';
import '../widgets/common.dart';

/// Troca de plano (sem pagamento real: só atualiza a assinatura).
class PlanManageScreen extends ConsumerStatefulWidget {
  const PlanManageScreen({super.key});

  @override
  ConsumerState<PlanManageScreen> createState() => _PlanManageScreenState();
}

class _PlanManageScreenState extends ConsumerState<PlanManageScreen> {
  bool _busy = false;

  Future<void> _selectPlan(Plan plan) async {
    final student = ref.read(authProvider).value;
    if (student == null || _busy) return;

    final current = student.subscription;
    if (current?.plan.id == plan.id) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(current == null ? 'Assinar ${plan.name}?' : 'Trocar para ${plan.name}?'),
        content: Text(
          '${_priceLabel(student, plan)}. ${plan.benefitsDescription} '
          '(POC: nenhuma cobrança real será feita.)',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busy = true);
    try {
      final api = ref.read(apiClientProvider);
      if (current == null) {
        await api.createSubscription(plan.id);
      } else {
        await api.updateSubscription(current.id, planId: plan.id);
      }
      await ref.read(authProvider.notifier).refreshProfile();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Agora você está no ${plan.name}.')),
        );
      }
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final student = ref.watch(authProvider).value;
    final plansAsync = ref.watch(plansProvider);
    final currentPlanId = student?.subscription?.plan.id;

    return Scaffold(
      appBar: AppBar(title: const Text('Planos')),
      body: plansAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(icon: LucideIcons.wifiOff, message: '$e'),
        data: (plans) => ListView.separated(
          padding: const EdgeInsets.all(UniHubSpacing.x6),
          itemCount: plans.length,
          separatorBuilder: (_, _) => const Divider(),
          itemBuilder: (context, i) {
            final plan = plans[i];
            final isCurrent = plan.id == currentPlanId;
            return InkWell(
              onTap: _busy || isCurrent ? null : () => _selectPlan(plan),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: UniHubSpacing.x4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.only(top: 6, right: UniHubSpacing.x3),
                      decoration: BoxDecoration(
                        color: Color(int.parse(plan.color.replaceFirst('#', '0xFF'))),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                plan.name,
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(width: UniHubSpacing.x2),
                              if (isCurrent)
                                const Text(
                                  'PLANO ATUAL',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1,
                                    color: UniHubColors.accent,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            plan.benefitsDescription,
                            style: const TextStyle(
                                fontSize: 13, color: UniHubColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: UniHubSpacing.x3),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${formatBRL(student?.priceFor(plan) ?? plan.monthlyPrice)}/mês',
                          style: UniHubStyles.money(size: 14),
                        ),
                        if ((student?.universitySubsidy ?? 0) > 0)
                          Text(
                            'com subsídio da ${student!.university}',
                            style: const TextStyle(
                                fontSize: 11, color: UniHubColors.textSecondary),
                          ),
                      ],
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

/// "R$ 120,00/mês (R$ 130,00 menos R$ 10,00 de subsídio da Unicamp)".
String _priceLabel(Student student, Plan plan) {
  final price = '${formatBRL(student.priceFor(plan))}/mês';
  if (student.universitySubsidy <= 0) return price;
  return '$price (${formatBRL(plan.monthlyPrice)} menos '
      '${formatBRL(student.universitySubsidy)} de subsídio da ${student.university})';
}
