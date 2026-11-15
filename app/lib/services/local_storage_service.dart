import 'dart:convert';
import 'dart:io';
import 'package:app/models/models.dart';
import 'package:app/services/app_database.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class LocalDataSnapshot {
  const LocalDataSnapshot({
    required this.categories,
    required this.tasks,
    required this.notes,
    required this.totalPoints,
    required this.currentLevel,
    required this.streakDays,
    required this.unlockedBadges,
    this.connectedUser,
    required this.syncQueue,
    required this.syncedEntityIds,
    this.lastSyncedAt,
  });

  final List<Category> categories;
  final List<Task> tasks;
  final List<Note> notes;
  final int totalPoints;
  final int currentLevel;
  final int streakDays;
  final Map<String, String> unlockedBadges; // badgeId -> unlockedAt ISO
  final User? connectedUser;
  final List<SyncOperation> syncQueue;
  final Set<String> syncedEntityIds;
  final String? lastSyncedAt;
}

class LocalStorageService {
  LocalStorageService({AppDatabase? database})
    : _appDb = database ?? AppDatabase.instance;

  final AppDatabase _appDb;
  static bool _sqliteUnavailable = false;

  // Fallback em memória para ambientes sem plugin nativo (Web, testes de widget ou hot-reload antes de rebuild)
  bool _memoryInitialized = false;
  List<Category> _memoryCategories = const [];
  List<Task> _memoryTasks = const [];
  List<Note> _memoryNotes = const [];
  List<SyncOperation> _memorySyncQueue = const [];
  Set<String> _memorySyncedIds = const {};
  final Map<String, String> _memoryMeta = <String, String>{};

  Future<Database?> _tryGetSqlite() async {
    if (kIsWeb || _sqliteUnavailable) return null;
    if (_appDb.customPath == null &&
        Platform.environment.containsKey('FLUTTER_TEST')) {
      return null;
    }
    try {
      return await _appDb.database;
    } catch (_) {
      _sqliteUnavailable = true;
      return null;
    }
  }

  Future<String?> _getMeta(String key) async {
    final db = await _tryGetSqlite();
    if (db != null) {
      final rows = await db.query(
        'app_metadata',
        where: 'key = ?',
        whereArgs: [key],
        limit: 1,
      );
      if (rows.isNotEmpty && rows.first['value'] != null) {
        return rows.first['value'].toString();
      }
      return null;
    }
    return _memoryMeta[key];
  }

  Future<void> _setMeta(String key, String? value) async {
    final db = await _tryGetSqlite();
    if (db != null) {
      if (value == null) {
        await db.delete('app_metadata', where: 'key = ?', whereArgs: [key]);
      } else {
        await _putMetaTxn(db, key, value);
      }
      return;
    }
    if (value == null) {
      _memoryMeta.remove(key);
    } else {
      _memoryMeta[key] = value;
    }
  }

  // --- Preferências de Tema, Perfil e Notificações no SQLite (app_metadata) ---

  Future<String?> loadThemeMode() => _getMeta('app_theme_mode');

  Future<void> saveThemeMode(String mode) => _setMeta('app_theme_mode', mode);

