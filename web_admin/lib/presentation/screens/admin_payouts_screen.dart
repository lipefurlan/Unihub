import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_models/shared_models.dart';

import '../providers.dart';
import '../widgets/common.dart';

/// Caixa da operação: quanto pagar a cada academia no mês, com baixa manual.
class AdminPayoutsScreen extends ConsumerStatefulWidget {
  const AdminPayoutsScreen({super.key});

  @override
  ConsumerState<AdminPayoutsScreen> createState() => _AdminPayoutsScreenState();
}

class _AdminPayoutsScreenState extends ConsumerState<AdminPayoutsScreen> {
  late String _month;
  bool _busy = false;
  String _search = '';
  int _sortColumn = 0; // ACADEMIA
  bool _ascending = true;

  void _onSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumn = columnIndex;
      _ascending = ascending;
    });
  }

  @override
  void initState() {
    super.initState();
    _month = _monthKey(DateTime.now());
  }

  static String _monthKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}';

  /// Últimos 6 meses para o seletor.
  List<String> get _monthOptions {
    final now = DateTime.now();
    return [
      for (var i = 0; i < 6; i++)
        _monthKey(DateTime(now.year, now.month - i, 1)),
    ];
  }

  Future<void> _markPaid(AdminPayoutRow row) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Confirmar pagamento à ${row.gymName}?'),
        content: Text(
          '${row.totalCheckins} check-ins em ${monthLabel(row.referenceMonth)} = '
          '${formatBRL(row.totalAmount)}. O status passa a "pago".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Confirmar pagamento'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busy = true);
    try {
      await ref
          .read(apiClientProvider)
          .markPayoutPaid(row.gymId, row.referenceMonth);
      ref.invalidate(adminPayoutsProvider(_month));
      ref.invalidate(adminOverviewProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Repasse de ${row.gymName} marcado como pago.'),
          ),
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
    final payoutsAsync = ref.watch(adminPayoutsProvider(_month));

    return ListView(
      padding: const EdgeInsets.all(UniHubSpacing.x8),
      children: [
        PageTitle(
          'Repasses',
          subtitle: 'Quanto a plataforma deve a cada academia parceira',
          action: DropdownButton<String>(
            value: _month,
            underline: const SizedBox.shrink(),
            items: [
              for (final m in _monthOptions)
                DropdownMenuItem(value: m, child: Text(monthLabel(m))),
            ],
            onChanged: (m) => setState(() => _month = m ?? _month),
          ),
        ),
        const SizedBox(height: UniHubSpacing.x6),
        payoutsAsync.when(
          loading: () => const LinearProgressIndicator(minHeight: 2),
          error: (e, _) => Text(
            '$e',
            style: const TextStyle(color: UniHubColors.textSecondary),
          ),
          data: (rows) {
            if (rows.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: UniHubSpacing.x8),
                child: Text(
                  'Nenhum check-in neste mês.',
                  style: TextStyle(
                    fontSize: 14,
                    color: UniHubColors.textSecondary,
                  ),
                ),
              );
            }
            // Métricas sempre sobre o mês inteiro (independem do filtro da tabela)
            final total = rows.fold<double>(0, (sum, r) => sum + r.totalAmount);
            final pending = rows
                .where((r) => !r.isPaid)
                .fold<double>(0, (s, r) => s + r.totalAmount);

            var visible = rows;
            if (_search.isNotEmpty) {
              final q = _search.toLowerCase();
              visible = visible
                  .where((r) => r.gymName.toLowerCase().contains(q))
                  .toList();
            }
            visible = [...visible]
              ..sort((a, b) {
                final cmp = switch (_sortColumn) {
                  0 => a.gymName.compareTo(b.gymName),
                  1 => a.totalCheckins.compareTo(b.totalCheckins),
                  2 => a.totalAmount.compareTo(b.totalAmount),
                  _ => a.status.compareTo(b.status),
                };
                return _ascending ? cmp : -cmp;
              });

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: MetricBlock(
                        label: 'Total do mês',
                        value: formatBRL(total),
                        detail: '${rows.length} academias',
                      ),
                    ),
                    Expanded(
                      child: MetricBlock(
                        label: 'Pendente de pagamento',
                        value: formatBRL(pending),
                        highlight: pending > 0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: UniHubSpacing.x6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Buscar academia',
                      prefixIcon: Icon(LucideIcons.search, size: 18),
                    ),
                    onChanged: (v) => setState(() => _search = v),
                  ),
                ),
                const SizedBox(height: UniHubSpacing.x4),
                SizedBox(
                  width: double.infinity,
                  child: DataTable(
                    sortColumnIndex: _sortColumn,
                    sortAscending: _ascending,
                    showCheckboxColumn: false,
                    columns: [
                      DataColumn(
                        label: const Text('ACADEMIA'),
                        onSort: _onSort,
                      ),
                      DataColumn(
                        label: const Text('CHECK-INS'),
                        numeric: true,
                        onSort: _onSort,
                      ),
                      DataColumn(
                        label: const Text('VALOR'),
                        numeric: true,
                        onSort: _onSort,
                      ),
                      DataColumn(label: const Text('STATUS'), onSort: _onSort),
                      const DataColumn(label: Text('PAGO EM')),
                      const DataColumn(label: Text('')),
                    ],
                    rows: [
                      for (final r in visible)
                        DataRow(
                          cells: [
                            DataCell(
                              Text(
                                r.gymName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                '${r.totalCheckins}',
                                style: UniHubStyles.money(size: 14),
                              ),
                            ),
                            DataCell(
                              Text(
                                formatBRL(r.totalAmount),
                                style: UniHubStyles.money(size: 14),
                              ),
                            ),
                            DataCell(StatusBadge(paid: r.isPaid)),
                            DataCell(
                              Text(
                                r.paidAt == null ? '—' : formatDate(r.paidAt!),
                              ),
                            ),
                            DataCell(
                              r.isPaid
                                  ? const SizedBox.shrink()
                                  : TextButton(
                                      onPressed: _busy
                                          ? null
                                          : () => _markPaid(r),
                                      child: const Text('Marcar como pago'),
                                    ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
