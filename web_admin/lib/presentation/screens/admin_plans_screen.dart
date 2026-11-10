import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_models/shared_models.dart';

import '../providers.dart';
import '../widgets/common.dart';

/// Gestão dos planos vendidos aos alunos: criar, editar preço e benefícios,
/// tirar da vitrine. Só a operação UniHub vê esta tela.
class AdminPlansScreen extends ConsumerStatefulWidget {
  const AdminPlansScreen({super.key});

  @override
  ConsumerState<AdminPlansScreen> createState() => _AdminPlansScreenState();
}

class _AdminPlansScreenState extends ConsumerState<AdminPlansScreen> {
  bool _busy = false;

  void _refresh() {
    ref.invalidate(adminPlansProvider);
    ref.invalidate(adminOverviewProvider);
  }

  Future<void> _openForm({AdminPlan? plan}) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _PlanFormDialog(plan: plan),
    );
    if (saved == true) _refresh();
  }

  Future<void> _toggleActive(AdminPlan row) async {
    final plan = row.plan;
    final activate = !plan.isActive;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(activate ? 'Voltar a vender ${plan.name}?' : 'Tirar ${plan.name} da vitrine?'),
        content: Text(
          activate
              ? 'O plano volta a aparecer no app para novos alunos.'
              : 'O plano some do app para quem ainda não assina. '
                    'Os ${row.activeSubscribers} assinantes atuais continuam nele normalmente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(activate ? 'Reativar' : 'Desativar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busy = true);
    try {
      await ref.read(apiClientProvider).updatePlan(plan.id, {'is_active': activate});
      _refresh();
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final plansAsync = ref.watch(adminPlansProvider);

    return plansAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text('$e', style: const TextStyle(color: UniHubColors.textSecondary)),
      ),
      data: (plans) {
        final active = plans.where((p) => p.plan.isActive).length;
        final subscribers = plans.fold<int>(0, (sum, p) => sum + p.activeSubscribers);
        return ListView(
          padding: pagePadding(context),
          children: [
            PageTitle(
              'Planos',
              subtitle: '$active à venda · $subscribers assinantes ativos',
              action: FilledButton.icon(
                onPressed: _busy ? null : () => _openForm(),
                icon: const Icon(LucideIcons.plus, size: 16),
                label: const Text('Novo plano'),
              ),
            ),
            const SizedBox(height: UniHubSpacing.x4),
            const Text(
              'O preço aqui é a mensalidade cheia. No app, o aluno vê esse valor menos o '
              'subsídio da faculdade dele. Um preço novo vale para novas assinaturas e trocas '
              'de plano; quem já assina mantém o valor contratado.',
              style: TextStyle(fontSize: 13, color: UniHubColors.textSecondary, height: 1.45),
            ),
            const SizedBox(height: UniHubSpacing.x6),
            for (final (i, row) in plans.indexed) ...[
              if (i > 0) const Divider(),
              _PlanRow(
                row: row,
                busy: _busy,
                onEdit: () => _openForm(plan: row),
                onToggleActive: () => _toggleActive(row),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow({
    required this.row,
    required this.busy,
    required this.onEdit,
    required this.onToggleActive,
  });

  final AdminPlan row;
  final bool busy;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;

  @override
  Widget build(BuildContext context) {
    final plan = row.plan;
    final details = [
      if (plan.includedCategories.isNotEmpty) plan.includedCategories.join(', '),
      if (plan.hasRunningCoach) 'com assessoria de corrida',
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: UniHubSpacing.x4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: UniHubSpacing.x2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      plan.name,
                      style: UniHubFonts.display(fontSize: 17, fontWeight: FontWeight.w800),
                    ),
                    _Tag(
                      plan.isActive ? 'À VENDA' : 'FORA DA VITRINE',
                      background: plan.isActive ? UniHubColors.accentSoft : UniHubColors.surface,
                      color: plan.isActive ? UniHubColors.accentPressed : UniHubColors.textSecondary,
                    ),
                  ],
                ),
                if (plan.benefitsDescription.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    plan.benefitsDescription,
                    style: const TextStyle(fontSize: 13, color: UniHubColors.textSecondary),
                  ),
                ],
                if (details.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    details,
                    style: const TextStyle(fontSize: 12.5, color: UniHubColors.textTertiary),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: UniHubSpacing.x6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${formatBRL(plan.monthlyPrice)}/mês',
                style: UniHubStyles.money(size: 17, weight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Text(
                '${row.activeSubscribers} assinantes',
                style: const TextStyle(fontSize: 12.5, color: UniHubColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(width: UniHubSpacing.x3),
          IconButton(
            onPressed: busy ? null : onEdit,
            tooltip: 'Editar',
            icon: const Icon(LucideIcons.pencil, size: 18, color: UniHubColors.textSecondary),
          ),
          IconButton(
            onPressed: busy ? null : onToggleActive,
            tooltip: plan.isActive ? 'Tirar da vitrine' : 'Voltar a vender',
            icon: Icon(
              plan.isActive ? LucideIcons.eyeOff : LucideIcons.eye,
              size: 18,
              color: UniHubColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text, {required this.background, required this.color});

  final String text;
  final Color background;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: UniHubSpacing.x2, vertical: 2),
      decoration: BoxDecoration(color: background, borderRadius: UniHubRadius.brPill),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1, color: color),
      ),
    );
  }
}

class _PlanFormDialog extends ConsumerStatefulWidget {
  const _PlanFormDialog({this.plan});

  final AdminPlan? plan; // null = plano novo

  @override
  ConsumerState<_PlanFormDialog> createState() => _PlanFormDialogState();
}

class _PlanFormDialogState extends ConsumerState<_PlanFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _price;
  late final TextEditingController _description;
  late final TextEditingController _categories;
  late bool _runningCoach;
  bool _saving = false;

  bool get isNew => widget.plan == null;

  @override
  void initState() {
    super.initState();
    final p = widget.plan?.plan;
    _name = TextEditingController(text: p?.name ?? '');
    _price = TextEditingController(text: p?.monthlyPrice.toStringAsFixed(2).replaceAll('.', ',') ?? '');
    _description = TextEditingController(text: p?.benefitsDescription ?? '');
    _categories = TextEditingController(text: p?.includedCategories.join(', ') ?? '');
    _runningCoach = p?.hasRunningCoach ?? false;
  }

  @override
  void dispose() {
    for (final c in [_name, _price, _description, _categories]) {
      c.dispose();
    }
    super.dispose();
  }

  double? _parsePrice(String? v) =>
      double.tryParse((v ?? '').replaceAll('R\$', '').replaceAll('.', '').replaceAll(',', '.').trim());

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final data = <String, dynamic>{
      'name': _name.text.trim(),
      'monthly_price': _parsePrice(_price.text),
      'benefits_description': _description.text.trim(),
      'included_categories': _categories.text
          .split(',')
          .map((c) => c.trim().toLowerCase())
          .where((c) => c.isNotEmpty)
          .toList(),
      'has_running_coach': _runningCoach,
    };

    try {
      final api = ref.read(apiClientProvider);
      if (isNew) {
        await api.createPlan(data);
      } else {
        await api.updatePlan(widget.plan!.plan.id, data);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(isNew ? 'Novo plano' : 'Editar ${widget.plan!.plan.name}'),
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
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Nome do plano'),
                  validator: (v) => v == null || v.trim().length < 2 ? 'Informe o nome' : null,
                ),
                const SizedBox(height: UniHubSpacing.x4),
                TextFormField(
                  controller: _price,
                  decoration: const InputDecoration(
                    labelText: 'Mensalidade cheia (R\$)',
                    helperText: 'Antes do subsídio da faculdade',
                  ),
                  validator: (v) {
                    final price = _parsePrice(v);
                    return price == null || price <= 0 ? 'Valor inválido' : null;
                  },
                ),
                const SizedBox(height: UniHubSpacing.x4),
                TextFormField(
                  controller: _description,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'O que está incluído (aparece no app)'),
                ),
                const SizedBox(height: UniHubSpacing.x4),
                TextFormField(
                  controller: _categories,
                  decoration: const InputDecoration(
                    labelText: 'Modalidades incluídas',
                    helperText: 'Separadas por vírgula',
                  ),
                ),
                const SizedBox(height: UniHubSpacing.x2),
                CheckboxListTile(
                  value: _runningCoach,
                  onChanged: (v) => setState(() => _runningCoach = v ?? false),
                  title: const Text('Inclui assessoria de corrida', style: TextStyle(fontSize: 14)),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(isNew ? 'Criar plano' : 'Salvar'),
        ),
      ],
    );
  }
}
