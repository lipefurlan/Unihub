import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tokens de cor do design system UniHub, conforme o manual de identidade
/// visual 2.0.
///
/// Laranja UniHub é a plataforma (botões, símbolo, destaques) e o preto café
/// é o universitário (textos). Papel, laranja claro e laranja brasa são cores
/// de apoio. Sem gradientes, sem roxo, sem azul. Blocos de cor levam a
/// textura de papel (PaperGrain) para não parecerem chapados.
abstract final class UniHubColors {
  static const background = Color(0xFFFFFFFF);
  static const surface = Color(0xFFFFF7F2); // Papel: separa seções e cartões
  static const accent = Color(0xFFFF5A1F); // Laranja UniHub
  static const accentPressed = Color(0xFFD9430C); // Laranja brasa: toque e textos laranja pequenos
  static const accentSoft = Color(0xFFFFE3D4); // Laranja claro: etiquetas e destaque suave
  static const textPrimary = Color(0xFF1F1410); // Preto café
  static const textSecondary = Color(0xFF6F5E55);
  static const textTertiary = Color(0xFF8A766B);
  static const divider = Color(0xFFEADCD2);
  static const border = Color(0xFFE2D2C7);
  static const error = Color(0xFFB42318); // uso funcional, apenas em mensagens de erro
  static const success = Color(0xFF1A7F37); // uso funcional, apenas em confirmações
}

/// Tipografia do manual: Red Hat Display para títulos, números e marca;
/// Red Hat Text para textos, botões e rótulos.
abstract final class UniHubFonts {
  static TextStyle display({
    double? fontSize,
    FontWeight fontWeight = FontWeight.w800,
    Color? color,
    double? letterSpacing,
    List<FontFeature>? fontFeatures,
  }) =>
      GoogleFonts.redHatDisplay(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
        fontFeatures: fontFeatures,
      );

  static TextStyle text({
    double? fontSize,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
    double? letterSpacing,
  }) =>
      GoogleFonts.redHatText(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
      );
}

/// Escala de espaçamento (múltiplos de 4): whitespace generoso é a regra.
abstract final class UniHubSpacing {
  static const double x1 = 4;
  static const double x2 = 8;
  static const double x3 = 12;
  static const double x4 = 16;
  static const double x5 = 20;
  static const double x6 = 24;
  static const double x8 = 32;
  static const double x10 = 40;
  static const double x12 = 48;
}

/// Raios: 6 e 8 px para campos e cartões, 16 px para os blocos de marca
/// (plano, carteirinha); botões são em pílula, como no manual.
abstract final class UniHubRadius {
  static const double sm = 6;
  static const double md = 8;
  static const double lg = 16;
  static const double pill = 999;
  static final BorderRadius brSm = BorderRadius.circular(sm);
  static final BorderRadius brMd = BorderRadius.circular(md);
  static final BorderRadius brLg = BorderRadius.circular(lg);
  static final BorderRadius brPill = BorderRadius.circular(pill);
}

/// Estilos auxiliares que não cabem no ThemeData.
abstract final class UniHubStyles {
  /// Números tabulares para valores financeiros alinhados em tabelas.
  static const tabularNumbers = [FontFeature.tabularFigures()];

  /// Valores em Red Hat Display, com algarismos alinhados (manual: números).
  static TextStyle money({double size = 16, FontWeight weight = FontWeight.w700, Color? color}) =>
      UniHubFonts.display(
        fontSize: size,
        fontWeight: weight,
        color: color ?? UniHubColors.textPrimary,
        fontFeatures: tabularNumbers,
      );
}