  Future<UserProfile> loadUserProfile({String? connectedUsername}) async {
    final raw = await _getMeta('user_profile');
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          final loaded = UserProfile.fromJson(
            Map<String, dynamic>.from(decoded),
          );
          if (connectedUsername != null && connectedUsername.isNotEmpty) {
            return loaded.copyWith(username: connectedUsername);
          }
          return loaded;
        }
      } catch (_) {}
    }
    return UserProfile(
      displayName: 'Bruno',
      username: connectedUsername ?? 'Modo Offline',
      avatarIcon: 'User',
      avatarColor: '#C0533A',
    );
  }

  Future<void> saveUserProfile(UserProfile profile) =>
      _setMeta('user_profile', jsonEncode(profile.toJson()));

  Future<NotificationSettings> loadNotificationSettings() async {
    final raw = await _getMeta('notification_settings');
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          return NotificationSettings.fromJson(
            Map<String, dynamic>.from(decoded),
          );
        }
      } catch (_) {}
    }
    return const NotificationSettings();
  }

  Future<void> saveNotificationSettings(NotificationSettings settings) =>
      _setMeta('notification_settings', jsonEncode(settings.toJson()));

  // --- Carregamento de Snapshot ---

  Future<LocalDataSnapshot> loadSnapshot({
    required List<Category> defaultCategories,
    required List<Task> defaultTasks,
    required List<Note> defaultNotes,
    required Map<String, String> defaultUnlockedBadges,
  }) async {
    final db = await _tryGetSqlite();
    if (db != null) {
      return _loadFromSqlite(
        db: db,
        defaultCategories: defaultCategories,
        defaultTasks: defaultTasks,
        defaultNotes: defaultNotes,
        defaultUnlockedBadges: defaultUnlockedBadges,
      );
    }

    return _loadFromMemoryFallback(
      defaultCategories: defaultCategories,
      defaultTasks: defaultTasks,
      defaultNotes: defaultNotes,
      defaultUnlockedBadges: defaultUnlockedBadges,
    );
  }

  Future<LocalDataSnapshot> _loadFromSqlite({
    required Database db,
    required List<Category> defaultCategories,
    required List<Task> defaultTasks,
    required List<Note> defaultNotes,
    required Map<String, String> defaultUnlockedBadges,
  }) async {
    final initRow = await db.query(
      'app_metadata',
      where: 'key = ?',
      whereArgs: const ['sqlite_initialized_v1'],
      limit: 1,
    );

    if (initRow.isEmpty) {
      await _seedSqliteTransaction(
        db: db,
        categories: defaultCategories,
        tasks: defaultTasks,
        notes: defaultNotes,
        totalPoints: 45,
        currentLevel: 1,
        streakDays: 3,
        unlockedBadges: defaultUnlockedBadges,
        connectedUser: null,
        syncQueue: const [],
        syncedIds: const {},
        lastSyncedAt: null,
      );

      return LocalDataSnapshot(
        categories: List<Category>.from(defaultCategories),
        tasks: List<Task>.from(defaultTasks),
        notes: List<Note>.from(defaultNotes),
        totalPoints: 45,
        currentLevel: 1,
        streakDays: 3,
        unlockedBadges: Map<String, String>.from(defaultUnlockedBadges),
        syncQueue: const [],
        syncedEntityIds: const {},
      );
    }

    final catRows = await db.query('categories');
    final categories = catRows.map(_categoryFromSqliteRow).toList();

    final taskRows = await db.query('tasks', orderBy: 'created_at DESC');
    final tasks = taskRows.map(_taskFromSqliteRow).toList();

    final noteRows = await db.query('notes', orderBy: 'created_at DESC');
    final notes = noteRows.map(_noteFromSqliteRow).toList();

    final queueRows = await db.query('sync_queue');
    final syncQueue = queueRows.map(_syncOpFromSqliteRow).toList();

    final syncedRows = await db.query('synced_entities');
    final syncedIds = syncedRows
        .map((r) => r['entity_id']?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .toSet();

    final metaRows = await db.query('app_metadata');
    final meta = <String, String>{
      for (final r in metaRows)
        if (r['key'] != null && r['value'] != null)
          r['key'].toString(): r['value'].toString(),
    };

    final totalPoints = int.tryParse(meta['total_points'] ?? '') ?? 45;
    final currentLevel = int.tryParse(meta['current_level'] ?? '') ?? 1;
    final streakDays = int.tryParse(meta['streak_days'] ?? '') ?? 3;

    final unlockedBadges = <String, String>{};
    final rawBadges = meta['unlocked_badges'];
    if (rawBadges != null && rawBadges.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawBadges);
        if (decoded is Map) {
          for (final entry in decoded.entries) {
            if (entry.value is String) {
              unlockedBadges[entry.key.toString()] = entry.value as String;
            }
          }
        }
      } catch (_) {}
    } else {
      unlockedBadges.addAll(defaultUnlockedBadges);
    }

    User? connectedUser;
    final rawUser = meta['connected_user'];
    if (rawUser != null && rawUser.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawUser);
        if (decoded is Map) {
          connectedUser = User.fromJson(Map<String, dynamic>.from(decoded));
        }
      } catch (_) {}
    }

    return LocalDataSnapshot(
      categories: categories,
      tasks: tasks,
      notes: notes,
      totalPoints: totalPoints,
      currentLevel: currentLevel,
      streakDays: streakDays,
      unlockedBadges: unlockedBadges,
      connectedUser: connectedUser,
      syncQueue: syncQueue,
      syncedEntityIds: syncedIds,
      lastSyncedAt: meta['last_synced_at'],
    );
  }

  Future<void> _seedSqliteTransaction({
    required Database db,
    required List<Category> categories,
    required List<Task> tasks,
    required List<Note> notes,
    required int totalPoints,
    required int currentLevel,
    required int streakDays,
    required Map<String, String> unlockedBadges,
    required User? connectedUser,
    required List<SyncOperation> syncQueue,
    required Set<String> syncedIds,
    required String? lastSyncedAt,
  }) async {
    await db.transaction((txn) async {
      for (final c in categories) {
        await txn.insert(
          'categories',
          _categoryToSqliteRow(c),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      for (final t in tasks) {
        await txn.insert(
          'tasks',
          _taskToSqliteRow(t),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      for (final n in notes) {
        await txn.insert(
          'notes',
          _noteToSqliteRow(n),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      for (final op in syncQueue) {
        await txn.insert(
          'sync_queue',
          _syncOpToSqliteRow(op),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      for (final id in syncedIds) {
        await txn.insert(
          'synced_entities',
          {'entity_id': id},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      await _putMetaTxn(txn, 'total_points', '$totalPoints');
      await _putMetaTxn(txn, 'current_level', '$currentLevel');
      await _putMetaTxn(txn, 'streak_days', '$streakDays');
      await _putMetaTxn(txn, 'unlocked_badges', jsonEncode(unlockedBadges));
      if (connectedUser != null) {
        await _putMetaTxn(
          txn,
          'connected_user',
          jsonEncode(connectedUser.toJson()),
        );
      }
      if (lastSyncedAt != null) {
        await _putMetaTxn(txn, 'last_synced_at', lastSyncedAt);
      }
      await _putMetaTxn(txn, 'sqlite_initialized_v1', 'true');
    });
  }

  Future<void> _putMetaTxn(
    DatabaseExecutor txn,
    String key,
    String value,
  ) async {
    await txn.insert(
      'app_metadata',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Map<String, Object?> _categoryToSqliteRow(Category c) => {
    'id': c.id,
    'name': c.name,
    'color': c.color,
    'icon': c.icon,
    'extra_json': jsonEncode(c.toJson()),
  };

  Category _categoryFromSqliteRow(Map<String, Object?> row) => Category(
    id: row['id']?.toString() ?? '',
    name: row['name']?.toString() ?? '',
    color: row['color']?.toString() ?? '#C0533A',
    icon: row['icon']?.toString() ?? 'Tag',
  );

  Map<String, Object?> _taskToSqliteRow(Task t) => {
    'id': t.id,
    'title': t.title,
    'description': t.description ?? '',
    'priority': t.priority.value,
    'status': t.status.value,
    'category_id': t.categoryId,
    'due_date': t.dueDate,
    'created_at': t.createdAt,
    'updated_at': t.updatedAt,
    'tags': jsonEncode(t.tags),
    'recurrence': t.recurrence != null
        ? jsonEncode(t.recurrence!.toJson())
        : null,
    'parent_task_id': t.parentTaskId,
    'occurrence_date': t.occurrenceDate,
    'subtasks': jsonEncode(t.subtasks.map((s) => s.toJson()).toList()),
    'extra_json': jsonEncode(t.toJson()),
  };

  Task _taskFromSqliteRow(Map<String, Object?> row) {
    return Task.fromJson({
      'id': row['id'],
      'title': row['title'],
      'description': row['description'],
      'priority': row['priority'],
      'status': row['status'],
      'categoryId': row['category_id'],
      'dueDate': row['due_date'],
      'createdAt': row['created_at'],
      'updatedAt': row['updated_at'],
      'tags': row['tags'],
      'recurrence': row['recurrence'],
      'parentTaskId': row['parent_task_id'],
      'occurrenceDate': row['occurrence_date'],
      'subtasks': row['subtasks'],
    });
  }

  Map<String, Object?> _noteToSqliteRow(Note n) => {
    'id': n.id,
    'title': n.title,
    'content': n.content,
    'category_id': n.categoryId,
    'created_at': n.createdAt,
    'updated_at': n.updatedAt,
    'tags': jsonEncode(n.tags),
    'pinned': n.pinned ? 1 : 0,
    'extra_json': jsonEncode(n.toJson()),
  };

  Note _noteFromSqliteRow(Map<String, Object?> row) {
    return Note.fromJson({
      'id': row['id'],
      'title': row['title'],
      'content': row['content'],
      'categoryId': row['category_id'],
      'createdAt': row['created_at'],
      'updatedAt': row['updated_at'],
      'tags': row['tags'],
      'pinned': row['pinned'],
    });
  }

  Map<String, Object?> _syncOpToSqliteRow(SyncOperation op) => {
    'id': op.id,
    'entity_type': op.entityType,
    'action': op.action,
    'entity_id': op.entityId,
    'payload': op.payload != null ? jsonEncode(op.payload) : null,
    'updated_at': op.updatedAt,
  };

  SyncOperation _syncOpFromSqliteRow(Map<String, Object?> row) {
    return SyncOperation.fromJson({
      'id': row['id'],
      'entityType': row['entity_type'],
      'action': row['action'],
      'entityId': row['entity_id'],
      'payload': row['payload'],
      'updatedAt': row['updated_at'],
    });
  }

  // --- Operações Granulares Atômicas no SQLite (sem apagar tabelas) ---

  Future<void> upsertCategory(Category category) async {
    final db = await _tryGetSqlite();
    if (db != null) {
      await db.insert(
        'categories',
        _categoryToSqliteRow(category),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return;
    }
    final list = List<Category>.from(_memoryCategories);
    final idx = list.indexWhere((c) => c.id == category.id);
    if (idx >= 0) {
      list[idx] = category;
    } else {
      list.add(category);
    }
    _memoryCategories = list;
  }

  Future<void> deleteCategoryById(String id) async {
    final db = await _tryGetSqlite();
    if (db != null) {
      await db.delete('categories', where: 'id = ?', whereArgs: [id]);
      return;
    }
    _memoryCategories = _memoryCategories.where((c) => c.id != id).toList();
  }

  Future<void> upsertTask(Task task) async {
    final db = await _tryGetSqlite();
    if (db != null) {
      await db.insert(
        'tasks',
        _taskToSqliteRow(task),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return;
    }
    final list = List<Task>.from(_memoryTasks);
    final idx = list.indexWhere((t) => t.id == task.id);
    if (idx >= 0) {
      list[idx] = task;
    } else {
      list.insert(0, task);
    }
    _memoryTasks = list;
  }

  Future<void> deleteTaskById(String id) async {
    final db = await _tryGetSqlite();
    if (db != null) {
      await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
      return;
    }
    _memoryTasks = _memoryTasks.where((t) => t.id != id).toList();
  }

  Future<void> upsertNote(Note note) async {
    final db = await _tryGetSqlite();
    if (db != null) {
      await db.insert(
        'notes',
        _noteToSqliteRow(note),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return;
    }
    final list = List<Note>.from(_memoryNotes);
    final idx = list.indexWhere((n) => n.id == note.id);
    if (idx >= 0) {
      list[idx] = note;
    } else {
      list.insert(0, note);
    }
    _memoryNotes = list;
  }

  Future<void> deleteNoteById(String id) async {
    final db = await _tryGetSqlite();
    if (db != null) {
      await db.delete('notes', where: 'id = ?', whereArgs: [id]);
      return;
    }
    _memoryNotes = _memoryNotes.where((n) => n.id != id).toList();
  }

  // --- Sincronização de Coleções (Transacional com Upsert + Remoção Seletiva) ---

  Future<void> saveCategories(List<Category> items) async {
    final db = await _tryGetSqlite();
    if (db != null) {
      await db.transaction((txn) async {
        final keepIds = items.map((e) => e.id).toSet();
        final existing = await txn.query('categories', columns: ['id']);
        for (final row in existing) {
          final id = row['id']?.toString();
          if (id != null && !keepIds.contains(id)) {
            await txn.delete('categories', where: 'id = ?', whereArgs: [id]);
          }
        }
        for (final c in items) {
          await txn.insert(
            'categories',
            _categoryToSqliteRow(c),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });
      return;
    }
    _memoryCategories = List<Category>.from(items);
  }

  Future<void> saveTasks(List<Task> items) async {
    final db = await _tryGetSqlite();
    if (db != null) {
      await db.transaction((txn) async {
        final keepIds = items.map((e) => e.id).toSet();
        final existing = await txn.query('tasks', columns: ['id']);
        for (final row in existing) {
          final id = row['id']?.toString();
          if (id != null && !keepIds.contains(id)) {
            await txn.delete('tasks', where: 'id = ?', whereArgs: [id]);
          }
        }
        for (final t in items) {
          await txn.insert(
            'tasks',
            _taskToSqliteRow(t),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });
      return;
    }
    _memoryTasks = List<Task>.from(items);
  }

  Future<void> saveNotes(List<Note> items) async {
    final db = await _tryGetSqlite();
    if (db != null) {
      await db.transaction((txn) async {
        final keepIds = items.map((e) => e.id).toSet();
        final existing = await txn.query('notes', columns: ['id']);
        for (final row in existing) {
          final id = row['id']?.toString();
          if (id != null && !keepIds.contains(id)) {
            await txn.delete('notes', where: 'id = ?', whereArgs: [id]);
          }
        }
        for (final n in items) {
          await txn.insert(
            'notes',
            _noteToSqliteRow(n),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });
      return;
    }
    _memoryNotes = List<Note>.from(items);
  }

  Future<void> saveGamification({
    required int totalPoints,
    required int currentLevel,
    required int streakDays,
    required Map<String, String> unlockedBadges,
  }) async {
    final db = await _tryGetSqlite();
    if (db != null) {
      await db.transaction((txn) async {
        await _putMetaTxn(txn, 'total_points', '$totalPoints');
        await _putMetaTxn(txn, 'current_level', '$currentLevel');
        await _putMetaTxn(txn, 'streak_days', '$streakDays');
        await _putMetaTxn(txn, 'unlocked_badges', jsonEncode(unlockedBadges));
      });
      return;
    }
    _memoryMeta['total_points'] = '$totalPoints';
    _memoryMeta['current_level'] = '$currentLevel';
    _memoryMeta['streak_days'] = '$streakDays';
    _memoryMeta['unlocked_badges'] = jsonEncode(unlockedBadges);
  }

  Future<void> saveConnectedUser(User? user) =>
      _setMeta('connected_user', user != null ? jsonEncode(user.toJson()) : null);

  Future<void> saveSyncQueue(List<SyncOperation> queue) async {
    final db = await _tryGetSqlite();
    if (db != null) {
      await db.transaction((txn) async {
        final keepIds = queue.map((e) => e.id).toSet();
        final existing = await txn.query('sync_queue', columns: ['id']);
        for (final row in existing) {
          final id = row['id']?.toString();
          if (id != null && !keepIds.contains(id)) {
            await txn.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
          }
        }
        for (final op in queue) {
          await txn.insert(
            'sync_queue',
            _syncOpToSqliteRow(op),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });
      return;
    }
    _memorySyncQueue = List<SyncOperation>.from(queue);
  }

  Future<void> saveSyncedEntityIds(Set<String> ids) async {
    final db = await _tryGetSqlite();
    if (db != null) {
      await db.transaction((txn) async {
        final existing = await txn.query(
          'synced_entities',
          columns: ['entity_id'],
        );
        for (final row in existing) {
          final id = row['entity_id']?.toString();
          if (id != null && !ids.contains(id)) {
            await txn.delete(
              'synced_entities',
              where: 'entity_id = ?',
              whereArgs: [id],
            );
          }
        }
        for (final id in ids) {
          await txn.insert(
            'synced_entities',
            {'entity_id': id},
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });
      return;
    }
    _memorySyncedIds = Set<String>.from(ids);
  }

  Future<void> saveLastSyncedAt(String? iso) => _setMeta('last_synced_at', iso);

  // --- Fallback Seguro em Memória ---

  LocalDataSnapshot _loadFromMemoryFallback({
    required List<Category> defaultCategories,
    required List<Task> defaultTasks,
    required List<Note> defaultNotes,
    required Map<String, String> defaultUnlockedBadges,
  }) {
    if (!_memoryInitialized) {
      _memoryInitialized = true;
      _memoryCategories = List<Category>.from(defaultCategories);
      _memoryTasks = List<Task>.from(defaultTasks);
      _memoryNotes = List<Note>.from(defaultNotes);
      _memoryMeta['total_points'] = '45';
      _memoryMeta['current_level'] = '1';
      _memoryMeta['streak_days'] = '3';
      _memoryMeta['unlocked_badges'] = jsonEncode(defaultUnlockedBadges);
    }

    final unlockedBadges = <String, String>{};
    final rawBadges = _memoryMeta['unlocked_badges'];
    if (rawBadges != null && rawBadges.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawBadges);
        if (decoded is Map) {
          for (final entry in decoded.entries) {
            if (entry.value is String) {
              unlockedBadges[entry.key.toString()] = entry.value as String;
            }
          }
        }
      } catch (_) {}
    } else {
      unlockedBadges.addAll(defaultUnlockedBadges);
    }

    User? connectedUser;
    final rawUser = _memoryMeta['connected_user'];
    if (rawUser != null && rawUser.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawUser);
        if (decoded is Map) {
          connectedUser = User.fromJson(Map<String, dynamic>.from(decoded));
        }
      } catch (_) {}
    }

    return LocalDataSnapshot(
      categories: List<Category>.from(_memoryCategories),
      tasks: List<Task>.from(_memoryTasks),
      notes: List<Note>.from(_memoryNotes),
      totalPoints: int.tryParse(_memoryMeta['total_points'] ?? '') ?? 45,
      currentLevel: int.tryParse(_memoryMeta['current_level'] ?? '') ?? 1,
      streakDays: int.tryParse(_memoryMeta['streak_days'] ?? '') ?? 3,
      unlockedBadges: unlockedBadges,
      connectedUser: connectedUser,
      syncQueue: List<SyncOperation>.from(_memorySyncQueue),
      syncedEntityIds: Set<String>.from(_memorySyncedIds),
      lastSyncedAt: _memoryMeta['last_synced_at'],
    );
  }
}
