import 'package:flutter/widgets.dart';

/// Logo oficial do UniHub (manual de identidade visual 2.0): nome em
/// Red Hat Display com o símbolo das duas meias-luas no lugar do ponto.
///
/// [height] é a altura do desenho; a largura segue a proporção do arquivo.
class UniHubLogo extends StatelessWidget {
  const UniHubLogo({
    super.key,
    this.height = 22,
    this.onDark = false,
    this.onOrange = false,
    this.semanticLabel = 'UniHub',
  });

  /// Proporção largura/altura do arquivo unihub-logo-cor.png.
  static const aspectRatio = 2400 / 429;

  final double height;

  /// Versão com nome branco e meia-lua laranja para fundos escuros.
  final bool onDark;

  /// Versão sobre laranja: nome branco, crescentes branco e preto.
  final bool onOrange;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      onOrange
          ? 'assets/brand/unihub-logo-fundo-laranja.png'
          : onDark
              ? 'assets/brand/unihub-logo-fundo-escuro.png'
              : 'assets/brand/unihub-logo-cor.png',
      package: 'shared_models',
      height: height,
      width: height * aspectRatio,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      semanticLabel: semanticLabel,
    );
  }
}
