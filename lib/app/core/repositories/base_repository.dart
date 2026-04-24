import 'package:dio/dio.dart';
import 'package:sqflite/sqflite.dart';

import '../models/base_model.dart';
import '../services/database_helper.dart';
import '../services/dio_client.dart';

/// Repositório genérico — toda concretização DEVE estendê-lo.
///
/// Centraliza:
/// - acesso ao SQLite (via `DatabaseHelper`)
/// - acesso à API REST do Supabase (via `DioClient`)
abstract class BaseRepository<T extends BaseModel> {
  final Dio dio = DioClient.instance.dio;
  final DatabaseHelper helper = DatabaseHelper.instance;

  Future<Database> get db => helper.database;

  /// Nome da tabela local correspondente.
  String get table;

  /// Endpoint REST do Supabase (ex.: `clientes`, `ordens_servico`).
  String get endpoint => table;

  /// Reconstrói uma entidade a partir de uma linha do SQLite.
  T fromMap(Map<String, dynamic> map);

  /// Reconstrói uma entidade a partir do JSON da API.
  T fromJson(Map<String, dynamic> json);

  // ---------- CRUD local ----------

  Future<int> insertLocal(T item) async {
    final database = await db;
    return database.insert(
      table,
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateLocal(T item) async {
    final database = await db;
    return database.update(
      table,
      item.toMap(),
      where: 'local_uuid = ?',
      whereArgs: [item.localUuid],
    );
  }

  Future<int> deleteLocal(String localUuid) async {
    final database = await db;
    return database.delete(
      table,
      where: 'local_uuid = ?',
      whereArgs: [localUuid],
    );
  }

  Future<List<T>> getAllLocal({String? orderBy, String? where, List<Object?>? whereArgs}) async {
    final database = await db;
    final rows = await database.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy ?? 'created_at DESC',
    );
    return rows.map(fromMap).toList();
  }

  Future<T?> getByLocalUuid(String localUuid) async {
    final database = await db;
    final rows = await database.query(
      table,
      where: 'local_uuid = ?',
      whereArgs: [localUuid],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return fromMap(rows.first);
  }

  Future<List<T>> getPending() {
    return getAllLocal(where: "status = ?", whereArgs: ['P']);
  }

  /// Marca como sincronizado (e armazena o id remoto se vier do servidor).
  Future<void> markSynced(String localUuid, {String? remoteId}) async {
    final database = await db;
    await database.update(
      table,
      {
        'status': 'S',
        if (remoteId != null) 'remote_id': remoteId,
      },
      where: 'local_uuid = ?',
      whereArgs: [localUuid],
    );
  }
}
