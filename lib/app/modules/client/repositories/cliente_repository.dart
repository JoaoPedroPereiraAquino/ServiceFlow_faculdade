// Clientes: banco local e servidor (mesma lista para o usuário).
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

  /// Salva no banco local e envia ao servidor se estiver logado e com internet.
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

  /// Baixa do servidor só o que mudou desde a última vez; na primeira, baixa tudo.
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

  /// Envia ao servidor os registros que ainda estavam só no aparelho.
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

  /// Quantas OS usam este cliente (id local).
  Future<int> contarOrdensVinculadas(String clienteLocalUuid) async {
    final database = await db;
    final r = await database.rawQuery(
      'SELECT COUNT(*) as c FROM ordens_servico WHERE cliente_local_uuid = ?',
      [clienteLocalUuid],
    );
    if (r.isEmpty) return 0;
    return (r.first['c'] as int?) ?? 0;
  }

  /// Atualiza no banco local e tenta enviar ao servidor.
  Future<Cliente> atualizar(Cliente c) async {
    final user = Supabase.instance.client.auth.currentUser;
    c.userId = user?.id;
    c.status = 'P';
    await updateLocal(c);
    if (user != null) {
      final ok = await _pushOne(c, userId: user.id);
      if (ok) await markSynced(c.localUuid, remoteId: c.remoteId);
    }
    return c;
  }

  /// Apaga no aparelho e no servidor se não houver OS ligada a este cliente.
  Future<void> excluir(Cliente c) async {
    final n = await contarOrdensVinculadas(c.localUuid);
    if (n > 0) {
      throw Exception(
        'Existem $n ordem(ns) de serviço vinculada(s) a este cliente. '
        'Exclua ou reatribua as OS antes de remover o cadastro.',
      );
    }
    final user = Supabase.instance.client.auth.currentUser;
    if (c.remoteId != null && c.remoteId!.isNotEmpty && user != null) {
      try {
        await Supabase.instance.client
            .from('clientes')
            .delete()
            .eq('id', c.remoteId!);
      } catch (e, st) {
        AppLogger.e('cliente.delete', e, st);
        rethrow;
      }
    }
    await deleteLocal(c.localUuid);
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
