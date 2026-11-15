import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class AppDatabase {
  AppDatabase._({this.customPath});

  static final AppDatabase instance = AppDatabase._();

  /// Construtor para testes isolados (permite testar migrações de versão em arquivo temporário).
  factory AppDatabase.forTesting(String dbPath) =>
      AppDatabase._(customPath: dbPath);

  static const int currentSchemaVersion = 2;
  static const String _dbFileName = 'meu_caderno.db';

  final String? customPath;
  Database? _db;
  static bool _ffiInitialized = false;

  static void ensurePlatformInitialized() {
    if (kIsWeb || _ffiInitialized) return;
    if (Platform.isLinux || Platform.isWindows) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    _ffiInitialized = true;
  }

  Future<Database> get database async {
    if (_db != null && _db!.isOpen) return _db!;
    _db = await open();
    return _db!;
  }

  Future<String> resolveDbPath() async {
    if (customPath != null) return customPath!;
    ensurePlatformInitialized();
    try {
      final base = await getDatabasesPath();
      final dir = Directory(base);
      if (!dir.existsSync()) {
        await dir.create(recursive: true);
      }
      return p.join(base, _dbFileName);
    } catch (_) {
      return p.join(Directory.systemTemp.path, _dbFileName);
    }
  }

  Future<Database> open({int? overrideVersion}) async {
    ensurePlatformInitialized();
    final dbPath = await resolveDbPath();
    final targetVersion = overrideVersion ?? currentSchemaVersion;

    return openDatabase(
      dbPath,
      version: targetVersion,
      onConfigure: (db) async {
        try {
          await db.rawQuery('PRAGMA journal_mode = WAL;');
          await db.execute('PRAGMA synchronous = NORMAL;');
        } catch (_) {}
      },
      onCreate: (db, version) async {
        await _createTablesIfNotExist(db);
        await ensureSchemaIntegrity(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await _backupDatabaseBeforeUpgrade(dbPath, oldVersion);
        await _createTablesIfNotExist(db);
        await ensureSchemaIntegrity(db);
      },
      onDowngrade: (db, oldVersion, newVersion) async {
        // Nunca apaga tabelas mesmo em downgrade de versão de build
        await _createTablesIfNotExist(db);
        await ensureSchemaIntegrity(db);
      },
      onOpen: (db) async {
        // Auto-introspecção contínua: garante que novas colunas existam mesmo sem bump de versão
        await _createTablesIfNotExist(db);
        await ensureSchemaIntegrity(db);
      },
    );
  }

  /// Cria uma cópia física do arquivo .db antes de aplicar qualquer migração de versão.
  Future<void> _backupDatabaseBeforeUpgrade(
    String dbPath,
    int oldVersion,
  ) async {
    if (dbPath == inMemoryDatabasePath) return;
    try {
      final file = File(dbPath);
      if (file.existsSync()) {
        final backupPath = '$dbPath.v$oldVersion.bak';
        await file.copy(backupPath);
      }
    } catch (_) {}
  }

  Future<void> _createTablesIfNotExist(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        color TEXT NOT NULL,
        icon TEXT NOT NULL,
        extra_json TEXT DEFAULT '{}'
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS tasks (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT DEFAULT '',
        priority TEXT NOT NULL DEFAULT 'medium',
        status TEXT NOT NULL DEFAULT 'pending',
        category_id TEXT,
        due_date TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        tags TEXT NOT NULL DEFAULT '[]',
        recurrence TEXT,
        parent_task_id TEXT,
        occurrence_date TEXT,
        subtasks TEXT NOT NULL DEFAULT '[]',
        extra_json TEXT DEFAULT '{}'
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS notes (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        category_id TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        tags TEXT NOT NULL DEFAULT '[]',
        pinned INTEGER NOT NULL DEFAULT 0,
        extra_json TEXT DEFAULT '{}'
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_queue (
        id TEXT PRIMARY KEY,
        entity_type TEXT NOT NULL,
        action TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        payload TEXT,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS synced_entities (
        entity_id TEXT PRIMARY KEY
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_metadata (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  /// Inspeciona as colunas reais de cada tabela via PRAGMA table_info e adiciona
  /// quaisquer colunas novas sem jamais apagar ou sobrescrever registros existentes.
  Future<void> ensureSchemaIntegrity(DatabaseExecutor db) async {
    await _ensureColumns(db, 'categories', const {
      'id': 'TEXT',
      'name': "TEXT NOT NULL DEFAULT ''",
      'color': "TEXT NOT NULL DEFAULT '#C0533A'",
      'icon': "TEXT NOT NULL DEFAULT 'Tag'",
      'extra_json': "TEXT DEFAULT '{}'",
    });

    await _ensureColumns(db, 'tasks', const {
      'id': 'TEXT',
      'title': "TEXT NOT NULL DEFAULT ''",
      'description': "TEXT DEFAULT ''",
      'priority': "TEXT NOT NULL DEFAULT 'medium'",
      'status': "TEXT NOT NULL DEFAULT 'pending'",
      'category_id': 'TEXT',
      'due_date': 'TEXT',
      'created_at': "TEXT NOT NULL DEFAULT ''",
      'updated_at': "TEXT NOT NULL DEFAULT ''",
      'tags': "TEXT NOT NULL DEFAULT '[]'",
      'recurrence': 'TEXT',
      'parent_task_id': 'TEXT',
      'occurrence_date': 'TEXT',
      'subtasks': "TEXT NOT NULL DEFAULT '[]'",
      'extra_json': "TEXT DEFAULT '{}'",
    });

    await _ensureColumns(db, 'notes', const {
      'id': 'TEXT',
      'title': "TEXT NOT NULL DEFAULT ''",
      'content': "TEXT NOT NULL DEFAULT ''",
      'category_id': 'TEXT',
      'created_at': "TEXT NOT NULL DEFAULT ''",
      'updated_at': "TEXT NOT NULL DEFAULT ''",
      'tags': "TEXT NOT NULL DEFAULT '[]'",
      'pinned': 'INTEGER NOT NULL DEFAULT 0',
      'extra_json': "TEXT DEFAULT '{}'",
    });

    await _ensureColumns(db, 'sync_queue', const {
      'id': 'TEXT',
      'entity_type': "TEXT NOT NULL DEFAULT ''",
      'action': "TEXT NOT NULL DEFAULT ''",
      'entity_id': "TEXT NOT NULL DEFAULT ''",
      'payload': 'TEXT',
      'updated_at': "TEXT NOT NULL DEFAULT ''",
    });
  }

  Future<void> _ensureColumns(
    DatabaseExecutor db,
    String table,
    Map<String, String> requiredColumns,
  ) async {
    final rows = await db.rawQuery('PRAGMA table_info($table)');
    final existing = rows
        .map((r) => r['name']?.toString().toLowerCase())
        .whereType<String>()
        .toSet();

    for (final entry in requiredColumns.entries) {
      if (!existing.contains(entry.key.toLowerCase())) {
        await db.execute(
          'ALTER TABLE $table ADD COLUMN ${entry.key} ${entry.value}',
        );
      }
    }
  }

  Future<void> close() async {
    if (_db != null && _db!.isOpen) {
      await _db!.close();
    }
    _db = null;
  }
}
