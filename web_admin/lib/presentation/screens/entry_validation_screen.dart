import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_models/shared_models.dart';

import '../providers.dart';
import '../widgets/common.dart';

/// Recepção: digita (ou lê com leitor de QR, que "digita" o texto) o código
/// que o aluno mostra no app e confirma a entrada.
class EntryValidationScreen extends ConsumerStatefulWidget {
  const EntryValidationScreen({super.key});

  @override
  ConsumerState<EntryValidationScreen> createState() =>
      _EntryValidationScreenState();
}

class _EntryValidationScreenState extends ConsumerState<EntryValidationScreen> {
  final _code = TextEditingController();
  final _focus = FocusNode();
  bool _busy = false;
  EntryValidation? _result;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _validate() async {
    final code = _code.text.trim();
    if (code.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
      _result = null;
    });
    try {
      final result = await ref.read(apiClientProvider).validateEntryCode(code);
      ref.invalidate(gymCheckinsProvider);
      setState(() => _result = result);
      _code.clear();
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
      _focus.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final recent = ref.watch(gymCheckinsProvider);
    return ListView(
      padding: pagePadding(context),
      children: [
        const PageTitle(
          'Validar entrada',
          subtitle:
              'Peça o código que aparece no app do aluno depois do check-in',
        ),
        const SizedBox(height: UniHubSpacing.x8),
        MaxWidth(
          maxWidth: 480,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _code,
                  focusNode: _focus,
                  autofocus: true,
                  textCapitalization: TextCapitalization.characters,
                  style: UniHubStyles.money(size: 20, weight: FontWeight.w700),
                  decoration: const InputDecoration(
                    hintText: 'Ex.: K7M2QX',
                    prefixIcon: Icon(LucideIcons.qrCode, size: 18),
                  ),
                  onSubmitted: (_) => _validate(),
                ),
              ),
              const SizedBox(width: UniHubSpacing.x3),
              FilledButton(
                onPressed: _busy ? null : _validate,
                child: const Text('Validar'),
              ),
            ],
          ),
        ),
        const SizedBox(height: UniHubSpacing.x6),
        if (_result != null) _ResultCard(result: _result!),
        if (_error != null)
          _Banner(
            icon: LucideIcons.circleX,
            color: UniHubColors.error,
            title: 'Entrada não liberada',
            body: _error!,
          ),
        const SizedBox(height: UniHubSpacing.x10),
        const Divider(),
        const SizedBox(height: UniHubSpacing.x6),
        const Text(
          'Check-ins recentes',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: UniHubSpacing.x3),
        recent.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text('$e'),
          data: (list) => Column(
            children: [
              for (final c in list.take(8))
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: UniHubSpacing.x2,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${c.studentName} · ${c.studentUniversity}',
                          style: const TextStyle(fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        formatDateTime(c.timestamp),
                        style: const TextStyle(
                          fontSize: 13,
                          color: UniHubColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: UniHubSpacing.x3),
                      Icon(
                        c.validatedAt != null
                            ? LucideIcons.circleCheck
                            : LucideIcons.clock,
                        size: 16,
                        color: c.validatedAt != null
                            ? UniHubColors.success
                            : UniHubColors.textSecondary,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});

  final EntryValidation result;

  @override
  Widget build(BuildContext context) {
    return _Banner(
      icon: LucideIcons.circleCheck,
      color: UniHubColors.success,
      title: result.alreadyValidated
          ? 'Entrada já confirmada'
          : 'Entrada liberada',
      body:
          '${result.studentName} · ${result.studentUniversity}\n'
          'Check-in às ${formatTime(result.timestamp)}'
          '${result.alreadyValidated ? ', confirmado às ${formatTime(result.validatedAt)}' : ''}',
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return MaxWidth(
      maxWidth: 480,
      child: Container(
        padding: const EdgeInsets.all(UniHubSpacing.x4),
        decoration: BoxDecoration(
          borderRadius: UniHubRadius.brMd,
          border: Border.all(color: color, width: 1.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: UniHubSpacing.x3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(body, style: const TextStyle(fontSize: 14, height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
