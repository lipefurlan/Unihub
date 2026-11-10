import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_models/shared_models.dart';

import '../providers.dart';
import '../widgets/common.dart';

/// Confirmação dos e-mails por código: um para o pessoal, outro para o da
/// faculdade. Sem os dois confirmados o aluno navega, mas não assina.
class VerifyEmailScreen extends ConsumerWidget {
  const VerifyEmailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final student = ref.watch(authProvider).value;
    if (student == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(title: Text(student.singleEmail ? 'Confirmar e-mail' : 'Confirmar e-mails')),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(UniHubSpacing.x6),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    student.isVerified ? 'Tudo certo!' : 'Falta pouco',
                    style: UniHubFonts.display(fontSize: 24, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: UniHubSpacing.x2),
                  Text(
                    student.isVerified
                        ? 'Seu cadastro está confirmado. Já dá para escolher um plano.'
                        : student.singleEmail
                            ? 'Enviamos um código de 6 dígitos para o e-mail da faculdade. '
                                'Digite abaixo para confirmar.'
                            : 'Enviamos um código de 6 dígitos para cada e-mail. '
                                'O da faculdade comprova que você é aluno de uma conveniada.',
                    style: const TextStyle(fontSize: 15, color: UniHubColors.textSecondary),
                  ),
                  const SizedBox(height: UniHubSpacing.x6),
                  if (student.singleEmail)
                    _EmailCodeCard(
                      kind: 'personal',
                      title: 'E-mail da faculdade',
                      email: student.email,
                      verified: student.isVerified,
                    )
                  else ...[
                    _EmailCodeCard(
                      kind: 'personal',
                      title: 'E-mail pessoal',
                      email: student.email,
                      verified: student.emailVerified,
                    ),
                    const SizedBox(height: UniHubSpacing.x4),
                    _EmailCodeCard(
                      kind: 'institutional',
                      title: 'E-mail da faculdade',
                      email: student.institutionalEmail!,
                      verified: student.institutionalEmailVerified,
                    ),
                  ],
                  const SizedBox(height: UniHubSpacing.x6),
                  if (student.isVerified)
                    FilledButton(
                      onPressed: () => context.go('/plans'),
                      child: const Text('Escolher meu plano'),
                    )
                  else ...[
                    const Text(
                      'Não chegou? Confira o spam ou peça outro código.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: UniHubColors.textTertiary),
                    ),
                    TextButton(
                      onPressed: () => context.go('/home'),
                      child: const Text('Fazer isso depois'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmailCodeCard extends ConsumerStatefulWidget {
  const _EmailCodeCard({
    required this.kind,
    required this.title,
    required this.email,
    required this.verified,
  });

  final String kind; // personal | institutional
  final String title;
  final String email;
  final bool verified;

  @override
  ConsumerState<_EmailCodeCard> createState() => _EmailCodeCardState();
}

class _EmailCodeCardState extends ConsumerState<_EmailCodeCard> {
  final _code = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _run(Future<Student> Function(ApiClient api) call, {String? success}) async {
    setState(() => _busy = true);
    try {
      final profile = await call(ref.read(apiClientProvider));
      ref.read(authProvider.notifier).setProfile(profile);
      if (success != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success)));
      }
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _confirm() {
    final code = _code.text.trim();
    if (code.length != 6) return;
    _run((api) => api.confirmVerificationCode(widget.kind, code));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(UniHubSpacing.x4),
      decoration: BoxDecoration(
        color: widget.verified ? UniHubColors.surface : UniHubColors.background,
        border: Border.all(color: UniHubColors.border),
        borderRadius: UniHubRadius.brMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                widget.verified ? LucideIcons.circleCheck : LucideIcons.mail,
                size: 20,
                color: widget.verified ? UniHubColors.success : UniHubColors.accent,
              ),
              const SizedBox(width: UniHubSpacing.x2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(
                      widget.email,
                      style: const TextStyle(fontSize: 13, color: UniHubColors.textSecondary),
                    ),
                  ],
                ),
              ),
              if (widget.verified)
                const Text(
                  'Confirmado',
                  style: TextStyle(fontSize: 13, color: UniHubColors.success, fontWeight: FontWeight.w600),
                ),
            ],
          ),
          if (!widget.verified) ...[
            const SizedBox(height: UniHubSpacing.x4),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _code,
                    enabled: !_busy,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(fontSize: 20, letterSpacing: 6, fontWeight: FontWeight.w700),
                    decoration: const InputDecoration(hintText: '000000', counterText: ''),
                    onChanged: (v) {
                      if (v.length == 6) _confirm();
                    },
                    onSubmitted: (_) => _confirm(),
                  ),
                ),
                const SizedBox(width: UniHubSpacing.x3),
                FilledButton(
                  onPressed: _busy ? null : _confirm,
                  child: const Text('Confirmar'),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: _busy
                    ? null
                    : () => _run(
                          (api) => api.sendVerificationCode(widget.kind),
                          success: 'Enviamos um novo código para ${widget.email}.',
                        ),
                child: const Text('Reenviar código'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
