import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

List<dynamic> _safeDecodeList(dynamic raw) {
  if (raw == null) return const [];
  if (raw is List) return raw;
  if (raw is String && raw.isNotEmpty) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) return decoded;
      if (decoded is String) {
        final second = jsonDecode(decoded);
        if (second is List) return second;
      }
    } catch (_) {}
  }
  return const [];
}

Map<String, dynamic>? _safeDecodeMap(dynamic raw) {
  if (raw == null) return null;
  if (raw is Map<String, dynamic>) return raw;
  if (raw is Map) return Map<String, dynamic>.from(raw);
  if (raw is String && raw.isNotEmpty) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
  }
  return null;
}

enum Priority {
  low('low', 'Baixa'),
  medium('medium', 'Média'),
  high('high', 'Alta');

  const Priority(this.value, this.label);
  final String value;
  final String label;

  static Priority fromString(String? val) {
    return Priority.values.firstWhere(
      (e) => e.value == val,
      orElse: () => Priority.medium,
    );
  }
}

enum TaskStatus {
  pending('pending', 'Pendente'),
  inProgress('in_progress', 'Em andamento'),
  done('done', 'Concluída');

  const TaskStatus(this.value, this.label);
  final String value;
  final String label;

  static TaskStatus fromString(String? val) {
    return TaskStatus.values.firstWhere(
      (e) => e.value == val,
      orElse: () => TaskStatus.pending,
    );
  }
}

enum RecurrenceFrequency {
  daily('daily', 'Diariamente'),
  weekly('weekly', 'Semanalmente'),
  monthly('monthly', 'Mensalmente');

  const RecurrenceFrequency(this.value, this.label);
  final String value;
  final String label;

  static RecurrenceFrequency fromString(String? val) {
    return RecurrenceFrequency.values.firstWhere(
      (e) => e.value == val,
      orElse: () => RecurrenceFrequency.weekly,
    );
  }
}

class Subtask {
  const Subtask({
    required this.id,
    required this.title,
    required this.completed,
    required this.priority,
  });

  final String id;
  final String title;
  final bool completed;
  final Priority priority;

  Subtask copyWith({
    String? id,
    String? title,
    bool? completed,
    Priority? priority,
  }) {
    return Subtask(
      id: id ?? this.id,
      title: title ?? this.title,
      completed: completed ?? this.completed,
      priority: priority ?? this.priority,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'completed': completed,
    'priority': priority.value,
  };

  factory Subtask.fromJson(Map<String, dynamic> json) => Subtask(
    id: json['id'] as String? ?? '',
    title: json['title'] as String? ?? '',
    completed: json['completed'] as bool? ?? false,
    priority: Priority.fromString(json['priority'] as String?),
  );
}

class RecurrenceRule {
  const RecurrenceRule({
    required this.frequency,
    required this.interval,
    this.endDate,
    this.maxOccurrences,
  });

  final RecurrenceFrequency frequency;
  final int interval;
  final String? endDate;
  final int? maxOccurrences;

  String get intervalLabel {
    if (interval == 1) return frequency.label;
    final unit = switch (frequency) {
      RecurrenceFrequency.daily => interval == 1 ? 'dia' : 'dias',
      RecurrenceFrequency.weekly => interval == 1 ? 'semana' : 'semanas',
      RecurrenceFrequency.monthly => interval == 1 ? 'mês' : 'meses',
    };
    return 'Cada $interval $unit';
  }

  String get summary {
    var text = intervalLabel;
    if (maxOccurrences != null) {
      text += ' (até $maxOccurrences ocorrências)';
    }
    if (endDate != null && endDate!.isNotEmpty) {
      final parsed = DateTime.tryParse(endDate!);
      if (parsed != null) {
        text += ' (até ${DateFormat('dd/MM/yyyy').format(parsed)})';
      }
    }
    return text;
  }

  Map<String, dynamic> toJson() => {
    'frequency': frequency.value,
    'interval': interval,
    if (endDate != null) 'endDate': endDate,
    if (maxOccurrences != null) 'maxOccurrences': maxOccurrences,
  };

