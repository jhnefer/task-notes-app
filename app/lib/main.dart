import 'package:app/pages/main_layout.dart';
import 'package:app/services/local_storage_service.dart';
import 'package:app/themes/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Intl.defaultLocale = 'pt_BR';
  await initializeDateFormatting('pt_BR', null);

  runApp(const TaskApp());
}

class TaskApp extends StatefulWidget {
  const TaskApp({super.key});

  @override
  State<TaskApp> createState() => _TaskAppState();
}

class _TaskAppState extends State<TaskApp> {
  final LocalStorageService _storage = LocalStorageService();
  ThemeMode _themeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final saved = await _storage.loadThemeMode();
      if (saved != null && mounted) {
        setState(() {
          _themeMode = switch (saved) {
            'dark' => ThemeMode.dark,
            'system' => ThemeMode.system,
            _ => ThemeMode.light,
          };
        });
      }
    } catch (_) {}
  }

  Future<void> _setThemeMode(ThemeMode mode) async {
    setState(() => _themeMode = mode);
    try {
      await _storage.saveThemeMode(mode.name);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Meu Caderno',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: MainLayout(
        themeMode: _themeMode,
        onThemeModeChanged: _setThemeMode,
      ),
    );
  }
}
