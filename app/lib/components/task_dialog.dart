import 'package:app/models/models.dart';
import 'package:app/themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

Future<void> showTaskDialog(
  BuildContext context, {
  Task? task,
  required List<Category> categories,
  required ValueChanged<Task> onSave,
  Future<List<Subtask>> Function(String goal)? onAiBreakdown,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => _TaskDialog(
      task: task,
      categories: categories,
      onSave: onSave,
      onAiBreakdown: onAiBreakdown,
    ),
  );
}

class _TaskDialog extends StatefulWidget {
  const _TaskDialog({
    this.task,
    required this.categories,
    required this.onSave,
    this.onAiBreakdown,
  });

  final Task? task;
  final List<Category> categories;
  final ValueChanged<Task> onSave;
  final Future<List<Subtask>> Function(String goal)? onAiBreakdown;

  @override
  State<_TaskDialog> createState() => _TaskDialogState();
}

class _TaskDialogState extends State<_TaskDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _tagsController;
  late final TextEditingController _subtaskController;

  late Priority _priority;
  late TaskStatus _status;
  String? _categoryId;
  DateTime? _dueDate;
  late List<Subtask> _subtasks;

  bool _aiLoading = false;
  List<Subtask> _aiSuggested = [];
  String? _aiError;

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    _titleController = TextEditingController(text: t?.title ?? '');
    _descriptionController = TextEditingController(text: t?.description ?? '');
    _tagsController = TextEditingController(text: t?.tags.join(', ') ?? '');
    _subtaskController = TextEditingController();
    _priority = t?.priority ?? Priority.medium;
    _status = t?.status ?? TaskStatus.pending;
    _categoryId = t?.categoryId;
    _dueDate = t?.dueDate != null ? DateTime.tryParse(t!.dueDate!) : null;
    _subtasks = List<Subtask>.from(t?.subtasks ?? const []);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    _subtaskController.dispose();
    super.dispose();
  }

  void _addManualSubtask() {
    final text = _subtaskController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _subtasks.add(
        Subtask(
          id: 'sub-${DateTime.now().microsecondsSinceEpoch}',
          title: text,
          completed: false,
          priority: _priority,
        ),
      );
      _subtaskController.clear();
    });
  }

  Future<void> _generateAiBreakdown() async {
    final goal = _titleController.text.trim();
    if (goal.isEmpty) return;

    setState(() {
      _aiLoading = true;
      _aiError = null;
    });

    try {
      if (widget.onAiBreakdown != null) {
        final generated = await widget.onAiBreakdown!(goal);
        if (!mounted) return;
        setState(() => _aiSuggested = generated);
      } else {
        await Future<void>.delayed(const Duration(milliseconds: 600));
        if (!mounted) return;
        setState(() {
          _aiSuggested = [
            Subtask(
              id: 'ai-1-${DateTime.now().microsecondsSinceEpoch}',
              title: 'Planejar etapas iniciais de "$goal"',
              completed: false,
              priority: Priority.high,
            ),
            Subtask(
              id: 'ai-2-${DateTime.now().microsecondsSinceEpoch}',
              title: 'Executar atividade principal de "$goal"',
              completed: false,
              priority: Priority.medium,
            ),
            Subtask(
              id: 'ai-3-${DateTime.now().microsecondsSinceEpoch}',
              title: 'Revisar e validar entrega de "$goal"',
              completed: false,
              priority: Priority.low,
            ),
          ];
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _aiError = 'Não foi possível gerar subtarefas.');
    } finally {
      if (mounted) {
        setState(() => _aiLoading = false);
      }
    }
  }

  void _applyAiSubtasks() {
    if (_aiSuggested.isEmpty) return;
    setState(() {
      _subtasks.addAll(_aiSuggested);
      _aiSuggested = [];
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Submetas adicionadas à tarefa!')),
    );
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 5),
      locale: const Locale('pt', 'BR'),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  void _handleSave() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('O título é obrigatório.')),
      );
      return;
    }

    if (_status == TaskStatus.done && _subtasks.isNotEmpty) {
      final pendingCount = _subtasks.where((s) => !s.completed).length;
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

    final nowIso = DateTime.now().toIso8601String();
    final tags = _tagsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final savedTask = Task(
      id: widget.task?.id ?? 'task-${DateTime.now().microsecondsSinceEpoch}',
      title: title,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      priority: _priority,
      status: _status,
      categoryId: _categoryId,
      dueDate: _dueDate?.toIso8601String(),
      createdAt: widget.task?.createdAt ?? nowIso,
      updatedAt: nowIso,
      tags: tags,
      recurrence: widget.task?.recurrence,
      subtasks: _subtasks,
    );

    widget.onSave(savedTask);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final completedSubs = _subtasks.where((s) => s.completed).length;
    final subPct = _subtasks.isNotEmpty
        ? ((completedSubs / _subtasks.length) * 100).round()
        : 0;

    return Dialog(
      backgroundColor: AppColors.cardBackGround,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.task != null ? 'Editar Tarefa' : 'Nova Tarefa',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.onPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(LucideIcons.x, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Body
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _FieldLabel('Título *'),
                      TextField(
                        controller: _titleController,
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(fontFamily: 'Lora', fontSize: 14),
                        decoration: _inputDecoration('O que precisa ser feito?'),
                      ),
                      const SizedBox(height: 12),

                      // Módulo Gemini IA Breakdown
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Flexible(
                                  child: Row(
                                    children: [
                                      Icon(
                                        LucideIcons.sparkles,
                                        size: 16,
                                        color: Color(0xFF6366F1),
                                      ),
                                      SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          'Sugestão Inteligente (Gemini IA)',
                                          style: TextStyle(
                                            fontFamily: 'Lora',
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.onPrimary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                OutlinedButton.icon(
                                  onPressed:
                                      _aiLoading ||
                                          _titleController.text.trim().isEmpty
                                      ? null
                                      : _generateAiBreakdown,
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                      color: Color(0xFFC7D2FE),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                  ),
                                  icon: _aiLoading
                                      ? const SizedBox(
                                          width: 12,
                                          height: 12,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(
                                          LucideIcons.sparkles,
                                          size: 13,
                                          color: Color(0xFF6366F1),
                                        ),
                                  label: Text(
                                    _aiLoading
                                        ? 'A gerar...'
                                        : 'Decompor Meta',
                                    style: const TextStyle(
                                      fontFamily: 'Lora',
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (_aiError != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                _aiError!,
                                style: const TextStyle(
                                  color: AppColors.destructive,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                            if (_aiSuggested.isNotEmpty) ...[
                              const Divider(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'SUBTAREFAS GERADAS:',
                                    style: TextStyle(
                                      fontFamily: 'Lora',
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.onMuted,
                                    ),
                                  ),
                                  FilledButton.icon(
                                    onPressed: _applyAiSubtasks,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFF4F46E5),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      minimumSize: Size.zero,
                                    ),
                                    icon: const Icon(
                                      LucideIcons.plus,
                                      size: 12,
                                      color: Colors.white,
                                    ),
                                    label: const Text(
                                      'Adicionar à Tarefa',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ..._aiSuggested.map(
                                (item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        LucideIcons.circleCheck,
                                        size: 13,
                                        color: AppColors.chartPriorityLow,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          item.title,
                                          style: const TextStyle(
                                            fontFamily: 'Lora',
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Lista interativa de Submetas
                      Container(
                        padding: const EdgeInsets.only(top: 8),
                        decoration: const BoxDecoration(
                          border: Border(
                            top: BorderSide(color: AppColors.border),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      LucideIcons.target,
                                      size: 15,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Submetas ($completedSubs/${_subtasks.length})',
                                      style: const TextStyle(
                                        fontFamily: 'Lora',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.onPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                if (_subtasks.isNotEmpty)
                                  Text(
                                    '$subPct% concluídas',
                                    style: const TextStyle(
                                      fontFamily: 'Lora',
                                      fontSize: 11,
                                      color: AppColors.onMuted,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (_subtasks.isEmpty)
                              const Text(
                                'Nenhuma submeta adicionada ainda.',
                                style: TextStyle(
                                  fontFamily: 'Lora',
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                  color: AppColors.onMuted,
                                ),
                              )
                            else
                              ..._subtasks.asMap().entries.map((entry) {
                                final idx = entry.key;
                                final st = entry.value;
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 6),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.muted.withValues(
                                      alpha: 0.5,
                                    ),
                                    border: Border.all(color: AppColors.border),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Checkbox(
                                        value: st.completed,
                                        activeColor: AppColors.primary,
                                        visualDensity: VisualDensity.compact,
                                        onChanged: (val) {
                                          setState(() {
                                            _subtasks[idx] = st.copyWith(
                                              completed: val ?? false,
                                            );
                                          });
                                        },
                                      ),
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
                                      IconButton(
                                        visualDensity: VisualDensity.compact,
                                        onPressed: () {
                                          setState(
                                            () => _subtasks.removeAt(idx),
                                          );
                                        },
                                        icon: const Icon(
                                          LucideIcons.trash2,
                                          size: 14,
                                          color: AppColors.destructive,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _subtaskController,
                                    onSubmitted: (_) => _addManualSubtask(),
                                    style: const TextStyle(
                                      fontFamily: 'Lora',
                                      fontSize: 12,
                                    ),
                                    decoration: _inputDecoration(
                                      'Adicionar submeta manual...',
                                      dense: true,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton.icon(
                                  onPressed: _addManualSubtask,
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                      color: AppColors.border,
                                    ),
                                    foregroundColor: AppColors.onPrimary,
                                  ),
                                  icon: const Icon(LucideIcons.plus, size: 13),
                                  label: const Text(
                                    'Adicionar',
                                    style: TextStyle(
                                      fontFamily: 'Lora',
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      const _FieldLabel('Descrição'),
                      TextField(
                        controller: _descriptionController,
                        maxLines: 3,
                        style: const TextStyle(fontFamily: 'Lora', fontSize: 13),
                        decoration: _inputDecoration('Detalhes adicionais...'),
                      ),
                      const SizedBox(height: 12),

                      // Prioridade + Status
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _FieldLabel('Prioridade'),
                                DropdownButtonFormField<Priority>(
                                  initialValue: _priority,
                                  decoration: _inputDecoration('', dense: true),
                                  items: Priority.values
                                      .map(
                                        (p) => DropdownMenuItem(
                                          value: p,
                                          child: Text(
                                            p.label,
                                            style: const TextStyle(
                                              fontFamily: 'Lora',
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (v) {
                                    if (v != null) {
                                      setState(() => _priority = v);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _FieldLabel('Status'),
                                DropdownButtonFormField<TaskStatus>(
                                  initialValue: _status,
                                  decoration: _inputDecoration('', dense: true),
                                  items: TaskStatus.values
                                      .map(
                                        (s) => DropdownMenuItem(
                                          value: s,
                                          child: Text(
                                            s.label,
                                            style: const TextStyle(
                                              fontFamily: 'Lora',
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (v) {
                                    if (v != null) {
                                      setState(() => _status = v);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Categoria + Prazo
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _FieldLabel('Categoria'),
                                DropdownButtonFormField<String?>(
                                  initialValue: _categoryId,
                                  decoration: _inputDecoration('', dense: true),
                                  items: [
                                    const DropdownMenuItem<String?>(
                                      value: null,
                                      child: Text(
                                        'Sem categoria',
                                        style: TextStyle(
                                          fontFamily: 'Lora',
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    ...widget.categories.map(
                                      (c) => DropdownMenuItem<String?>(
                                        value: c.id,
                                        child: Text(
                                          c.name,
                                          style: const TextStyle(
                                            fontFamily: 'Lora',
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                  onChanged: (v) =>
                                      setState(() => _categoryId = v),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _FieldLabel('Prazo'),
                                InkWell(
                                  onTap: _pickDueDate,
                                  borderRadius: BorderRadius.circular(8),
                                  child: InputDecorator(
                                    decoration: _inputDecoration(
                                      '',
                                      dense: true,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _dueDate != null
                                              ? DateFormat(
                                                  'dd/MM/yyyy',
                                                ).format(_dueDate!)
                                              : 'Selecionar...',
                                          style: const TextStyle(
                                            fontFamily: 'Lora',
                                            fontSize: 13,
                                          ),
                                        ),
                                        const Icon(
                                          LucideIcons.calendar,
                                          size: 14,
                                          color: AppColors.onMuted,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      const _FieldLabel('Tags (separadas por vírgula)'),
                      TextField(
                        controller: _tagsController,
                        style: const TextStyle(fontFamily: 'Lora', fontSize: 13),
                        decoration: _inputDecoration(
                          'trabalho, urgente, reunião...',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.border),
                      foregroundColor: AppColors.onPrimary,
                    ),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(fontFamily: 'Lora'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: _handleSave,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      widget.task != null ? 'Salvar' : 'Criar Tarefa',
                      style: const TextStyle(fontFamily: 'Lora'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, {bool dense = false}) {
    return InputDecoration(
      hintText: hint,
      isDense: true,
      filled: true,
      fillColor: AppColors.background,
      contentPadding: EdgeInsets.symmetric(
        horizontal: 12,
        vertical: dense ? 10 : 12,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.border),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Lora',
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.onPrimary,
        ),
      ),
    );
  }
}