  factory RecurrenceRule.fromJson(Map<String, dynamic> json) => RecurrenceRule(
    frequency: RecurrenceFrequency.fromString(json['frequency'] as String?),
    interval: (json['interval'] as num?)?.toInt() ?? 1,
    endDate: json['endDate'] as String?,
    maxOccurrences: (json['maxOccurrences'] as num?)?.toInt(),
  );
}

class Task {
  const Task({
    required this.id,
    required this.title,
    this.description,
    required this.priority,
    required this.status,
    this.categoryId,
    this.dueDate,
    required this.createdAt,
    required this.updatedAt,
    this.tags = const [],
    this.recurrence,
    this.parentTaskId,
    this.occurrenceDate,
    this.subtasks = const [],
  });

  final String id;
  final String title;
  final String? description;
  final Priority priority;
  final TaskStatus status;
  final String? categoryId;
  final String? dueDate;
  final String createdAt;
  final String updatedAt;
  final List<String> tags;
  final RecurrenceRule? recurrence;
  final String? parentTaskId;
  final String? occurrenceDate;
  final List<Subtask> subtasks;

  Task copyWith({
    String? id,
    String? title,
    String? description,
    Priority? priority,
    TaskStatus? status,
    String? categoryId,
    bool clearCategoryId = false,
    String? dueDate,
    bool clearDueDate = false,
    String? createdAt,
    String? updatedAt,
    List<String>? tags,
    RecurrenceRule? recurrence,
    List<Subtask>? subtasks,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      categoryId: clearCategoryId ? null : (categoryId ?? this.categoryId),
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tags: tags ?? this.tags,
      recurrence: recurrence ?? this.recurrence,
      parentTaskId: parentTaskId,
      occurrenceDate: occurrenceDate,
      subtasks: subtasks ?? this.subtasks,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    if (description != null) 'description': description,
    'priority': priority.value,
    'status': status.value,
    if (categoryId != null) 'categoryId': categoryId,
    if (dueDate != null) 'dueDate': dueDate,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    'tags': tags,
    if (recurrence != null) 'recurrence': recurrence!.toJson(),
    if (parentTaskId != null) 'parentTaskId': parentTaskId,
    if (occurrenceDate != null) 'occurrenceDate': occurrenceDate,
    'subtasks': subtasks.map((s) => s.toJson()).toList(),
  };

  factory Task.fromJson(Map<String, dynamic> json) {
    final nowIso = DateTime.now().toIso8601String();
    final rawTags = _safeDecodeList(json['tags']);
    final rawSubtasks = _safeDecodeList(json['subtasks']);
    final recMap = _safeDecodeMap(json['recurrence']);
    final desc = json['description'] as String?;

    return Task(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: (desc != null && desc.isNotEmpty) ? desc : null,
      priority: Priority.fromString(json['priority'] as String?),
      status: TaskStatus.fromString(json['status'] as String?),
      categoryId: json['categoryId'] as String?,
      dueDate: json['dueDate'] as String?,
      createdAt: json['createdAt'] as String? ?? nowIso,
      updatedAt: json['updatedAt'] as String? ?? nowIso,
      tags: rawTags.map((e) => e.toString()).toList(),
      recurrence: recMap != null ? RecurrenceRule.fromJson(recMap) : null,
      parentTaskId: json['parentTaskId'] as String?,
      occurrenceDate: json['occurrenceDate'] as String?,
      subtasks: rawSubtasks
          .whereType<Map<dynamic, dynamic>>()
          .map((m) => Subtask.fromJson(Map<String, dynamic>.from(m)))
          .toList(),
    );
  }
}

class Note {
  const Note({
    required this.id,
    required this.title,
    required this.content,
    this.categoryId,
    required this.createdAt,
    required this.updatedAt,
    this.tags = const [],
    this.pinned = false,
  });

  final String id;
  final String title;
  final String content;
  final String? categoryId;
  final String createdAt;
  final String updatedAt;
  final List<String> tags;
  final bool pinned;

