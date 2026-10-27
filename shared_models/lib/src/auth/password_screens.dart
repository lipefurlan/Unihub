import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../theme/unihub_theme.dart';

/// "Esqueci minha senha": pede o e-mail e dispara o link de redefinição.
/// Usada pelo app do estudante e pelo painel (academia/admin).
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, required this.api, required this.onBackToLogin});

  final ApiClient api;
  final VoidCallback onBackToLogin;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _loading = false;
  String? _sentMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final message = await widget.api.forgotPassword(_emailController.text.trim());
      if (mounted) setState(() => _sentMessage = message);
    } catch (e) {
      if (mounted) _showError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AuthCard(
      title: 'Esqueci minha senha',
      subtitle: _sentMessage ??
          'Informe o e-mail da sua conta. Vamos enviar um link para você criar uma nova senha.',
      children: [
        if (_sentMessage == null)
          Form(
            key: _formKey,
            child: TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'E-mail'),
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              onFieldSubmitted: (_) => _submit(),
              validator: (v) => v == null || !v.contains('@') ? 'Informe um e-mail válido' : null,
            ),
          ),
        if (_sentMessage == null) ...[
          const SizedBox(height: UniHubSpacing.x6),
          FilledButton(
            onPressed: _loading ? null : _submit,
            child: _loading ? const _ButtonSpinner() : const Text('Enviar link'),
          ),
        ],
        const SizedBox(height: UniHubSpacing.x4),
        TextButton(onPressed: widget.onBackToLogin, child: const Text('Voltar para o login')),
      ],
    );
  }
}

/// Tela aberta pelo link do e-mail (`/redefinir-senha?token=...`).
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({
    super.key,
    required this.api,
    required this.token,
    required this.onBackToLogin,
  });

  final ApiClient api;
  final String? token;
  final VoidCallback onBackToLogin;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _loading = false;
  String? _doneMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final message = await widget.api.resetPassword(widget.token!, _passwordController.text);
      if (mounted) setState(() => _doneMessage = message);
    } catch (e) {
      if (mounted) _showError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final token = widget.token;
    if (token == null || token.isEmpty) {
      return _AuthCard(
        title: 'Link inválido',
        subtitle: 'Abra o link exatamente como chegou no e-mail ou peça um novo.',
        children: [
          TextButton(onPressed: widget.onBackToLogin, child: const Text('Voltar para o login')),
        ],
      );
    }
    if (_doneMessage != null) {
      return _AuthCard(
        title: 'Senha alterada',
        subtitle: _doneMessage!,
        children: [FilledButton(onPressed: widget.onBackToLogin, child: const Text('Ir para o login'))],
      );
    }
    return _AuthCard(
      title: 'Criar nova senha',
      subtitle: 'Escolha uma senha com pelo menos 6 caracteres.',
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Nova senha'),
                obscureText: true,
                autofillHints: const [AutofillHints.newPassword],
                validator: (v) => v == null || v.length < 6 ? 'Use ao menos 6 caracteres' : null,
              ),
              const SizedBox(height: UniHubSpacing.x4),
              TextFormField(
                controller: _confirmController,
                decoration: const InputDecoration(labelText: 'Repita a nova senha'),
                obscureText: true,
                onFieldSubmitted: (_) => _submit(),
                validator: (v) => v != _passwordController.text ? 'As senhas não são iguais' : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: UniHubSpacing.x6),
        FilledButton(
          onPressed: _loading ? null : _submit,
          child: _loading ? const _ButtonSpinner() : const Text('Salvar nova senha'),
        ),
      ],
    );
  }
}

void _showError(BuildContext context, Object error) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(error.toString()), backgroundColor: UniHubColors.error),
  );
}

class _ButtonSpinner extends StatelessWidget {
  const _ButtonSpinner();

  @override
  Widget build(BuildContext context) => const SizedBox(
        height: 18,
        width: 18,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
      );
}

class _AuthCard extends StatelessWidget {
  const _AuthCard({required this.title, required this.subtitle, required this.children});

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: UniHubSpacing.x6),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: UniHubSpacing.x2),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: UniHubColors.textSecondary),
                  ),
                  const SizedBox(height: UniHubSpacing.x8),
                  ...children,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
