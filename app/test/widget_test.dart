import 'dart:io';
import 'package:app/components/app_navigation_bar.dart';
import 'package:app/components/sync_status_indicator.dart';
import 'package:app/main.dart';
import 'package:app/models/models.dart';
import 'package:app/services/api_client.dart';
import 'package:app/services/app_database.dart';
import 'package:app/services/local_storage_service.dart';
import 'package:app/services/sync_service.dart';
import 'package:app/utils/data_exporter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

void main() {
  setUpAll(() async {
    Intl.defaultLocale = 'pt_BR';
    await initializeDateFormatting('pt_BR', null);
  });

  testWidgets('Renderiza Meu Caderno e navega pela AppNavigationBar', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const TaskApp());
    await tester.pumpAndSettle();

    expect(find.text('Meu Caderno'), findsWidgets);
    expect(find.text('Visão Geral'), findsOneWidget);
    expect(find.byType(AppNavigationBar), findsOneWidget);

    // Verifica os 4 itens principais na Navigation Bar
    expect(
      find.descendant(
        of: find.byType(AppNavigationBar),
        matching: find.text('Início'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(AppNavigationBar),
        matching: find.text('Tarefas'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(AppNavigationBar),
        matching: find.text('Anotações'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(AppNavigationBar),
        matching: find.text('Relatórios'),
      ),
      findsOneWidget,
    );

    // Navega para Tarefas
    await tester.tap(
      find.descendant(
        of: find.byType(AppNavigationBar),
        matching: find.text('Tarefas'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Nova Tarefa'), findsOneWidget);

    // Navega para Anotações
    await tester.tap(
      find.descendant(
        of: find.byType(AppNavigationBar),
        matching: find.text('Anotações'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Nova Anotação'), findsOneWidget);

    // Navega para Relatórios
    await tester.tap(
      find.descendant(
        of: find.byType(AppNavigationBar),
        matching: find.text('Relatórios'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Análise de produtividade e progresso'), findsOneWidget);

    // Retorna para Início
    await tester.tap(
      find.descendant(
        of: find.byType(AppNavigationBar),
        matching: find.text('Início'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Visão Geral'), findsOneWidget);

    // Navega arrastando para o lado (Início -> Tarefas)
    await tester.drag(find.byType(PageView), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.text('Nova Tarefa'), findsOneWidget);
  });

  testWidgets('Navega para Configurações via Drawer e testa seções', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const TaskApp());
    await tester.pumpAndSettle();

    // Abre o Drawer
    final scaffoldState = tester.firstState<ScaffoldState>(
      find.byType(Scaffold),
    );
    scaffoldState.openDrawer();
    await tester.pumpAndSettle();

    expect(find.text('Configurações'), findsOneWidget);
    await tester.ensureVisible(find.text('Configurações'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Configurações'));
    await tester.pumpAndSettle();

    // Verifica seções da página de Configurações
    expect(find.text('Perfil do Usuário'), findsOneWidget);
    expect(find.text('Aparência e Tema'), findsOneWidget);
    expect(find.text('Notificações e Alertas'), findsOneWidget);
    expect(find.text('Exportação e Dados'), findsOneWidget);

    // Alterna tema para Escuro
    await tester.ensureVisible(find.text('Escuro'));
    await tester.tap(find.text('Escuro'));
    await tester.pumpAndSettle();

    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.themeMode, ThemeMode.dark);
  });

  test('DataExporter gera CSV e JSON corretamente', () {
    const categories = [
      Category(id: 'c1', name: 'Trabalho', color: '#C0533A', icon: 'Briefcase'),
    ];
    const tasks = [
      Task(
        id: 't1',
        title: 'Tarefa Teste',
        priority: Priority.high,
        status: TaskStatus.pending,
        categoryId: 'c1',
        createdAt: '2026-11-15T10:00:00.000Z',
        updatedAt: '2026-11-15T10:00:00.000Z',
      ),
    ];
    const notes = [
      Note(
        id: 'n1',
        title: 'Nota Teste',
        content: 'Conteúdo da nota',
        categoryId: 'c1',
        createdAt: '2026-11-15T10:00:00.000Z',
        updatedAt: '2026-11-15T10:00:00.000Z',
        pinned: true,
      ),
    ];

    final tasksCsv = DataExporter.buildTasksCsv(tasks, categories);
    expect(tasksCsv, contains('Tarefa Teste'));
    expect(tasksCsv, contains('Trabalho'));

    final notesCsv = DataExporter.buildNotesCsv(notes, categories);
    expect(notesCsv, contains('Nota Teste'));
    expect(notesCsv, contains('Sim'));

    final jsonBackup = DataExporter.buildBackupJson(
      tasks: tasks,
      notes: notes,
      categories: categories,
      profile: const UserProfile(displayName: 'Bruno', username: 'bruno@dev'),
    );
    expect(jsonBackup, contains('"app": "Meu Caderno"'));
    expect(jsonBackup, contains('"displayName": "Bruno"'));
  });

  test('SyncService compacta fila offline (coalescing) e permite uso sem conta', () async {
    final storage = LocalStorageService();
    final api = ApiClient();

    SyncState currentState = SyncState.localOnly;
    int currentPending = 0;

    final sync = SyncService(
      storage: storage,
      api: api,
      onDataMerged: ({required categories, required tasks, required notes}) {},
      onStateChanged: (state, pending, _) {
        currentState = state;
        currentPending = pending;
      },
    );

    sync.initialize(
      user: null,
      initialQueue: const [],
      syncedIds: const {},
      lastSyncedAt: null,
    );

    expect(currentState, SyncState.localOnly);
    expect(sync.isCloudEnabled, isFalse);

    // 1. Cria tarefa offline e depois atualiza a mesma tarefa offline:
    // Deve compactar em uma única operação 'create' com título atualizado
    await sync.recordOperation(
      entityType: 'task',
      action: 'create',
      entityId: 't-offline-1',
      payload: {'id': 't-offline-1', 'title': 'Rascunho'},
    );
    await sync.recordOperation(
      entityType: 'task',
      action: 'update',
      entityId: 't-offline-1',
      payload: {'id': 't-offline-1', 'title': 'Versão Final'},
    );

    expect(currentPending, 1);

    // 2. Cria uma segunda tarefa offline e a exclui antes de sincronizar:
    // Ambas as operações para 't-offline-2' devem se anular
    await sync.recordOperation(
      entityType: 'task',
      action: 'create',
      entityId: 't-offline-2',
      payload: {'id': 't-offline-2', 'title': 'Temporária'},
    );
    expect(currentPending, 2);

    await sync.recordOperation(
      entityType: 'task',
      action: 'delete',
      entityId: 't-offline-2',
    );
    expect(currentPending, 1);

    sync.dispose();
  });

  testWidgets('SyncStatusIndicator exibe estado sutil e oculta no modo localOnly', (
    WidgetTester tester,
  ) async {
    // 1. Modo localOnly: não renderiza ícone na AppBar
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SyncStatusIndicator(state: SyncState.localOnly),
        ),
      ),
    );
    expect(find.byType(Tooltip), findsNothing);

    // 2. Modo pendingOffline: renderiza indicador discreto com Tooltip
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SyncStatusIndicator(
            state: SyncState.pendingOffline,
            pendingCount: 3,
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(Tooltip), findsOneWidget);
  });

  test('SQLite preserva 100% dos dados entre atualizações de versão e cria backup .bak', () async {
    final tempDir = await Directory.systemTemp.createTemp('caderno_sqlite_test_');
    final dbPath = p.join(tempDir.path, 'meu_caderno.db');

    try {
      // 1. Abre banco na versão 1 e grava dados
      final dbV1 = AppDatabase.forTesting(dbPath);
      await dbV1.open(overrideVersion: 1);
      final storageV1 = LocalStorageService(database: dbV1);

      await storageV1.loadSnapshot(
        defaultCategories: const [
          Category(id: 'c1', name: 'Pessoal', color: '#4A7C59', icon: 'User'),
        ],
        defaultTasks: const [
          Task(
            id: 't1',
            title: 'Tarefa Persistente SQLite',
            priority: Priority.high,
            status: TaskStatus.pending,
            categoryId: 'c1',
            createdAt: '2026-11-15T10:00:00.000Z',
            updatedAt: '2026-11-15T10:00:00.000Z',
          ),
        ],
        defaultNotes: const [
          Note(
            id: 'n1',
            title: 'Nota Importante',
            content: 'Nunca perder este texto',
            createdAt: '2026-11-15T10:00:00.000Z',
            updatedAt: '2026-11-15T10:00:00.000Z',
          ),
        ],
        defaultUnlockedBadges: const {'first_task': '2026-11-15T10:00:00.000Z'},
      );
      await storageV1.saveThemeMode('dark');
      await dbV1.close();

      // 2. Reabre o mesmo arquivo .db na versão 2 (simulando atualização do app)
      final dbV2 = AppDatabase.forTesting(dbPath);
      await dbV2.open(overrideVersion: 2);
      final storageV2 = LocalStorageService(database: dbV2);

      final snapshotAfterUpgrade = await storageV2.loadSnapshot(
        defaultCategories: const [],
        defaultTasks: const [],
        defaultNotes: const [],
        defaultUnlockedBadges: const {},
      );

      // Verifica que todos os registros continuam intactos e o backup .v1.bak foi criado
      expect(snapshotAfterUpgrade.tasks.length, 1);
      expect(snapshotAfterUpgrade.tasks.first.title, 'Tarefa Persistente SQLite');
      expect(snapshotAfterUpgrade.notes.length, 1);
      expect(snapshotAfterUpgrade.notes.first.content, 'Nunca perder este texto');
      expect(snapshotAfterUpgrade.categories.first.name, 'Pessoal');
      expect(await storageV2.loadThemeMode(), 'dark');
      expect(File('$dbPath.v1.bak').existsSync(), isTrue);

      await dbV2.close();
    } finally {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    }
  });
}
