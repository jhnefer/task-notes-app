import 'dart:async';
import 'package:app/models/models.dart';
import 'package:app/services/api_client.dart';
import 'package:app/services/local_storage_service.dart';
import 'package:dio/dio.dart';

typedef DataMergedCallback = void Function({
  required List<Category> categories,
  required List<Task> tasks,
  required List<Note> notes,
});

typedef SyncStateChangedCallback = void Function(
  SyncState state,
  int pendingCount,
  String? lastSyncedAt,
);

class SyncService {
  SyncService({
    required this.storage,
    required this.api,
    required this.onDataMerged,
    required this.onStateChanged,
  });

  final LocalStorageService storage;
  final ApiClient api;
  final DataMergedCallback onDataMerged;
  final SyncStateChangedCallback onStateChanged;

  List<SyncOperation> _queue = [];
  Set<String> _syncedIds = {};
  User? _connectedUser;
  String? _lastSyncedAt;
  SyncState _state = SyncState.localOnly;

  bool _isSyncing = false;
  bool _needsResync = false;
  Timer? _debounceTimer;
  Timer? _periodicTimer;

  SyncState get state => _state;
  int get pendingCount => _queue.length;
  User? get connectedUser => _connectedUser;
  String? get lastSyncedAt => _lastSyncedAt;
  bool get isCloudEnabled => _connectedUser != null;

  void initialize({
    required User? user,
    required List<SyncOperation> initialQueue,
    required Set<String> syncedIds,
    required String? lastSyncedAt,
  }) {
    _connectedUser = user;
    _queue = List<SyncOperation>.from(initialQueue);
    _syncedIds = Set<String>.from(syncedIds);
    _lastSyncedAt = lastSyncedAt;

    if (_connectedUser == null) {
      _updateState(SyncState.localOnly);
    } else if (_queue.isNotEmpty) {
      _updateState(SyncState.pendingOffline);
      scheduleSync(delay: const Duration(milliseconds: 600));
    } else {
      _updateState(SyncState.synced);
      scheduleSync(delay: const Duration(milliseconds: 900));
    }

    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(const Duration(seconds: 45), (_) {
      if (_connectedUser != null) {
        unawaited(syncNow());
      }
    });
  }

  void dispose() {
    _debounceTimer?.cancel();
    _periodicTimer?.cancel();
  }

  void _updateState(SyncState next) {
    _state = next;
    onStateChanged(_state, _queue.length, _lastSyncedAt);
  }

  /// Registra uma operação local na fila de sincronização com compactação (coalescing).
  /// Mesmo quando em Modo Offline (sem conta), a fila registra ou os itens locais
  /// ficam prontos para quando o usuário decidir conectar uma conta no futuro.
  Future<void> recordOperation({
    required String entityType,
    required String action,
    required String entityId,
    Map<String, dynamic>? payload,
  }) async {
    final nowIso = DateTime.now().toIso8601String();
    final existingIdx = _queue.indexWhere(
      (op) => op.entityType == entityType && op.entityId == entityId,
    );

    if (existingIdx != -1) {
      final existing = _queue[existingIdx];
      if (existing.action == 'create' && action == 'update') {
        _queue[existingIdx] = existing.copyWith(
          payload: payload,
          updatedAt: nowIso,
        );
      } else if (existing.action == 'create' && action == 'delete') {
        // Criado e deletado antes de sincronizar: cancela ambos
        _queue.removeAt(existingIdx);
      } else {
        _queue[existingIdx] = existing.copyWith(
          action: action,
          payload: payload,
          updatedAt: nowIso,
        );
      }
    } else {
      _queue.add(
        SyncOperation(
          id: 'op-${DateTime.now().microsecondsSinceEpoch}-$entityId',
          entityType: entityType,
          action: action,
          entityId: entityId,
          payload: payload,
          updatedAt: nowIso,
        ),
      );
    }

    await storage.saveSyncQueue(_queue);

    if (_connectedUser == null) {
      _updateState(SyncState.localOnly);
      return;
    }

    _updateState(SyncState.pendingOffline);
    scheduleSync();
  }

