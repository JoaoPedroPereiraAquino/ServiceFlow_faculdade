// Aviso rápido na tela (barra embaixo) para o usuário saber o que aconteceu.

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum FeedbackKind { success, error, info, warning }

mixin UiFeedbackMixin<T extends StatefulWidget> on State<T> {
  void showFeedback(String message, {FeedbackKind kind = FeedbackKind.info}) {
    if (!mounted) return;

    final palette = _palette(kind);
    final messenger = ScaffoldMessenger.of(context);

    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          backgroundColor: palette.bg,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 3),
          content: Row(
            children: [
              Icon(palette.icon, color: palette.fg, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: palette.fg,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  _Palette _palette(FeedbackKind kind) {
    switch (kind) {
      case FeedbackKind.success:
        return _Palette(AppColors.successFg, Colors.white, Icons.check_circle_outline);
      case FeedbackKind.error:
        return _Palette(AppColors.dangerFg, Colors.white, Icons.error_outline);
      case FeedbackKind.warning:
        return _Palette(AppColors.warningFg, Colors.white, Icons.warning_amber_rounded);
      case FeedbackKind.info:
        return _Palette(AppColors.text, Colors.white, Icons.info_outline);
    }
  }
}

class _Palette {
  final Color bg;
  final Color fg;
  final IconData icon;
  _Palette(this.bg, this.fg, this.icon);
}
