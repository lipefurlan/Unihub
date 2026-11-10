import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_models/shared_models.dart';

import '../providers.dart';
import '../widgets/common.dart';

// Conta de demonstração do seed (aparece como atalho para a banca)
const _demoEmail = 'joao.silva@dac.unicamp.br';
const _demoPassword = 'senha123';

/// Envia o ID token do Google para a API e abre a sessão.
Future<void> googleLogin(BuildContext context, WidgetRef ref, String idToken) async {
  try {
    await ref.read(authProvider.notifier).loginWithGoogle(idToken);
  } catch (e) {
    if (context.mounted) showApiError(context, e);
  }
}

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

  void _fillDemo() {
    _emailController.text = _demoEmail;
    _passwordController.text = _demoPassword;
    _submit();
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            const _LoginHero(),
            Center(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    UniHubSpacing.x6, UniHubSpacing.x8, UniHubSpacing.x6, UniHubSpacing.x6),
                child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Entrar',
                      style: UniHubFonts.display(fontSize: 24, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: UniHubSpacing.x5),
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
                        onIdToken: (token) => googleLogin(context, ref, token),
                        onError: (e) => showApiError(context, e),
                      ),
                      const SizedBox(height: UniHubSpacing.x2),
                    ],
                    TextButton(
                      onPressed: () => context.go('/register'),
                      child: const Text('Ainda não tem conta? Cadastre-se'),
                    ),
                    const SizedBox(height: UniHubSpacing.x6),
                    OutlinedButton(
                      onPressed: _loading ? null : _fillDemo,
                      child: const Text('Entrar como aluno de demonstração'),
                    ),
                    const SizedBox(height: UniHubSpacing.x2),
                    const Text(
                      'João Silva, Unicamp · joao.silva@dac.unicamp.br · senha123',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: UniHubColors.textSecondary),
                    ),
                  ],
                ),
              ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Topo laranja do login, como a tela de abertura do manual: logo branco,
/// textura de papel e a cortina de meias-luas encostada na borda de baixo.
class _LoginHero extends StatelessWidget {
  const _LoginHero();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: UniHubColors.accent,
      child: Stack(
        children: [
          const Positioned.fill(child: PaperGrain()),
          // Símbolo vazado gigante saindo pelos cantos, longe do logo
          const Positioned(left: -150, top: -120, child: SymbolOutline(height: 300, opacity: 0.30)),
          const Positioned(right: -170, bottom: 10, child: SymbolOutline(height: 260, opacity: 0.30)),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                const SizedBox(height: UniHubSpacing.x12 + UniHubSpacing.x6),
                const UniHubLogo(height: 40, onOrange: true),
                const SizedBox(height: UniHubSpacing.x4),
                Text(
                  'Academias para universitários',
                  style: UniHubFonts.text(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: UniHubSpacing.x12 + UniHubSpacing.x6),
                const HalfMoonCurtain(radius: 14, onOrange: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