/// Tema único do UniHub — usado pelo app do estudante e pelo painel web.
abstract final class UniHubTheme {
  static ThemeData light() {
    final base = GoogleFonts.redHatTextTextTheme();
    TextStyle? heading(TextStyle? style, FontWeight weight) => style == null
        ? null
        : GoogleFonts.redHatDisplay(textStyle: style, fontWeight: weight);
    final textTheme = base
        .copyWith(
          displayLarge: heading(base.displayLarge, FontWeight.w900),
          displayMedium: heading(base.displayMedium, FontWeight.w900),
          displaySmall: heading(base.displaySmall, FontWeight.w800),
          headlineLarge: heading(base.headlineLarge, FontWeight.w800),
          headlineMedium: heading(base.headlineMedium, FontWeight.w800),
          headlineSmall: heading(base.headlineSmall, FontWeight.w800),
          titleLarge: heading(base.titleLarge, FontWeight.w700),
          titleMedium: heading(base.titleMedium, FontWeight.w600),
          titleSmall: heading(base.titleSmall, FontWeight.w600),
        )
        .apply(
          bodyColor: UniHubColors.textPrimary,
          displayColor: UniHubColors.textPrimary,
        );

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: UniHubColors.background,
      colorScheme: const ColorScheme.light(
        primary: UniHubColors.accent,
        onPrimary: Colors.white,
        secondary: UniHubColors.accent,
        onSecondary: Colors.white,
        surface: UniHubColors.background,
        onSurface: UniHubColors.textPrimary,
        error: UniHubColors.error,
        onError: Colors.white,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: UniHubColors.background,
        foregroundColor: UniHubColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: UniHubFonts.display(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: UniHubColors.textPrimary,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.pressed)
                ? UniHubColors.accentPressed
                : UniHubColors.accent,
          ),
          foregroundColor: const WidgetStatePropertyAll(Colors.white),
          textStyle: WidgetStatePropertyAll(
            UniHubFonts.text(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: UniHubSpacing.x6, vertical: 14),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: UniHubRadius.brPill),
          ),
          elevation: const WidgetStatePropertyAll(0),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: UniHubColors.textPrimary,
          side: const BorderSide(color: UniHubColors.border, width: 1),
          textStyle: UniHubFonts.text(fontSize: 15, fontWeight: FontWeight.w700),
          padding: const EdgeInsets.symmetric(horizontal: UniHubSpacing.x6, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: UniHubRadius.brPill),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: UniHubColors.accentPressed,
          textStyle: UniHubFonts.text(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: UniHubRadius.brMd,
          borderSide: const BorderSide(color: UniHubColors.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: UniHubRadius.brMd,
          borderSide: const BorderSide(color: UniHubColors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: UniHubRadius.brMd,
          borderSide: const BorderSide(color: UniHubColors.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: UniHubRadius.brMd,
          borderSide: const BorderSide(color: UniHubColors.error, width: 1),
        ),
        labelStyle: UniHubFonts.text(fontSize: 14, color: UniHubColors.textSecondary),
        hintStyle: UniHubFonts.text(fontSize: 14, color: UniHubColors.textSecondary),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: UniHubSpacing.x4,
          vertical: UniHubSpacing.x3,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: UniHubColors.divider,
        thickness: 1,
        space: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: UniHubColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        indicatorColor: Colors.transparent,
        height: 64,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => UniHubFonts.text(
            fontSize: 11,
            fontWeight:
                states.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? UniHubColors.accent
                : UniHubColors.textSecondary,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 22,
            color: states.contains(WidgetState.selected)
                ? UniHubColors.accent
                : UniHubColors.textSecondary,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: UniHubColors.textPrimary,
        contentTextStyle: UniHubFonts.text(fontSize: 14, color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: UniHubRadius.brMd),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: UniHubColors.background,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: UniHubRadius.brMd),
        titleTextStyle: UniHubFonts.display(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: UniHubColors.textPrimary,
        ),
        contentTextStyle: UniHubFonts.text(fontSize: 14, color: UniHubColors.textSecondary),
      ),
      dataTableTheme: DataTableThemeData(
        headingTextStyle: UniHubFonts.text(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: UniHubColors.textSecondary,
        ),
        dataTextStyle: UniHubFonts.text(fontSize: 14, color: UniHubColors.textPrimary),
        dividerThickness: 1,
        horizontalMargin: 0,
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.zero,
        iconColor: UniHubColors.textSecondary,
      ),
      splashFactory: InkRipple.splashFactory,
    );
  }
}
