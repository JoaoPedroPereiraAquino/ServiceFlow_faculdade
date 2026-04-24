import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/repositories/base_repository.dart';
import '../../../core/services/app_logger.dart';
import '../../../core/services/sync_state_store.dart';
import '../models/cliente.dart';

class ClienteRepository extends BaseRepository<Cliente> {
  @override
  String get table => 'clientes';

  @override
  Cliente fromMap(Map<String, dynamic> map) => Cliente.fromMap(map);

  @override
  Cliente fromJson(Map<String, dynamic> json) => Cliente.fromJson(json);

  /// Cria localmente e tenta sincronizar imediatamente, se houver sessão online.
  Future<Cliente> criar(Cliente c) async {
    final user = Supabase.instance.client.auth.currentUser;
    c.userId = user?.id;
    final id = await insertLocal(c);
    c.localId = id;

    if (user != null) {
      final ok = await _pushOne(c, userId: user.id);
      if (ok) await markSynced(c.localUuid, remoteId: c.remoteId);
    }
    return c;
  }

  /// Pull incremental: traz apenas registros com `updated_at > lastSync`.
  /// Na primeira execução pega tudo. Cursor por usuário.
  Future<void> pullDoServidor() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final cursor = await SyncStateStore.instance.lastSyncedAt(
        userId: user.id,
        entity: 'clientes',
      );

      var query = Supabase.instance.client
          .from('clientes')
          .select()
          .eq('user_id', user.id);
      if (cursor != null) {
        query = query.gt('updated_at', cursor.toUtc().toIso8601String());
      }
      final rows = await query.order('updated_at', ascending: true).limit(500);

      DateTime? maxUpdated = cursor;
      for (final row in rows) {
        final c = Cliente.fromJson(row);
        c.userId = user.id;

        final exists = await getByLocalUuid(c.localUuid);
        if (exists == null) {
          await insertLocal(c);
        } else {
          c.localId = exists.localId;
          await updateLocal(c);
        }

        final updatedAt =
            DateTime.tryParse(row['updated_at']?.toString() ?? '');
        if (updatedAt != null &&
            (maxUpdated == null || updatedAt.isAfter(maxUpdated))) {
          maxUpdated = updatedAt;
        }
      }

      if (maxUpdated != null) {
        await SyncStateStore.instance.setLastSyncedAt(
          userId: user.id,
          entity: 'clientes',
          value: maxUpdated,
        );
      }
    } catch (e, st) {
      AppLogger.e('cliente.pull', e, st);
      rethrow;
    }
  }

  Future<List<Cliente>> listarTodos() {
    return getAllLocal(orderBy: 'nome COLLATE NOCASE ASC');
  }

  /// Sincroniza pendentes (chamado pelo OfflineSyncService).
  Future<int> syncPendentes() async {
    final pending = await getPending();
    if (pending.isEmpty) return 0;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return 0;

    int ok = 0;
    for (final c in pending) {
      final pushed = await _pushOne(c, userId: user.id);
      if (pushed) {
        await markSynced(c.localUuid, remoteId: c.remoteId);
        ok++;
      }
    }
    return ok;
  }

  Future<bool> _pushOne(Cliente c, {required String userId}) async {
    try {
      final inserted = await Supabase.instance.client
          .from('clientes')
          .upsert({
            'user_id': userId,
            'nome': c.nome,
            'doc': c.doc,
            'email': c.email,
            'telefone': c.telefone,
            'local_id': c.localUuid,
          }, onConflict: 'user_id,local_id')
          .select()
          .single();
      c.remoteId = inserted['id'] as String?;
      return true;
    } catch (e, st) {
      AppLogger.e('cliente.push', e, st);
      return false;
    }
  }
}
