import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';

import '../providers.dart';
import 'common.dart';

/// Suporte manual: confirma, gera a senha temporária e mostra uma única vez.
Future<void> generateTemporaryPassword(
  BuildContext context,
  WidgetRef ref, {
  required String accountName,
  int? studentId,
  int? gymId,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('Gerar senha temporária para $accountName?'),
      content: const Text(
        'A senha atual deixa de funcionar. Passe a nova senha à pessoa por um canal seguro '
        'e peça para ela trocar depois em "Esqueci minha senha".',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Gerar senha'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;

  final String password;
  try {
    password = await ref
        .read(apiClientProvider)
        .generateTemporaryPassword(studentId: studentId, gymId: gymId);
  } catch (e) {
    if (context.mounted) showApiError(context, e);
    return;
  }
  if (!context.mounted) return;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Senha temporária'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nova senha de $accountName. Ela aparece só agora:',
            style: const TextStyle(fontSize: 14, color: UniHubColors.textSecondary),
          ),
          const SizedBox(height: UniHubSpacing.x4),
          SelectableText(
            password,
            style: UniHubStyles.money(size: 26, weight: FontWeight.w800),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: password));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Senha copiada.')),
            );
          },
          child: const Text('Copiar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Pronto'),
        ),
      ],
    ),
  );
}
