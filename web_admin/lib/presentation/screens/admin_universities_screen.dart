import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_models/shared_models.dart';

import '../csv_download.dart';
import '../providers.dart';
import '../widgets/common.dart';

/// Faculdades conveniadas e a lista oficial de alunos de cada uma.
///
/// Sem lista importada, o aluno se cadastra com qualquer e-mail do domínio da
/// faculdade e confirma por código. Com a lista (CSV enviado pela IES), só
/// quem estiver nela consegue se cadastrar.
class AdminUniversitiesScreen extends ConsumerWidget {
  const AdminUniversitiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final universitiesAsync = ref.watch(adminUniversitiesProvider);
    return universitiesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text('$e', style: const TextStyle(color: UniHubColors.textSecondary)),
      ),
      data: (universities) => ListView(
        padding: pagePadding(context),
        children: [
          PageTitle(
            'Faculdades',
            subtitle: 'Lista de alunos de cada faculdade, para validar quem pode se cadastrar',
            action: OutlinedButton.icon(
              onPressed: () => downloadTextFile(_templateCsv, 'modelo-lista-alunos.csv'),
              icon: const Icon(LucideIcons.download, size: 16),
              label: const Text('Baixar modelo CSV'),
            ),
          ),
          const SizedBox(height: UniHubSpacing.x6),
          const _HowItWorks(),
          const SizedBox(height: UniHubSpacing.x6),
          for (final u in universities) ...[
            _UniversityCard(university: u),
            const SizedBox(height: UniHubSpacing.x4),
          ],
        ],
      ),
    );
  }
}

const _templateCsv = 'nome;email;ra\n'
    'Ana Rocha;ana.rocha@facamp.edu.br;2025001\n'
    'Bruno Lima;bruno.lima@facamp.edu.br;2025002\n';

class _HowItWorks extends StatelessWidget {
  const _HowItWorks();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(UniHubSpacing.x4),
      decoration: BoxDecoration(color: UniHubColors.surface, borderRadius: UniHubRadius.brMd),
      child: const Text(
        'Todo aluno confirma o e-mail da faculdade com um código enviado na hora do cadastro. '
        'Enquanto a faculdade não enviar a lista, basta o e-mail ser do domínio dela. '
        'Depois de importar o CSV, só se cadastra quem estiver na lista. O arquivo precisa '
        'de uma coluna "email"; "nome" e "ra" são opcionais (o RA fica guardado para o '
        'cruzamento futuro com o sistema da faculdade). Separador vírgula ou ponto e vírgula.',
        style: TextStyle(fontSize: 13.5, color: UniHubColors.textSecondary, height: 1.45),
      ),
    );
  }
}

class _UniversityCard extends ConsumerStatefulWidget {
  const _UniversityCard({required this.university});

  final AdminUniversity university;

  @override
  ConsumerState<_UniversityCard> createState() => _UniversityCardState();
}

class _UniversityCardState extends ConsumerState<_UniversityCard> {
  bool _busy = false;

  AdminUniversity get u => widget.university;

