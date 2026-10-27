import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_models/shared_models.dart';
import 'package:web/web.dart' as web;

import '../providers.dart';
import '../widgets/challenge_ranking.dart';
import '../widgets/common.dart';

/// Link do placar público: abre sem login, para a TV da faculdade ou o grupo da turma.
String scoreboardUrl(Challenge c) => '${Uri.base.origin}${Uri.base.path}#/placar/${c.publicToken}';

String _shortDate(DateTime d) => formatDate(d).substring(0, 5);

String _period(Challenge c) => '${_shortDate(c.startDate)} a ${formatDate(c.endDate)}';

String _scopeLabel(Challenge c) =>
    c.betweenCourses ? 'Entre cursos · ${c.universityName ?? ''}' : 'Entre faculdades';

/// Lista de desafios da operação (todos) ou da faculdade (os dela).
class ChallengesScreen extends ConsumerWidget {
  const ChallengesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider).value;
    final asUniversity = session?.isUniversity == true;
    final challengesAsync = ref.watch(challengesProvider);

    Future<void> create() async {
      final created = await showDialog<Challenge>(
        context: context,
        builder: (_) => _ChallengeFormDialog(asUniversity: asUniversity),
      );
      if (created == null) return;
      ref.invalidate(challengesProvider);
      if (context.mounted) context.go('${session!.areaPrefix}/desafios/${created.id}');
    }

    return challengesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text('$e', style: const TextStyle(color: UniHubColors.textSecondary)),
      ),
      data: (challenges) {
        final sections = [
          ('Em andamento', challenges.where((c) => c.isActive).toList()),
          ('Próximos', challenges.where((c) => c.status == 'upcoming').toList()),
          ('Encerrados', challenges.where((c) => c.isEnded).toList()),
        ];
        return ListView(
          padding: pagePadding(context),
          children: [
            PageTitle(
              'Desafios',
              subtitle: asUniversity
                  ? 'Engaje a turma: cursos da ${session?.university?.name ?? 'faculdade'} disputando quem treina mais'
                  : 'Faculdades e cursos disputando quem treina mais',
              action: FilledButton.icon(
                onPressed: create,
                icon: const Icon(LucideIcons.plus, size: 16),
                label: const Text('Novo desafio'),
              ),
            ),
            const SizedBox(height: UniHubSpacing.x8),
            if (challenges.isEmpty)
              const Text(
                'Nenhum desafio ainda. Crie o primeiro e compartilhe o placar com os alunos.',
                style: TextStyle(color: UniHubColors.textSecondary),
              ),
            for (final (title, list) in sections)
              if (list.isNotEmpty) ...[
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: UniHubSpacing.x3),
                for (final c in list)
                  _ChallengeTile(
                    challenge: c,
                    onTap: () => context.go('${session!.areaPrefix}/desafios/${c.id}'),
                  ),
                const SizedBox(height: UniHubSpacing.x8),
              ],
          ],
        );
      },
    );
  }
}

class _ChallengeTile extends StatelessWidget {
  const _ChallengeTile({required this.challenge, required this.onTap});