  /// Quando o usuário usava o app 100% offline e decide fazer login ou criar conta,
  /// garante que todas as categorias, tarefas e notas locais sejam enfileiradas
  /// para sincronização sem perder nada.
  Future<void> onUserAuthenticated({
    required User user,
    required List<Category> localCategories,
    required List<Task> localTasks,
    required List<Note> localNotes,
  }) async {
    _connectedUser = user;
    await storage.saveConnectedUser(user);

    final nowIso = DateTime.now().toIso8601String();

    for (final cat in localCategories) {
      final inQueue = _queue.any(
        (op) => op.entityType == 'category' && op.entityId == cat.id,
      );
      if (!inQueue && !_syncedIds.contains(cat.id)) {
        _queue.add(
          SyncOperation(
            id: 'op-init-cat-${cat.id}',
            entityType: 'category',
            action: 'create',
            entityId: cat.id,
            payload: cat.toJson(),
            updatedAt: nowIso,
          ),
        );
      }
    }

    for (final task in localTasks) {
      final inQueue = _queue.any(
        (op) => op.entityType == 'task' && op.entityId == task.id,
      );
      if (!inQueue && !_syncedIds.contains(task.id)) {
        _queue.add(
          SyncOperation(
            id: 'op-init-task-${task.id}',
            entityType: 'task',
            action: 'create',
            entityId: task.id,
            payload: task.toJson(),
            updatedAt: task.updatedAt,
          ),
        );
      }
    }

    for (final note in localNotes) {
      final inQueue = _queue.any(
        (op) => op.entityType == 'note' && op.entityId == note.id,
      );
      if (!inQueue && !_syncedIds.contains(note.id)) {
        _queue.add(
          SyncOperation(
            id: 'op-init-note-${note.id}',
            entityType: 'note',
            action: 'create',
            entityId: note.id,
            payload: note.toJson(),
            updatedAt: note.updatedAt,
          ),
        );
      }
    }

    await storage.saveSyncQueue(_queue);
    await syncNow(
      currentCategories: localCategories,
      currentTasks: localTasks,
      currentNotes: localNotes,
    );
  }

  /// Desconecta a conta voltando ao Modo Offline (mantendo todos os dados locais no aparelho).
  Future<void> disconnectAccount() async {
    _debounceTimer?.cancel();
    _connectedUser = null;
    await storage.saveConnectedUser(null);
    await api.logout();
    _updateState(SyncState.localOnly);
  }

  void scheduleSync({Duration delay = const Duration(milliseconds: 1400)}) {
    if (_connectedUser == null) return;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(delay, () {
      unawaited(syncNow());
    });
  }

  /// Executa Push da fila local + Pull e Merge silencioso em segundo plano.
  Future<void> syncNow({
    List<Category>? currentCategories,
    List<Task>? currentTasks,
    List<Note>? currentNotes,
  }) async {
    if (_connectedUser == null) {
      _updateState(SyncState.localOnly);
      return;
    }

    if (_isSyncing) {
      _needsResync = true;
      return;
    }

    _isSyncing = true;
    _updateState(SyncState.syncing);

    try {
      // 1. Ordenar fila para respeitar integridade referencial:
      // Categorias (create/update) -> Tasks & Notes (create/update) -> Deletes (Task/Note -> Category)
      final ordered = List<SyncOperation>.from(_queue)
        ..sort((a, b) => _operationPriority(a).compareTo(_operationPriority(b)));

      for (final op in ordered) {
        final success = await _executeSingleOperation(op);
        if (!success) {
          // Falha de rede ou sessão: pausa silenciosamente para tentar depois
          _isSyncing = false;
          _updateState(SyncState.pendingOffline);
          return;
        }
        _queue.removeWhere((item) => item.id == op.id);
        if (op.action == 'delete') {
          _syncedIds.remove(op.entityId);
        } else {
          _syncedIds.add(op.entityId);
        }
        await storage.saveSyncQueue(_queue);
        await storage.saveSyncedEntityIds(_syncedIds);
      }

      // 2. Pull remoto + Merge (Last-Write-Wins por updatedAt)
      final remoteCategories = await api.fetchCategories();
      final remoteTasks = await api.fetchTasks();
      final remoteNotes = await api.fetchNotes();

      final snapshot = await storage.loadSnapshot(
        defaultCategories: currentCategories ?? const [],
        defaultTasks: currentTasks ?? const [],
        defaultNotes: currentNotes ?? const [],
        defaultUnlockedBadges: const {},
      );

      final localCats = currentCategories ?? snapshot.categories;
      final localTasks = currentTasks ?? snapshot.tasks;
      final localNotes = currentNotes ?? snapshot.notes;

      final mergedCategories = _mergeCategories(localCats, remoteCategories);
      final mergedTasks = _mergeTasks(localTasks, remoteTasks);
      final mergedNotes = _mergeNotes(localNotes, remoteNotes);

      // Se havia itens locais que nunca subiram ao servidor (ex.: banco do servidor foi recriado),
      // garante que sejam enviados no próximo ciclo
      for (final c in mergedCategories) {
        _syncedIds.add(c.id);
      }
      for (final t in mergedTasks) {
        _syncedIds.add(t.id);
      }
      for (final n in mergedNotes) {
        _syncedIds.add(n.id);
      }

      await storage.saveCategories(mergedCategories);
      await storage.saveTasks(mergedTasks);
      await storage.saveNotes(mergedNotes);
      await storage.saveSyncedEntityIds(_syncedIds);

      _lastSyncedAt = DateTime.now().toIso8601String();
      await storage.saveLastSyncedAt(_lastSyncedAt);

      onDataMerged(
        categories: mergedCategories,
        tasks: mergedTasks,
        notes: mergedNotes,
      );

      _updateState(_queue.isEmpty ? SyncState.synced : SyncState.pendingOffline);
    } catch (_) {
      _updateState(SyncState.pendingOffline);
    } finally {
      _isSyncing = false;
      if (_needsResync && _connectedUser != null) {
        _needsResync = false;
        scheduleSync(delay: const Duration(milliseconds: 800));
      }
    }
  }

