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

  static final _demoStyle = OutlinedButton.styleFrom(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
  );

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
      backgroundColor: UniHubColors.surface,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final form = ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: _buildForm(context),
          );
          if (constraints.maxWidth >= 900) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Expanded(
                  flex: 5,
                  child: LoginPhotoHero(
                    sideways: true,
                    headlineSize: 40,
                    headline: 'Academias, faculdades\ne alunos no mesmo lugar.',
                    caption:
                        'Painel das academias parceiras, das faculdades conveniadas e da operação UniHub.',
                  ),
                ),
                Expanded(
                  flex: 6,
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(UniHubSpacing.x10),
                      child: form,
                    ),
                  ),
                ),
              ],
            );
          }
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(
                  height: 300,
                  child: LoginPhotoHero(
                    headlineSize: 28,
                    headline: 'Academias, faculdades\ne alunos no mesmo lugar.',
                  ),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(UniHubSpacing.x6),
                    child: form,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    Widget demo(String label, String email, String password) => Expanded(
          child: OutlinedButton(
            style: _demoStyle,
            onPressed: _loading ? null : () => _loginAsDemo(email, password),
            child: Text(label),
          ),
        );

    return AutofillGroup(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const BrandLabel('Painel UniHub'),
            const SizedBox(height: UniHubSpacing.x1),
            Text(
              'Entrar no painel',
              style: UniHubFonts.display(fontSize: 30, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: UniHubSpacing.x1),
            Text(
              'Para academias parceiras, faculdades conveniadas e a operação.',
              style: UniHubFonts.text(fontSize: 14, color: UniHubColors.textSecondary),
            ),
            const SizedBox(height: UniHubSpacing.x6),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'E-mail',
                filled: true,
                fillColor: Colors.white,
                prefixIcon: Icon(Icons.mail_outline_rounded, size: 20),
              ),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              validator: (v) =>
                  v == null || !v.contains('@') ? 'Informe um e-mail válido' : null,
            ),
            const SizedBox(height: UniHubSpacing.x4),
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Senha',
                filled: true,
                fillColor: Colors.white,
                prefixIcon: Icon(Icons.lock_outline_rounded, size: 20),
              ),
              obscureText: true,
              autofillHints: const [AutofillHints.password],
              onFieldSubmitted: (_) => _submit(),
              validator: (v) => v == null || v.isEmpty ? 'Informe a senha' : null,
            ),
            const SizedBox(height: UniHubSpacing.x2),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: UniHubSpacing.x1),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: UniHubFonts.text(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                onPressed: () => context.go('/esqueci-senha'),
                child: const Text('Esqueci minha senha'),
              ),
            ),
            const SizedBox(height: UniHubSpacing.x5),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Entrar no painel'),
              ),
            ),
            if (googleLoginEnabled) ...[
              const SizedBox(height: UniHubSpacing.x4),
              const OrDivider(),
              const SizedBox(height: UniHubSpacing.x4),
              GoogleLoginButton(
                onIdToken: _googleLogin,
                onError: (e) => showApiError(context, e),
              ),
            ],
            const SizedBox(height: UniHubSpacing.x10),
            BrandLabel('Entrar como demonstração', color: UniHubColors.textTertiary, size: 10.5),
            const SizedBox(height: UniHubSpacing.x3),
            Row(
              children: [
                demo('Academia', 'contato@campusfit.com.br', 'academia123'),
                const SizedBox(width: UniHubSpacing.x2),
                demo('Faculdade', 'programa@facamp.edu.br', 'facamp123'),
                const SizedBox(width: UniHubSpacing.x2),
                demo('Operação', 'admin@unihub.com.br', 'admin123'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