  final Challenge challenge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = challenge;
    final highlight = c.isEnded
        ? (c.champion == null ? 'Sem check-ins' : 'Campeão: ${c.champion}')
        : (c.leader == null ? 'Ninguém pontuou ainda' : 'Liderando: ${c.leader}');
    return Padding(
      padding: const EdgeInsets.only(bottom: UniHubSpacing.x3),
      child: InkWell(
        onTap: onTap,
        borderRadius: UniHubRadius.brMd,
        child: Container(
          padding: const EdgeInsets.all(UniHubSpacing.x4),
          decoration: BoxDecoration(
            borderRadius: UniHubRadius.brMd,
            border: Border.all(color: c.isActive ? UniHubColors.accent : UniHubColors.border),
          ),
          child: Row(
            children: [
              Icon(
                c.isEnded ? LucideIcons.trophy : (c.betweenCourses ? LucideIcons.bookOpen : LucideIcons.school),
                size: 22,
                color: c.isActive ? UniHubColors.accent : UniHubColors.textSecondary,
              ),
              const SizedBox(width: UniHubSpacing.x4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                      '${_scopeLabel(c)} · ${c.metricLabel} · ${_period(c)}',
                      style: const TextStyle(fontSize: 13, color: UniHubColors.textSecondary),
                    ),
                    const SizedBox(height: UniHubSpacing.x2),
                    Text(
                      '$highlight  ·  ${c.participants} alunos  ·  ${c.totalCheckins} check-ins',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: c.isEnded && c.champion != null ? UniHubColors.accent : UniHubColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(LucideIcons.chevronRight, size: 18, color: UniHubColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

/// Detalhe: ranking, evolução semana a semana e o link do placar.
class ChallengeDetailScreen extends ConsumerWidget {
  const ChallengeDetailScreen({super.key, required this.challengeId});

  final int challengeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider).value;
    final detailAsync = ref.watch(challengeDetailProvider(challengeId));

    return detailAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text('$e', style: const TextStyle(color: UniHubColors.textSecondary)),
      ),
      data: (c) {
        // A faculdade não apaga desafio entre faculdades (é da operação)
        final canDelete = session?.isAdmin == true || c.betweenCourses;
        final statusDetail = switch (c.status) {
          'upcoming' => 'começa em ${formatDate(c.startDate)}',
          'ended' => 'encerrado em ${formatDate(c.endDate)}',
          _ => c.daysLeft == 0 ? 'termina hoje' : 'faltam ${c.daysLeft} dias',
        };
        return ListView(
          padding: pagePadding(context),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => context.go('${session!.areaPrefix}/desafios'),
                icon: const Icon(LucideIcons.arrowLeft, size: 16),
                label: const Text('Desafios'),
              ),
            ),
            const SizedBox(height: UniHubSpacing.x2),
            PageTitle(
              c.title,
              subtitle: [_scopeLabel(c), c.metricLabel, _period(c)].join(' · '),
              action: IconButton(
                onPressed: () => ref.invalidate(challengeDetailProvider(challengeId)),
                icon: const Icon(LucideIcons.refreshCw, size: 18, color: UniHubColors.textSecondary),
                tooltip: 'Atualizar',
              ),
            ),
            if (c.description != null) ...[
              const SizedBox(height: UniHubSpacing.x3),
              Text(c.description!, style: const TextStyle(fontSize: 14)),
            ],
            const SizedBox(height: UniHubSpacing.x4),
            Wrap(
              spacing: UniHubSpacing.x2,
              runSpacing: UniHubSpacing.x2,
              children: [
                FilledButton.icon(
                  onPressed: () => web.window.open(scoreboardUrl(c), '_blank'),
                  icon: const Icon(LucideIcons.monitor, size: 16),
                  label: const Text('Abrir placar'),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: scoreboardUrl(c)));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Link do placar copiado. Mande no grupo da turma.')),
                      );
                    }
                  },
                  icon: const Icon(LucideIcons.link, size: 16),
                  label: const Text('Copiar link'),
                ),
                if (canDelete)
                  TextButton.icon(
                    onPressed: () => _delete(context, ref, c),
                    icon: const Icon(LucideIcons.trash2, size: 16),
                    label: const Text('Excluir'),
                    style: TextButton.styleFrom(foregroundColor: UniHubColors.textSecondary),
                  ),
              ],
            ),
            const SizedBox(height: UniHubSpacing.x8),
            MetricRow(
              children: [
                MetricBlock(
                  label: c.isEnded ? 'Campeão' : 'Liderando',
                  value: (c.isEnded ? c.champion : c.leader) ?? '—',
                  detail: statusDetail,
                  highlight: true,
                ),
                MetricBlock(
                  label: c.betweenCourses ? 'Cursos' : 'Faculdades',
                  value: '${c.groups}',
                  detail: 'na disputa',
                ),
                MetricBlock(label: 'Alunos', value: '${c.participants}', detail: 'assinantes participando'),
                MetricBlock(label: 'Check-ins', value: '${c.totalCheckins}', detail: 'no período do desafio'),
              ],
            ),
            const SizedBox(height: UniHubSpacing.x10),
            const Divider(),
            const SizedBox(height: UniHubSpacing.x8),
            const Text('Ranking', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: UniHubSpacing.x2),
            Text(
              c.sharePercent
                  ? 'Pontua a parte da turma com ao menos um treino por semana do desafio.'
                  : 'Pontua a média de check-ins por aluno assinante, para grupo pequeno disputar com grupo grande.',
              style: const TextStyle(fontSize: 13, color: UniHubColors.textSecondary),
            ),
            const SizedBox(height: UniHubSpacing.x4),
            MaxWidth(maxWidth: 820, child: ChallengeRanking(challenge: c)),
            if (c.evolutionLabels.length > 1) ...[
              const SizedBox(height: UniHubSpacing.x10),
              const Divider(),
              const SizedBox(height: UniHubSpacing.x8),
              const Text('Evolução semana a semana', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: UniHubSpacing.x4),
              MaxWidth(maxWidth: 820, child: _EvolutionChart(challenge: c)),
            ],
          ],
        );
      },
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Challenge c) async {
    final session = ref.read(sessionProvider).value!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Excluir "${c.title}"?'),
        content: const Text('O placar público deixa de funcionar. Os check-ins dos alunos não são afetados.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Excluir')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(apiClientProvider).deleteChallenge(c.id, asUniversity: session.isUniversity);
      ref.invalidate(challengesProvider);
      if (context.mounted) context.go('${session.areaPrefix}/desafios');
    } catch (e) {
      if (context.mounted) showApiError(context, e);
    }
  }
}

