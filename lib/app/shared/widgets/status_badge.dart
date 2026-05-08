// Faixa com o estado da OS (aberta, em execução, feita).
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../modules/service_order/models/ordem_servico.dart';

class StatusBadge extends StatelessWidget {
  final OsStatus status;
  final bool small;

  const StatusBadge({super.key, required this.status, this.small = false});

  @override
  Widget build(BuildContext context) {
    final (bg, fg, line) = switch (status) {
      OsStatus.aberto => (AppColors.neutralBg, AppColors.neutralFg, AppColors.neutralLine),
      OsStatus.execucao => (AppColors.warningBg, AppColors.warningFg, AppColors.warningLine),
      OsStatus.executada => (AppColors.successBg, AppColors.successFg, AppColors.successLine),
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 10,
        vertical: small ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: TextStyle(
              color: fg,
              fontSize: small ? 11 : 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}
