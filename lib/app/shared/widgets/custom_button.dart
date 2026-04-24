import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

enum CustomButtonVariant { primary, secondary, ghost, danger }

enum CustomButtonSize { sm, md, lg }

class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final CustomButtonVariant variant;
  final CustomButtonSize size;
  final IconData? icon;
  final bool loading;
  final bool fullWidth;

  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = CustomButtonVariant.primary,
    this.size = CustomButtonSize.md,
    this.icon,
    this.loading = false,
    this.fullWidth = true,
  });

  double get _height => switch (size) {
        CustomButtonSize.sm => 40,
        CustomButtonSize.md => 48,
        CustomButtonSize.lg => 52,
      };

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || loading;

    final (bg, fg, border) = switch (variant) {
      CustomButtonVariant.primary => (
          AppColors.primary,
          AppColors.onPrimary,
          AppColors.primary,
        ),
      CustomButtonVariant.secondary => (
          AppColors.surface,
          AppColors.text,
          AppColors.border,
        ),
      CustomButtonVariant.ghost => (
          Colors.transparent,
          AppColors.primary,
          Colors.transparent,
        ),
      CustomButtonVariant.danger => (
          AppColors.dangerFg,
          Colors.white,
          AppColors.dangerFg,
        ),
    };

    final child = loading
        ? SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                variant == CustomButtonVariant.secondary
                    ? AppColors.primary
                    : Colors.white,
              ),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: fg),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(
                  color: fg,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          );

    final btn = Material(
      color: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: border, width: 1.5),
      ),
      child: InkWell(
        onTap: disabled ? null : onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Opacity(
          opacity: disabled ? 0.5 : 1,
          child: SizedBox(
            height: _height,
            child: Center(child: child),
          ),
        ),
      ),
    );

    return fullWidth ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}
