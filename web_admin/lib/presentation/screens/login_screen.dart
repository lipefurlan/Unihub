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

  // Contas de demonstração do seed (atalhos para a banca)
  void _loginAsDemo(String email, String password) {
    _emailController.text = email;
    _passwordController.text = password;
    _submit();
  }

  Future<void> _googleLogin(String idToken) async {
    try {
      await ref.read(sessionProvider.notifier).loginWithGoogle(idToken);
    } catch (e) {
      if (mounted) showApiError(context, e);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref
          .read(sessionProvider.notifier)
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
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(UniHubSpacing.x6),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(
                    child: UniHubWordmark(size: 28, suffix: 'painel'),
                  ),
                  const SizedBox(height: UniHubSpacing.x2),
                  const Text(
                    'Acesso para academias parceiras e para a operação UniHub.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: UniHubColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: UniHubSpacing.x10),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'E-mail'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => v == null || !v.contains('@')
                        ? 'Informe um e-mail válido'
                        : null,
                  ),
                  const SizedBox(height: UniHubSpacing.x4),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: 'Senha'),
                    obscureText: true,
                    onFieldSubmitted: (_) => _submit(),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Informe a senha' : null,
                  ),
                  const SizedBox(height: UniHubSpacing.x6),
                  FilledButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Entrar no painel'),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => context.go('/esqueci-senha'),
                      child: const Text('Esqueci minha senha'),
                    ),
                  ),
                  if (googleLoginEnabled) ...[
                    const OrDivider(),
                    const SizedBox(height: UniHubSpacing.x4),
                    GoogleLoginButton(
                      onIdToken: _googleLogin,
                      onError: (e) => showApiError(context, e),
                    ),
                  ],
                  const SizedBox(height: UniHubSpacing.x8),
                  const Text(
                    'Demonstração',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: UniHubColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: UniHubSpacing.x2),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _loading
                              ? null
                              : () => _loginAsDemo(
                                  'contato@campusfit.com.br',
                                  'academia123',
                                ),
                          child: const Text('Academia'),
                        ),
                      ),
                      const SizedBox(width: UniHubSpacing.x3),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _loading
                              ? null
                              : () => _loginAsDemo(
                                  'admin@unihub.com.br',
                                  'admin123',
                                ),
                          child: const Text('Operação UniHub'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
