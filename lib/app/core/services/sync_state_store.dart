// Guarda quando cada tipo de dado foi atualizado pela última vez (busca só o que é novo).
// Armazenamento seguro por usuário para não misturar contas.
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SyncStateStore {
  SyncStateStore._();
  static final SyncStateStore instance = SyncStateStore._();

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  String _key(String userId, String entity) => 'sf.sync.$userId.$entity';

  Future<DateTime?> lastSyncedAt({
    required String userId,
    required String entity,
  }) async {
    final raw = await _storage.read(key: _key(userId, entity));
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> setLastSyncedAt({
    required String userId,
    required String entity,
    required DateTime value,
  }) {
    return _storage.write(
      key: _key(userId, entity),
      value: value.toUtc().toIso8601String(),
    );
  }

  Future<void> clearAll() {
    return _storage.deleteAll();
  }
}
