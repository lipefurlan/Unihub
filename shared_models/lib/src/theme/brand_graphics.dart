import 'dart:math' as math;
import 'dart:ui' show PointMode;

import 'package:flutter/material.dart';

import 'unihub_theme.dart';

/// Símbolo do UniHub desenhado em código: dois círculos que se cruzam, sem a
/// área em comum. O crescente laranja (plataforma) fica sempre à esquerda e o
/// preto (universitário) à direita, encostando nas pontas.
///
/// [meet] vai de 0 (crescentes afastados) a 1 (posição final do logo) e
/// serve para animar "o encontro" no check-in.
class UniHubSymbol extends StatelessWidget {
  const UniHubSymbol({
    super.key,
    this.height = 24,
    this.left = UniHubColors.accent,
    this.right = UniHubColors.textPrimary,
    this.meet = 1,
  });

  /// Largura/altura do símbolo na posição final (medida do manual).
  static const aspectRatio = 1.46;

  final double height;
  final Color left;
  final Color right;
  final double meet;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: height * aspectRatio,
      child: CustomPaint(painter: _SymbolPainter(left: left, right: right, meet: meet)),
    );
  }
}

class _SymbolPainter extends CustomPainter {
  _SymbolPainter({required this.left, required this.right, required this.meet});

  final Color left;
  final Color right;
  final double meet;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.height / 2;
    final cy = size.height / 2;
    // Distância final entre os centros: 0,46 do diâmetro
    final finalGap = size.height * 0.46;
    final gap = finalGap + (1 - meet) * size.height * 0.9;
    final mid = size.width / 2;
    final a = Rect.fromCircle(center: Offset(mid - gap / 2, cy), radius: r);
    final b = Rect.fromCircle(center: Offset(mid + gap / 2, cy), radius: r);
    final pa = Path()..addOval(a);
    final pb = Path()..addOval(b);
    canvas.drawPath(Path.combine(PathOperation.difference, pa, pb), Paint()..color = left);
    canvas.drawPath(Path.combine(PathOperation.difference, pb, pa), Paint()..color = right);
  }

  @override
  bool shouldRepaint(_SymbolPainter old) =>
      old.meet != meet || old.left != left || old.right != right;
}

/// Cortina de meias-luas do manual: fileira de meias-luas alternadas, sempre
/// encostada numa borda da peça. Use uma por tela e nunca encostada no logo.
///
/// Sobre fundo laranja, passe [onOrange] para a meia-lua laranja virar branca.
class HalfMoonCurtain extends StatelessWidget {
  const HalfMoonCurtain({
    super.key,
    this.radius = 12,
    this.onOrange = false,
    this.vertical = false,
  });

  final double radius;
  final bool onOrange;

  /// Fileira em pé, para encostar numa lateral (a meia-lua clara fica de
  /// fora, a escura encosta na borda).
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final strip = SizedBox(
      height: radius * 2,
      width: double.infinity,
      child: CustomPaint(
        painter: _CurtainPainter(
          radius: radius,
          top: onOrange ? Colors.white : UniHubColors.accent,
          bottom: UniHubColors.textPrimary,
        ),
      ),
    );
    if (!vertical) return strip;
    return RotatedBox(quarterTurns: 3, child: strip);
  }
}

class _CurtainPainter extends CustomPainter {
  _CurtainPainter({required this.radius, required this.top, required this.bottom});

  final double radius;
  final Color top;
  final Color bottom;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);
    final period = radius * 4;
    final topPaint = Paint()..color = top;
    final bottomPaint = Paint()..color = bottom;
    // Centraliza a fileira para as pontas ficarem iguais dos dois lados
    final count = (size.width / period).ceil() + 1;
    final start = (size.width - (count - 1) * period) / 2 - period / 2;
    for (var i = 0; i <= count; i++) {
      final x = start + i * period;
      // Meia-lua de cima: corte reto encostado na linha de cima
      canvas.drawArc(
        Rect.fromCircle(center: Offset(x, 0), radius: radius),
        0,
        math.pi,
        true,
        topPaint,
      );
      // Meia-lua de baixo, intercalada, com o corte reto na borda
      canvas.drawArc(
        Rect.fromCircle(center: Offset(x + period / 2, size.height), radius: radius),
        math.pi,
        math.pi,
        true,
        bottomPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_CurtainPainter old) =>
      old.radius != radius || old.top != top || old.bottom != bottom;
}

/// Textura de papel: grão fino e fixo (sempre o mesmo desenho) por cima de
/// blocos de cor, para eles não parecerem chapados na tela. Bem sutil, não
/// é efeito: some a um palmo de distância.
class PaperGrain extends StatelessWidget {
  const PaperGrain({super.key, this.opacity = 0.06, this.seed = 7});

  final double opacity;
  final int seed;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _GrainPainter(opacity: opacity, seed: seed),
          isComplex: true,
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _GrainPainter extends CustomPainter {
  _GrainPainter({required this.opacity, required this.seed});

  final double opacity;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(seed);
    final light = <Offset>[];
    final dark = <Offset>[];
    final n = (size.width * size.height / 14).round();
    for (var i = 0; i < n; i++) {
      final p = Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height);
      (rnd.nextBool() ? light : dark).add(p);
    }
    final stroke = Paint()
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.square;
    canvas.drawPoints(
        PointMode.points, light, stroke..color = Colors.white.withValues(alpha: opacity * 1.6));
    canvas.drawPoints(PointMode.points, dark,
        stroke..color = UniHubColors.textPrimary.withValues(alpha: opacity));
  }

  @override
  bool shouldRepaint(_GrainPainter old) => old.opacity != opacity || old.seed != seed;
}

/// Bloco de marca: cor chapada com textura de papel e cantos de 16 px.
/// Base para o card do plano, a carteirinha e o card de sequência.
class BrandBlock extends StatelessWidget {
  const BrandBlock({
    super.key,
    required this.child,
    this.color = UniHubColors.accent,
    this.padding = const EdgeInsets.all(UniHubSpacing.x5),
    this.footer,
    this.lift = false,
  });

  final Widget child;
  final Color color;
  final EdgeInsetsGeometry padding;

  /// Algo encostado na borda de baixo, sem padding (ex.: a cortina).
  final Widget? footer;

  /// Sombra curta na cor do bloco, para objetos "físicos" como a carteirinha.
  final bool lift;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: UniHubRadius.brLg,
        boxShadow: lift
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.28),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: UniHubRadius.brLg,
        child: ColoredBox(
          color: color,
          child: Stack(
            children: [
              const Positioned.fill(child: PaperGrain()),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(padding: padding, child: child),
                  ?footer,
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Rótulo em caixa alta do manual (Red Hat Text 700, espaçado).
class BrandLabel extends StatelessWidget {
  const BrandLabel(this.text, {super.key, this.color = UniHubColors.accentPressed, this.size = 11});

  final String text;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: UniHubFonts.text(
          fontSize: size,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.3,
          color: color,
        ),
      );
}
