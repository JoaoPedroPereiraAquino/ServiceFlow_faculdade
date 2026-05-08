// Campo de texto com borda, ícone, erro e foco.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';

class CustomTextField extends StatefulWidget {
  final String? label;
  final String? placeholder;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;
  final IconData? icon;
  final Widget? trailing;
  final String? errorText;
  final bool obscure;
  final VoidCallback? onToggleObscure;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLines;
  final bool autofocus;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final bool readOnly;

  const CustomTextField({
    super.key,
    this.label,
    this.placeholder,
    this.controller,
    this.onChanged,
    this.validator,
    this.icon,
    this.trailing,
    this.errorText,
    this.obscure = false,
    this.onToggleObscure,
    this.keyboardType,
    this.inputFormatters,
    this.maxLines = 1,
    this.autofocus = false,
    this.textInputAction,
    this.onSubmitted,
    this.readOnly = false,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  final _focus = FocusNode();
  bool get _focused => _focus.hasFocus;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;
    final borderColor = hasError
        ? AppColors.dangerFg
        : _focused
            ? AppColors.primary
            : AppColors.border;
    final labelColor = hasError
        ? AppColors.dangerFg
        : _focused
            ? AppColors.primary
            : AppColors.textMuted;
    final isMultiline = (widget.maxLines ?? 1) > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null && widget.label!.isNotEmpty) ...[
          Text(
            widget.label!,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: labelColor,
            ),
          ),
          const SizedBox(height: 6),
        ],
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: borderColor, width: 1.5),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: 12,
            vertical: isMultiline ? 10 : 0,
          ),
          constraints: BoxConstraints(
            minHeight: isMultiline ? 96 : 48,
          ),
          child: Row(
            crossAxisAlignment: isMultiline
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Padding(
                  padding: EdgeInsets.only(top: isMultiline ? 4 : 0, right: 10),
                  child: Icon(widget.icon, size: 18, color: labelColor),
                ),
              ],
              Expanded(
                child: TextFormField(
                  controller: widget.controller,
                  focusNode: _focus,
                  onChanged: widget.onChanged,
                  validator: widget.validator,
                  obscureText: widget.obscure,
                  readOnly: widget.readOnly,
                  autofocus: widget.autofocus,
                  keyboardType: widget.keyboardType,
                  inputFormatters: widget.inputFormatters,
                  textInputAction: widget.textInputAction,
                  onFieldSubmitted: widget.onSubmitted,
                  maxLines: widget.obscure ? 1 : widget.maxLines,
                  style: TextStyle(
                    fontSize: 15,
                    color: widget.readOnly ? AppColors.textMuted : AppColors.text,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      vertical: isMultiline ? 0 : 14,
                    ),
                    hintText: widget.placeholder,
                    hintStyle: TextStyle(
                      color: AppColors.textFaint,
                      fontSize: 15,
                    ),
                    errorStyle: TextStyle(height: 0, fontSize: 0),
                  ),
                ),
              ),
              if (widget.onToggleObscure != null)
                IconButton(
                  onPressed: widget.onToggleObscure,
                  icon: Icon(
                    widget.obscure ? Icons.visibility : Icons.visibility_off,
                    size: 18,
                    color: AppColors.textMuted,
                  ),
                  splashRadius: 18,
                ),
              if (widget.trailing != null) widget.trailing!,
            ],
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Text(
            widget.errorText!,
            style: TextStyle(fontSize: 12, color: AppColors.dangerFg),
          ),
        ],
      ],
    );
  }
}
