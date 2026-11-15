import 'package:app/config/api_config.dart';
import 'package:app/models/models.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';

class ApiClient {
  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 4),
        receiveTimeout: const Duration(seconds: 6),
        sendTimeout: const Duration(seconds: 6),
        headers: {'Content-Type': 'application/json'},
      ),
    );
  }

  late final Dio _dio;
  bool _cookieInitialized = false;

  Future<void> _ensureInitialized() async {
    if (_cookieInitialized) return;
    _cookieInitialized = true;
    if (kIsWeb) return;
    try {
      final dir = await getApplicationSupportDirectory();
      final jar = PersistCookieJar(
        storage: FileStorage('${dir.path}/.cookies/'),
      );
      _dio.interceptors.add(CookieManager(jar));
    } catch (_) {
      _dio.interceptors.add(CookieManager(CookieJar()));
    }
  }

  Future<User> login(String username, String password) async {
    await _ensureInitialized();
    final res = await _dio.post<dynamic>(
      '/login',
      data: {'username': username, 'password': password},
    );
    return User.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<User> register(String username, String password) async {
    await _ensureInitialized();
    final res = await _dio.post<dynamic>(
      '/register',
      data: {'username': username, 'password': password},
    );
    return User.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<void> logout() async {
    await _ensureInitialized();
    try {
      await _dio.post<dynamic>('/logout');
    } catch (_) {}
  }

  Future<User?> getCurrentUser() async {
    await _ensureInitialized();
    try {
      final res = await _dio.get<dynamic>('/user');
      if (res.data is Map) {
        return User.fromJson(Map<String, dynamic>.from(res.data as Map));
      }
    } catch (_) {}
    return null;
  }

  // --- Categories ---
  Future<List<Category>> fetchCategories() async {
    await _ensureInitialized();
    final res = await _dio.get<dynamic>('/categories');
    final list = res.data as List<dynamic>? ?? const [];
    return list
        .whereType<Map<dynamic, dynamic>>()
        .map((e) => Category.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<Category> upsertCategory(Map<String, dynamic> data) async {
    await _ensureInitialized();
    final res = await _dio.post<dynamic>('/categories', data: data);
    return Category.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<void> deleteCategory(String id) async {
    await _ensureInitialized();
    await _dio.delete<dynamic>('/categories/$id');
  }

  // --- Tasks ---
  Future<List<Task>> fetchTasks() async {
    await _ensureInitialized();
    final res = await _dio.get<dynamic>('/tasks');
    final list = res.data as List<dynamic>? ?? const [];
    return list
        .whereType<Map<dynamic, dynamic>>()
        .map((e) => Task.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<Task> createTask(Map<String, dynamic> data) async {
    await _ensureInitialized();
    final res = await _dio.post<dynamic>('/tasks', data: data);
    return Task.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<void> updateTask(String id, Map<String, dynamic> data) async {
    await _ensureInitialized();
    await _dio.patch<dynamic>('/tasks/$id', data: data);
  }

  Future<void> deleteTask(String id) async {
    await _ensureInitialized();
    await _dio.delete<dynamic>('/tasks/$id');
  }

  // --- Notes ---
  Future<List<Note>> fetchNotes() async {
    await _ensureInitialized();
    final res = await _dio.get<dynamic>('/notes');
    final list = res.data as List<dynamic>? ?? const [];
    return list
        .whereType<Map<dynamic, dynamic>>()
        .map((e) => Note.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<Note> createNote(Map<String, dynamic> data) async {
    await _ensureInitialized();
    final res = await _dio.post<dynamic>('/notes', data: data);
    return Note.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<void> updateNote(String id, Map<String, dynamic> data) async {
    await _ensureInitialized();
    await _dio.patch<dynamic>('/notes/$id', data: data);
  }

  Future<void> deleteNote(String id) async {
    await _ensureInitialized();
    await _dio.delete<dynamic>('/notes/$id');
  }

  // --- AI Breakdown ---
  Future<List<Subtask>> generateSubtasks(String goal) async {
    await _ensureInitialized();
    final res = await _dio.post<dynamic>(
      '/ai/breakdown',
      data: {'goal': goal},
    );
    final map = res.data as Map<dynamic, dynamic>?;
    final list = map?['subtasks'] as List<dynamic>? ?? const [];
    final now = DateTime.now().microsecondsSinceEpoch;
    var idx = 0;
    return list.whereType<Map<dynamic, dynamic>>().map((item) {
      idx++;
      return Subtask(
        id: 'ai-$now-$idx',
        title: item['title']?.toString() ?? '',
        completed: false,
        priority: Priority.fromString(item['priority']?.toString()),
      );
    }).toList();
  }
}