  Note copyWith({
    String? id,
    String? title,
    String? content,
    String? categoryId,
    bool clearCategoryId = false,
    String? createdAt,
    String? updatedAt,
    List<String>? tags,
    bool? pinned,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      categoryId: clearCategoryId ? null : (categoryId ?? this.categoryId),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tags: tags ?? this.tags,
      pinned: pinned ?? this.pinned,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    if (categoryId != null) 'categoryId': categoryId,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    'tags': tags,
    'pinned': pinned,
  };

  factory Note.fromJson(Map<String, dynamic> json) {
    final nowIso = DateTime.now().toIso8601String();
    final rawTags = _safeDecodeList(json['tags']);
    final pinnedVal = json['pinned'];
    final isPinned = pinnedVal is bool
        ? pinnedVal
        : (pinnedVal is num ? pinnedVal != 0 : false);

    return Note(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      categoryId: json['categoryId'] as String?,
      createdAt: json['createdAt'] as String? ?? nowIso,
      updatedAt: json['updatedAt'] as String? ?? nowIso,
      tags: rawTags.map((e) => e.toString()).toList(),
      pinned: isPinned,
    );
  }
}

Color parseHexColor(String hex) {
  final cleaned = hex.replaceFirst('#', '');
  final val = int.tryParse('FF$cleaned', radix: 16);
  return val != null ? Color(val) : const Color(0xFFC0533A);
}

IconData iconDataFromName(String icon) {
  return switch (icon) {
    'User' => LucideIcons.user,
    'Briefcase' => LucideIcons.briefcase,
    'BookOpen' => LucideIcons.bookOpen,
    'Heart' => LucideIcons.heart,
    'DollarSign' => LucideIcons.dollarSign,
    'Home' => LucideIcons.house,
    'Star' => LucideIcons.star,
    'Zap' => LucideIcons.zap,
    'Globe' => LucideIcons.globe,
    'Music' => LucideIcons.music,
    'Camera' => LucideIcons.camera,
    'Coffee' => LucideIcons.coffee,
    'Smile' => LucideIcons.smile,
    'Target' => LucideIcons.target,
    'Award' => LucideIcons.award,
    _ => LucideIcons.tag,
  };
}

class Category {
  const Category({
    required this.id,
    required this.name,
    required this.color,
    required this.icon,
  });

  final String id;
  final String name;
  final String color;
  final String icon;

  Color get parsedColor => parseHexColor(color);
  IconData get iconData => iconDataFromName(icon);

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'color': color,
    'icon': icon,
  };

  factory Category.fromJson(Map<String, dynamic> json) => Category(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    color: json['color'] as String? ?? '#C0533A',
    icon: json['icon'] as String? ?? 'Tag',
  );
}

class User {
  const User({required this.id, required this.username});
  final String id;
  final String username;

  Map<String, dynamic> toJson() => {'id': id, 'username': username};

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'] as String? ?? '',
    username: json['username'] as String? ?? '',
  );
}

enum SyncState {
  localOnly,
  synced,
  syncing,
  pendingOffline,
}

class SyncOperation {
  const SyncOperation({
    required this.id,
    required this.entityType,
    required this.action,
    required this.entityId,
    this.payload,
    required this.updatedAt,
  });

  final String id;
  final String entityType; // 'category' | 'task' | 'note'
  final String action; // 'create' | 'update' | 'delete'
  final String entityId;
  final Map<String, dynamic>? payload;
  final String updatedAt;

  SyncOperation copyWith({
    String? action,
    Map<String, dynamic>? payload,
    String? updatedAt,
  }) {
    return SyncOperation(
      id: id,
      entityType: entityType,
      action: action ?? this.action,
      entityId: entityId,
      payload: payload ?? this.payload,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'entityType': entityType,
    'action': action,
    'entityId': entityId,
    if (payload != null) 'payload': payload,
    'updatedAt': updatedAt,
  };

  factory SyncOperation.fromJson(Map<String, dynamic> json) => SyncOperation(
    id: json['id'] as String? ?? '',
    entityType: json['entityType'] as String? ?? '',
    action: json['action'] as String? ?? '',
    entityId: json['entityId'] as String? ?? '',
    payload: _safeDecodeMap(json['payload']),
    updatedAt:
        json['updatedAt'] as String? ?? DateTime.now().toIso8601String(),
  );
}

class UserProfile {
  const UserProfile({
    this.displayName = 'Bruno',
    this.username = 'nomedocabra@logado.com',
    this.avatarIcon = 'User',
    this.avatarColor = '#C0533A',
  });

