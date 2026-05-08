// Barra inferior: abas + Nova OS; bolinha nos alertas não lidos.
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../core/theme/app_colors.dart';
import '../../modules/notifications/repositories/notificacao_repository.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onChanged;
  final VoidCallback onNewOS;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onChanged,
    required this.onNewOS,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.borderSoft, width: 1),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 8),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            _Item(
              icon: Icons.home_outlined,
              activeIcon: Icons.home_rounded,
              label: 'Início',
              active: currentIndex == 0,
              onTap: () => onChanged(0),
            ),
            _Item(
              icon: Icons.work_outline_rounded,
              activeIcon: Icons.work_rounded,
              label: 'Ordens',
              active: currentIndex == 1,
              onTap: () => onChanged(1),
            ),
            _PrimaryItem(onTap: onNewOS),
            ValueListenableBuilder<int>(
              valueListenable: GetIt.I<NotificacaoRepository>().unreadCount,
              builder: (_, unread, __) => _Item(
                icon: Icons.notifications_outlined,
                activeIcon: Icons.notifications_rounded,
                label: 'Alertas',
                active: currentIndex == 2,
                badge: unread,
                onTap: () => onChanged(2),
              ),
            ),
            _Item(
              icon: Icons.person_outline_rounded,
              activeIcon: Icons.person_rounded,
              label: 'Perfil',
              active: currentIndex == 3,
              onTap: () => onChanged(3),
            ),
          ],
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool active;
  final int badge;
  final VoidCallback onTap;

  const _Item({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.active,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primary : AppColors.textMuted;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 6, 4, 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  if (active)
                    Positioned(
                      top: -8,
                      child: Container(
                        width: 24,
                        height: 3,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  Icon(active ? activeIcon : icon, size: 22, color: color),
                  if (badge > 0)
                    Positioned(
                      top: -4,
                      right: -8,
                      child: AnimatedScale(
                        scale: 1,
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.elasticOut,
                        child: Container(
                          constraints: const BoxConstraints(minWidth: 16),
                          height: 16,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: AppColors.dangerFg,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: AppColors.surface,
                              width: 1.5,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            badge > 99 ? '99+' : '$badge',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimaryItem extends StatelessWidget {
  final VoidCallback onTap;
  const _PrimaryItem({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.45),
                      offset: Offset(0, 6),
                      blurRadius: 14,
                    ),
                  ],
                ),
                child: Icon(Icons.add_rounded, size: 22, color: Colors.white),
              ),
              const SizedBox(height: 3),
              Text(
                'Nova OS',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
