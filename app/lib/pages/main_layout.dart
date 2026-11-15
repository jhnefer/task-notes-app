import 'dart:async';
import 'package:app/components/app_navigation_bar.dart';
import 'package:app/components/drawer_app.dart';
import 'package:app/components/notification_panel.dart';
import 'package:app/components/sync_status_indicator.dart';
import 'package:app/components/task_dialog.dart';
import 'package:app/models/models.dart';
import 'package:app/pages/achievements_page.dart';
import 'package:app/pages/auth_page.dart';
import 'package:app/pages/categories_page.dart';
import 'package:app/pages/home_page.dart';
import 'package:app/pages/notes_page.dart';
import 'package:app/pages/reports_page.dart';
import 'package:app/pages/settings_page.dart';
import 'package:app/pages/tasks_page.dart';
import 'package:app/services/api_client.dart';
import 'package:app/services/local_storage_service.dart';
import 'package:app/services/sync_service.dart';
import 'package:app/themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({
    this.themeMode = ThemeMode.light,
    this.onThemeModeChanged,
    super.key,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode>? onThemeModeChanged;

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  bool _showAuthScreen = false;
  PageController _pageController = PageController();
  bool _isAnimatingPage = false;

  final LocalStorageService _storage = LocalStorageService();
  final ApiClient _api = ApiClient();
  late final SyncService _syncService;

  SyncState _syncState = SyncState.localOnly;
  int _pendingSyncCount = 0;

  UserProfile _profile = const UserProfile();
  NotificationSettings _notificationSettings = const NotificationSettings();

  late List<Category> _categories;
  late List<Task> _tasks;
  late List<Note> _notes;
  late List<AchievementBadge> _badges;
  int _totalPoints = 45;
  int _currentLevel = 1;
  int _pointsToNextLevel = 55;
  int _streakDays = 3;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initDefaultDataInMemory();
    _syncService = SyncService(
      storage: _storage,
      api: _api,
      onDataMerged: ({
        required categories,
        required tasks,
        required notes,
      }) {
        if (!mounted) return;
        setState(() {
          _categories = categories;
          _tasks = tasks;
          _notes = notes;
        });
      },
      onStateChanged: (state, pendingCount, _) {
        if (!mounted) return;
        setState(() {
          _syncState = state;
          _pendingSyncCount = pendingCount;
        });
      },
    );
    _loadOfflineDataAndSettings();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    _syncService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _syncService.isCloudEnabled) {
      unawaited(
        _syncService.syncNow(
          currentCategories: _categories,
          currentTasks: _tasks,
          currentNotes: _notes,
        ),
      );
    }
  }

  Future<void> _loadOfflineDataAndSettings() async {
    try {
      final defaultUnlocked = <String, String>{};
      for (final b in _badges) {
        if (b.unlockedAt != null) {
          defaultUnlocked[b.id] = b.unlockedAt!;
        }
      }

      final snapshot = await _storage.loadSnapshot(
        defaultCategories: _categories,
        defaultTasks: _tasks,
        defaultNotes: _notes,
        defaultUnlockedBadges: defaultUnlocked,
      );
      final profile = await _storage.loadUserProfile(
        connectedUsername: snapshot.connectedUser?.username,
      );
      final notifSettings = await _storage.loadNotificationSettings();

      if (!mounted) return;
      setState(() {
        _categories = snapshot.categories;
        _tasks = snapshot.tasks;
        _notes = snapshot.notes;
        _totalPoints = snapshot.totalPoints;
        _currentLevel = snapshot.currentLevel;
        _pointsToNextLevel = (_currentLevel * 100) - _totalPoints;
        _streakDays = snapshot.streakDays;
        _badges = kAllBadgeDefinitions.map((b) {
          final unlockedAt = snapshot.unlockedBadges[b.id];
          return unlockedAt != null ? b.copyWith(unlockedAt: unlockedAt) : b;
        }).toList();

        _profile = profile;
        _notificationSettings = notifSettings;
      });

      _syncService.initialize(
        user: snapshot.connectedUser,
        initialQueue: snapshot.syncQueue,
        syncedIds: snapshot.syncedEntityIds,
        lastSyncedAt: snapshot.lastSyncedAt,
      );
    } catch (_) {}
  }

  Future<void> _updateProfile(UserProfile updated) async {
    setState(() => _profile = updated);
    try {
      await _storage.saveUserProfile(updated);
    } catch (_) {}
  }

  Future<void> _updateNotificationSettings(NotificationSettings updated) async {
    setState(() => _notificationSettings = updated);
    try {
      await _storage.saveNotificationSettings(updated);
    } catch (_) {}
  }

  void _initDefaultDataInMemory() {
    final now = DateTime.now();
    _categories = [
      const Category(
        id: 'cat-1',
        name: 'Trabalho',
        color: '#C0533A',
        icon: 'Briefcase',
      ),
      const Category(
        id: 'cat-2',
        name: 'Pessoal',
        color: '#4A7C59',
        icon: 'User',
      ),
      const Category(
        id: 'cat-3',
        name: 'Estudos',
        color: '#3A5A7C',
        icon: 'BookOpen',
      ),
    ];

    _tasks = [
      Task(
        id: 'task-1',
        title: 'Finalizar telas do aplicativo Meu Caderno',
        description: 'Implementar todas as telas baseadas na versão Web.',
        priority: Priority.high,
        status: TaskStatus.inProgress,
        categoryId: 'cat-1',
        dueDate: now.add(const Duration(hours: 5)).toIso8601String(),
        createdAt: now.subtract(const Duration(days: 1)).toIso8601String(),
        updatedAt: now.toIso8601String(),
        tags: const ['flutter', 'mobile'],
        subtasks: const [
          Subtask(
            id: 'sub-1',
            title: 'Configurar tema Warm Paper Notebook',
            completed: true,
            priority: Priority.high,
          ),
          Subtask(
            id: 'sub-2',
            title: 'Criar telas de Tarefas, Notas e Relatórios',
            completed: false,
            priority: Priority.medium,
          ),
        ],
      ),
      Task(
        id: 'task-2',
        title: 'Revisar documentação da API Express',
        description: 'Verificar endpoints de tarefas, categorias e notas.',
        priority: Priority.medium,
        status: TaskStatus.done,
        categoryId: 'cat-3',
        dueDate: now.toIso8601String(),
        createdAt: now.subtract(const Duration(days: 2)).toIso8601String(),
        updatedAt: now.toIso8601String(),
        tags: const ['api', 'backend'],
      ),
      Task(
        id: 'task-3',
        title: 'Planejamento semanal de metas',
        priority: Priority.low,
        status: TaskStatus.pending,
        categoryId: 'cat-2',
        dueDate: now.add(const Duration(days: 1)).toIso8601String(),
        createdAt: now.toIso8601String(),
        updatedAt: now.toIso8601String(),
        recurrence: const RecurrenceRule(
          frequency: RecurrenceFrequency.weekly,
          interval: 1,
          maxOccurrences: 12,
        ),
      ),
    ];

    _notes = [
      Note(
        id: 'note-1',
        title: 'Ideias para o Design do Caderno',
        content:
            'Usar paleta pergaminho (#FDF6E3), terracota (#C0533A) e tipografia clássica com Playfair Display, Lora e Caveat.',
        categoryId: 'cat-1',
        createdAt: now.toIso8601String(),
        updatedAt: now.toIso8601String(),
        tags: const ['design', 'ui'],
        pinned: true,
      ),
      Note(
        id: 'note-2',
        title: 'Resumo de Estudos',
        content:
            'Anotações sobre gerenciamento de estado, persistência local e gráficos com fl_chart.',
        categoryId: 'cat-3',
        createdAt: now.toIso8601String(),
        updatedAt: now.toIso8601String(),
        tags: const ['estudo'],
        pinned: false,
      ),
    ];

    _badges = kAllBadgeDefinitions.map((b) {
      if (b.id == 'first_task' ||
          b.id == 'first_completion' ||
          b.id == 'streak_3_days') {
        return b.copyWith(unlockedAt: now.toIso8601String());
      }
      return b;
    }).toList();
  }

  Future<void> _resetToDefaultData() async {
    setState(_initDefaultDataInMemory);
    await _storage.saveCategories(_categories);
    await _storage.saveTasks(_tasks);
    await _storage.saveNotes(_notes);
    if (_syncService.isCloudEnabled) {
      for (final c in _categories) {
        await _syncService.recordOperation(
          entityType: 'category',
          action: 'create',
          entityId: c.id,
          payload: c.toJson(),
        );
      }
      for (final t in _tasks) {
        await _syncService.recordOperation(
          entityType: 'task',
          action: 'create',
          entityId: t.id,
          payload: t.toJson(),
        );
      }
      for (final n in _notes) {
        await _syncService.recordOperation(
          entityType: 'note',
          action: 'create',
          entityId: n.id,
          payload: n.toJson(),
        );
      }
    }
  }

  List<TaskNotification> get _notifications {
    if (!_notificationSettings.enabled) return const [];
    final now = DateTime.now();
    final result = <TaskNotification>[];
    for (final t in _tasks) {
      if (t.status == TaskStatus.done || t.dueDate == null) continue;
      final due = DateTime.tryParse(t.dueDate!);
      if (due == null) continue;
      final hours = due.difference(now).inHours;
      if (hours > 48) continue;

      if (hours < 0) {
        if (_notificationSettings.criticalAlerts) {
          result.add(
            TaskNotification(
              taskId: t.id,
              title: t.title,
              dueDate: t.dueDate!,
              hoursUntilDue: hours,
              urgency: NotificationUrgency.critical,
              message: 'Tarefa em atraso',
            ),
          );
        }
      } else if (hours <= 1) {
        if (_notificationSettings.criticalAlerts) {
          result.add(
            TaskNotification(
              taskId: t.id,
              title: t.title,
              dueDate: t.dueDate!,
              hoursUntilDue: hours,
              urgency: NotificationUrgency.critical,
              message: 'Vence em menos de 1 hora',
            ),
          );
        }
      } else if (hours <= 6) {
        if (_notificationSettings.highAlerts) {
          result.add(
            TaskNotification(
              taskId: t.id,
              title: t.title,
              dueDate: t.dueDate!,
              hoursUntilDue: hours,
              urgency: NotificationUrgency.high,
              message: 'Vence em ${hours}h',
            ),
          );
        }
      } else if (hours <= 24) {
        if (_notificationSettings.mediumAlerts) {
          result.add(
            TaskNotification(
              taskId: t.id,
              title: t.title,
              dueDate: t.dueDate!,
              hoursUntilDue: hours,
              urgency: NotificationUrgency.medium,
              message: 'Vence hoje',
            ),
          );
        }
      } else {
        result.add(
          TaskNotification(
            taskId: t.id,
            title: t.title,
            dueDate: t.dueDate!,
            hoursUntilDue: hours,
            urgency: NotificationUrgency.low,
            message: 'Vence amanhã',
          ),
        );
      }
    }
    return result;
  }

  void _persistGamification() {
    final unlocked = <String, String>{};
    for (final b in _badges) {
      if (b.unlockedAt != null) {
        unlocked[b.id] = b.unlockedAt!;
      }
    }
    unawaited(
      _storage.saveGamification(
        totalPoints: _totalPoints,
        currentLevel: _currentLevel,
        streakDays: _streakDays,
        unlockedBadges: unlocked,
      ),
    );
  }

  void _addTask(Task task) {
    setState(() => _tasks.insert(0, task));
    unawaited(_storage.upsertTask(task));
    unawaited(
      _syncService.recordOperation(
        entityType: 'task',
        action: 'create',
        entityId: task.id,
        payload: task.toJson(),
      ),
    );
  }

  void _updateTask(Task updated) {
    setState(() {
      final idx = _tasks.indexWhere((t) => t.id == updated.id);
      if (idx != -1) {
        _tasks[idx] = updated;
      }
    });
    unawaited(_storage.upsertTask(updated));
    unawaited(
      _syncService.recordOperation(
        entityType: 'task',
        action: 'update',
        entityId: updated.id,
        payload: updated.toJson(),
      ),
    );
  }

  void _deleteTask(String id) {
    setState(() => _tasks.removeWhere((t) => t.id == id));
    unawaited(_storage.deleteTaskById(id));
    unawaited(
      _syncService.recordOperation(
        entityType: 'task',
        action: 'delete',
        entityId: id,
      ),
    );
  }

  void _toggleTaskStatus(String id) {
    Task? updatedTask;
    setState(() {
      final idx = _tasks.indexWhere((t) => t.id == id);
      if (idx == -1) return;
      final current = _tasks[idx];
      final next = current.status == TaskStatus.done
          ? TaskStatus.pending
          : TaskStatus.done;
      updatedTask = current.copyWith(
        status: next,
        updatedAt: DateTime.now().toIso8601String(),
      );
      _tasks[idx] = updatedTask!;
      if (next == TaskStatus.done) {
        _totalPoints += 15;
        if (_totalPoints >= _currentLevel * 100) {
          _currentLevel++;
        }
        _pointsToNextLevel = (_currentLevel * 100) - _totalPoints;
      }
    });
    if (updatedTask != null) {
      unawaited(_storage.upsertTask(updatedTask!));
      _persistGamification();
      unawaited(
        _syncService.recordOperation(
          entityType: 'task',
          action: 'update',
          entityId: updatedTask!.id,
          payload: updatedTask!.toJson(),
        ),
      );
    }
  }

  void _toggleSubtask(String taskId, String subtaskId) {
    Task? updatedTask;
    setState(() {
      final idx = _tasks.indexWhere((t) => t.id == taskId);
      if (idx == -1) return;
      final task = _tasks[idx];
      final updatedSubs = task.subtasks.map((s) {
        if (s.id == subtaskId) {
          return s.copyWith(completed: !s.completed);
        }
        return s;
      }).toList();
      final allDone =
          updatedSubs.isNotEmpty && updatedSubs.every((s) => s.completed);
      var nextStatus = task.status;
      if (allDone && task.status != TaskStatus.done) {
        nextStatus = TaskStatus.done;
      } else if (!allDone && task.status == TaskStatus.done) {
        nextStatus = TaskStatus.inProgress;
      }
      updatedTask = task.copyWith(
        subtasks: updatedSubs,
        status: nextStatus,
        updatedAt: DateTime.now().toIso8601String(),
      );
      _tasks[idx] = updatedTask!;
    });
    if (updatedTask != null) {
      unawaited(_storage.upsertTask(updatedTask!));
      unawaited(
        _syncService.recordOperation(
          entityType: 'task',
          action: 'update',
          entityId: updatedTask!.id,
          payload: updatedTask!.toJson(),
        ),
      );
    }
  }

  void _addNote(Note note) {
    setState(() => _notes.insert(0, note));
    unawaited(_storage.upsertNote(note));
    unawaited(
      _syncService.recordOperation(
        entityType: 'note',
        action: 'create',
        entityId: note.id,
        payload: note.toJson(),
      ),
    );
  }

  void _updateNote(Note note) {
    setState(() {
      final idx = _notes.indexWhere((item) => item.id == note.id);
      if (idx != -1) _notes[idx] = note;
    });
    unawaited(_storage.upsertNote(note));
    unawaited(
      _syncService.recordOperation(
        entityType: 'note',
        action: 'update',
        entityId: note.id,
        payload: note.toJson(),
      ),
    );
  }

  void _deleteNote(String id) {
    setState(() => _notes.removeWhere((n) => n.id == id));
    unawaited(_storage.deleteNoteById(id));
    unawaited(
      _syncService.recordOperation(
        entityType: 'note',
        action: 'delete',
        entityId: id,
      ),
    );
  }

  void _toggleNotePin(String id) {
    Note? updatedNote;
    setState(() {
      final idx = _notes.indexWhere((n) => n.id == id);
      if (idx != -1) {
        updatedNote = _notes[idx].copyWith(
          pinned: !_notes[idx].pinned,
          updatedAt: DateTime.now().toIso8601String(),
        );
        _notes[idx] = updatedNote!;
      }
    });
    if (updatedNote != null) {
      unawaited(_storage.upsertNote(updatedNote!));
      unawaited(
        _syncService.recordOperation(
          entityType: 'note',
          action: 'update',
          entityId: updatedNote!.id,
          payload: updatedNote!.toJson(),
        ),
      );
    }
  }

  void _addCategory(Category category) {
    setState(() => _categories.add(category));
    unawaited(_storage.upsertCategory(category));
    unawaited(
      _syncService.recordOperation(
        entityType: 'category',
        action: 'create',
        entityId: category.id,
        payload: category.toJson(),
      ),
    );
  }

  void _deleteCategory(String id) {
    setState(() => _categories.removeWhere((c) => c.id == id));
    unawaited(_storage.deleteCategoryById(id));
    unawaited(
      _syncService.recordOperation(
        entityType: 'category',
        action: 'delete',
        entityId: id,
      ),
    );
  }

  Future<void> _handleDisconnectCloud() async {
    await _syncService.disconnectAccount();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Modo Offline ativo. Seus dados continuam salvos neste dispositivo.',
        ),
      ),
    );
  }

  void _selectTab(int index) {
    final targetPage = AppNavigationBar.mainRouteIndices.indexOf(index);
    final wasInMainTabs = AppNavigationBar.mainRouteIndices.contains(
      _selectedIndex,
    );
    setState(() => _selectedIndex = index);
    if (targetPage == -1) return;
    if (!wasInMainTabs || !_pageController.hasClients) {
      _pageController.dispose();
      _pageController = PageController(initialPage: targetPage);
      return;
    }
    _isAnimatingPage = true;
    _pageController
        .animateToPage(
          targetPage,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
        )
        .whenComplete(() => _isAnimatingPage = false);
  }

  Widget _buildPageByIndex(int index) {
    return switch (index) {
      0 => HomePage(
        tasks: _tasks,
        notes: _notes,
        categories: _categories,
        notifications: _notifications,
        onNavigateToTab: _selectTab,
        onQuickCreateTask: () {
          showTaskDialog(
            context,
            categories: _categories,
            onSave: _addTask,
            onAiBreakdown: _api.generateSubtasks,
          );
        },
        onResetData: _resetToDefaultData,
      ),
      1 => TasksPage(
        tasks: _tasks,
        categories: _categories,
        onAddTask: _addTask,
        onUpdateTask: _updateTask,
        onDeleteTask: _deleteTask,
        onToggleTaskStatus: _toggleTaskStatus,
        onToggleSubtask: _toggleSubtask,
        onAiBreakdown: _api.generateSubtasks,
      ),
      2 => NotesPage(
        notes: _notes,
        categories: _categories,
        onAddNote: _addNote,
        onUpdateNote: _updateNote,
        onDeleteNote: _deleteNote,
        onTogglePin: _toggleNotePin,
      ),
      3 => CategoriesPage(
        categories: _categories,
        tasks: _tasks,
        notes: _notes,
        onAddCategory: _addCategory,
        onDeleteCategory: _deleteCategory,
      ),
      4 => ReportsPage(tasks: _tasks, categories: _categories),
      5 => AchievementsPage(
        tasks: _tasks,
        badges: _badges,
        totalPoints: _totalPoints,
        currentLevel: _currentLevel,
        pointsToNextLevel: _pointsToNextLevel,
        streakDays: _streakDays,
      ),
      6 => SettingsPage(
        profile: _profile,
        onUpdateProfile: _updateProfile,
        themeMode: widget.themeMode,
        onThemeModeChanged: (m) => widget.onThemeModeChanged?.call(m),
        notificationSettings: _notificationSettings,
        onUpdateNotificationSettings: _updateNotificationSettings,
        tasks: _tasks,
        notes: _notes,
        categories: _categories,
        isCloudConnected: _syncService.isCloudEnabled,
        onConnectCloud: () => setState(() => _showAuthScreen = true),
        onResetData: _resetToDefaultData,
        onLogout: _handleDisconnectCloud,
      ),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _buildActivePage() {
    if (AppNavigationBar.mainRouteIndices.contains(_selectedIndex)) {
      return PageView(
        controller: _pageController,
        onPageChanged: (pageIdx) {
          if (_isAnimatingPage) return;
          setState(() {
            _selectedIndex = AppNavigationBar.mainRouteIndices[pageIdx];
          });
        },
        children: AppNavigationBar.mainRouteIndices
            .map(_buildPageByIndex)
            .toList(),
      );
    }
    return _buildPageByIndex(_selectedIndex);
  }

  @override
  Widget build(BuildContext context) {
    if (_showAuthScreen) {
      return AuthPage(
        apiClient: _api,
        onContinueOffline: () => setState(() => _showAuthScreen = false),
        onUserAuthenticated: (user) {
          _updateProfile(_profile.copyWith(username: user.username));
          setState(() => _showAuthScreen = false);
          unawaited(
            _syncService.onUserAuthenticated(
              user: user,
              localCategories: _categories,
              localTasks: _tasks,
              localNotes: _notes,
            ),
          );
        },
        onAuthenticated: (username) {
          if (_showAuthScreen) {
            final fallbackUser = User(id: 'local-$username', username: username);
            _updateProfile(_profile.copyWith(username: username));
            setState(() => _showAuthScreen = false);
            unawaited(
              _syncService.onUserAuthenticated(
                user: fallbackUser,
                localCategories: _categories,
                localTasks: _tasks,
                localNotes: _notes,
              ),
            );
          }
        },
      );
    }

    final notifs = _notifications;
    final urgentCount = notifs
        .where(
          (n) =>
              n.urgency == NotificationUrgency.critical ||
              n.urgency == NotificationUrgency.high,
        )
        .length;

    return Scaffold(
      drawer: DrawerApp(
        selectedIndex: _selectedIndex,
        onSelectIndex: _selectTab,
        username: _profile.username,
        profile: _profile,
        urgentBadgeCount: urgentCount,
        isCloudConnected: _syncService.isCloudEnabled,
        syncState: _syncState,
        pendingSyncCount: _pendingSyncCount,
        onConnectCloud: () => setState(() => _showAuthScreen = true),
        onManualSync: () => _syncService.syncNow(
          currentCategories: _categories,
          currentTasks: _tasks,
          currentNotes: _notes,
        ),
        onLogout: _handleDisconnectCloud,
      ),
      bottomNavigationBar: AppNavigationBar(
        selectedIndex: _selectedIndex,
        urgentBadgeCount: urgentCount,
        onSelectIndex: _selectTab,
      ),
      appBar: AppBar(
        animateColor: true,
        centerTitle: true,
        actionsPadding: const EdgeInsets.only(right: 12),
        elevation: 1,
        shape: Border(
          bottom: BorderSide(
            color: AppColors.secondary.withAlpha(70),
            width: 1.5,
          ),
        ),
        actions: [
          SyncStatusIndicator(
            state: _syncState,
            pendingCount: _pendingSyncCount,
            onTap: () => _syncService.syncNow(
              currentCategories: _categories,
              currentTasks: _tasks,
              currentNotes: _notes,
            ),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                onPressed: () {
                  showNotificationPanelDialog(
                    context,
                    notifications: notifs,
                  );
                },
                tooltip: 'Notificações',
                icon: const Icon(LucideIcons.bell, size: 20),
              ),
              if (urgentCount > 0)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.destructive,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
        title: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 10,
          children: [
            Icon(
              LucideIcons.bookOpen,
              color: Theme.of(context).primaryColor,
              size: 20,
            ),
            Text(
              'Meu Caderno',
              style: TextStyle(
                fontFamily: 'Playfair Display',
                fontWeight: .bold,
                fontSize: MediaQuery.of(context).textScaler.scale(20),
              ),
            ),
          ],
        ),
      ),
      body: _buildActivePage(),
    );
  }
}
