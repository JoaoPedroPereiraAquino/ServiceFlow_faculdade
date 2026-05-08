// Barra no topo: título, subtítulo e voltar.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';

class AppBarCustom extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final List<Widget> actions;

  const AppBarCustom({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.actions = const [],
  });

  @override
  Size get preferredSize {
    final h = subtitle == null ? kToolbarHeight : 70.0;
    return Size.fromHeight(h);
  }

  /// Mesma margem horizontal do corpo (~20 px) quando não há voltar.
  static const double _titleInsetNoLeading = 20;

  @override
  Widget build(BuildContext context) {
    final canPop = onBack != null || Navigator.of(context).canPop();
    final withSub = subtitle != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      shape: Border(
        bottom: BorderSide(color: AppColors.borderSoft, width: 1),
      ),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
      leading: canPop
          ? IconButton(
              padding: const EdgeInsets.only(left: 8),
              icon: Icon(Icons.arrow_back_ios_new, size: 18),
              color: AppColors.text,
              onPressed: onBack ?? () => Navigator.of(context).maybePop(),
            )
          : null,
      // Com voltar: só o espaço após o ícone; sem voltar: 20 px como a lista.
      titleSpacing: canPop ? 8 : 0,
      title: Padding(
        padding: EdgeInsetsDirectional.only(
          start: canPop ? 0 : _titleInsetNoLeading,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
                letterSpacing: -0.2,
              ),
            ),
            if (withSub) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        for (int i = 0; i < actions.length; i++) actions[i],
        const SizedBox(width: 6),
      ],
      toolbarHeight: withSub ? 70.0 : kToolbarHeight,
    );
  }
}
