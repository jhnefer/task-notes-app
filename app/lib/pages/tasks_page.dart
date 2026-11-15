import 'package:app/components/kanban_board.dart';
import 'package:app/components/recurring_task_dialog.dart';
import 'package:app/components/task_dialog.dart';
import 'package:app/models/models.dart';
import 'package:app/themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class TasksPage extends StatefulWidget {
  const TasksPage({
    required this.tasks,
    required this.categories,
    required this.onAddTask,
    required this.onUpdateTask,
    required this.onDeleteTask,
    required this.onToggleTaskStatus,
    required this.onToggleSubtask,
    this.onAiBreakdown,
    super.key,
  });

  final List<Task> tasks;
  final List<Category> categories;
  final ValueChanged<Task> onAddTask;
  final ValueChanged<Task> onUpdateTask;
  final ValueChanged<String> onDeleteTask;
  final ValueChanged<String> onToggleTaskStatus;
  final void Function(String taskId, String subtaskId) onToggleSubtask;
  final Future<List<Subtask>> Function(String goal)? onAiBreakdown;

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  final _searchController = TextEditingController();
  String _search = '';
  Priority? _filterPriority;
  TaskStatus? _filterStatus;
  String _filterCategory = 'all';
  bool _showFilters = false;
  bool _isKanban = false;
  final Map<String, bool> _expandedTasks = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getCategoryName(String? id) {
    if (id == null) return '';
    return widget.categories
            .where((c) => c.id == id)
            .map((c) => c.name)
            .firstOrNull ??
        '';
  }

  List<Task> get _filteredTasks {
    return widget.tasks.where((t) {
      final q = _search.toLowerCase();
      final matchSearch =
          q.isEmpty ||
          t.title.toLowerCase().contains(q) ||
          (t.description?.toLowerCase().contains(q) ?? false) ||
          t.tags.any((tag) => tag.toLowerCase().contains(q));
      final matchPriority =
          _filterPriority == null || t.priority == _filterPriority;
      final matchStatus = _filterStatus == null || t.status == _filterStatus;
      final matchCategory =
          _filterCategory == 'all' ||
          (_filterCategory == 'none'
              ? t.categoryId == null
              : t.categoryId == _filterCategory);
      return matchSearch && matchPriority && matchStatus && matchCategory;
    }).toList();
  }

  int get _activeFiltersCount =>
      (_filterPriority != null ? 1 : 0) +
      (_filterStatus != null ? 1 : 0) +
      (_filterCategory != 'all' ? 1 : 0);

  void _handleToggleTask(Task task) {
    if (task.status != TaskStatus.done && task.subtasks.isNotEmpty) {
      final pendingCount = task.subtasks.where((s) => !s.completed).length;
      if (pendingCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.chartPriorityMedium,
            content: Text(
              '⚠️ Esta meta possui $pendingCount submeta${pendingCount > 1 ? 's' : ''} pendente${pendingCount > 1 ? 's' : ''}. Complete todas antes de finalizá-la!',
            ),
          ),
        );
        return;
      }
    }
    widget.onToggleTaskStatus(task.id);
  }

  void _handleStatusChange(String taskId, TaskStatus newStatus) {
    final task = widget.tasks.where((t) => t.id == taskId).firstOrNull;
    if (task == null) return;

    if (newStatus == TaskStatus.done && task.subtasks.isNotEmpty) {
      final pendingCount = task.subtasks.where((s) => !s.completed).length;
      if (pendingCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.chartPriorityMedium,
            content: Text(
              '⚠️ Esta meta possui $pendingCount submeta${pendingCount > 1 ? 's' : ''} pendente${pendingCount > 1 ? 's' : ''}. Complete todas antes de finalizá-la!',
            ),
          ),
        );
        return;
      }
    }
    widget.onUpdateTask(task.copyWith(status: newStatus));
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredTasks;
    final grouped = <TaskStatus, List<Task>>{
      TaskStatus.inProgress: filtered
          .where((t) => t.status == TaskStatus.inProgress)
          .toList(),
      TaskStatus.pending: filtered
          .where((t) => t.status == TaskStatus.pending)
          .toList(),
      TaskStatus.done: filtered
          .where((t) => t.status == TaskStatus.done)
          .toList(),
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tarefas',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.onPrimary,
                            ),
                      ),
                      Text(
                        '${filtered.length} de ${widget.tasks.length} tarefas',
                        style: const TextStyle(
                          fontFamily: 'Lora',
                          fontSize: 13,
                          color: AppColors.onMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Action buttons row
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      showRecurringTaskDialog(
                        context,
                        categories: widget.categories,
                        onSave: widget.onAddTask,
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.border),
                      foregroundColor: AppColors.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(LucideIcons.repeat2, size: 15),
                    label: const Text(
                      'Recorrente',
                      style: TextStyle(fontFamily: 'Lora', fontSize: 13),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () {
                      showTaskDialog(
                        context,
                        categories: widget.categories,
                        onSave: widget.onAddTask,
                        onAiBreakdown: widget.onAiBreakdown,
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(LucideIcons.plus, size: 15),
                    label: const Text(
                      'Nova Tarefa',
                      style: TextStyle(fontFamily: 'Lora', fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // View toggle + Search + Filter button
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: AppColors.muted,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        _ViewToggleBtn(
                          icon: LucideIcons.layoutList,
                          active: !_isKanban,
                          onTap: () => setState(() => _isKanban = false),
                        ),
                        _ViewToggleBtn(
                          icon: LucideIcons.columns3,
                          active: _isKanban,
                          onTap: () => setState(() => _isKanban = true),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _search = v),
                      style: const TextStyle(fontFamily: 'Lora', fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Buscar tarefas...',
                        prefixIcon: const Icon(LucideIcons.search, size: 16),
                        isDense: true,
                        filled: true,
                        fillColor: AppColors.cardBackGround,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () =>
                        setState(() => _showFilters = !_showFilters),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: _showFilters ? AppColors.muted : null,
                      side: const BorderSide(color: AppColors.border),
                      foregroundColor: AppColors.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(LucideIcons.listFilter, size: 15),
                    label: Row(
                      children: [
                        const Text(
                          'Filtros',
                          style: TextStyle(fontFamily: 'Lora', fontSize: 12),
                        ),
                        if (_activeFiltersCount > 0) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$_activeFiltersCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),

              // Filter panel
              if (_showFilters) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.muted.withValues(alpha: 0.6),
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<Priority?>(
                              initialValue: _filterPriority,
                              decoration: const InputDecoration(
                                labelText: 'Prioridade',
                                isDense: true,
                              ),
                              items: [
                                const DropdownMenuItem<Priority?>(
                                  value: null,
                                  child: Text('Todas'),
                                ),
                                ...Priority.values.map(
                                  (p) => DropdownMenuItem(
                                    value: p,
                                    child: Text(p.label),
                                  ),
                                ),
                              ],
                              onChanged: (v) =>
                                  setState(() => _filterPriority = v),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<TaskStatus?>(
                              initialValue: _filterStatus,
                              decoration: const InputDecoration(
                                labelText: 'Status',
                                isDense: true,
                              ),
                              items: [
                                const DropdownMenuItem<TaskStatus?>(
                                  value: null,
                                  child: Text('Todos'),
                                ),
                                ...TaskStatus.values.map(
                                  (s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s.label),
                                  ),
                                ),
                              ],
                              onChanged: (v) =>
                                  setState(() => _filterStatus = v),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _filterCategory,
                              decoration: const InputDecoration(
                                labelText: 'Categoria',
                                isDense: true,
                              ),
                              items: [
                                const DropdownMenuItem(
                                  value: 'all',
                                  child: Text('Todas'),
                                ),
                                const DropdownMenuItem(
                                  value: 'none',
                                  child: Text('Sem categoria'),
                                ),
                                ...widget.categories.map(
                                  (c) => DropdownMenuItem(
                                    value: c.id,
                                    child: Text(c.name),
                                  ),
                                ),
                              ],
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() => _filterCategory = v);
                                }
                              },
                            ),
                          ),
                          if (_activeFiltersCount > 0) ...[
                            const SizedBox(width: 10),
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _filterPriority = null;
                                  _filterStatus = null;
                                  _filterCategory = 'all';
                                });
                              },
                              icon: const Icon(
                                LucideIcons.x,
                                size: 14,
                                color: AppColors.destructive,
                              ),
                              label: const Text(
                                'Limpar',
                                style: TextStyle(color: AppColors.destructive),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // Content
              if (_isKanban)
                KanbanBoard(
                  tasks: filtered,
                  onStatusChange: _handleStatusChange,
                  onEdit: (task) {
                    showTaskDialog(
                      context,
                      task: task,
                      categories: widget.categories,
                      onSave: widget.onUpdateTask,
                      onAiBreakdown: widget.onAiBreakdown,
                    );
                  },
                  onDelete: widget.onDeleteTask,
                  getCategoryName: _getCategoryName,
                )
              else if (filtered.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Column(
                      children: [
                        Text(
                          'Nenhuma tarefa encontrada',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(color: AppColors.onMuted),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _search.isNotEmpty || _activeFiltersCount > 0
                              ? 'Tente ajustar os filtros de busca'
                              : 'Clique em "Nova Tarefa" para começar',
                          style: const TextStyle(
                            fontFamily: 'Caveat',
                            fontSize: 18,
                            color: AppColors.onMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...([
                  TaskStatus.inProgress,
                  TaskStatus.pending,
                  TaskStatus.done,
                ]).map((status) {
                  final group = grouped[status] ?? [];
                  if (group.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.only(bottom: 3),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.4,
                                    ),
                                    width: 2,
                                  ),
                                ),
                              ),
                              child: Text(
                                status.label,
                                style: const TextStyle(
                                  fontFamily: 'Playfair Display',
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.onPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${group.length}',
                              style: const TextStyle(
                                fontFamily: 'Caveat',
                                fontSize: 17,
                                color: AppColors.onMuted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...group.map((task) {
                          final isExpanded = _expandedTasks[task.id] ?? false;
                          return _TaskCardItem(
                            task: task,
                            categoryName: _getCategoryName(task.categoryId),
                            isExpanded: isExpanded,
                            onToggleExpand: () {
                              setState(() {
                                _expandedTasks[task.id] = !isExpanded;
                              });
                            },
                            onToggleStatus: () => _handleToggleTask(task),
                            onToggleSubtask: (subId) =>
                                widget.onToggleSubtask(task.id, subId),
                            onEdit: () {
                              showTaskDialog(
                                context,
                                task: task,
                                categories: widget.categories,
                                onSave: widget.onUpdateTask,
                                onAiBreakdown: widget.onAiBreakdown,
                              );
                            },
                            onDelete: () => widget.onDeleteTask(task.id),
                          );
                        }),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}

class _ViewToggleBtn extends StatelessWidget {
  const _ViewToggleBtn({
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: active ? AppColors.cardBackGround : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 16,
          color: active ? AppColors.onPrimary : AppColors.onMuted,
        ),
      ),
    );
  }
}

class _TaskCardItem extends StatelessWidget {
  const _TaskCardItem({
    required this.task,
    required this.categoryName,
    required this.isExpanded,
    required this.onToggleExpand,
    required this.onToggleStatus,
    required this.onToggleSubtask,
    required this.onEdit,
    required this.onDelete,
  });

  final Task task;
  final String categoryName;
  final bool isExpanded;
  final VoidCallback onToggleExpand;
  final VoidCallback onToggleStatus;
  final ValueChanged<String> onToggleSubtask;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isDone = task.status == TaskStatus.done;
    final due = formatDueDateLabel(task.dueDate);
    final isLate = !isDone && isDueDatePast(task.dueDate);
    final pColor = switch (task.priority) {
      Priority.high => AppColors.chartPriorityHigh,
      Priority.medium => AppColors.chartPriorityMedium,
      Priority.low => AppColors.chartPriorityLow,
    };

    final completedSubs = task.subtasks.where((s) => s.completed).length;
    final totalSubs = task.subtasks.length;
    final subPct = totalSubs > 0 ? completedSubs / totalSubs : 0.0;

    return Opacity(
      opacity: isDone ? 0.72 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.cardBackGround,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: pColor, width: 4),
            ),
          ),
          child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Checkbox
            InkWell(
              onTap: onToggleStatus,
              borderRadius: BorderRadius.circular(5),
              child: Container(
                margin: const EdgeInsets.only(top: 2),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: isDone
                      ? AppColors.chartPriorityLow
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: isDone
                        ? AppColors.chartPriorityLow
                        : AppColors.border,
                    width: 2,
                  ),
                ),
                child: isDone
                    ? const Icon(
                        LucideIcons.check,
                        size: 13,
                        color: Colors.white,
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          task.title,
                          style: TextStyle(
                            fontFamily: 'Lora',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDone
                                ? AppColors.onMuted
                                : AppColors.onPrimary,
                            decoration: isDone
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: onEdit,
                        icon: const Icon(
                          LucideIcons.pencil,
                          size: 15,
                          color: AppColors.onMuted,
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: onDelete,
                        icon: const Icon(
                          LucideIcons.trash2,
                          size: 15,
                          color: AppColors.destructive,
                        ),
                      ),
                    ],
                  ),
                  if (task.description != null &&
                      task.description!.isNotEmpty) ...[
                    const SizedBox(height: 2),
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

                  // Subtasks section
                  if (totalSubs > 0) ...[
                    const SizedBox(height: 10),
                    const Divider(height: 1, color: AppColors.border),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: onToggleExpand,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                LucideIcons.target,
                                size: 13,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Submetas ($completedSubs/$totalSubs)',
                                style: const TextStyle(
                                  fontFamily: 'Lora',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '(${(subPct * 100).round()}%)',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.onMuted,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                isExpanded ? 'Ocultar' : 'Ver submetas',
                                style: const TextStyle(
                                  fontFamily: 'Lora',
                                  fontSize: 11,
                                  color: AppColors.onMuted,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                isExpanded
                                    ? LucideIcons.chevronUp
                                    : LucideIcons.chevronDown,
                                size: 13,
                                color: AppColors.onMuted,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: subPct,
                        minHeight: 5,
                        backgroundColor: AppColors.muted,
                        color: subPct == 1.0
                            ? AppColors.chartPriorityLow
                            : AppColors.primary,
                      ),
                    ),
                    if (isExpanded) ...[
                      const SizedBox(height: 8),
                      ...task.subtasks.map(
                        (st) => InkWell(
                          onTap: () => onToggleSubtask(st.id),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Icon(
                                  st.completed
                                      ? LucideIcons.squareCheck
                                      : LucideIcons.square,
                                  size: 15,
                                  color: st.completed
                                      ? AppColors.chartPriorityLow
                                      : AppColors.onMuted,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    st.title,
                                    style: TextStyle(
                                      fontFamily: 'Lora',
                                      fontSize: 12,
                                      decoration: st.completed
                                          ? TextDecoration.lineThrough
                                          : null,
                                      color: st.completed
                                          ? AppColors.onMuted
                                          : AppColors.onPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],

                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: pColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          task.priority.label,
                          style: TextStyle(
                            fontFamily: 'Caveat',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: pColor,
                          ),
                        ),
                      ),
                      if (categoryName.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.muted,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                LucideIcons.tag,
                                size: 10,
                                color: AppColors.onMuted,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                categoryName,
                                style: const TextStyle(
                                  fontFamily: 'Lora',
                                  fontSize: 11,
                                  color: AppColors.onMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      RecurrenceBadge(task: task),
                      if (due != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                               isLate
                                  ? LucideIcons.circleAlert
                                  : LucideIcons.clock,
                              size: 11,
                              color: isLate
                                  ? AppColors.destructive
                                  : AppColors.onMuted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              due,
                              style: TextStyle(
                                fontFamily: 'Lora',
                                fontSize: 11,
                                fontWeight: isLate
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: isLate
                                    ? AppColors.destructive
                                    : AppColors.onMuted,
                              ),
                            ),
                          ],
                        ),
                      ...task.tags.map(
                        (tag) => Text(
                          '#$tag',
                          style: const TextStyle(
                            fontFamily: 'Lora',
                            fontSize: 11,
                            color: AppColors.onMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}
