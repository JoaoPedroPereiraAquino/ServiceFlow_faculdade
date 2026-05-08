// Cores do app; chame atualização ao mudar claro/escuro para recalcular tons.
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static Brightness _b = Brightness.light;

  static void sync(Brightness brightness) {
    _b = brightness;
  }

  static bool get isDark => _b == Brightness.dark;

  // Cor de destaque
  static Color get primary => const Color(0xFF0F766E);
  static Color get primaryDark => const Color(0xFF0B5E58);
  static Color get primaryInk => const Color(0xFF083F3C);
  static Color get onPrimary => const Color(0xFFFFFFFF);

  // Superfícies
  static Color get bg =>
      isDark ? const Color(0xFF0F172A) : const Color(0xFFF4F6FA);
  static Color get surface =>
      isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF);
  static Color get surfaceAlt =>
      isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC);
  static Color get border =>
      isDark ? const Color(0xFF334155) : const Color(0xFFE3E8EF);
  static Color get borderSoft =>
      isDark ? const Color(0xFF475569) : const Color(0xFFEEF2F6);

  // Texto
  static Color get text =>
      isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
  static Color get textMuted =>
      isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
  static Color get textFaint =>
      isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

  static Color get tint =>
      isDark ? const Color(0xFF134E4A) : const Color(0xFFE6F2F1);

  // Estados (sucesso, aviso, erro) ajustados para fundo escuro
  static Color get successBg =>
      isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5);
  static Color get successFg =>
      isDark ? const Color(0xFF6EE7B7) : const Color(0xFF047857);
  static Color get successLine =>
      isDark ? const Color(0xFF047857) : const Color(0xFFA7F3D0);

  static Color get warningBg =>
      isDark ? const Color(0xFF713F12) : const Color(0xFFFEF6E4);
  static Color get warningFg =>
      isDark ? const Color(0xFFFCD34D) : const Color(0xFFB25C0B);
  static Color get warningLine =>
      isDark ? const Color(0xFFC2410C) : const Color(0xFFFCD9A3);

  static Color get dangerBg =>
      isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEF2F2);
  static Color get dangerFg =>
      isDark ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C);
  static Color get dangerLine =>
      isDark ? const Color(0xFFB91C1C) : const Color(0xFFFECACA);

  static Color get neutralBg =>
      isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9);
  static Color get neutralFg =>
      isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569);
  static Color get neutralLine =>
      isDark ? const Color(0xFF64748B) : const Color(0xFFE2E8F0);
}