  final String displayName;
  final String username;
  final String avatarIcon;
  final String avatarColor;

  Color get parsedColor => parseHexColor(avatarColor);
  IconData get iconData => iconDataFromName(avatarIcon);

  UserProfile copyWith({
    String? displayName,
    String? username,
    String? avatarIcon,
    String? avatarColor,
  }) {
    return UserProfile(
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      avatarIcon: avatarIcon ?? this.avatarIcon,
      avatarColor: avatarColor ?? this.avatarColor,
    );
  }

  Map<String, dynamic> toJson() => {
    'displayName': displayName,
    'username': username,
    'avatarIcon': avatarIcon,
    'avatarColor': avatarColor,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    displayName: json['displayName'] as String? ?? 'Bruno',
    username: json['username'] as String? ?? 'Modo Offline',
    avatarIcon: json['avatarIcon'] as String? ?? 'User',
    avatarColor: json['avatarColor'] as String? ?? '#C0533A',
  );
}

class NotificationSettings {
  const NotificationSettings({
    this.enabled = true,
    this.criticalAlerts = true,
    this.highAlerts = true,
    this.mediumAlerts = true,
    this.soundAndVibration = true,
  });

  final bool enabled;
  final bool criticalAlerts;
  final bool highAlerts;
  final bool mediumAlerts;
  final bool soundAndVibration;

  NotificationSettings copyWith({
    bool? enabled,
    bool? criticalAlerts,
    bool? highAlerts,
    bool? mediumAlerts,
    bool? soundAndVibration,
  }) {
    return NotificationSettings(
      enabled: enabled ?? this.enabled,
      criticalAlerts: criticalAlerts ?? this.criticalAlerts,
      highAlerts: highAlerts ?? this.highAlerts,
      mediumAlerts: mediumAlerts ?? this.mediumAlerts,
      soundAndVibration: soundAndVibration ?? this.soundAndVibration,
    );
  }

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'criticalAlerts': criticalAlerts,
    'highAlerts': highAlerts,
    'mediumAlerts': mediumAlerts,
    'soundAndVibration': soundAndVibration,
  };

  factory NotificationSettings.fromJson(Map<String, dynamic> json) =>
      NotificationSettings(
        enabled: json['enabled'] as bool? ?? true,
        criticalAlerts: json['criticalAlerts'] as bool? ?? true,
        highAlerts: json['highAlerts'] as bool? ?? true,
        mediumAlerts: json['mediumAlerts'] as bool? ?? true,
        soundAndVibration: json['soundAndVibration'] as bool? ?? true,
      );
}

enum NotificationUrgency { critical, high, medium, low }

class TaskNotification {
  const TaskNotification({
    required this.taskId,
    required this.title,
    required this.dueDate,
    required this.hoursUntilDue,
    required this.urgency,
    required this.message,
  });

  final String taskId;
  final String title;
  final String dueDate;
  final int hoursUntilDue;
  final NotificationUrgency urgency;
  final String message;
}

enum BadgeRarity { common, uncommon, rare, epic, legendary }

class AchievementBadge {
  const AchievementBadge({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.rarity,
    this.unlockedAt,
  });

  final String id;
  final String name;
  final String description;
  final String icon;
  final BadgeRarity rarity;
  final String? unlockedAt;

  bool get isUnlocked => unlockedAt != null;

