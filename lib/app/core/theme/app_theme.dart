// Aparência Material 3 com fonte Inter, nos modos claro e escuro.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  static const _lOnSurface = Color(0xFF0F172A);
  static const _dOnSurface = Color(0xFFF1F5F9);
  static const _dSurface = Color(0xFF1E293B);
  static const _dBg = Color(0xFF0F172A);
  static const _dBorder = Color(0xFF334155);

  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    final textTheme = GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: _lOnSurface,
      displayColor: _lOnSurface,
    );

    return base.copyWith(
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF0F766E),
        onPrimary: Color(0xFFFFFFFF),
        secondary: Color(0xFF0B5E58),
        onSecondary: Colors.white,
        surface: Color(0xFFFFFFFF),
        onSurface: _lOnSurface,
        error: Color(0xFFB91C1C),
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: const Color(0xFFF4F6FA),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFFFFFFFF),
        foregroundColor: _lOnSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: _lOnSurface,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFFFFFFFF),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFFEEF2F6), width: 1),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    final textTheme = GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: _dOnSurface,
      displayColor: _dOnSurface,
    );

    return base.copyWith(
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF2DD4BF),
        onPrimary: Color(0xFF042F2E),
        secondary: Color(0xFF0F766E),
        onSecondary: Colors.white,
        surface: _dSurface,
        onSurface: _dOnSurface,
        error: Color(0xFFF87171),
        onError: Color(0xFF450A0A),
      ),
      scaffoldBackgroundColor: _dBg,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: _dSurface,
        foregroundColor: _dOnSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: _dOnSurface,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: _dSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: _dBorder, width: 1),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static TextStyle mono(
      {double size = 11, FontWeight weight = FontWeight.w600, Color? color}) {
    return GoogleFonts.jetBrainsMono(
      fontSize: size,
      fontWeight: weight,
      color: color ?? const Color(0xFF64748B),
      letterSpacing: 0.4,
    );
  }
}
