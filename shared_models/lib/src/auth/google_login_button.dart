import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../theme/unihub_theme.dart';
import 'google_button_stub.dart' if (dart.library.js_interop) 'google_button_web.dart';

/// Client ID do Google (OAuth, tipo "Aplicativo da Web"), passado no build:
/// `--dart-define=GOOGLE_CLIENT_ID=...`. Vazio = botão escondido.
const googleClientId = String.fromEnvironment('GOOGLE_CLIENT_ID');

/// Login com Google disponível neste build (por ora, só na versão web).
bool get googleLoginEnabled => googleClientId.isNotEmpty && googleButtonSupported;

/// Botão oficial "Continuar com o Google" (Google Identity Services).
///
/// Quando a pessoa conclui o login no Google, entrega o ID token em
/// [onIdToken]; quem usa o botão envia esse token para `POST /auth/google`.
class GoogleLoginButton extends StatefulWidget {
  const GoogleLoginButton({super.key, required this.onIdToken, this.onError});

  final ValueChanged<String> onIdToken;
  final ValueChanged<Object>? onError;

  @override
  State<GoogleLoginButton> createState() => _GoogleLoginButtonState();
}

class _GoogleLoginButtonState extends State<GoogleLoginButton> {
  // O plugin só pode ser inicializado uma vez por execução do app
  static Future<void>? _initialization;

  StreamSubscription<GoogleSignInAuthenticationEvent>? _subscription;

  @override
  void initState() {
    super.initState();
    _initialization ??= GoogleSignIn.instance.initialize(clientId: googleClientId);
    _subscription = GoogleSignIn.instance.authenticationEvents.listen(
      (event) {
        if (event is GoogleSignInAuthenticationEventSignIn) {
          final idToken = event.user.authentication.idToken;
          if (idToken != null) widget.onIdToken(idToken);
        }
      },
      onError: (Object error) {
        // Fechar a janela do Google não é erro
        if (error is GoogleSignInException && error.code == GoogleSignInExceptionCode.canceled) return;
        widget.onError?.call(error);
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox(height: 44);
        }
        return Center(child: renderGoogleButton());
      },
    );
  }
}

/// Separador "ou" entre o login por senha e o botão do Google.
class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: Divider()),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: UniHubSpacing.x3),
          child: Text('ou', style: TextStyle(fontSize: 13, color: UniHubColors.textSecondary)),
        ),
        Expanded(child: Divider()),
      ],
    );
  }
}
