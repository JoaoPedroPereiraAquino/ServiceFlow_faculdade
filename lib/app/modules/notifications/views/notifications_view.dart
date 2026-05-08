// Lista de alertas; puxar para atualizar; toque marca como lido.
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../core/services/offline_sync_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/app_bar_custom.dart';
import '../models/notificacao.dart';
import '../repositories/notificacao_repository.dart';

class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key});

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  late final NotificacaoRepository _repo = GetIt.I<NotificacaoRepository>();
  late final OfflineSyncService _sync = GetIt.I<OfflineSyncService>();

  List<Notificacao> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await _repo.listar();
    if (!mounted) return;
    setState(() {
      _items = list;
      _loading = false;
    });
  }

  Future<void> _markAll() async {
    await _repo.marcarTodasComoLidas();
    await _load();
  }

  IconData _iconFor(String name) {
    switch (name) {
      case 'check':
        return Icons.check_circle_outline;
      case 'clock':
        return Icons.access_time_rounded;
      case 'users':
        return Icons.people_outline;
      case 'money':
        return Icons.attach_money_rounded;
      case 'pencil':
        return Icons.edit_outlined;
      case 'bell':
      default:
        return Icons.notifications_outlined;
    }
  }

  (Color, Color, Color) _palette(String kind) {
    switch (kind) {
      case 'success':
        return (AppColors.successBg, AppColors.successFg, AppColors.successLine);
      case 'warning':
        return (AppColors.warningBg, AppColors.warningFg, AppColors.warningLine);
      case 'danger':
        return (AppColors.dangerBg, AppColors.dangerFg, AppColors.dangerLine);
      default:
        return (AppColors.tint, AppColors.primary, AppColors.borderSoft);
    }
  }

  @override
  Widget build(BuildContext context) {
    final unread = _items.where((n) => !n.lida).length;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBarCustom(
        title: 'Notificações',
        subtitle: unread > 0 ? '$unread não lidas' : 'Tudo em dia',
        actions: [
          TextButton(
            onPressed: unread > 0 ? _markAll : null,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: Text(
              'Marcar tudo',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _sync.syncAll();
          await _load();
        },
        child: _loading
            ? Center(child: CircularProgressIndicator())
            : _items.isEmpty
                ? ListView(
                    children: [
                      const SizedBox(height: 100),
                      Center(
                        child: Column(
                          children: [
                            Icon(Icons.notifications_off_outlined,
                                size: 36, color: AppColors.textFaint),
                            const SizedBox(height: 10),
                            Text('Nenhuma notificação',
                                style: TextStyle(color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => Divider(
                        height: 1, color: AppColors.borderSoft),
                    itemBuilder: (_, i) {
                      final n = _items[i];
                      final (bg, fg, line) = _palette(n.kind);
                      return InkWell(
                        onTap: () async {
                          await _repo.marcarComoLida(n);
                          await _load();
                        },
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!n.lida)
                                Padding(
                                  padding: const EdgeInsets.only(top: 18, right: 6),
                                  child: Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                )
                              else
                                const SizedBox(width: 12),
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: bg,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: line),
                                ),
                                child: Icon(_iconFor(n.icon), size: 18, color: fg),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.baseline,
                                      textBaseline: TextBaseline.alphabetic,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            n.titulo,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: n.lida
                                                  ? FontWeight.w500
                                                  : FontWeight.w600,
                                              color: AppColors.text,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          n.createdAt != null
                                              ? fmtRelative(n.createdAt!)
                                              : '',
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textFaint),
                                        ),
                                      ],
                                    ),
                                    if ((n.corpo ?? '').isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        n.corpo!,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textMuted,
                                          height: 1.45,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
