import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_models/shared_models.dart';

import '../csv_download.dart';
import '../providers.dart';
import '../widgets/common.dart';

/// Controle financeiro: extrato do mês, histórico de repasses e detalhamento.
class FinanceScreen extends ConsumerStatefulWidget {
  const FinanceScreen({super.key});

  @override
  ConsumerState<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends ConsumerState<FinanceScreen> {
  String? _selectedMonth;

  @override
  Widget build(BuildContext context) {
    final payoutsAsync = ref.watch(payoutsProvider);

    return payoutsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text(
          '$e',
          style: const TextStyle(color: UniHubColors.textSecondary),
        ),
      ),
      data: (payouts) {
        if (payouts.isEmpty) {
          return const Center(
            child: Text(
              'Nenhum repasse ainda — os check-ins dos alunos aparecem aqui.',
              style: TextStyle(color: UniHubColors.textSecondary),
            ),
          );
        }

        final selected = _selectedMonth ?? payouts.first.referenceMonth;
        final current = payouts.first;

        return ListView(
          padding: const EdgeInsets.all(UniHubSpacing.x8),
          children: [
            const PageTitle(
              'Financeiro',
              subtitle:
                  'Repasses por check-in — modelo UniHub: você recebe quando o aluno treina',
            ),
            const SizedBox(height: UniHubSpacing.x8),
            // Extrato do mês corrente: a conta que importa, em destaque
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: MetricBlock(
                    label:
                        'Mês corrente (${monthLabelShort(current.referenceMonth)})',
                    value: '${current.totalCheckins} check-ins',
                  ),
                ),
                Expanded(
                  child: MetricBlock(
                    label: 'Valor médio por check-in',
                    value: current.totalCheckins == 0
                        ? '—'
                        : formatBRL(
                            current.totalAmount / current.totalCheckins,
                          ),
                  ),
                ),
                Expanded(
                  child: MetricBlock(
                    label: 'A receber no mês',
                    value: formatBRL(current.totalAmount),
                    detail: 'em apuração até o fechamento',
                    highlight: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: UniHubSpacing.x10),
            const Divider(),
            const SizedBox(height: UniHubSpacing.x8),
            const Text(
              'Histórico de repasses',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: UniHubSpacing.x4),
            SizedBox(
              width: double.infinity,
              child: DataTable(
                showCheckboxColumn: false,
                columns: const [
                  DataColumn(label: Text('MÊS')),
                  DataColumn(label: Text('CHECK-INS'), numeric: true),
                  DataColumn(label: Text('VALOR'), numeric: true),
                  DataColumn(label: Text('STATUS')),
                  DataColumn(label: Text('PAGO EM')),
                  DataColumn(label: Text('')),
                ],
                rows: [
                  for (final p in payouts)
                    DataRow(
                      selected: p.referenceMonth == selected,
                      onSelectChanged: (_) =>
                          setState(() => _selectedMonth = p.referenceMonth),
                      cells: [
                        DataCell(
                          Text(
                            monthLabel(p.referenceMonth),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        DataCell(
                          Text(
                            '${p.totalCheckins}',
                            style: UniHubStyles.money(size: 14),
                          ),
                        ),
                        DataCell(
                          Text(
                            formatBRL(p.totalAmount),
                            style: UniHubStyles.money(size: 14),
                          ),
                        ),
                        DataCell(StatusBadge(paid: p.isPaid)),
                        DataCell(
                          Text(p.paidAt == null ? '—' : formatDate(p.paidAt!)),
                        ),
                        DataCell(
                          TextButton.icon(
                            onPressed: () => _exportCsv(p.referenceMonth),
                            icon: const Icon(LucideIcons.download, size: 15),
                            label: const Text('CSV'),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: UniHubSpacing.x10),
            const Divider(),
            const SizedBox(height: UniHubSpacing.x8),
            _MonthDetail(month: selected, onExport: () => _exportCsv(selected)),
          ],
        );
      },
    );
  }

  Future<void> _exportCsv(String month) async {
    try {
      final csv = await ref.read(apiClientProvider).downloadPayoutCsv(month);
      downloadTextFile(csv, 'extrato-unihub-$month.csv');
    } catch (e) {
      if (mounted) showApiError(context, e);
    }
  }
}

/// Detalhamento do mês selecionado: os check-ins que compõem o repasse.
class _MonthDetail extends ConsumerStatefulWidget {
  const _MonthDetail({required this.month, required this.onExport});

  final String month;
  final VoidCallback onExport;

  @override
  ConsumerState<_MonthDetail> createState() => _MonthDetailState();
}

class _MonthDetailState extends ConsumerState<_MonthDetail> {
  String _search = '';
  int _sortColumn = 0; // DATA/HORA
  bool _ascending = false;

  void _onSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumn = columnIndex;
      _ascending = ascending;
    });
  }

  @override
  Widget build(BuildContext context) {
    final month = widget.month;
    final detailAsync = ref.watch(payoutDetailProvider(month));

    return detailAsync.when(
      loading: () => const LinearProgressIndicator(minHeight: 2),
      error: (e, _) =>
          Text('$e', style: const TextStyle(color: UniHubColors.textSecondary)),
      data: (detail) {
        var checkins = detail.checkins;
        if (_search.isNotEmpty) {
          final q = _search.toLowerCase();
          checkins = checkins
              .where(
                (c) =>
                    c.studentName.toLowerCase().contains(q) ||
                    c.studentUniversity.toLowerCase().contains(q),
              )
              .toList();
        }
        checkins = [...checkins]
          ..sort((a, b) {
            final cmp = switch (_sortColumn) {
              1 => a.studentName.compareTo(b.studentName),
              2 => a.studentUniversity.compareTo(b.studentUniversity),
              4 => a.payoutAmountRecorded.compareTo(b.payoutAmountRecorded),
              _ => a.timestamp.compareTo(b.timestamp),
            };
            return _ascending ? cmp : -cmp;
          });

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Detalhamento — ${monthLabel(month)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: widget.onExport,
                  icon: const Icon(LucideIcons.download, size: 15),
                  label: const Text('Exportar extrato (CSV)'),
                ),
              ],
            ),
            const SizedBox(height: UniHubSpacing.x2),
            Text(
              '${detail.totalCheckins} check-ins × valor por check-in = '
              '${formatBRL(detail.totalAmount)} a receber',
              style: const TextStyle(
                fontSize: 13,
                color: UniHubColors.textSecondary,
              ),
            ),
            const SizedBox(height: UniHubSpacing.x4),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Buscar por aluno ou universidade',
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
                  DataColumn(label: const Text('DATA/HORA'), onSort: _onSort),
                  DataColumn(label: const Text('ALUNO'), onSort: _onSort),
                  DataColumn(
                    label: const Text('UNIVERSIDADE'),
                    onSort: _onSort,
                  ),
                  const DataColumn(label: Text('TIER DO PLANO'), numeric: true),
                  DataColumn(
                    label: const Text('REPASSE'),
                    numeric: true,
                    onSort: _onSort,
                  ),
                ],
                rows: [
                  for (final c in checkins)
                    DataRow(
                      cells: [
                        DataCell(Text(formatDateTime(c.timestamp))),
                        DataCell(
                          Text(
                            c.studentName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        DataCell(Text(c.studentUniversity)),
                        DataCell(Text('${c.planTierAtCheckin}')),
                        DataCell(
                          Text(
                            formatBRL(c.payoutAmountRecorded),
                            style: UniHubStyles.money(size: 14),
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
    );
  }
}
