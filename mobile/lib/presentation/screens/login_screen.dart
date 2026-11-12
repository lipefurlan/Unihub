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
  bool _showPassword = false;

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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 880;
          final form = _buildForm(context);
          if (wide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Expanded(
                  flex: 5,
                  child: LoginPhotoHero(
                    sideways: true,
                    headlineSize: 46,
                    headline: 'Uma assinatura,\nvárias academias.',
                    caption:
                        'Academias perto do campus, com check-in pelo app e o subsídio da sua faculdade.',
                  ),
                ),
                Expanded(
                  flex: 6,
                  child: SafeArea(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(UniHubSpacing.x10),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 400),
                          child: form,
                        ),
                      ),
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
                  height: 380,
                  child: LoginPhotoHero(headline: 'Uma assinatura,\nvárias academias.'),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      UniHubSpacing.x6,
                      UniHubSpacing.x8,
                      UniHubSpacing.x6,
                      UniHubSpacing.x8,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: form,
                    ),
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
    return AutofillGroup(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Entrar',
              style: UniHubFonts.display(fontSize: 28, color: UniHubColors.textPrimary),
            ),
            const SizedBox(height: UniHubSpacing.x1),
            Text(
              'Use o e-mail da sua faculdade e a sua senha.',
              style: UniHubFonts.text(fontSize: 14, color: UniHubColors.textSecondary),
            ),
            const SizedBox(height: UniHubSpacing.x6),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'E-mail universitário',
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
              decoration: InputDecoration(
                labelText: 'Senha',
                prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                suffixIcon: IconButton(
                  tooltip: _showPassword ? 'Esconder senha' : 'Mostrar senha',
                  icon: Icon(
                    _showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _showPassword = !_showPassword),
                ),
              ),
              obscureText: !_showPassword,
              autofillHints: const [AutofillHints.password],
              onFieldSubmitted: (_) => _submit(),
              validator: (v) =>
                  v == null || v.length < 6 ? 'A senha tem ao menos 6 caracteres' : null,
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
                onPressed: () => context.push('/esqueci-senha'),
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
                    : const Text('Entrar'),
              ),
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
            const SizedBox(height: UniHubSpacing.x6),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Ainda não tem conta?',
                  style: UniHubFonts.text(fontSize: 14, color: UniHubColors.textSecondary),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: UniHubSpacing.x1,
                      vertical: UniHubSpacing.x1,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () => context.push('/register'),
                  child: const Text('Cadastre-se'),
                ),
              ],
            ),
            const SizedBox(height: UniHubSpacing.x8),
            _DemoBox(onPressed: _loading ? null : _fillDemo),
          ],
        ),
      ),
    );
  }
}

/// Atalho da conta de demonstração do seed, separado do login de verdade.
class _DemoBox extends StatelessWidget {
  const _DemoBox({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(UniHubSpacing.x4),
      decoration: BoxDecoration(
        color: UniHubColors.accentSoft.withValues(alpha: 0.45),
        borderRadius: UniHubRadius.brLg,
        border: Border.all(color: UniHubColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const BrandLabel('Modo demonstração'),
          const SizedBox(height: UniHubSpacing.x1),
          Text(
            'Entre como João Silva, aluno da Unicamp, para ver o app com dados de exemplo.',
            style: UniHubFonts.text(fontSize: 13, color: UniHubColors.textSecondary),
          ),
          const SizedBox(height: UniHubSpacing.x3),
          OutlinedButton(
            onPressed: onPressed,
            child: const Text('Entrar na demonstração'),
          ),
        ],
      ),
    );
  }
}
