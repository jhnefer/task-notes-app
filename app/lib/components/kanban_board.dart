import 'package:app/components/recurring_task_dialog.dart';
import 'package:app/models/models.dart';
import 'package:app/themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class KanbanBoard extends StatelessWidget {
  const KanbanBoard({
    required this.tasks,
    required this.onStatusChange,
    required this.onEdit,
    required this.onDelete,
    required this.getCategoryName,
    super.key,
  });

  final List<Task> tasks;
  final void Function(String taskId, TaskStatus newStatus) onStatusChange;
  final ValueChanged<Task> onEdit;
  final ValueChanged<String> onDelete;
  final String Function(String? id) getCategoryName;

  @override
  Widget build(BuildContext context) {
    final pending = tasks.where((t) => t.status == TaskStatus.pending).toList();
    final inProgress = tasks
        .where((t) => t.status == TaskStatus.inProgress)
        .toList();
    final done = tasks.where((t) => t.status == TaskStatus.done).toList();

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.muted,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: TabBar(
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: AppColors.cardBackGround,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                  ),
                ],
              ),
              labelColor: AppColors.onPrimary,
              unselectedLabelColor: AppColors.onMuted,
              labelStyle: const TextStyle(
                fontFamily: 'Playfair Display',
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
              tabs: [
                Tab(text: 'Pendente (${pending.length})'),
                Tab(text: 'Andamento (${inProgress.length})'),
                Tab(text: 'Concluída (${done.length})'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 460,
            child: TabBarView(
              children: [
                _KanbanColumn(
                  status: TaskStatus.pending,
                  label: 'Pendente',
                  bgColor: const Color(0xFFF8FAFC),
                  tasks: pending,
                  onStatusChange: onStatusChange,
                  onEdit: onEdit,
                  onDelete: onDelete,
                  getCategoryName: getCategoryName,
                ),
                _KanbanColumn(
                  status: TaskStatus.inProgress,
                  label: 'Em Andamento',
                  bgColor: const Color(0xFFFFFBEB),
                  tasks: inProgress,
                  onStatusChange: onStatusChange,
                  onEdit: onEdit,
                  onDelete: onDelete,
                  getCategoryName: getCategoryName,
                ),
                _KanbanColumn(
                  status: TaskStatus.done,
                  label: 'Concluída',
                  bgColor: const Color(0xFFF0FDF4),
                  tasks: done,
                  onStatusChange: onStatusChange,
                  onEdit: onEdit,
                  onDelete: onDelete,
                  getCategoryName: getCategoryName,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KanbanColumn extends StatelessWidget {
  const _KanbanColumn({
    required this.status,
    required this.label,
    required this.bgColor,
    required this.tasks,
    required this.onStatusChange,
    required this.onEdit,
    required this.onDelete,
    required this.getCategoryName,
  });

  final TaskStatus status;
  final String label;
  final Color bgColor;
  final List<Task> tasks;
  final void Function(String taskId, TaskStatus newStatus) onStatusChange;
  final ValueChanged<Task> onEdit;
  final ValueChanged<String> onDelete;
  final String Function(String? id) getCategoryName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Playfair Display',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.muted,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${tasks.length}',
                  style: const TextStyle(
                    fontFamily: 'Caveat',
                    fontSize: 15,
                    color: AppColors.onMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: tasks.isEmpty
                ? const Center(
                    child: Text(
                      'Nenhuma tarefa',
                      style: TextStyle(
                        fontFamily: 'Caveat',
                        fontSize: 18,
                        color: AppColors.onMuted,
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: tasks.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return _KanbanCard(
                        task: task,
                        onStatusChange: (newStatus) =>
                            onStatusChange(task.id, newStatus),
                        onEdit: () => onEdit(task),
                        onDelete: () => onDelete(task.id),
                        getCategoryName: getCategoryName,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _KanbanCard extends StatelessWidget {
  const _KanbanCard({
    required this.task,
    required this.onStatusChange,
    required this.onEdit,
    required this.onDelete,
    required this.getCategoryName,
  });

  final Task task;
  final ValueChanged<TaskStatus> onStatusChange;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final String Function(String? id) getCategoryName;

  Color _priorityColor(Priority p) {
    return switch (p) {
      Priority.high => AppColors.chartPriorityHigh,
      Priority.medium => AppColors.chartPriorityMedium,
      Priority.low => AppColors.chartPriorityLow,
    };
  }

  @override
  Widget build(BuildContext context) {
    final pColor = _priorityColor(task.priority);
    final catName = getCategoryName(task.categoryId);
    final dueLabel = formatDueDateLabel(task.dueDate);
    final completedSubs = task.subtasks.where((s) => s.completed).length;
    final subPct = task.subtasks.isNotEmpty
        ? completedSubs / task.subtasks.length
        : 0.0;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: pColor, width: 4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Lora',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onPrimary,
                    ),
                  ),
                ),
                PopupMenuButton<TaskStatus>(
                  tooltip: 'Mover coluna',
                  icon: const Icon(
                    LucideIcons.arrowLeftRight,
                    size: 14,
                    color: AppColors.onMuted,
                  ),
                  onSelected: onStatusChange,
                  itemBuilder: (_) => TaskStatus.values
                      .where((s) => s != task.status)
                      .map(
                        (s) => PopupMenuItem(
                          value: s,
                          child: Text(
                            'Mover para: ${s.label}',
                            style: const TextStyle(
                              fontFamily: 'Lora',
                              fontSize: 12,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: onEdit,
                  icon: const Icon(
                    LucideIcons.pencil,
                    size: 14,
                    color: AppColors.onMuted,
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: onDelete,
                  icon: const Icon(
                    LucideIcons.trash2,
                    size: 14,
                    color: AppColors.destructive,
                  ),
                ),
              ],
            ),
            if (task.description != null && task.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                task.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Lora',
                  fontSize: 12,
                  color: AppColors.onMuted,
                ),
              ),
            ],
            if (task.subtasks.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.muted.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              LucideIcons.target,
                              size: 11,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Submetas: $completedSubs/${task.subtasks.length}',
                              style: const TextStyle(
                                fontFamily: 'Lora',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${(subPct * 100).round()}%',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.onMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: subPct,
                        minHeight: 4,
                        backgroundColor: AppColors.muted,
                        color: subPct == 1.0
                            ? AppColors.chartPriorityLow
                            : AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.muted,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    task.priority.label,
                    style: const TextStyle(
                      fontFamily: 'Caveat',
                      fontSize: 13,
                      color: AppColors.onMuted,
                    ),
                  ),
                ),
                if (catName.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.muted.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      catName,
                      style: const TextStyle(
                        fontFamily: 'Lora',
                        fontSize: 11,
                        color: AppColors.onMuted,
                      ),
                    ),
                  ),
                RecurrenceBadge(task: task),
                if (dueLabel != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        LucideIcons.clock,
                        size: 11,
                        color: AppColors.onMuted,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        dueLabel,
                        style: const TextStyle(
                          fontFamily: 'Lora',
                          fontSize: 11,
                          color: AppColors.onMuted,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
