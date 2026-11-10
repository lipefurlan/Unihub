import 'package:flutter/widgets.dart';

/// Logo oficial do UniHub (manual de identidade visual 2.0): nome em
/// Red Hat Display com o símbolo das duas meias-luas no lugar do ponto.
///
/// [height] é a altura do desenho; a largura segue a proporção do arquivo.
class UniHubLogo extends StatelessWidget {
  const UniHubLogo({super.key, this.height = 22, this.semanticLabel = 'UniHub'});

  /// Proporção largura/altura do arquivo unihub-logo-cor.png.
  static const aspectRatio = 2400 / 429;

  final double height;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/brand/unihub-logo-cor.png',
      package: 'shared_models',
      height: height,
      width: height * aspectRatio,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      semanticLabel: semanticLabel,
    );
  }
}
