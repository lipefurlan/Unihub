import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_models/shared_models.dart';

import '../providers.dart';
import '../widgets/common.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref
          .read(authProvider.notifier)
          .login(_emailController.text.trim(), _passwordController.text);
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: UniHubSpacing.x6),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: UniHubWordmark(size: 32)),
                    const SizedBox(height: UniHubSpacing.x2),
                    const Text(
                      'Bem-estar para a sua vida universitária',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: UniHubColors.textSecondary),
                    ),
                    const SizedBox(height: UniHubSpacing.x10),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'E-mail universitário'),
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      validator: (v) =>
                          v == null || !v.contains('@') ? 'Informe um e-mail válido' : null,
                    ),
                    const SizedBox(height: UniHubSpacing.x4),
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(labelText: 'Senha'),
                      obscureText: true,
                      onFieldSubmitted: (_) => _submit(),
                      validator: (v) =>
                          v == null || v.length < 6 ? 'A senha tem ao menos 6 caracteres' : null,
                    ),
                    const SizedBox(height: UniHubSpacing.x6),
                    FilledButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Entrar'),
                    ),
                    const SizedBox(height: UniHubSpacing.x4),
                    TextButton(
                      onPressed: () => context.go('/register'),
                      child: const Text('Ainda não tem conta? Cadastre-se'),
                    ),
                    const SizedBox(height: UniHubSpacing.x8),
                    const Text(
                      'Demo: joao.silva@dac.unicamp.br · senha123',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: UniHubColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
