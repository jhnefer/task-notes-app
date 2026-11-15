import 'package:app/models/models.dart';
import 'package:app/themes/app_colors.dart';
import 'package:app/utils/data_exporter.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ExportMenu extends StatelessWidget {
  const ExportMenu({
    this.tasks = const [],
    this.notes = const [],
    this.categories = const [],
    this.onExportTasksCsv,
    this.onExportTasksPdf,
    this.onExportNotesCsv,
    this.onExportNotesPdf,
    super.key,
  });

  final List<Task> tasks;
  final List<Note> notes;
  final List<Category> categories;
  final VoidCallback? onExportTasksCsv;
  final VoidCallback? onExportTasksPdf;
  final VoidCallback? onExportNotesCsv;
  final VoidCallback? onExportNotesPdf;

  @override
  Widget build(BuildContext context) {
    final hasData = tasks.isNotEmpty || notes.isNotEmpty;

    return PopupMenuButton<String>(
      enabled: hasData,
      color: AppColors.cardBackGround,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppColors.border),
      ),
      onSelected: (value) {
        switch (value) {
          case 'tasks_csv':
            if (onExportTasksCsv != null) {
              onExportTasksCsv!();
            } else {
              DataExporter.exportTasksCsv(tasks, categories);
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${tasks.length} tarefas exportadas para CSV'),
              ),
            );
          case 'tasks_pdf':
            if (onExportTasksPdf != null) {
              onExportTasksPdf!();
            } else {
              DataExporter.exportTasksPdf(tasks, categories);
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${tasks.length} tarefas exportadas para PDF'),
              ),
            );
          case 'notes_csv':
            if (onExportNotesCsv != null) {
              onExportNotesCsv!();
            } else {
              DataExporter.exportNotesCsv(notes, categories);
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${notes.length} anotações exportadas para CSV'),
              ),
            );
          case 'notes_pdf':
            if (onExportNotesPdf != null) {
              onExportNotesPdf!();
            } else {
              DataExporter.exportNotesPdf(notes, categories);
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${notes.length} anotações exportadas para PDF'),
              ),
            );
        }
      },
      itemBuilder: (context) => [
        if (tasks.isNotEmpty) ...[
          PopupMenuItem<String>(
            enabled: false,
            height: 28,
            child: Text(
              'TAREFAS (${tasks.length})',
              style: const TextStyle(
                fontFamily: 'Lora',
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.onMuted,
              ),
            ),
          ),
          const PopupMenuItem<String>(
            value: 'tasks_csv',
            child: Row(
              children: [
                Icon(LucideIcons.sheet, size: 15, color: AppColors.onPrimary),
                SizedBox(width: 8),
                Text(
                  'Exportar como CSV',
                  style: TextStyle(fontFamily: 'Lora', fontSize: 13),
                ),
              ],
            ),
          ),
          const PopupMenuItem<String>(
            value: 'tasks_pdf',
            child: Row(
              children: [
                Icon(
                  LucideIcons.fileText,
                  size: 15,
                  color: AppColors.onPrimary,
                ),
                SizedBox(width: 8),
                Text(
                  'Exportar como PDF',
                  style: TextStyle(fontFamily: 'Lora', fontSize: 13),
                ),
              ],
            ),
          ),
        ],
        if (tasks.isNotEmpty && notes.isNotEmpty) const PopupMenuDivider(),
        if (notes.isNotEmpty) ...[
          PopupMenuItem<String>(
            enabled: false,
            height: 28,
            child: Text(
              'ANOTAÇÕES (${notes.length})',
              style: const TextStyle(
                fontFamily: 'Lora',
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.onMuted,
              ),
            ),
          ),
          const PopupMenuItem<String>(
            value: 'notes_csv',
            child: Row(
              children: [
                Icon(LucideIcons.sheet, size: 15, color: AppColors.onPrimary),
                SizedBox(width: 8),
                Text(
                  'Exportar como CSV',
                  style: TextStyle(fontFamily: 'Lora', fontSize: 13),
                ),
              ],
            ),
          ),
          const PopupMenuItem<String>(
            value: 'notes_pdf',
            child: Row(
              children: [
                Icon(
                  LucideIcons.fileText,
                  size: 15,
                  color: AppColors.onPrimary,
                ),
                SizedBox(width: 8),
                Text(
                  'Exportar como PDF',
                  style: TextStyle(fontFamily: 'Lora', fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ],
      child: IgnorePointer(
        child: OutlinedButton.icon(
          onPressed: hasData ? () {} : null,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.border),
            foregroundColor: AppColors.onPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          icon: const Icon(LucideIcons.download, size: 15),
          label: const Text(
            'Exportar',
            style: TextStyle(fontFamily: 'Lora', fontSize: 13),
          ),
        ),
      ),
    );
  }
}
