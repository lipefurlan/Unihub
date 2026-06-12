import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_models/shared_models.dart';

import '../providers.dart';
import '../widgets/common.dart';

class StudentsScreen extends ConsumerStatefulWidget {
  const StudentsScreen({super.key});

  @override
  ConsumerState<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends ConsumerState<StudentsScreen> {
  String _search = '';
  String? _university;
  String? _plan;
  int _sortColumn = 4; // índice visual da coluna; padrão: último check-in
  bool _ascending = false;

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(gymStudentsProvider);

    return studentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text(
          '$e',
          style: const TextStyle(color: UniHubColors.textSecondary),
        ),
      ),
      data: (students) {
        final universities = students.map((s) => s.university).toSet().toList()
          ..sort();
        final plans = students.map((s) => s.planName).nonNulls.toSet().toList()
          ..sort();

        var rows = students;
        if (_search.isNotEmpty) {
          final q = _search.toLowerCase();
          rows = rows
              .where(
                (s) =>
                    s.name.toLowerCase().contains(q) ||
                    s.university.toLowerCase().contains(q),
              )
              .toList();
        }
        if (_university != null) {
          rows = rows.where((s) => s.university == _university).toList();
        }
        if (_plan != null) {
          rows = rows.where((s) => s.planName == _plan).toList();
        }

        rows = [...rows]
          ..sort((a, b) {
            final cmp = switch (_sortColumn) {
              0 => a.name.compareTo(b.name),
              1 => a.university.compareTo(b.university),
              3 => a.totalCheckins.compareTo(b.totalCheckins),
              _ => a.lastCheckin.compareTo(b.lastCheckin),
            };
            return _ascending ? cmp : -cmp;
          });

        return ListView(
          padding: pagePadding(context),
          children: [
            PageTitle(
              'Alunos',
              subtitle:
                  '${students.length} alunos UniHub já treinaram na sua academia',
            ),
            const SizedBox(height: UniHubSpacing.x6),
            Wrap(
              spacing: UniHubSpacing.x3,
              runSpacing: UniHubSpacing.x3,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Buscar por nome ou universidade',
                      prefixIcon: Icon(LucideIcons.search, size: 18),
                    ),
                    onChanged: (v) => setState(() => _search = v),
                  ),
                ),
                FilterDropdown(
                  label: 'Universidade',
                  value: _university,
                  options: universities,
                  onChanged: (v) => setState(() => _university = v),
                ),
                FilterDropdown(
                  label: 'Plano',
                  value: _plan,
                  options: plans,
                  allLabel: 'Todos',
                  onChanged: (v) => setState(() => _plan = v),
                ),
              ],
            ),
            const SizedBox(height: UniHubSpacing.x6),
            ResponsiveTable(
              child: DataTable(
                sortColumnIndex: _sortColumn,
                sortAscending: _ascending,
                showCheckboxColumn: false,
                columns: [
                  DataColumn(label: const Text('ALUNO'), onSort: _onSort),
                  DataColumn(
                    label: const Text('UNIVERSIDADE'),
                    onSort: _onSort,
                  ),
                  const DataColumn(label: Text('PLANO')),
                  DataColumn(
                    label: const Text('CHECK-INS'),
                    numeric: true,
                    onSort: _onSort,
                  ),
                  DataColumn(
                    label: const Text('ÚLTIMO CHECK-IN'),
                    onSort: _onSort,
                  ),
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
                        DataCell(Text(s.university)),
                        DataCell(Text(s.planName ?? '—')),
                        DataCell(
                          Text(
                            '${s.totalCheckins}',
                            style: UniHubStyles.money(size: 14),
                          ),
                        ),
                        DataCell(Text(formatDateTime(s.lastCheckin))),
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

  void _onSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumn = columnIndex;
      _ascending = ascending;
    });
  }
}
