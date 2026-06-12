import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';

import '../providers.dart';
import '../widgets/common.dart';

/// Configurações da academia: edita os próprios dados via PUT /gyms/{id}.
/// Valor de repasse e tier mínimo são cláusulas do contrato com a UniHub —
/// a academia visualiza, mas apenas a operação altera.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _modalitiesController;
  late final TextEditingController _capacityController;
  late final TextEditingController _hoursController;
  bool _saving = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _addressController = TextEditingController();
    _modalitiesController = TextEditingController();
    _capacityController = TextEditingController();
    _hoursController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _modalitiesController.dispose();
    _capacityController.dispose();
    _hoursController.dispose();
    super.dispose();
  }

  void _fillFrom(Gym gym) {
    if (_initialized) return;
    _initialized = true;
    _nameController.text = gym.name;
    _addressController.text = gym.address;
    _modalitiesController.text = gym.modalities.join(', ');
    _capacityController.text = '${gym.capacity}';
    _hoursController.text = gym.openingHours;
  }

  Future<void> _save(Gym gym) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(apiClientProvider).updateGym(gym.id, {
        'name': _nameController.text.trim(),
        'address': _addressController.text.trim(),
        'modalities': _modalitiesController.text
            .split(',')
            .map((m) => m.trim().toLowerCase())
            .where((m) => m.isNotEmpty)
            .toList(),
        'capacity': int.parse(_capacityController.text),
        'opening_hours': _hoursController.text.trim(),
      });
      await ref.read(sessionProvider.notifier).refreshProfile();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dados da academia atualizados.')),
        );
      }
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gym = ref.watch(sessionProvider).value?.gym;
    if (gym == null) return const SizedBox.shrink();
    _fillFrom(gym);

    return ListView(
      padding: pagePadding(context),
      children: [
        const PageTitle(
          'Configurações',
          subtitle: 'Dados da academia exibidos aos estudantes no app',
        ),
        const SizedBox(height: UniHubSpacing.x8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome da academia',
                  ),
                  validator: (v) => v == null || v.trim().length < 2
                      ? 'Informe o nome'
                      : null,
                ),
                const SizedBox(height: UniHubSpacing.x4),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: 'Endereço'),
                  validator: (v) => v == null || v.trim().length < 5
                      ? 'Informe o endereço'
                      : null,
                ),
                const SizedBox(height: UniHubSpacing.x4),
                TextFormField(
                  controller: _modalitiesController,
                  decoration: const InputDecoration(
                    labelText: 'Modalidades',
                    helperText:
                        'Separadas por vírgula, ex.: musculação, funcional',
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Informe ao menos uma'
                      : null,
                ),
                const SizedBox(height: UniHubSpacing.x4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _capacityController,
                        decoration: const InputDecoration(
                          labelText: 'Capacidade (alunos)',
                        ),
                        validator: (v) {
                          final parsed = int.tryParse(v ?? '');
                          if (parsed == null || parsed <= 0) {
                            return 'Número inválido';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: UniHubSpacing.x4),
                    Expanded(
                      child: TextFormField(
                        controller: _hoursController,
                        decoration: const InputDecoration(
                          labelText: 'Horário de funcionamento',
                          helperText: 'Ex.: 06:00–23:00',
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Informe o horário'
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: UniHubSpacing.x8),
                const Divider(),
                const SizedBox(height: UniHubSpacing.x6),
                const Text(
                  'Contrato com a UniHub',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: UniHubSpacing.x2),
                const Text(
                  'Estes valores são definidos em contrato. Para alterá-los, fale com a operação UniHub.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: UniHubColors.textSecondary,
                  ),
                ),
                const SizedBox(height: UniHubSpacing.x4),
                MetricRow(
                  children: [
                    MetricBlock(
                      label: 'Repasse por check-in',
                      value: formatBRL(gym.checkinPayoutAmount ?? 0),
                      highlight: true,
                    ),
                    MetricBlock(
                      label: 'Tier mínimo de acesso',
                      value: 'Plano ${gym.minPlanTier}+',
                    ),
                  ],
                ),
                const SizedBox(height: UniHubSpacing.x8),
                FilledButton(
                  onPressed: _saving ? null : () => _save(gym),
                  child: _saving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Salvar alterações'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
