import 'package:sqflite/sqflite.dart';

import '../../modules/auth/models/usuario.dart';
import 'database_helper.dart';

/// Cache local do perfil do utilizador (SQLite) — leitura offline e fila de
/// sincronização após edições sem rede.
class PerfilCacheService {
  PerfilCacheService._();
  static final PerfilCacheService instance = PerfilCacheService._();

  static const String table = 'perfil_cache';

  Future<Database> get _db => DatabaseHelper.instance.database;

  /// [markPending] `true` quando o utilizador alterou dados ainda não enviados ao Supabase.
  Future<void> upsert(
    Usuario u, {
    required bool markPending,
    String? avatarLocalPendingPath,
    bool avatarRemovePending = false,
  }) async {
    final db = await _db;
    final now = DateTime.now().toUtc().toIso8601String();
    await db.insert(
      table,
      {
        'user_id': u.localUuid,
        'nome': u.nome,
        'email': u.email,
        'telefone': u.telefone,
        'empresa': u.empresa,
        'cargo': u.cargo,
        'avaliacao': u.avaliacao,
        'avatar_url': u.avatarUrl,
        'profile_pending_sync': markPending ? 1 : 0,
        'avatar_local_pending': avatarLocalPendingPath,
        'avatar_remove_pending': avatarRemovePending ? 1 : 0,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Usuario?> load(String userId) async {
    final db = await _db;
    final rows = await db.query(
      table,
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _rowToUsuario(rows.first);
  }

  Usuario _rowToUsuario(Map<String, dynamic> m) {
    final localPend = m['avatar_local_pending'] as String?;
    return Usuario(
      remoteId: m['user_id'] as String?,
      localUuid: m['user_id'] as String? ?? '',
      nome: (m['nome'] as String?) ?? '',
      email: (m['email'] as String?) ?? '',
      telefone: m['telefone'] as String?,
      empresa: m['empresa'] as String?,
      cargo: m['cargo'] as String?,
      avaliacao: ((m['avaliacao'] as num?) ?? 0).toDouble(),
      avatarUrl: m['avatar_url'] as String?,
      avatarPendentePath: (localPend != null && localPend.isNotEmpty)
          ? localPend
          : null,
    );
  }

  /// Estado para o envio do perfil ao Supabase (foto a remover, ficheiro local, etc.)
  Future<PerfilPendenteSyncState?> loadPendenteEnvio(String userId) async {
    final db = await _db;
    final rows = await db.query(
      table,
      where: 'user_id = ? AND profile_pending_sync = 1',
      whereArgs: [userId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final m = rows.first;
    final u = _rowToUsuario(m);
    return PerfilPendenteSyncState(
      user: u,
      removeAvatar: (m['avatar_remove_pending'] as int? ?? 0) == 1,
    );
  }

  /// Se existe alteração local por sincronizar.
  Future<bool> hasPending(String userId) async {
    final db = await _db;
    final r = await db.query(
      table,
      columns: ['profile_pending_sync'],
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (r.isEmpty) return false;
    return (r.first['profile_pending_sync'] as int? ?? 0) == 1;
  }

  Future<void> deleteAll() async {
    final db = await _db;
    await db.delete(table);
  }
}

/// Dados do perfil marcado como pendente de [AuthRepository.sincronizarPerfilPendente].
class PerfilPendenteSyncState {
  const PerfilPendenteSyncState({
    required this.user,
    required this.removeAvatar,
  });

  final Usuario user;
  final bool removeAvatar;
}
