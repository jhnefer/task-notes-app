import 'package:app/components/category_dialog.dart';
import 'package:app/models/models.dart';
import 'package:app/themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({
    required this.categories,
    required this.tasks,
    required this.notes,
    required this.onAddCategory,
    required this.onDeleteCategory,
    super.key,
  });

  final List<Category> categories;
  final List<Task> tasks;
  final List<Note> notes;
  final ValueChanged<Category> onAddCategory;
  final ValueChanged<String> onDeleteCategory;

  ({int tasks, int notes, int done}) _statsFor(String catId) {
    final catTasks = tasks.where((t) => t.categoryId == catId).toList();
    final catNotes = notes.where((n) => n.categoryId == catId).length;
    final doneCount = catTasks
        .where((t) => t.status == TaskStatus.done)
        .length;
    return (tasks: catTasks.length, notes: catNotes, done: doneCount);
  }

  void _handleDelete(BuildContext context, Category cat) {
    final stats = _statsFor(cat.id);
    if (stats.tasks > 0 || stats.notes > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.destructive,
          content: Text(
            'Esta categoria possui ${stats.tasks} tarefa(s) e ${stats.notes} anotação(ões). Remova-as primeiro.',
          ),
        ),
      );
      return;
    }
    onDeleteCategory(cat.id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Categoria removida.')),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Categorias',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.onPrimary,
                            ),
                      ),
                      Text(
                        '${categories.length} categorias criadas',
                        style: const TextStyle(
                          fontFamily: 'Lora',
                          fontSize: 13,
                          color: AppColors.onMuted,
                        ),
                      ),
                    ],
                  ),
                  FilledButton.icon(
                    onPressed: () {
                      showCategoryDialog(context, onSave: onAddCategory);
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
                      'Nova Categoria',
                      style: TextStyle(fontFamily: 'Lora', fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              if (categories.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Column(
                      children: [
                        const Icon(
                          LucideIcons.tag,
                          size: 36,
                          color: AppColors.onMuted,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Nenhuma categoria',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(color: AppColors.onMuted),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Crie categorias para organizar suas tarefas e anotações',
                          style: TextStyle(
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
                ...categories.map((cat) {
                  final stats = _statsFor(cat.id);
                  final progress = stats.tasks > 0
                      ? stats.done / stats.tasks
                      : 0.0;
                  final catColor = cat.parsedColor;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackGround,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border, width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: catColor,
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    cat.name.isNotEmpty
                                        ? cat.name[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      fontFamily: 'Playfair Display',
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      cat.name,
                                      style: const TextStyle(
                                        fontFamily: 'Playfair Display',
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.onPrimary,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Icon(
                                          cat.iconData,
                                          size: 12,
                                          color: AppColors.onMuted,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          cat.icon,
                                          style: const TextStyle(
                                            fontFamily: 'Caveat',
                                            fontSize: 14,
                                            color: AppColors.onMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            IconButton(
                              onPressed: () => _handleDelete(context, cat),
                              icon: const Icon(
                                LucideIcons.trash2,
                                size: 16,
                                color: AppColors.destructive,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.muted,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  children: [
                                    const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          LucideIcons.checkSquare,
                                          size: 12,
                                          color: AppColors.onMuted,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Tarefas',
                                          style: TextStyle(
                                            fontFamily: 'Lora',
                                            fontSize: 12,
                                            color: AppColors.onMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${stats.tasks}',
                                      style: const TextStyle(
                                        fontFamily: 'Playfair Display',
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.onPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.muted,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  children: [
                                    const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          LucideIcons.fileText,
                                          size: 12,
                                          color: AppColors.onMuted,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Notas',
                                          style: TextStyle(
                                            fontFamily: 'Lora',
                                            fontSize: 12,
                                            color: AppColors.onMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${stats.notes}',
                                      style: const TextStyle(
                                        fontFamily: 'Playfair Display',
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.onPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        if (stats.tasks > 0) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Progresso',
                                style: TextStyle(
                                  fontFamily: 'Lora',
                                  fontSize: 12,
                                  color: AppColors.onMuted,
                                ),
                              ),
                              Text(
                                '${(progress * 100).round()}%',
                                style: TextStyle(
                                  fontFamily: 'Caveat',
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: catColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 6,
                              backgroundColor: AppColors.muted,
                              color: catColor,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${stats.done} de ${stats.tasks} concluídas',
                            style: const TextStyle(
                              fontFamily: 'Lora',
                              fontSize: 11,
                              color: AppColors.onMuted,
                            ),
                          ),
                        ] else if (stats.notes == 0)
                          const Center(
                            child: Text(
                              'Nenhum item nesta categoria',
                              style: TextStyle(
                                fontFamily: 'Caveat',
                                fontSize: 15,
                                color: AppColors.onMuted,
                              ),
                            ),
                          ),
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
