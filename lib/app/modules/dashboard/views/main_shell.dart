import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../core/services/connectivity_service.dart';
import '../../../core/services/theme_controller.dart';
import '../../../core/services/offline_sync_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/bottom_nav.dart';
import '../../notifications/repositories/notificacao_repository.dart';
import '../../notifications/views/notifications_view.dart';
import '../../profile/views/profile_view.dart';
import '../../service_order/views/os_form_view.dart';
import '../../service_order/views/os_list_view.dart';
import 'dashboard_view.dart';

/// Casca principal — abriga as 4 abas do bottom-nav e o botão "Nova OS".
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  /// Incrementa após criar OS para o [OsListView] remontar e chamar [_load] de novo.
  int _osListKey = 0;

  late final OfflineSyncService _sync = GetIt.I<OfflineSyncService>();
  late final ConnectivityService _connectivity = GetIt.I<ConnectivityService>();
  late final NotificacaoRepository _notifRepo = GetIt.I<NotificacaoRepository>();

  @override
  void initState() {
    super.initState();
    // Popula o badge a partir do SQLite (funciona offline).
    _notifRepo.refreshUnreadCount();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sync.syncAll();
    });
  }

  void _openNewOS() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const OsFormView()),
    );
    if (created == true && mounted) {
      setState(() => _osListKey++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardView(
        onOpenList: (filter) {
          setState(() => _index = 1);
        },
        onNewOS: _openNewOS,
        onOpenProfile: () => setState(() => _index = 3),
      ),
      OsListView(key: ValueKey(_osListKey)),
      const NotificationsView(),
      const ProfileView(),
    ];

    // [AppColors] é estático (sincronizado no root) e o shell pode não receber
    // rebuild com `const` / mesma rota. Escutar [ThemeController] garante que
    // bottom bar e [Scaffold] acompanhem claro/escuro de imediato.
    return ListenableBuilder(
      listenable: GetIt.I<ThemeController>(),
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.bg,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _OfflineBanner(connectivity: _connectivity, sync: _sync),
                Expanded(
                  child: KeyedSubtree(
                    key: ValueKey(_index),
                    child: pages[_index],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: AppBottomNav(
            currentIndex: _index,
            onChanged: (i) => setState(() => _index = i),
            onNewOS: _openNewOS,
          ),
        );
      },
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  final ConnectivityService connectivity;
  final OfflineSyncService sync;
  const _OfflineBanner({required this.connectivity, required this.sync});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: connectivity.isOnline,
      builder: (_, online, __) {
        return ValueListenableBuilder<bool>(
          valueListenable: sync.syncing,
          builder: (_, syncing, __) {
            final show = !online || (online && syncing);
            final bg = online ? AppColors.tint : AppColors.warningBg;
            final fg = online ? AppColors.primary : AppColors.warningFg;
            final icon = online ? Icons.sync : Icons.cloud_off_outlined;
            final txt = online
                ? 'Sincronizando dados…'
                : 'Sem conexão · suas alterações ficam salvas localmente';

            // Altura animada evita o “salto” da coluna ao iniciar/terminar sync.
            return AnimatedSize(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: show
                  ? Container(
                      width: double.infinity,
                      color: bg,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      child: Row(
                        children: [
                          Icon(icon, size: 14, color: fg),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              txt,
                              style: TextStyle(
                                fontSize: 12,
                                color: fg,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            );
          },
        );
      },
    );
  }
}