  int _operationPriority(SyncOperation op) {
    if (op.action != 'delete') {
      if (op.entityType == 'category') return 0;
      return 1;
    } else {
      if (op.entityType != 'category') return 2;
      return 3;
    }
  }

  Future<bool> _executeSingleOperation(SyncOperation op) async {
    try {
      final data = op.payload ?? <String, dynamic>{};
      switch ((op.entityType, op.action)) {
        case ('category', 'create'):
        case ('category', 'update'):
          await api.upsertCategory(data);
        case ('category', 'delete'):
          await api.deleteCategory(op.entityId);
        case ('task', 'create'):
          await api.createTask(data);
        case ('task', 'update'):
          await api.createTask(data); // POST faz upsert completo e seguro no backend
        case ('task', 'delete'):
          await api.deleteTask(op.entityId);
        case ('note', 'create'):
          await api.createNote(data);
        case ('note', 'update'):
          await api.createNote(data); // POST faz upsert completo e seguro no backend
        case ('note', 'delete'):
          await api.deleteNote(op.entityId);
      }
      return true;
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      // Se tentou deletar algo que já não existe no servidor, considera concluído
      if (op.action == 'delete' && (code == 404 || code == 204)) {
        return true;
      }
      // Se erro 400 de validação em item inválido, descarta para não travar a fila
      if (code == 400) {
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  List<Category> _mergeCategories(
    List<Category> local,
    List<Category> remote,
  ) {
    final byId = <String, Category>{};
    for (final r in remote) {
      byId[r.id] = r;
    }
    for (final l in local) {
      final hasPendingOp = _queue.any(
        (op) => op.entityType == 'category' && op.entityId == l.id,
      );
      if (hasPendingOp || (!_syncedIds.contains(l.id) && !byId.containsKey(l.id))) {
        byId[l.id] = l;
      }
    }
    return byId.values.toList();
  }

  List<Task> _mergeTasks(List<Task> local, List<Task> remote) {
    final byId = <String, Task>{};
    for (final r in remote) {
      byId[r.id] = r;
    }
    for (final l in local) {
      final hasPendingOp = _queue.any(
        (op) => op.entityType == 'task' && op.entityId == l.id,
      );
      if (hasPendingOp) {
        byId[l.id] = l;
        continue;
      }
      final existing = byId[l.id];
      if (existing == null) {
        if (!_syncedIds.contains(l.id)) {
          byId[l.id] = l;
        }
      } else {
        final localTime = DateTime.tryParse(l.updatedAt);
        final remoteTime = DateTime.tryParse(existing.updatedAt);
        if (localTime != null &&
            remoteTime != null &&
            localTime.isAfter(remoteTime)) {
          byId[l.id] = l;
        }
      }
    }
    final result = byId.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  List<Note> _mergeNotes(List<Note> local, List<Note> remote) {
    final byId = <String, Note>{};
    for (final r in remote) {
      byId[r.id] = r;
    }
    for (final l in local) {
      final hasPendingOp = _queue.any(
        (op) => op.entityType == 'note' && op.entityId == l.id,
      );
      if (hasPendingOp) {
        byId[l.id] = l;
        continue;
      }
      final existing = byId[l.id];
      if (existing == null) {
        if (!_syncedIds.contains(l.id)) {
          byId[l.id] = l;
        }
      } else {
        final localTime = DateTime.tryParse(l.updatedAt);
        final remoteTime = DateTime.tryParse(existing.updatedAt);
        if (localTime != null &&
            remoteTime != null &&
            localTime.isAfter(remoteTime)) {
          byId[l.id] = l;
        }
      }
    }
    final result = byId.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }
}
