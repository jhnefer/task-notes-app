import 'package:app/models/models.dart';
import 'package:app/themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

Future<void> showNoteDialog(
  BuildContext context, {
  Note? note,
  required List<Category> categories,
  required ValueChanged<Note> onSave,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => _NoteDialog(
      note: note,
      categories: categories,
      onSave: onSave,
    ),
  );
}

class _NoteDialog extends StatefulWidget {
  const _NoteDialog({
    this.note,
    required this.categories,
    required this.onSave,
  });

  final Note? note;
  final List<Category> categories;
  final ValueChanged<Note> onSave;

  @override
  State<_NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<_NoteDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late final TextEditingController _tagsController;
  String? _categoryId;
  late bool _pinned;

  @override
  void initState() {
    super.initState();
    final n = widget.note;
    _titleController = TextEditingController(text: n?.title ?? '');
    _contentController = TextEditingController(text: n?.content ?? '');
    _tagsController = TextEditingController(text: n?.tags.join(', ') ?? '');
    _categoryId = n?.categoryId;
    _pinned = n?.pinned ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _handleSave() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('O título é obrigatório.')),
      );
      return;
    }

    final nowIso = DateTime.now().toIso8601String();
    final tags = _tagsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final saved = Note(
      id: widget.note?.id ?? 'note-${DateTime.now().microsecondsSinceEpoch}',
      title: title,
      content: _contentController.text,
      categoryId: _categoryId,
      createdAt: widget.note?.createdAt ?? nowIso,
      updatedAt: nowIso,
      tags: tags,
      pinned: _pinned,
    );

    widget.onSave(saved);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.cardBackGround,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.note != null ? 'Editar Anotação' : 'Nova Anotação',
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
                        style: const TextStyle(
                          fontFamily: 'Playfair Display',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: _decoration('Título da anotação...'),
                      ),
                      const SizedBox(height: 12),

                      const Text(
                        'Conteúdo',
                        style: TextStyle(
                          fontFamily: 'Lora',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      CustomPaint(
                        foregroundPainter: _RuledLinesPainter(),
                        child: TextField(
                          controller: _contentController,
                          maxLines: 8,
                          style: const TextStyle(
                            fontFamily: 'Lora',
                            fontSize: 14,
                            height: 2.0,
                          ),
                          decoration: _decoration(
                            'Escreva suas anotações aqui...',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Categoria',
                                  style: TextStyle(
                                    fontFamily: 'Lora',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<String?>(
                                  initialValue: _categoryId,
                                  decoration: _decoration(''),
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
                                const Text(
                                  'Tags (vírgula)',
                                  style: TextStyle(
                                    fontFamily: 'Lora',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _tagsController,
                                  style: const TextStyle(
                                    fontFamily: 'Lora',
                                    fontSize: 13,
                                  ),
                                  decoration: _decoration(
                                    'ideia, projeto, referência...',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      InkWell(
                        onTap: () => setState(() => _pinned = !_pinned),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _pinned
                                ? AppColors.primary.withValues(alpha: 0.1)
                                : Colors.transparent,
                            border: Border.all(
                              color: _pinned
                                  ? AppColors.primary.withValues(alpha: 0.4)
                                  : AppColors.border,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                LucideIcons.pin,
                                size: 14,
                                color: _pinned
                                    ? AppColors.primary
                                    : AppColors.onMuted,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _pinned ? 'Fixada' : 'Fixar nota',
                                style: TextStyle(
                                  fontFamily: 'Lora',
                                  fontSize: 13,
                                  color: _pinned
                                      ? AppColors.primary
                                      : AppColors.onMuted,
                                ),
                              ),
                            ],
                          ),
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
                    icon: const Icon(LucideIcons.save, size: 15),
                    label: Text(
                      widget.note != null ? 'Salvar' : 'Criar Anotação',
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

  InputDecoration _decoration(String hint) {
    return InputDecoration(
      hintText: hint,
      isDense: true,
      filled: true,
      fillColor: AppColors.background,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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

class _RuledLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.35)
      ..strokeWidth = 1;
    const lineHeight = 28.0;
    for (double y = 36; y < size.height - 8; y += lineHeight) {
      canvas.drawLine(Offset(10, y), Offset(size.width - 10, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
