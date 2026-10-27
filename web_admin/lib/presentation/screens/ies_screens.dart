import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_models/shared_models.dart';

import '../providers.dart';
import '../widgets/common.dart';

/// Portal da faculdade: adesão, uso e a fatura do mês.
class IesOverviewScreen extends ConsumerWidget {
  const IesOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewAsync = ref.watch(iesOverviewProvider);
    final university = ref.watch(sessionProvider).value?.university;

    return overviewAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text(
          '$e',
          style: const TextStyle(color: UniHubColors.textSecondary),
        ),
      ),
      data: (o) {
        final adoption = o.registeredStudents == 0
            ? 0
            : o.subscribers / o.registeredStudents;
        return ListView(
          padding: pagePadding(context),
          children: [
            PageTitle(
              'Visão geral',
              subtitle:
                  'Programa de bem-estar da ${university?.name ?? 'faculdade'} no mês',
              action: IconButton(
                onPressed: () {
                  ref.invalidate(iesOverviewProvider);
                  ref.invalidate(iesStudentsProvider);
                },
                icon: const Icon(
                  LucideIcons.refreshCw,
                  size: 18,
                  color: UniHubColors.textSecondary,
                ),
                tooltip: 'Atualizar',
              ),
            ),
            const SizedBox(height: UniHubSpacing.x8),
            MetricRow(
              children: [
                MetricBlock(
                  label: 'Cadastrados',
                  value: '${o.registeredStudents}',
                  detail: 'com o e-mail da faculdade',
                ),
                MetricBlock(
                  label: 'Assinantes',
                  value: '${o.subscribers}',
                  detail: '${(adoption * 100).round()}% dos cadastrados',
                ),
                MetricBlock(
                  label: 'Treinaram no mês',
                  value: '${o.activeUsers}',
                  detail:
                      '${o.visitsPerActiveUser.toStringAsFixed(1).replaceAll('.', ',')} visitas por aluno ativo',
                ),
                MetricBlock(
                  label: 'Fatura do mês',
                  value: formatBRL(o.invoice.total),
                  detail: 'detalhe abaixo',
                  highlight: true,
                ),
              ],
            ),
            const SizedBox(height: UniHubSpacing.x10),
            const Divider(),
            const SizedBox(height: UniHubSpacing.x8),
            const Text(
              'Fatura',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: UniHubSpacing.x4),
            MaxWidth(
              maxWidth: 560,
              child: Column(
                children: [
                  _InvoiceLine('Taxa fixa do convênio', o.invoice.monthlyFee),
                  _InvoiceLine(
                    'Taxa por assinante (${o.subscribers} × ${formatBRL(university?.feePerStudent ?? 0)})',
                    o.invoice.perStudentFees,
                  ),
                  _InvoiceLine(
                    'Subsídio aos alunos (${o.subscribers} × ${formatBRL(university?.subsidyPerStudent ?? 0)})',
                    o.invoice.subsidies,
                  ),
                  const Divider(),
                  _InvoiceLine('Total', o.invoice.total, bold: true),
                ],
              ),
            ),
            const SizedBox(height: UniHubSpacing.x10),
            const Divider(),
            const SizedBox(height: UniHubSpacing.x8),
            const Text(
              'Onde os alunos mais treinam',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: UniHubSpacing.x4),
            if (o.topGyms.isEmpty)
              const Text(
                'Nenhum check-in neste mês ainda.',
                style: TextStyle(
                  fontSize: 14,
                  color: UniHubColors.textSecondary,
                ),
              )
            else
              for (final (i, g) in o.topGyms.indexed)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: UniHubSpacing.x2,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 28,
                        child: Text(
                          '${i + 1}º',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: i == 0
                                ? UniHubColors.accent
                                : UniHubColors.textSecondary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          g.gymName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(
                        '${g.checkins} check-ins',
                        style: UniHubStyles.money(size: 14),
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

class _InvoiceLine extends StatelessWidget {
  const _InvoiceLine(this.label, this.value, {this.bold = false});

  final String label;
  final double value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: UniHubSpacing.x2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            formatBRL(value),
            style: UniHubStyles.money(
              size: 14,
              weight: bold ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Alunos da faculdade no programa, com o uso no mês.
class IesStudentsScreen extends ConsumerStatefulWidget {
  const IesStudentsScreen({super.key});

  @override
  ConsumerState<IesStudentsScreen> createState() => _IesStudentsScreenState();
}

class _IesStudentsScreenState extends ConsumerState<IesStudentsScreen> {
  String _search = '';
  String? _status;

  static const _statusLabels = {'active': 'Assinante', 'paused': 'Pausado'};

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(iesStudentsProvider);
    return studentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text(
          '$e',
          style: const TextStyle(color: UniHubColors.textSecondary),
        ),
      ),
      data: (students) {
        var rows = students;
        if (_search.isNotEmpty) {
          final q = _search.toLowerCase();
          rows = rows
              .where(
                (s) =>
                    s.name.toLowerCase().contains(q) ||
                    s.email.toLowerCase().contains(q),
              )
              .toList();
        }
        if (_status != null) {
          rows = rows
              .where(
                (s) =>
                    (_statusLabels[s.subscriptionStatus] ?? 'Sem plano') ==
                    _status,
              )
              .toList();
        }
        return ListView(
          padding: pagePadding(context),
          children: [
            PageTitle(
              'Alunos',
              subtitle: '${students.length} cadastrados no programa',
            ),
            const SizedBox(height: UniHubSpacing.x6),
            Wrap(
              spacing: UniHubSpacing.x3,
              runSpacing: UniHubSpacing.x3,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Buscar por nome ou e-mail',
                      prefixIcon: Icon(LucideIcons.search, size: 18),
                    ),
                    onChanged: (v) => setState(() => _search = v),
                  ),
                ),
                FilterDropdown(
                  label: 'Situação',
                  value: _status,
                  options: const ['Assinante', 'Pausado', 'Sem plano'],
                  onChanged: (v) => setState(() => _status = v),
                ),
              ],
            ),
            const SizedBox(height: UniHubSpacing.x6),
            ResponsiveTable(
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('NOME')),
                  DataColumn(label: Text('E-MAIL')),
                  DataColumn(label: Text('SITUAÇÃO')),
                  DataColumn(label: Text('VISITAS NO MÊS'), numeric: true),
                  DataColumn(label: Text('ÚLTIMO TREINO')),
                ],
                rows: [
                  for (final s in rows)
                    DataRow(
                      cells: [
                        DataCell(
                          Text(
                            s.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        DataCell(Text(s.email)),
                        DataCell(
                          Text(
                            _statusLabels[s.subscriptionStatus] ?? 'Sem plano',
                          ),
                        ),
                        DataCell(
                          Text(
                            '${s.monthCheckins}',
                            style: UniHubStyles.money(size: 14),
                          ),
                        ),
                        DataCell(
                          Text(
                            s.lastCheckin == null
                                ? '—'
                                : formatDate(s.lastCheckin!),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: UniHubSpacing.x4),
            const Text(
              'A faculdade vê só frequência, nunca localização ou horários de cada aluno.',
              style: TextStyle(
                fontSize: 12.5,
                color: UniHubColors.textSecondary,
              ),
            ),
          ],
        );
      },
    );
  }
}
