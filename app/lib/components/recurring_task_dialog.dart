import 'package:app/models/models.dart';
import 'package:app/themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class RecurrenceBadge extends StatelessWidget {
  const RecurrenceBadge({required this.task, super.key});

  final Task task;

  @override
  Widget build(BuildContext context) {
    final rule = task.recurrence;
    if (rule == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.repeat2, size: 11, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            rule.summary,
            style: const TextStyle(
              fontFamily: 'Lora',
              fontSize: 11,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> showRecurringTaskDialog(
  BuildContext context, {
  required List<Category> categories,
  required ValueChanged<Task> onSave,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => _RecurringTaskDialog(
      categories: categories,
      onSave: onSave,
    ),
  );
}

class _RecurringTaskDialog extends StatefulWidget {
  const _RecurringTaskDialog({
    required this.categories,
    required this.onSave,
  });

  final List<Category> categories;
  final ValueChanged<Task> onSave;

  @override
  State<_RecurringTaskDialog> createState() => _RecurringTaskDialogState();
}

class _RecurringTaskDialogState extends State<_RecurringTaskDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _intervalController = TextEditingController(text: '1');
  final _maxOccurrencesController = TextEditingController(text: '12');

  Priority _priority = Priority.medium;
  String? _categoryId;
  DateTime? _startDate;
  RecurrenceFrequency _frequency = RecurrenceFrequency.weekly;
  bool _useEndDate = false;
  DateTime? _endDate;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _intervalController.dispose();
    _maxOccurrencesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: (isStart ? _startDate : _endDate) ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      locale: const Locale('pt', 'BR'),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
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
    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A data de início é obrigatória.')),
      );
      return;
    }

    final interval = (int.tryParse(_intervalController.text) ?? 1).clamp(1, 365);
    final maxOcc =
        (int.tryParse(_maxOccurrencesController.text) ?? 12).clamp(1, 365);

    final rule = RecurrenceRule(
      frequency: _frequency,
      interval: interval,
      maxOccurrences: _useEndDate ? null : maxOcc,
      endDate: _useEndDate && _endDate != null
          ? _endDate!.toIso8601String()
          : null,
    );

    final nowIso = DateTime.now().toIso8601String();
    final newTask = Task(
      id: 'rec-${DateTime.now().microsecondsSinceEpoch}',
      title: title,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      priority: _priority,
      status: TaskStatus.pending,
      categoryId: _categoryId,
      dueDate: _startDate!.toIso8601String(),
      createdAt: nowIso,
      updatedAt: nowIso,
      recurrence: rule,
    );

    widget.onSave(newTask);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final interval = (int.tryParse(_intervalController.text) ?? 1).clamp(1, 365);
    final previewRule = RecurrenceRule(
      frequency: _frequency,
      interval: interval,
    );

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
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.repeat2,
                        size: 20,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Nova Tarefa Recorrente',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.onPrimary,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(LucideIcons.x, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Título *',
                        style: TextStyle(
                          fontFamily: 'Lora',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _titleController,
                        style: const TextStyle(fontFamily: 'Lora', fontSize: 14),
                        decoration: _decoration('Título da tarefa...'),
                      ),
                      const SizedBox(height: 12),

                      const Text(
                        'Descrição',
                        style: TextStyle(
                          fontFamily: 'Lora',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _descriptionController,
                        maxLines: 2,
                        style: const TextStyle(fontFamily: 'Lora', fontSize: 13),
                        decoration: _decoration('Descrição da tarefa...'),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<Priority>(
                              initialValue: _priority,
                              decoration: _decoration('Prioridade'),
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
                                if (v != null) setState(() => _priority = v);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String?>(
                              initialValue: _categoryId,
                              decoration: _decoration('Categoria'),
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
                              onChanged: (v) => setState(() => _categoryId = v),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      const Text(
                        'Data de Início *',
                        style: TextStyle(
                          fontFamily: 'Lora',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () => _pickDate(isStart: true),
                        child: InputDecorator(
                          decoration: _decoration(''),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _startDate != null
                                    ? DateFormat(
                                        'dd/MM/yyyy',
                                      ).format(_startDate!)
                                    : 'Selecionar data...',
                                style: const TextStyle(
                                  fontFamily: 'Lora',
                                  fontSize: 13,
                                ),
                              ),
                              const Icon(LucideIcons.calendar, size: 15),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Configuração de Recorrência
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.muted.withValues(alpha: 0.5),
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  LucideIcons.repeat2,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Configuração de Recorrência',
                                  style: TextStyle(
                                    fontFamily: 'Playfair Display',
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            DropdownButtonFormField<RecurrenceFrequency>(
                              initialValue: _frequency,
                              decoration: _decoration('Frequência'),
                              items: RecurrenceFrequency.values
                                  .map(
                                    (f) => DropdownMenuItem(
                                      value: f,
                                      child: Text(
                                        f.label,
                                        style: const TextStyle(
                                          fontFamily: 'Lora',
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) setState(() => _frequency = v);
                              },
                            ),
                            const SizedBox(height: 10),

                            Row(
                              children: [
                                const Text(
                                  'Cada ',
                                  style: TextStyle(
                                    fontFamily: 'Lora',
                                    fontSize: 13,
                                  ),
                                ),
                                SizedBox(
                                  width: 70,
                                  child: TextField(
                                    controller: _intervalController,
                                    keyboardType: TextInputType.number,
                                    onChanged: (_) => setState(() {}),
                                    decoration: _decoration('1'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Resumo: ${previewRule.intervalLabel}',
                                  style: const TextStyle(
                                    fontFamily: 'Lora',
                                    fontSize: 12,
                                    color: AppColors.onMuted,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            RadioGroup<bool>(
                              groupValue: _useEndDate,
                              onChanged: (v) {
                                if (v != null) setState(() => _useEndDate = v);
                              },
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      const Radio<bool>(value: false),
                                      const Expanded(
                                        child: Text(
                                          'Máximo de ocorrências',
                                          style: TextStyle(
                                            fontFamily: 'Lora',
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 80,
                                        child: TextField(
                                          controller: _maxOccurrencesController,
                                          enabled: !_useEndDate,
                                          keyboardType: TextInputType.number,
                                          decoration: _decoration('12'),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      const Radio<bool>(value: true),
                                      const Expanded(
                                        child: Text(
                                          'Data de término',
                                          style: TextStyle(
                                            fontFamily: 'Lora',
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      TextButton.icon(
                                        onPressed: _useEndDate
                                            ? () => _pickDate(isStart: false)
                                            : null,
                                        icon: const Icon(
                                          LucideIcons.calendar,
                                          size: 14,
                                        ),
                                        label: Text(
                                          _endDate != null
                                              ? DateFormat(
                                                  'dd/MM/yyyy',
                                                ).format(_endDate!)
                                              : 'Escolher',
                                          style: const TextStyle(
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
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(fontFamily: 'Lora'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed: _handleSave,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(LucideIcons.repeat2, size: 15),
                    label: const Text(
                      'Criar Tarefa Recorrente',
                      style: TextStyle(fontFamily: 'Lora'),
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

  InputDecoration _decoration(String hint) {
    return InputDecoration(
      hintText: hint,
      isDense: true,
      filled: true,
      fillColor: AppColors.background,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
