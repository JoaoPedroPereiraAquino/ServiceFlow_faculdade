import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/repositories/base_repository.dart';
import '../../../core/services/app_logger.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/sync_state_store.dart';
import '../models/ordem_servico.dart';

class OrdemServicoRepository extends BaseRepository<OrdemServico> {
  final StorageService _storage = StorageService.instance;

  @override
  String get table => 'ordens_servico';

  @override
  OrdemServico fromMap(Map<String, dynamic> map) => OrdemServico.fromMap(map);

  @override
  OrdemServico fromJson(Map<String, dynamic> json) => OrdemServico.fromJson(json);

  /// Gera o próximo código sequencial OS-XXXXX (baseado no maior local).
  Future<String> proximoCodigo() async {
    final database = await db;
    final r = await database.rawQuery(
      "SELECT codigo FROM ordens_servico ORDER BY id DESC LIMIT 1",
    );
    int next = 412;
    if (r.isNotEmpty) {
      final last = (r.first['codigo'] as String?) ?? 'OS-00411';
      final m = RegExp(r'OS-(\d+)').firstMatch(last);
      if (m != null) {
        next = int.parse(m.group(1)!) + 1;
      }
    }
    return 'OS-${next.toString().padLeft(5, '0')}';
  }

  /// Cria a OS localmente e tenta sincronizar imediatamente.
  ///
  /// Fluxo offline-first:
  ///  1. INSERT no SQLite (com paths locais das fotos) — status `P`.
  ///  2. Se houver sessão e internet, tenta upload das fotos para o Storage,
  ///     resolve `cliente_remote_id` (se o cliente já estiver sincronizado),
  ///     INSERT no Supabase e marca como `S`.
  ///  3. Em caso de falha em qualquer ponto da etapa 2, a OS continua `P` e
  ///     o `OfflineSyncService` cuidará do reenvio.
  Future<OrdemServico> criar(OrdemServico os) async {
    final user = Supabase.instance.client.auth.currentUser;
    os.userId = user?.id;
    final id = await insertLocal(os);
    os.localId = id;

    if (user != null) {
      final pushed = await _pushOne(os, userId: user.id);
      if (pushed) {
        await markSynced(os.localUuid, remoteId: os.remoteId);
      }
    }
    return os;
  }

  Future<List<OrdemServico>> listarTodas() {
    return getAllLocal(orderBy: 'created_at DESC');
  }

  /// Pull incremental: traz apenas registros com `updated_at > lastSync`.
  Future<void> pullDoServidor() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final cursor = await SyncStateStore.instance.lastSyncedAt(
        userId: user.id,
        entity: 'ordens_servico',
      );

      var query = Supabase.instance.client
          .from('ordens_servico')
          .select()
          .eq('user_id', user.id);
      if (cursor != null) {
        query = query.gt('updated_at', cursor.toUtc().toIso8601String());
      }
      final rows = await query.order('updated_at', ascending: true).limit(500);

      DateTime? maxUpdated = cursor;
      for (final row in rows) {
        final os = OrdemServico.fromJson(row);
        os.userId = user.id;
        final exists = await getByLocalUuid(os.localUuid);
        if (exists == null) {
          await insertLocal(os);
        } else {
          os.localId = exists.localId;
          os.fotoAntesPath = exists.fotoAntesPath;
          os.fotoDepoisPath = exists.fotoDepoisPath;
          await updateLocal(os);
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
          entity: 'ordens_servico',
          value: maxUpdated,
        );
      }
    } catch (e, st) {
      AppLogger.e('os.pull', e, st);
      rethrow;
    }
  }

  /// Sincroniza pendentes — chamado pelo `OfflineSyncService`.
  /// Para cada OS pendente: faz upload de fotos novas, resolve cliente
  /// remoto (caso a OS tenha ficado órfã) e envia o registro.
  Future<int> syncPendentes() async {
    final pending = await getPending();
    if (pending.isEmpty) return 0;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return 0;

    int ok = 0;
    for (final os in pending) {
      final pushed = await _pushOne(os, userId: user.id);
      if (pushed) {
        await markSynced(os.localUuid, remoteId: os.remoteId);
        ok++;
      }
    }
    return ok;
  }

  // ---------------------------------------------------------------------------
  // Internos
  // ---------------------------------------------------------------------------

  /// Tenta enviar UMA OS para o Supabase. Retorna `true` em sucesso.
  Future<bool> _pushOne(OrdemServico os, {required String userId}) async {
    try {
      // 1) Resolve cliente_remote_id se ainda estiver vazio mas houver UUID local.
      if ((os.clienteRemoteId == null || os.clienteRemoteId!.isEmpty) &&
          os.clienteLocalUuid != null) {
        final database = await db;
        final r = await database.query(
          'clientes',
          columns: ['remote_id'],
          where: 'local_uuid = ?',
          whereArgs: [os.clienteLocalUuid],
          limit: 1,
        );
        if (r.isNotEmpty) {
          os.clienteRemoteId = r.first['remote_id'] as String?;
        }
      }

      // 2) Upload de fotos pendentes.
      if (os.fotoAntesPath != null &&
          os.fotoAntesPath!.isNotEmpty &&
          (os.fotoAntesRemotePath == null ||
              os.fotoAntesRemotePath!.isEmpty)) {
        final remote = await _storage.uploadOsPhoto(
          localUuidOs: os.localUuid,
          localFilePath: os.fotoAntesPath!,
          prefix: 'antes',
        );
        if (remote != null) {
          os.fotoAntesRemotePath = remote;
          await updateLocal(os);
        }
      }
      if (os.fotoDepoisPath != null &&
          os.fotoDepoisPath!.isNotEmpty &&
          (os.fotoDepoisRemotePath == null ||
              os.fotoDepoisRemotePath!.isEmpty)) {
        final remote = await _storage.uploadOsPhoto(
          localUuidOs: os.localUuid,
          localFilePath: os.fotoDepoisPath!,
          prefix: 'depois',
        );
        if (remote != null) {
          os.fotoDepoisRemotePath = remote;
          await updateLocal(os);
        }
      }

      // 3) Push do registro: se já existe (`remote_id`), faz UPDATE;
      //    caso contrário, INSERT por `local_id` (evita duplicação se o
      //    backend tiver constraint em `local_id`, ou se a OS já chegou
      //    pelo pull do servidor).
      final payload = {
        'user_id': userId,
        'codigo': os.codigo,
        'cliente_id': os.clienteRemoteId,
        'cliente_nome': os.clienteNome,
        'descricao': os.descricao,
        'valor': os.valor,
        'status': os.osStatus.raw,
        'foto_antes_path': os.fotoAntesRemotePath,
        'foto_depois_path': os.fotoDepoisRemotePath,
        'foto_antes_remote_path': os.fotoAntesRemotePath,
        'foto_depois_remote_path': os.fotoDepoisRemotePath,
        'assinatura_base64': os.assinaturaBase64,
        'tecnico': os.tecnico,
        'local_id': os.localUuid,
      };

      final inserted = await Supabase.instance.client
          .from('ordens_servico')
          .upsert(payload, onConflict: 'user_id,local_id')
          .select()
          .single();
      os.remoteId = inserted['id'] as String?;
      return true;
    } catch (e, st) {
      AppLogger.e('os.push', e, st);
      return false;
    }
  }
}
