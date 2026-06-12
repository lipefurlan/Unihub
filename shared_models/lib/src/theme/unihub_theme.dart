import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tokens de cor do design system UniHub.
///
/// Identidade: minimalista, branca, com laranja forte como única cor de
/// acento — usado com parcimônia (botões primários, valores em destaque,
/// estado ativo). Sem gradientes, sem roxo, sem azul.
abstract final class UniHubColors {
  static const background = Color(0xFFFFFFFF);
  static const surface = Color(0xFFF7F7F8); // só para separar seções quando necessário
  static const accent = Color(0xFFFF5A1F);
  static const accentPressed = Color(0xFFE64A19);
  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF6B6B6B);
  static const divider = Color(0xFFECECEE);
  static const border = Color(0xFFE2E2E5);
  static const error = Color(0xFFB42318); // uso funcional, apenas em mensagens de erro
  static const success = Color(0xFF1A7F37); // uso funcional, apenas em confirmações
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

/// Raio máximo permitido pelo design system: 8px.
abstract final class UniHubRadius {
  static const double sm = 6;
  static const double md = 8;
  static final BorderRadius brSm = BorderRadius.circular(sm);
  static final BorderRadius brMd = BorderRadius.circular(md);
}

/// Estilos auxiliares que não cabem no ThemeData.
abstract final class UniHubStyles {
  /// Números tabulares para valores financeiros alinhados em tabelas.
  static const tabularNumbers = [FontFeature.tabularFigures()];

  static TextStyle money({double size = 16, FontWeight weight = FontWeight.w600, Color? color}) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight,
        color: color ?? UniHubColors.textPrimary,
        fontFeatures: tabularNumbers,
      );
}

/// Tema único do UniHub — usado pelo app do estudante e pelo painel web.
abstract final class UniHubTheme {
  static ThemeData light() {
    final textTheme = GoogleFonts.interTextTheme().apply(
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
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w700,
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
            GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: UniHubSpacing.x6, vertical: 14),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: UniHubRadius.brMd),
          ),
          elevation: const WidgetStatePropertyAll(0),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: UniHubColors.textPrimary,
          side: const BorderSide(color: UniHubColors.border, width: 1),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(horizontal: UniHubSpacing.x6, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: UniHubRadius.brMd),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: UniHubColors.accent,
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
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
        labelStyle: GoogleFonts.inter(fontSize: 14, color: UniHubColors.textSecondary),
        hintStyle: GoogleFonts.inter(fontSize: 14, color: UniHubColors.textSecondary),
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
          (states) => GoogleFonts.inter(
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
        contentTextStyle: GoogleFonts.inter(fontSize: 14, color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: UniHubRadius.brMd),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: UniHubColors.background,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: UniHubRadius.brMd),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: UniHubColors.textPrimary,
        ),
        contentTextStyle: GoogleFonts.inter(fontSize: 14, color: UniHubColors.textSecondary),
      ),
      dataTableTheme: DataTableThemeData(
        headingTextStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: UniHubColors.textSecondary,
        ),
        dataTextStyle: GoogleFonts.inter(fontSize: 14, color: UniHubColors.textPrimary),
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
