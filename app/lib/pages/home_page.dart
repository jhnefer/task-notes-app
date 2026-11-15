import 'package:app/components/notification_panel.dart';
import 'package:app/models/models.dart';
import 'package:app/themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class HomePage extends StatelessWidget {
  const HomePage({
    this.tasks = const [],
    this.notes = const [],
    this.categories = const [],
    this.notifications = const [],
    this.onNavigateToTab,
    this.onQuickCreateTask,
    this.onResetData,
    super.key,
  });

  final List<Task> tasks;
  final List<Note> notes;
  final List<Category> categories;
  final List<TaskNotification> notifications;
  final ValueChanged<int>? onNavigateToTab;
  final VoidCallback? onQuickCreateTask;
  final VoidCallback? onResetData;

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Bom dia';
    if (h < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  String _getCategoryName(String? id) {
    if (id == null) return '';
    return categories
            .where((c) => c.id == id)
            .map((c) => c.name)
            .firstOrNull ??
        '';
  }

  @override
  Widget build(BuildContext context) {
    final total = tasks.length;
    final done = tasks.where((t) => t.status == TaskStatus.done).length;
    final inProgress = tasks
        .where((t) => t.status == TaskStatus.inProgress)
        .length;
    final overdue = tasks
        .where((t) => t.status != TaskStatus.done && isDueDatePast(t.dueDate))
        .length;

    final progressPct = total > 0 ? ((done / total) * 100).round() : 0;

    final upcomingTasks = tasks
        .where((t) => t.dueDate != null && t.status != TaskStatus.done)
        .toList()
      ..sort(
        (a, b) => (DateTime.tryParse(a.dueDate!) ?? DateTime.now()).compareTo(
          DateTime.tryParse(b.dueDate!) ?? DateTime.now(),
        ),
      );
    final topUpcoming = upcomingTasks.take(5).toList();

    final pinnedNotes = notes.where((n) => n.pinned).take(3).toList();
    final recentTasks = tasks
        .where((t) => t.status != TaskStatus.done)
        .take(5)
        .toList();

    final criticalCount = notifications
        .where((n) => n.urgency == NotificationUrgency.critical)
        .length;
    final highCount = notifications
        .where((n) => n.urgency == NotificationUrgency.high)
        .length;

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        clipBehavior: Clip.antiAlias,
        shape: const CircleBorder(),
        onPressed: onQuickCreateTask,
        child: const Icon(LucideIcons.filePlus2300),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Barra Superior (Resetar Dados)
              const SizedBox(height: 16),

              // 2. Saudação
              Row(
                children: [
                  Text(
                    '${_greeting()}!',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Caveat',
                      fontSize: 26,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    LucideIcons.sparkles,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // 3. Título Visão Geral
              Text(
                'Visão Geral',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.onPrimary,
                  fontFamily: 'Playfair Display',
                ),
              ),
              const SizedBox(height: 6),

              // 4. Data dinâmica
              Text(
                DateFormat(
                  "EEEE, d 'de' MMMM 'de' yyyy",
                  'pt_BR',
                ).format(DateTime.now()),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.onMuted,
                  fontFamily: 'Lora',
                ),
              ),
              const SizedBox(height: 20),

              // 5. Alerta de notificações
              if (criticalCount > 0 || highCount > 0) ...[
                NotificationAlert(critical: criticalCount, high: highCount),
                const SizedBox(height: 16),
              ],

              // 6. Grid de Cards
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 1.05,
                children: [
                  DashBoardCard(
                    title: 'Concluídas',
                    value: '$done',
                    subtitle: 'de $total tarefas',
                    icon: LucideIcons.checkSquare,
                    color: AppColors.chartPriorityLow,
                  ),
                  DashBoardCard(
                    title: 'Em andamento',
                    value: '$inProgress',
                    subtitle: 'tarefas ativas',
                    icon: LucideIcons.clock,
                    color: AppColors.chartPriorityMedium,
                  ),
                  DashBoardCard(
                    title: 'Em atraso',
                    value: '$overdue',
                    subtitle: 'precisam de atenção',
                    icon: LucideIcons.triangleAlert,
                    color: overdue > 0
                        ? AppColors.destructive
                        : AppColors.chartPriorityVeryHigh,
                  ),
                  DashBoardCard(
                    title: 'Anotações',
                    value: '${notes.length}',
                    subtitle: 'registros salvos',
                    icon: LucideIcons.fileText,
                    color: Colors.deepPurple.shade700,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 7. Card Progresso Geral
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.cardBackGround,
                  border: Border.all(color: AppColors.cardBorder, width: 2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              LucideIcons.trendingUp,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Progresso Geral',
                              style: TextStyle(
                                fontFamily: 'Playfair Display',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.onPrimary,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '$progressPct%',
                          style: const TextStyle(
                            fontFamily: 'Caveat',
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: SizedBox(
                        height: 12,
                        child: Stack(
                          children: [
                            Container(color: AppColors.muted),
                            FractionallySizedBox(
                              widthFactor: (progressPct / 100).clamp(0.0, 1.0),
                              child: Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.primary,
                                      AppColors.chartPriorityMedium,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$done de $total tarefas concluídas',
                          style: const TextStyle(
                            fontFamily: 'Lora',
                            fontSize: 12,
                            color: AppColors.onMuted,
                          ),
                        ),
                        if (progressPct == 100 && total > 0)
                          const Row(
                            children: [
                              Icon(
                                LucideIcons.sparkles,
                                size: 12,
                                color: AppColors.chartPriorityLow,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Tudo concluído!',
                                style: TextStyle(
                                  fontFamily: 'Caveat',
                                  fontSize: 14,
                                  color: AppColors.chartPriorityLow,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 8. Próximos Prazos
              _SectionCard(
                icon: LucideIcons.calendar,
                title: 'Próximos Prazos',
                actionLabel: 'Ver todas',
                onActionTap: () => onNavigateToTab?.call(1),
                emptyIcon: LucideIcons.calendar,
                emptyMessage: 'Nenhuma tarefa com prazo',
                children: topUpcoming.map((task) {
                  final due = formatDueDateLabel(task.dueDate);
                  final isLate = isDueDatePast(task.dueDate);
                  final catName = _getCategoryName(task.categoryId);
                  return _UpcomingTaskRow(
                    task: task,
                    categoryName: catName,
                    dueLabel: due,
                    isLate: isLate,
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // 9. Notas Fixadas
              _SectionCard(
                icon: LucideIcons.pin,
                title: 'Notas Fixadas',
                actionLabel: 'Ver todas',
                onActionTap: () => onNavigateToTab?.call(2),
                emptyIcon: LucideIcons.pin,
                emptyMessage: 'Nenhuma nota fixada',
                children: pinnedNotes.map((note) {
                  return InkWell(
                    onTap: () => onNavigateToTab?.call(2),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            note.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Lora',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            note.content,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Lora',
                              fontSize: 12,
                              color: AppColors.onMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // 10. Tarefas Recentes
              _SectionCard(
                icon: LucideIcons.checkSquare,
                title: 'Tarefas Recentes',
                actionLabel: 'Gerenciar',
                onActionTap: () => onNavigateToTab?.call(1),
                emptyIcon: LucideIcons.checkSquare,
                emptyMessage: 'Todas as tarefas concluídas!',
                children: recentTasks.map((task) {
                  final isInProgress = task.status == TaskStatus.inProgress;
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            task.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Lora',
                              fontSize: 14,
                              color: AppColors.onPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isInProgress
                                ? const Color(0xFFFEF3C7)
                                : AppColors.muted,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            isInProgress ? 'Em andamento' : 'Pendente',
                            style: TextStyle(
                              fontFamily: 'Lora',
                              fontSize: 11,
                              color: isInProgress
                                  ? const Color(0xFFB45309)
                                  : AppColors.onMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.actionLabel,
    required this.onActionTap,
    required this.emptyIcon,
    required this.emptyMessage,
    required this.children,
  });

  final IconData icon;
  final String title;
  final String actionLabel;
  final VoidCallback onActionTap;
  final IconData emptyIcon;
  final String emptyMessage;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.cardBackGround,
        border: Border.all(color: AppColors.cardBorder, width: 2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.muted.withValues(alpha: 0.4),
              border: const Border(
                bottom: BorderSide(color: AppColors.cardBorder),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 15, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Playfair Display',
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onPrimary,
                      ),
                    ),
                  ],
                ),
                InkWell(
                  onTap: onActionTap,
                  child: Row(
                    children: [
                      Text(
                        actionLabel,
                        style: const TextStyle(
                          fontFamily: 'Lora',
                          fontSize: 12,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        LucideIcons.arrowRight,
                        size: 12,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (children.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
              child: Column(
                children: [
                  Icon(
                    emptyIcon,
                    size: 28,
                    color: AppColors.onMuted.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    emptyMessage,
                    style: const TextStyle(
                      fontFamily: 'Caveat',
                      fontSize: 17,
                      color: AppColors.onMuted,
                    ),
                  ),
                ],
              ),
            )
          else
            ...children.asMap().entries.map((entry) {
              final idx = entry.key;
              final child = entry.value;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (idx > 0)
                    const Divider(height: 1, color: AppColors.cardBorder),
                  child,
                ],
              );
            }),
        ],
      ),
    );
  }
}

class _UpcomingTaskRow extends StatelessWidget {
  const _UpcomingTaskRow({
    required this.task,
    required this.categoryName,
    required this.dueLabel,
    required this.isLate,
  });

  final Task task;
  final String categoryName;
  final String? dueLabel;
  final bool isLate;

  @override
  Widget build(BuildContext context) {
    final (pColor, pBg) = switch (task.priority) {
      Priority.high => (
        AppColors.chartPriorityHigh,
        AppColors.chartPriorityHigh.withValues(alpha: 0.12),
      ),
      Priority.medium => (
        AppColors.chartPriorityMedium,
        AppColors.chartPriorityMedium.withValues(alpha: 0.12),
      ),
      Priority.low => (
        AppColors.chartPriorityLow,
        AppColors.chartPriorityLow.withValues(alpha: 0.12),
      ),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Lora',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.onPrimary,
                  ),
                ),
                if (categoryName.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    categoryName,
                    style: const TextStyle(
                      fontFamily: 'Lora',
                      fontSize: 11,
                      color: AppColors.onMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: pBg,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              task.priority.label,
              style: TextStyle(
                fontFamily: 'Caveat',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: pColor,
              ),
            ),
          ),
          if (dueLabel != null) ...[
            const SizedBox(width: 8),
            Text(
              dueLabel!,
              style: TextStyle(
                fontFamily: 'Lora',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isLate ? AppColors.destructive : AppColors.onMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class DashBoardCard extends StatelessWidget {
  const DashBoardCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    super.key,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackGround,
        border: Border.all(color: AppColors.cardBorder, width: 2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            Positioned(
              bottom: -40.0,
              right: -40.0,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontFamily: 'Lora',
                            fontSize: 14,
                            color: AppColors.onPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: color, size: 20),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    value,
                    style: TextStyle(
                      fontFamily: 'Playfair Display',
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Lora',
                      fontSize: 12,
                      color: AppColors.onMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
