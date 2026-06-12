import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_models/shared_models.dart';

import '../providers.dart';
import '../widgets/common.dart';

/// Gestão das academias parceiras (clientes da plataforma):
/// credenciamento, edição das cláusulas comerciais, foto e ativação.
class AdminGymsScreen extends ConsumerStatefulWidget {
  const AdminGymsScreen({super.key});

  @override
  ConsumerState<AdminGymsScreen> createState() => _AdminGymsScreenState();
}

class _AdminGymsScreenState extends ConsumerState<AdminGymsScreen> {
  bool _busy = false;
  String _search = '';
  String? _status; // 'Ativas' | 'Desativadas'

  void _refresh() {
    ref.invalidate(adminGymsProvider);
    ref.invalidate(adminOverviewProvider);
  }

  Future<void> _openForm({AdminGym? gym}) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => _GymFormDialog(gym: gym),
    );
    if (saved == true) _refresh();
  }

  Future<void> _uploadPhoto(AdminGym gym) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      withData: true,
    );
    final file = result?.files.firstOrNull;
    if (file == null || file.bytes == null) return;

    setState(() => _busy = true);
    try {
      await ref
          .read(apiClientProvider)
          .uploadGymPhoto(gym.id, file.bytes!, file.name);
      _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Foto da ${gym.name} atualizada.')),
        );
      }
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toggleActive(AdminGym gym) async {
    final activate = !gym.isActive;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          activate ? 'Reativar ${gym.name}?' : 'Desativar ${gym.name}?',
        ),
        content: Text(
          activate
              ? 'A academia volta a aparecer no app e a aceitar check-ins.'
              : 'A academia some do app e deixa de aceitar check-ins. '
                    'O histórico e os repasses são preservados.',
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
      await ref.read(apiClientProvider).updateGymAsAdmin(gym.id, {
        'is_active': activate,
      });
      _refresh();
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gymsAsync = ref.watch(adminGymsProvider);

    return gymsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text(
          '$e',
          style: const TextStyle(color: UniHubColors.textSecondary),
        ),
      ),
      data: (gyms) {
        var visible = [...gyms]..sort((a, b) => a.name.compareTo(b.name));
        if (_search.isNotEmpty) {
          final q = _search.toLowerCase();
          visible = visible
              .where(
                (g) =>
                    g.name.toLowerCase().contains(q) ||
                    g.address.toLowerCase().contains(q),
              )
              .toList();
        }
        if (_status != null) {
          final wantActive = _status == 'Ativas';
          visible = visible.where((g) => g.isActive == wantActive).toList();
        }

        return ListView(
          padding: const EdgeInsets.all(UniHubSpacing.x8),
          children: [
            PageTitle(
              'Academias',
              subtitle: '${gyms.length} parceiras credenciadas',
              action: FilledButton.icon(
                onPressed: _busy ? null : () => _openForm(),
                icon: const Icon(LucideIcons.plus, size: 16),
                label: const Text('Nova academia'),
              ),
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
                      hintText: 'Buscar por nome ou endereço',
                      prefixIcon: Icon(LucideIcons.search, size: 18),
                    ),
                    onChanged: (v) => setState(() => _search = v),
                  ),
                ),
                FilterDropdown(
                  label: 'Status',
                  value: _status,
                  options: const ['Ativas', 'Desativadas'],
                  onChanged: (v) => setState(() => _status = v),
                ),
              ],
            ),
            const SizedBox(height: UniHubSpacing.x4),
            for (final (i, gym) in visible.indexed) ...[
              if (i > 0) const Divider(),
              _GymRow(
                gym: gym,
                busy: _busy,
                onEdit: () => _openForm(gym: gym),
                onPhoto: () => _uploadPhoto(gym),
                onToggleActive: () => _toggleActive(gym),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _GymRow extends StatelessWidget {
  const _GymRow({
    required this.gym,
    required this.busy,
    required this.onEdit,
    required this.onPhoto,
    required this.onToggleActive,
  });

  final AdminGym gym;
  final bool busy;
  final VoidCallback onEdit;
  final VoidCallback onPhoto;
  final VoidCallback onToggleActive;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: UniHubSpacing.x4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Miniatura da foto (ou placeholder neutro)
          ClipRRect(
            borderRadius: UniHubRadius.brSm,
            child: SizedBox(
              width: 72,
              height: 54,
              child: gym.photoUrl == null
                  ? Container(
                      color: UniHubColors.surface,
                      child: const Icon(
                        LucideIcons.dumbbell,
                        size: 20,
                        color: UniHubColors.textSecondary,
                      ),
                    )
                  : Image.network(
                      gym.photoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: UniHubColors.surface,
                        child: const Icon(
                          LucideIcons.imageOff,
                          size: 20,
                          color: UniHubColors.textSecondary,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: UniHubSpacing.x4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      gym.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: UniHubSpacing.x2),
                    if (!gym.isActive)
                      const Text(
                        'DESATIVADA',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                          color: UniHubColors.error,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${gym.address} · ${gym.modalities.join(', ')}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: UniHubColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Plano ${gym.minPlanTier}+ · repasse ${formatBRL(gym.checkinPayoutAmount)}/check-in · '
                  '${gym.monthCheckins} check-ins no mês (${formatBRL(gym.monthAmount)}) · ${gym.email}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: UniHubColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: UniHubSpacing.x3),
          IconButton(
            onPressed: busy ? null : onPhoto,
            tooltip: 'Enviar foto',
            icon: const Icon(
              LucideIcons.imagePlus,
              size: 18,
              color: UniHubColors.textSecondary,
            ),
          ),
          IconButton(
            onPressed: busy ? null : onEdit,
            tooltip: 'Editar',
            icon: const Icon(
              LucideIcons.pencil,
              size: 18,
              color: UniHubColors.textSecondary,
            ),
          ),
          IconButton(
            onPressed: busy ? null : onToggleActive,
            tooltip: gym.isActive ? 'Desativar' : 'Reativar',
            icon: Icon(
              gym.isActive ? LucideIcons.powerOff : LucideIcons.power,
              size: 18,
              color: gym.isActive
                  ? UniHubColors.textSecondary
                  : UniHubColors.success,
            ),
          ),
        ],
      ),
    );
  }
}

/// Formulário de credenciamento/edição de academia.
class _GymFormDialog extends ConsumerStatefulWidget {
  const _GymFormDialog({this.gym});

  final AdminGym? gym; // null = nova academia

  @override
  ConsumerState<_GymFormDialog> createState() => _GymFormDialogState();
}

class _GymFormDialogState extends ConsumerState<_GymFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _password;
  late final TextEditingController _address;
  late final TextEditingController _latitude;
  late final TextEditingController _longitude;
  late final TextEditingController _modalities;
  late final TextEditingController _payout;
  late final TextEditingController _capacity;
  late final TextEditingController _hours;
  late int _minTier;
  bool _saving = false;

  bool get isNew => widget.gym == null;

  @override
  void initState() {
    super.initState();
    final g = widget.gym;
    _name = TextEditingController(text: g?.name ?? '');
    _email = TextEditingController(text: g?.email ?? '');
    _password = TextEditingController();
    _address = TextEditingController(text: g?.address ?? '');
    _latitude = TextEditingController(text: g?.latitude.toString() ?? '-22.90');
    _longitude = TextEditingController(
      text: g?.longitude.toString() ?? '-47.06',
    );
    _modalities = TextEditingController(text: g?.modalities.join(', ') ?? '');
    _payout = TextEditingController(
      text: g?.checkinPayoutAmount.toStringAsFixed(2) ?? '',
    );
    _capacity = TextEditingController(text: '${g?.capacity ?? 100}');
    _hours = TextEditingController(text: g?.openingHours ?? '06:00–22:00');
    _minTier = g?.minPlanTier ?? 1;
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _email,
      _password,
      _address,
      _latitude,
      _longitude,
      _modalities,
      _payout,
      _capacity,
      _hours,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final data = <String, dynamic>{
      'name': _name.text.trim(),
      'address': _address.text.trim(),
      'latitude': double.parse(_latitude.text.replaceAll(',', '.')),
      'longitude': double.parse(_longitude.text.replaceAll(',', '.')),
      'modalities': _modalities.text
          .split(',')
          .map((m) => m.trim().toLowerCase())
          .where((m) => m.isNotEmpty)
          .toList(),
      'min_plan_tier': _minTier,
      'checkin_payout_amount': double.parse(_payout.text.replaceAll(',', '.')),
      'capacity': int.parse(_capacity.text),
      'opening_hours': _hours.text.trim(),
    };

    try {
      final api = ref.read(apiClientProvider);
      if (isNew) {
        await api.createGym({
          ...data,
          'email': _email.text.trim(),
          'password': _password.text,
        });
      } else {
        await api.updateGymAsAdmin(widget.gym!.id, data);
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
      title: Text(
        isNew ? 'Credenciar nova academia' : 'Editar ${widget.gym!.name}',
      ),
      content: SizedBox(
        width: 560,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(
                    labelText: 'Nome da academia',
                  ),
                  validator: (v) => v == null || v.trim().length < 2
                      ? 'Informe o nome'
                      : null,
                ),
                const SizedBox(height: UniHubSpacing.x4),
                if (isNew) ...[
                  // Credenciais de acesso ao painel da academia
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _email,
                          decoration: const InputDecoration(
                            labelText: 'E-mail de acesso',
                          ),
                          validator: (v) => v == null || !v.contains('@')
                              ? 'E-mail inválido'
                              : null,
                        ),
                      ),
                      const SizedBox(width: UniHubSpacing.x4),
                      Expanded(
                        child: TextFormField(
                          controller: _password,
                          decoration: const InputDecoration(
                            labelText: 'Senha inicial (mín. 6)',
                          ),
                          validator: (v) => v == null || v.length < 6
                              ? 'Mínimo 6 caracteres'
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: UniHubSpacing.x4),
                ],
                TextFormField(
                  controller: _address,
                  decoration: const InputDecoration(labelText: 'Endereço'),
                  validator: (v) => v == null || v.trim().length < 5
                      ? 'Informe o endereço'
                      : null,
                ),
                const SizedBox(height: UniHubSpacing.x4),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _latitude,
                        decoration: const InputDecoration(
                          labelText: 'Latitude',
                        ),
                        validator: (v) =>
                            double.tryParse((v ?? '').replaceAll(',', '.')) ==
                                null
                            ? 'Número inválido'
                            : null,
                      ),
                    ),
                    const SizedBox(width: UniHubSpacing.x4),
                    Expanded(
                      child: TextFormField(
                        controller: _longitude,
                        decoration: const InputDecoration(
                          labelText: 'Longitude',
                        ),
                        validator: (v) =>
                            double.tryParse((v ?? '').replaceAll(',', '.')) ==
                                null
                            ? 'Número inválido'
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: UniHubSpacing.x4),
                TextFormField(
                  controller: _modalities,
                  decoration: const InputDecoration(
                    labelText: 'Modalidades',
                    helperText: 'Separadas por vírgula',
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Informe ao menos uma'
                      : null,
                ),
                const SizedBox(height: UniHubSpacing.x4),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _payout,
                        decoration: const InputDecoration(
                          labelText: 'Repasse por check-in (R\$)',
                        ),
                        validator: (v) {
                          final parsed = double.tryParse(
                            (v ?? '').replaceAll(',', '.'),
                          );
                          return parsed == null || parsed <= 0
                              ? 'Valor inválido'
                              : null;
                        },
                      ),
                    ),
                    const SizedBox(width: UniHubSpacing.x4),
                    Expanded(
                      child: TextFormField(
                        controller: _capacity,
                        decoration: const InputDecoration(
                          labelText: 'Capacidade',
                        ),
                        validator: (v) {
                          final parsed = int.tryParse(v ?? '');
                          return parsed == null || parsed <= 0
                              ? 'Número inválido'
                              : null;
                        },
                      ),
                    ),
                    const SizedBox(width: UniHubSpacing.x4),
                    Expanded(
                      child: TextFormField(
                        controller: _hours,
                        decoration: const InputDecoration(labelText: 'Horário'),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Informe' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: UniHubSpacing.x5),
                const Text(
                  'Tier mínimo de plano para acesso',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: UniHubSpacing.x2),
                Wrap(
                  spacing: UniHubSpacing.x2,
                  children: [
                    for (var tier = 1; tier <= 7; tier++)
                      InkWell(
                        onTap: () => setState(() => _minTier = tier),
                        borderRadius: UniHubRadius.brMd,
                        child: Container(
                          width: 40,
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: UniHubRadius.brMd,
                            border: Border.all(
                              color: tier == _minTier
                                  ? UniHubColors.accent
                                  : UniHubColors.border,
                              width: tier == _minTier ? 1.5 : 1,
                            ),
                          ),
                          child: Text(
                            '$tier',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: tier == _minTier
                                  ? UniHubColors.accent
                                  : UniHubColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                  ],
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
          child: _saving
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(isNew ? 'Credenciar academia' : 'Salvar'),
        ),
      ],
    );
  }
}