  Future<void> _import() async {
    // Com lista existente, pergunta se substitui ou só acrescenta
    var replace = true;
    if (u.hasRoster) {
      final choice = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('Importar lista da ${u.name}'),
          content: Text(
            'A ${u.name} já tem ${u.rosterSize} alunos na lista. Substituir pela lista nova '
            '(uso normal a cada semestre) ou só acrescentar (ex.: calouros que entraram depois)?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(null),
              child: const Text('Cancelar'),
            ),
            OutlinedButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Acrescentar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Substituir'),
            ),
          ],
        ),
      );
      if (choice == null) return;
      replace = choice;
    }

    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'txt'],
      withData: true,
    );
    final file = picked?.files.firstOrNull;
    if (file == null || file.bytes == null) return;

    setState(() => _busy = true);
    try {
      final result = await ref
          .read(apiClientProvider)
          .importUniversityRoster(u.id, file.bytes!, file.name, replace: replace);
      ref.invalidate(adminUniversitiesProvider);
      if (mounted) await _showResult(result);
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showResult(RosterImportResult r) => showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Lista importada'),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${r.imported} alunos importados de ${r.totalRows} linhas. '
                    'A lista da ${u.name} agora tem ${r.rosterSize} alunos.'),
                if (r.duplicates > 0)
                  Text(r.duplicates == 1 ? '1 repetido ignorado.' : '${r.duplicates} repetidos ignorados.'),
                if (r.wrongDomain > 0)
                  Text(r.wrongDomain == 1
                      ? '1 e-mail fora do domínio da faculdade ignorado.'
                      : '${r.wrongDomain} e-mails fora do domínio da faculdade ignorados.'),
                if (r.invalid > 0)
                  Text(r.invalid == 1
                      ? '1 linha sem e-mail válido ignorada.'
                      : '${r.invalid} linhas sem e-mail válido ignoradas.'),
                if (r.errors.isNotEmpty) ...[
                  const SizedBox(height: UniHubSpacing.x3),
                  for (final e in r.errors)
                    Text(e, style: const TextStyle(fontSize: 12.5, color: UniHubColors.textSecondary)),
                ],
              ],
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Ok'),
            ),
          ],
        ),
      );

  Future<void> _clear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Apagar a lista?'),
        content: Text(
          'A ${u.name} volta a aceitar qualquer e-mail do domínio '
          '(${u.emailDomains.join(', ')}), confirmado por código. '
          'Quem já tem conta continua com acesso.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Apagar lista'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _busy = true);
    try {
      await ref.read(apiClientProvider).clearUniversityRoster(u.id);
      ref.invalidate(adminUniversitiesProvider);
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final imported = u.rosterImportedAt;
    return Container(
      padding: const EdgeInsets.all(UniHubSpacing.x6),
      decoration: BoxDecoration(
        border: Border.all(color: UniHubColors.border),
        borderRadius: UniHubRadius.brMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      u.name,
                      style: UniHubFonts.display(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      u.emailDomains.map((d) => '@$d').join(', '),
                      style: const TextStyle(fontSize: 13, color: UniHubColors.textSecondary),
                    ),
                  ],
                ),
              ),
              _ValidationBadge(hasRoster: u.hasRoster),
            ],
          ),
          const SizedBox(height: UniHubSpacing.x5),
          MetricRow(
            children: [
              MetricBlock(label: 'Alunos com conta', value: '${u.students}'),
              MetricBlock(
                label: 'E-mails confirmados',
                value: '${u.verifiedStudents}',
                detail: u.students == 0 ? null : 'de ${u.students} cadastrados',
              ),
              MetricBlock(
                label: 'Na lista da faculdade',
                value: u.hasRoster ? '${u.rosterSize}' : '—',
                detail: imported == null
                    ? 'Nenhuma lista importada'
                    : 'Importada em ${imported.day.toString().padLeft(2, '0')}/'
                        '${imported.month.toString().padLeft(2, '0')}/${imported.year}',
              ),
              MetricBlock(
                label: 'Com conta, fora da lista',
                value: u.hasRoster ? '${u.studentsOutsideRoster}' : '—',
                detail: u.hasRoster ? 'Cadastrados antes ou já formados' : null,
              ),
            ],
          ),
          const SizedBox(height: UniHubSpacing.x5),
          Wrap(
            spacing: UniHubSpacing.x3,
            runSpacing: UniHubSpacing.x3,
            children: [
              FilledButton.icon(
                onPressed: _busy ? null : _import,
                icon: const Icon(LucideIcons.upload, size: 16),
                label: Text(u.hasRoster ? 'Importar nova lista' : 'Importar lista (CSV)'),
              ),
              if (u.hasRoster) ...[
                OutlinedButton.icon(
                  onPressed: _busy
                      ? null
                      : () => showDialog<void>(
                            context: context,
                            builder: (_) => _RosterDialog(university: u),
                          ),
                  icon: const Icon(LucideIcons.list, size: 16),
                  label: const Text('Ver lista'),
                ),
                TextButton(
                  onPressed: _busy ? null : _clear,
                  child: const Text('Apagar lista'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ValidationBadge extends StatelessWidget {
  const _ValidationBadge({required this.hasRoster});

  final bool hasRoster;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: UniHubSpacing.x3, vertical: 4),
      decoration: BoxDecoration(
        color: hasRoster ? UniHubColors.accentSoft : UniHubColors.surface,
        borderRadius: UniHubRadius.brPill,
      ),
      child: Text(
        hasRoster ? 'Valida pela lista' : 'Valida pelo domínio',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: hasRoster ? UniHubColors.accentPressed : UniHubColors.textSecondary,
        ),
      ),
    );
  }
}

/// Consulta a lista importada (busca por e-mail, nome ou RA).
class _RosterDialog extends ConsumerStatefulWidget {
  const _RosterDialog({required this.university});

  final AdminUniversity university;

  @override
  ConsumerState<_RosterDialog> createState() => _RosterDialogState();
}

class _RosterDialogState extends ConsumerState<_RosterDialog> {
  late Future<List<RosterEntry>> _entries = _load('');

  Future<List<RosterEntry>> _load(String q) =>
      ref.read(apiClientProvider).getUniversityRoster(widget.university.id, query: q);

  void _exportCsv(List<RosterEntry> entries) {
    final lines = ['nome;email;ra;tem_conta'];
    for (final e in entries) {
      lines.add('${e.name ?? ''};${e.email};${e.ra ?? ''};${e.registered ? 'sim' : 'nao'}');
    }
    downloadTextFile(lines.join('\n'), 'lista-${widget.university.name.toLowerCase()}.csv');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Lista da ${widget.university.name}'),
      content: SizedBox(
        width: 640,
        height: 480,
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: 'Buscar por e-mail, nome ou RA',
                prefixIcon: Icon(LucideIcons.search, size: 18),
              ),
              onChanged: (v) => setState(() => _entries = _load(v.trim())),
            ),
            const SizedBox(height: UniHubSpacing.x4),
            Expanded(
              child: FutureBuilder<List<RosterEntry>>(
                future: _entries,
                builder: (context, snap) {
                  if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                  final entries = snap.data!;
                  if (entries.isEmpty) {
                    return const Center(child: Text('Nenhum aluno encontrado.'));
                  }
                  return ListView.separated(
                    itemCount: entries.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final e = entries[i];
                      return ListTile(
                        dense: true,
                        title: Text(e.name ?? e.email),
                        subtitle: Text([e.email, if (e.ra != null) 'RA ${e.ra}'].join(' · ')),
                        trailing: Text(
                          e.registered ? 'Tem conta' : 'Sem conta',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: e.registered ? UniHubColors.success : UniHubColors.textTertiary,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        FutureBuilder<List<RosterEntry>>(
          future: _entries,
          builder: (context, snap) => TextButton(
            onPressed: snap.hasData ? () => _exportCsv(snap.data!) : null,
            child: const Text('Exportar CSV'),
          ),
        ),
        FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Fechar')),
      ],
    );
  }
}
