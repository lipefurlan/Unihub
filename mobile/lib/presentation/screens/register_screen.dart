import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_models/shared_models.dart';

import '../providers.dart';
import '../widgets/common.dart';
import 'login_screen.dart' show googleLogin;

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(authProvider.notifier).register(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar conta')),
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
                    const SizedBox(height: UniHubSpacing.x4),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Nome completo'),
                      validator: (v) =>
                          v == null || v.trim().length < 2 ? 'Informe seu nome' : null,
                    ),
                    const SizedBox(height: UniHubSpacing.x4),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'E-mail da faculdade',
                        helperText: 'A faculdade precisa ser conveniada ao UniHub',
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) =>
                          v == null || !v.contains('@') ? 'Informe um e-mail válido' : null,
                    ),
                    const SizedBox(height: UniHubSpacing.x4),
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(labelText: 'Senha (mín. 6 caracteres)'),
                      obscureText: true,
                      onFieldSubmitted: (_) => _submit(),
                      validator: (v) =>
                          v == null || v.length < 6 ? 'Use ao menos 6 caracteres' : null,
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
                          : const Text('Criar conta'),
                    ),
                    if (googleLoginEnabled) ...[
                      const SizedBox(height: UniHubSpacing.x4),
                      const OrDivider(),
                      const SizedBox(height: UniHubSpacing.x4),
                      GoogleLoginButton(
                        onIdToken: (token) => googleLogin(context, ref, token),
                        onError: (e) => showApiError(context, e),
                      ),
                    ],
                    const SizedBox(height: UniHubSpacing.x4),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('Já tenho conta'),
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
