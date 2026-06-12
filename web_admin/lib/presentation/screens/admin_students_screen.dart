import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_models/shared_models.dart';

import '../providers.dart';
import '../widgets/common.dart';

/// Base de assinantes da plataforma (somente leitura).
class AdminStudentsScreen extends ConsumerStatefulWidget {
  const AdminStudentsScreen({super.key});

  @override
  ConsumerState<AdminStudentsScreen> createState() =>
      _AdminStudentsScreenState();
}

class _AdminStudentsScreenState extends ConsumerState<AdminStudentsScreen> {
  String _search = '';
  String? _university;
  String? _plan;
  int _sortColumn = 0; // NOME
  bool _ascending = true;

  void _onSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumn = columnIndex;
      _ascending = ascending;
    });
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(adminStudentsProvider);

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
                    s.university.toLowerCase().contains(q) ||
                    s.email.toLowerCase().contains(q),
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
              1 => a.email.compareTo(b.email),
              2 => a.university.compareTo(b.university),
              3 => (a.planName ?? '').compareTo(b.planName ?? ''),
              _ => a.totalCheckins.compareTo(b.totalCheckins),
            };
            return _ascending ? cmp : -cmp;
          });

        return ListView(
          padding: pagePadding(context),
          children: [
            PageTitle(
              'Estudantes',
              subtitle: '${students.length} assinantes na plataforma',
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
                      hintText: 'Buscar por nome, e-mail ou universidade',
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
                  DataColumn(label: const Text('NOME'), onSort: _onSort),
                  DataColumn(label: const Text('E-MAIL'), onSort: _onSort),
                  DataColumn(
                    label: const Text('UNIVERSIDADE'),
                    onSort: _onSort,
                  ),
                  DataColumn(label: const Text('PLANO'), onSort: _onSort),
                  DataColumn(
                    label: const Text('CHECK-INS'),
                    numeric: true,
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
                        DataCell(Text(s.email)),
                        DataCell(Text(s.university)),
                        DataCell(Text(s.planName ?? 'Sem plano')),
                        DataCell(
                          Text(
                            '${s.totalCheckins}',
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