/// Cores das séries: o líder em laranja, os demais em tons neutros distintos.
const seriesColors = [
  UniHubColors.accent,
  UniHubColors.textPrimary,
  Color(0xFF3B82F6),
  Color(0xFF14B8A6),
  Color(0xFFA855F7),
];

class _EvolutionChart extends StatelessWidget {
  const _EvolutionChart({required this.challenge});

  final Challenge challenge;

  @override
  Widget build(BuildContext context) {
    final c = challenge;
    final maxPoint = c.evolution.expand((s) => s.points).fold<double>(0, (a, b) => b > a ? b : a);
    final maxY = c.sharePercent ? 100.0 : (maxPoint <= 0 ? 1.0 : (maxPoint * 1.15).ceilToDouble());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 240,
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: maxY,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxY / 4,
                getDrawingHorizontalLine: (_) => const FlLine(color: UniHubColors.divider, strokeWidth: 1),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(),
                rightTitles: const AxisTitles(),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    interval: maxY / 4,
                    getTitlesWidget: (value, _) => Text(
                      c.formatScore(value),
                      style: const TextStyle(fontSize: 11, color: UniHubColors.textSecondary),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    getTitlesWidget: (value, _) {
                      final i = value.toInt();
                      if (i < 0 || i >= c.evolutionLabels.length || value != i) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          _shortDate(c.evolutionLabels[i]),
                          style: const TextStyle(fontSize: 11, color: UniHubColors.textSecondary),
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => UniHubColors.textPrimary,
                  getTooltipItems: (spots) => [
                    for (final s in spots)
                      LineTooltipItem(
                        '${c.evolution[s.barIndex].name}: ${c.formatScore(s.y)}',
                        const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                  ],
                ),
              ),
              lineBarsData: [
                for (final (i, series) in c.evolution.indexed)
                  LineChartBarData(
                    spots: [for (final (x, y) in series.points.indexed) FlSpot(x.toDouble(), y)],
                    color: seriesColors[i % seriesColors.length],
                    barWidth: i == 0 ? 3 : 2,
                    dotData: const FlDotData(show: true),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: UniHubSpacing.x4),
        Wrap(
          spacing: UniHubSpacing.x4,
          runSpacing: UniHubSpacing.x2,
          children: [
            for (final (i, series) in c.evolution.indexed)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 10, height: 10, color: seriesColors[i % seriesColors.length]),
                  const SizedBox(width: 6),
                  Text(series.name, style: const TextStyle(fontSize: 12)),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

/// Formulário de novo desafio. A faculdade só cria entre os próprios cursos.
class _ChallengeFormDialog extends ConsumerStatefulWidget {
  const _ChallengeFormDialog({required this.asUniversity});

  final bool asUniversity;

  @override
  ConsumerState<_ChallengeFormDialog> createState() => _ChallengeFormDialogState();
}

class _ChallengeFormDialogState extends ConsumerState<_ChallengeFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  late String _scope = widget.asUniversity ? 'courses' : 'universities';
  String _metric = 'checkins_per_student';
  int? _universityId;
  late DateTimeRange _range;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Padrão: até o fim do mês corrente
    final today = DateUtils.dateOnly(DateTime.now());
    _range = DateTimeRange(start: today, end: DateTime(today.year, today.month + 1, 0));
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _range,
    );
    if (picked != null) setState(() => _range = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    String iso(DateTime d) => d.toIso8601String().substring(0, 10);
    try {
      final created = await ref.read(apiClientProvider).createChallenge({
        'title': _title.text.trim(),
        'description': _description.text.trim(),
        'scope': _scope,
        'metric': _metric,
        'start_date': iso(_range.start),
        'end_date': iso(_range.end),
        'university_id': ?_universityId,
      }, asUniversity: widget.asUniversity);
      if (mounted) Navigator.of(context).pop(created);
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final universities = ref.watch(universitiesProvider).value ?? const [];
    return AlertDialog(
      title: const Text('Novo desafio'),
      content: SizedBox(
        width: isMobile(context) ? double.maxFinite : 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _title,
                  decoration: InputDecoration(
                    labelText: 'Nome do desafio',
                    hintText: widget.asUniversity ? 'Copa de cursos de novembro' : 'Qual faculdade treina mais?',
                  ),
                  validator: (v) => v == null || v.trim().length < 3 ? 'Dê um nome ao desafio' : null,
                ),
                const SizedBox(height: UniHubSpacing.x4),
                TextFormField(
                  controller: _description,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Descrição e prêmio (opcional)',
                    hintText: 'Ex.: o curso campeão ganha o happy hour da atlética',
                  ),
                ),
                if (!widget.asUniversity) ...[
                  const SizedBox(height: UniHubSpacing.x6),
                  const Text('Quem disputa', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(height: UniHubSpacing.x2),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'universities', label: Text('Faculdades')),
                      ButtonSegment(value: 'courses', label: Text('Cursos de uma faculdade')),
                    ],
                    selected: {_scope},
                    onSelectionChanged: (s) => setState(() => _scope = s.first),
                  ),
                  if (_scope == 'courses') ...[
                    const SizedBox(height: UniHubSpacing.x4),
                    DropdownButtonFormField<int>(
                      initialValue: _universityId,
                      decoration: const InputDecoration(labelText: 'Faculdade'),
                      items: [
                        for (final u in universities) DropdownMenuItem(value: u.id, child: Text(u.name)),
                      ],
                      onChanged: (v) => setState(() => _universityId = v),
                      validator: (v) => v == null ? 'Escolha a faculdade' : null,
                    ),
                  ],
                ],
                const SizedBox(height: UniHubSpacing.x6),
                const Text('Como pontua', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                RadioGroup<String>(
                  groupValue: _metric,
                  onChanged: (v) => setState(() => _metric = v!),
                  child: const Column(
                    children: [
                      RadioListTile<String>(
                        value: 'checkins_per_student',
                        contentPadding: EdgeInsets.zero,
                        title: Text('Check-ins por aluno'),
                        subtitle: Text('Média de treinos por assinante do grupo'),
                      ),
                      RadioListTile<String>(
                        value: 'active_share',
                        contentPadding: EdgeInsets.zero,
                        title: Text('% da turma treinando toda semana'),
                        subtitle: Text('Premia a constância, não só quem treina muito'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: UniHubSpacing.x4),
                OutlinedButton.icon(
                  onPressed: _pickRange,
                  icon: const Icon(LucideIcons.calendar, size: 16),
                  label: Text('${formatDate(_range.start)} a ${formatDate(_range.end)}'),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Criando...' : 'Criar desafio'),
        ),
      ],
    );
  }
}
