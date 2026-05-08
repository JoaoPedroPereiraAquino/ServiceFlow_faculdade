// Cria o arquivo do banco no aparelho, a versão das tabelas e as migrações.
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Abre o banco local, cria ou atualiza tabelas e deixa o app usar os dados.
/// Inclui clientes, ordens, avisos, cópia do perfil e fila de envio pendente.
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static const _dbName = 'serviceflow.db';
  static const _dbVersion = 3;

  Database? _db;

  Future<Database> get database async {
    if (_db != null && _db!.isOpen) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    final path = p.join(dir, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON;');
      },
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int from, int to) async {
    if (from < 2) {
      await db.execute(
        "ALTER TABLE ordens_servico ADD COLUMN foto_antes_remote_path TEXT",
      );
      await db.execute(
        "ALTER TABLE ordens_servico ADD COLUMN foto_depois_remote_path TEXT",
      );
    }
    if (from < 3) {
      await _createPerfilCache(db);
    }
  }

  static Future<void> _createPerfilCache(Database db) {
    return db.execute('''
      CREATE TABLE IF NOT EXISTS perfil_cache (
        user_id TEXT PRIMARY KEY NOT NULL,
        nome TEXT NOT NULL,
        email TEXT NOT NULL,
        telefone TEXT,
        empresa TEXT,
        cargo TEXT,
        avaliacao REAL NOT NULL DEFAULT 0,
        avatar_url TEXT,
        profile_pending_sync INTEGER NOT NULL DEFAULT 0,
        avatar_local_pending TEXT,
        avatar_remove_pending INTEGER NOT NULL DEFAULT 0,
        updated_at TEXT NOT NULL
      );
    ''');
  }

  Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();

    batch.execute('''
      CREATE TABLE clientes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        local_uuid TEXT UNIQUE NOT NULL,
        remote_id TEXT,
        user_id TEXT,
        nome TEXT NOT NULL,
        doc TEXT,
        email TEXT,
        telefone TEXT,
        status TEXT NOT NULL DEFAULT 'P',
        created_at TEXT NOT NULL
      );
    ''');
    batch.execute('CREATE INDEX idx_clientes_status ON clientes(status);');

    batch.execute('''
      CREATE TABLE servicos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        local_uuid TEXT UNIQUE NOT NULL,
        remote_id TEXT,
        user_id TEXT,
        nome TEXT NOT NULL,
        tempo_estimado_min INTEGER DEFAULT 60,
        valor_padrao REAL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'P',
        created_at TEXT NOT NULL
      );
    ''');

    batch.execute('''
      CREATE TABLE ordens_servico (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        local_uuid TEXT UNIQUE NOT NULL,
        remote_id TEXT,
        user_id TEXT,
        codigo TEXT NOT NULL,
        cliente_local_uuid TEXT,
        cliente_remote_id TEXT,
        cliente_nome TEXT,
        descricao TEXT NOT NULL,
        valor REAL NOT NULL DEFAULT 0,
        os_status TEXT NOT NULL DEFAULT 'aberto',
        foto_antes_path TEXT,
        foto_depois_path TEXT,
        foto_antes_remote_path TEXT,
        foto_depois_remote_path TEXT,
        assinatura_base64 TEXT,
        tecnico TEXT,
        status TEXT NOT NULL DEFAULT 'P',
        created_at TEXT NOT NULL
      );
    ''');
    batch.execute('CREATE INDEX idx_os_status ON ordens_servico(os_status);');
    batch.execute('CREATE INDEX idx_os_sync ON ordens_servico(status);');

    batch.execute('''
      CREATE TABLE perfil_cache (
        user_id TEXT PRIMARY KEY NOT NULL,
        nome TEXT NOT NULL,
        email TEXT NOT NULL,
        telefone TEXT,
        empresa TEXT,
        cargo TEXT,
        avaliacao REAL NOT NULL DEFAULT 0,
        avatar_url TEXT,
        profile_pending_sync INTEGER NOT NULL DEFAULT 0,
        avatar_local_pending TEXT,
        avatar_remove_pending INTEGER NOT NULL DEFAULT 0,
        updated_at TEXT NOT NULL
      );
    ''');

    batch.execute('''
      CREATE TABLE notificacoes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        local_uuid TEXT UNIQUE NOT NULL,
        remote_id TEXT,
        user_id TEXT,
        kind TEXT NOT NULL DEFAULT 'info',
        icon TEXT DEFAULT 'bell',
        titulo TEXT NOT NULL,
        corpo TEXT,
        lida INTEGER DEFAULT 0,
        created_at TEXT NOT NULL
      );
    ''');

    batch.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entity TEXT NOT NULL,
        local_uuid TEXT NOT NULL,
        op TEXT NOT NULL,
        attempts INTEGER DEFAULT 0,
        last_error TEXT,
        created_at TEXT NOT NULL
      );
    ''');

    await batch.commit(noResult: true);
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

/// Apaga os dados locais (ao sair ou trocar de conta).
  Future<void> wipe() async {
    final db = await database;
    final batch = db.batch();
    for (final t in [
      'sync_queue',
      'notificacoes',
      'ordens_servico',
      'servicos',
      'clientes',
      'perfil_cache',
    ]) {
      batch.delete(t);
    }
    await batch.commit(noResult: true);
  }
}