  AchievementBadge copyWith({String? unlockedAt}) {
    return AchievementBadge(
      id: id,
      name: name,
      description: description,
      icon: icon,
      rarity: rarity,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }
}

const List<AchievementBadge> kAllBadgeDefinitions = [
  AchievementBadge(
    id: 'first_task',
    name: 'Primeiro Passo',
    description: 'Crie sua primeira tarefa',
    icon: '🚀',
    rarity: BadgeRarity.common,
  ),
  AchievementBadge(
    id: 'first_completion',
    name: 'Conquistador',
    description: 'Conclua sua primeira tarefa',
    icon: '✅',
    rarity: BadgeRarity.common,
  ),
  AchievementBadge(
    id: 'five_completed',
    name: 'Cinco Vitórias',
    description: 'Conclua 5 tarefas',
    icon: '🎯',
    rarity: BadgeRarity.uncommon,
  ),
  AchievementBadge(
    id: 'ten_completed',
    name: 'Dez Vezes Campeão',
    description: 'Conclua 10 tarefas',
    icon: '🏆',
    rarity: BadgeRarity.uncommon,
  ),
  AchievementBadge(
    id: 'fifty_completed',
    name: 'Mestre das Tarefas',
    description: 'Conclua 50 tarefas',
    icon: '👑',
    rarity: BadgeRarity.rare,
  ),
  AchievementBadge(
    id: 'hundred_completed',
    name: 'Lenda Viva',
    description: 'Conclua 100 tarefas',
    icon: '⭐',
    rarity: BadgeRarity.legendary,
  ),
  AchievementBadge(
    id: 'streak_3_days',
    name: 'Sequência de 3',
    description: 'Conclua tarefas por 3 dias consecutivos',
    icon: '🔥',
    rarity: BadgeRarity.uncommon,
  ),
  AchievementBadge(
    id: 'streak_7_days',
    name: 'Semana Perfeita',
    description: 'Conclua tarefas por 7 dias consecutivos',
    icon: '🌟',
    rarity: BadgeRarity.rare,
  ),
  AchievementBadge(
    id: 'streak_30_days',
    name: 'Mês Implacável',
    description: 'Conclua tarefas por 30 dias consecutivos',
    icon: '💎',
    rarity: BadgeRarity.epic,
  ),
  AchievementBadge(
    id: 'high_priority_master',
    name: 'Domador de Prioridades',
    description: 'Conclua 10 tarefas de alta prioridade',
    icon: '⚡',
    rarity: BadgeRarity.rare,
  ),
  AchievementBadge(
    id: 'category_master',
    name: 'Especialista em Categorias',
    description: 'Conclua 5 tarefas em uma mesma categoria',
    icon: '📚',
    rarity: BadgeRarity.uncommon,
  ),
  AchievementBadge(
    id: 'speed_demon',
    name: 'Demônio da Velocidade',
    description: 'Conclua uma tarefa em menos de 1 hora',
    icon: '⚡',
    rarity: BadgeRarity.rare,
  ),
  AchievementBadge(
    id: 'perfectionist',
    name: 'Perfeccionista',
    description: 'Conclua uma tarefa de alta prioridade com prazo',
    icon: '🎨',
    rarity: BadgeRarity.uncommon,
  ),
  AchievementBadge(
    id: 'night_owl',
    name: 'Coruja Noturna',
    description: 'Conclua uma tarefa entre 22h e 6h',
    icon: '🦉',
    rarity: BadgeRarity.uncommon,
  ),
  AchievementBadge(
    id: 'early_bird',
    name: 'Madrugador',
    description: 'Conclua uma tarefa entre 5h e 8h',
    icon: '🌅',
    rarity: BadgeRarity.uncommon,
  ),
];

String? formatDueDateLabel(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty) return null;
  final d = DateTime.tryParse(dateStr);
  if (d == null) return null;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(d.year, d.month, d.day);
  final diff = target.difference(today).inDays;
  if (diff == 0) return 'Hoje';
  if (diff == 1) return 'Amanhã';
  return DateFormat("d 'de' MMM", 'pt_BR').format(d);
}

bool isDueDatePast(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty) return false;
  final d = DateTime.tryParse(dateStr);
  if (d == null) return false;
  return d.isBefore(DateTime.now());
}
