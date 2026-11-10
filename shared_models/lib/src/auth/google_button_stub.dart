import 'package:flutter/widgets.dart';

/// Fora do navegador o botão do Google ainda não está ligado (o app nativo
/// precisa de configuração própria no Android/iOS).
const googleButtonSupported = false;

Widget renderGoogleButton() => const SizedBox.shrink();
