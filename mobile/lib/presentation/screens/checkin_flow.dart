import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_models/shared_models.dart';

import '../providers.dart';
import '../widgets/common.dart';

/// Fluxo compartilhado de check-in: confirmação → chamada à API → sucesso.
/// O bloqueio (tier insuficiente ou anti-fraude) chega como ApiException
/// com a mensagem do backend.
Future<void> startCheckinFlow(BuildContext context, WidgetRef ref, Gym gym) async {
  final confirmed = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: UniHubColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(UniHubRadius.md)),
    ),
    builder: (sheetContext) => Padding(
      padding: const EdgeInsets.all(UniHubSpacing.x6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Confirmar check-in',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: UniHubSpacing.x2),
          Text(
            gym.name,
            style: const TextStyle(fontSize: 15, color: UniHubColors.textSecondary),
          ),
          Text(
            gym.address,
            style: const TextStyle(fontSize: 13, color: UniHubColors.textSecondary),
          ),
          const SizedBox(height: UniHubSpacing.x6),
          FilledButton(
            onPressed: () => Navigator.of(sheetContext).pop(true),
            child: const Text('Confirmar check-in'),
          ),
          const SizedBox(height: UniHubSpacing.x2),
          OutlinedButton(
            onPressed: () => Navigator.of(sheetContext).pop(false),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    ),
  );

  if (confirmed != true || !context.mounted) return;

  try {
    final checkin = await ref.read(apiClientProvider).createCheckin(gym.id);
    // Histórico e contadores mudaram
    ref.invalidate(myCheckinsProvider);
    if (context.mounted) context.push('/checkin-success', extra: checkin);
  } on ApiException catch (e) {
    if (!context.mounted) return;
    // Mensagem clara de bloqueio (tier insuficiente / anti-fraude / sem assinatura)
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(LucideIcons.alertCircle, color: UniHubColors.accent, size: 28),
        title: const Text('Check-in não permitido'),
        content: Text(e.message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  } catch (e) {
    if (context.mounted) showApiError(context, e);
  }
}
