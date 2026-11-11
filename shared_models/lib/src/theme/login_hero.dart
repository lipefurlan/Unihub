import 'package:flutter/material.dart';

import 'brand_graphics.dart';
import 'unihub_logo.dart';
import 'unihub_theme.dart';

/// Foto da tela de entrada (app e painel). Para trocar, substitua o arquivo
/// shared_models/assets/brand/login-foto.jpg por uma foto real (academia
/// parceira ou aluno treinando), de preferência em pé, com 1200 px ou mais.
const loginPhotoAsset = 'assets/brand/login-foto.jpg';

/// Topo da tela de entrada no estilo da opção B do estudo: foto em duotone
/// laranja (preto e branco multiplicado pelo laranja UniHub), textura de
/// papel, símbolo vazado em traço fino, logo branco, frase de destaque e a
/// cortina de meias-luas encostada na borda que encontra o formulário.
class LoginPhotoHero extends StatelessWidget {
  const LoginPhotoHero({
    super.key,
    required this.headline,
    this.caption,
    this.sideways = false,
    this.headlineSize = 32,
  });

  final String headline;
  final String? caption;

  /// No computador o bloco fica à esquerda e a cortina desce pela borda
  /// direita; no celular fica em cima, com a cortina na borda de baixo.
  final bool sideways;
  final double headlineSize;

  // Preto e branco com um pouco mais de contraste, antes do laranja
  static const _grayscale = ColorFilter.matrix(<double>[
    0.25, 0.65, 0.10, 0, -12, //
    0.25, 0.65, 0.10, 0, -12, //
    0.25, 0.65, 0.10, 0, -12, //
    0, 0, 0, 1, 0, //
  ]);

  @override
  Widget build(BuildContext context) {
    final pad = sideways ? 64.0 : UniHubSpacing.x6;
    final photo = ColorFiltered(
      colorFilter: const ColorFilter.mode(UniHubColors.accent, BlendMode.multiply),
      child: ColorFiltered(
        colorFilter: _grayscale,
        child: Image.asset(
          loginPhotoAsset,
          package: 'shared_models',
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),
      ),
    );

    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          photo,
          // Clareia as sombras para o laranja continuar sendo laranja
          ColoredBox(color: UniHubColors.accent.withValues(alpha: 0.32)),
          const PaperGrain(opacity: 0.08),
          Positioned(
            right: sideways ? -160 : -90,
            bottom: sideways ? 40 : 30,
            child: SymbolOutline(height: sideways ? 420 : 230, opacity: 0.45),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              pad,
              sideways ? 56 : UniHubSpacing.x10,
              sideways ? pad + 24 : pad,
              sideways ? 72 : UniHubSpacing.x10 + 20,
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  UniHubLogo(height: sideways ? 36 : 30, onOrange: true),
                  const Spacer(),
                  Text(
                    headline,
                    style: UniHubFonts.display(
                      fontSize: headlineSize,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.6,
                    ).copyWith(height: 1.04),
                  ),
                  if (caption != null) ...[
                    const SizedBox(height: UniHubSpacing.x3),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: Text(
                        caption!,
                        style: UniHubFonts.text(
                          fontSize: sideways ? 16 : 14,
                          color: Colors.white.withValues(alpha: 0.92),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (sideways)
            const Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: HalfMoonCurtain(radius: 12, onOrange: true, vertical: true),
            )
          else
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: HalfMoonCurtain(radius: 12, onOrange: true),
            ),
        ],
      ),
    );
  }
}
