// Camada que lê e grava: banco local + formato de dados do servidor.
import 'package:dio/dio.dart';
import 'package:sqflite/sqflite.dart';

import '../models/base_model.dart';
import '../services/database_helper.dart';
import '../services/dio_client.dart';

abstract class BaseRepository<T extends BaseModel> {
  final Dio dio = DioClient.instance.dio;
  final DatabaseHelper helper = DatabaseHelper.instance;

  Future<Database> get db => helper.database;

  /// Nome da tabela no banco local.
  String get table;

  /// Parte do caminho no servidor (ex.: clientes, ordens_servico).
  String get endpoint => table;

  /// Monta o registro a partir de uma linha do banco local.
  T fromMap(Map<String, dynamic> map);

  /// Monta o registro a partir dos dados que vêm do servidor.
  T fromJson(Map<String, dynamic> json);

  // --- gravar, atualizar e apagar no aparelho ---

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

  /// Marca como já enviado e guarda o código do servidor, se tiver.
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
