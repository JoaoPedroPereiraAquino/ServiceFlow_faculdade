// Lê alertas do aparelho e busca novos no servidor; contagem para o badge da barra.
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/repositories/base_repository.dart';
import '../../../core/services/app_logger.dart';
import '../../../core/services/sync_state_store.dart';
import '../models/notificacao.dart';

class NotificacaoRepository extends BaseRepository<Notificacao> {
  /// Quantas notificações não lidas. A barra inferior usa isso no badge.
  final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);

  @override
  String get table => 'notificacoes';

  @override
  Notificacao fromMap(Map<String, dynamic> m) => Notificacao.fromMap(m);

  @override
  Notificacao fromJson(Map<String, dynamic> j) => Notificacao.fromJson(j);

  Future<List<Notificacao>> listar() async {
    final list = await getAllLocal(orderBy: 'created_at DESC');
    await refreshUnreadCount();
    return list;
  }

  Future<int> naoLidas() async {
    final database = await db;
    final r = await database.rawQuery(
      "SELECT COUNT(*) as n FROM notificacoes WHERE lida = 0",
    );
    return (r.first['n'] as int?) ?? 0;
  }

  /// Atualiza o número de não lidas (após marcar ou receber lista).
  Future<void> refreshUnreadCount() async {
    final n = await naoLidas();
    if (unreadCount.value != n) unreadCount.value = n;
  }

  /// Busca no servidor só itens novos ou alterados desde a última vez.
  Future<void> pullDoServidor() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final cursor = await SyncStateStore.instance.lastSyncedAt(
        userId: user.id,
        entity: 'notificacoes',
      );

      var query = Supabase.instance.client
          .from('notificacoes')
          .select()
          .eq('user_id', user.id);
      if (cursor != null) {
        query = query.gt('updated_at', cursor.toUtc().toIso8601String());
      }
      final rows = await query.order('updated_at', ascending: true).limit(200);

      DateTime? maxUpdated = cursor;
      for (final row in rows) {
        final n = Notificacao.fromJson(row);
        n.userId = user.id;
        final exists = await getByLocalUuid(n.localUuid);
        if (exists == null) {
          await insertLocal(n);
        } else {
          n.localId = exists.localId;
          await updateLocal(n);
        }

        final updatedAt = DateTime.tryParse(
            (row['updated_at'] ?? row['created_at'])?.toString() ?? '');
        if (updatedAt != null &&
            (maxUpdated == null || updatedAt.isAfter(maxUpdated))) {
          maxUpdated = updatedAt;
        }
      }

      if (maxUpdated != null) {
        await SyncStateStore.instance.setLastSyncedAt(
          userId: user.id,
          entity: 'notificacoes',
          value: maxUpdated,
        );
      }
      await refreshUnreadCount();
    } catch (e, st) {
      AppLogger.e('notif.pull', e, st);
      rethrow;
    }
  }

  Future<void> marcarTodasComoLidas() async {
    final database = await db;
    await database.update(
      'notificacoes',
      {'lida': 1},
      where: 'lida = 0',
    );

    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        // Só linhas não lidas: não mexe nas já lidas nem repete tudo na próxima busca.
        await Supabase.instance.client
            .from('notificacoes')
            .update({'lida': true})
            .eq('user_id', user.id)
            .eq('lida', false);
      } catch (e, st) {
        AppLogger.w('notif.mark_all', '$e\n$st');
      }
    }
    await refreshUnreadCount();
  }

  Future<void> marcarComoLida(Notificacao n) async {
    n.lida = true;
    await updateLocal(n);
    if (n.remoteId != null) {
      try {
        await Supabase.instance.client
            .from('notificacoes')
            .update({'lida': true})
            .eq('id', n.remoteId!);
      } catch (e, st) {
        AppLogger.w('notif.mark_one', '$e\n$st');
      }
    }
    await refreshUnreadCount();
  }
}
