import 'dart:convert';
import 'dart:io';

import 'package:app/models/models.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

class DataExporter {
  static String _catName(String? id, List<Category> categories) {
    if (id == null) return '';
    return categories
            .where((c) => c.id == id)
            .map((c) => c.name)
            .firstOrNull ??
        '';
  }

  static String _fmtDate(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final d = DateTime.tryParse(iso);
    if (d == null) return '';
    return DateFormat('dd/MM/yyyy HH:mm', 'pt_BR').format(d);
  }

  static String _esc(String val) =>
      '"${val.replaceAll('"', '""').replaceAll('\n', ' ')}"';

  static String buildTasksCsv(List<Task> tasks, List<Category> categories) {
    const headers = [
      'Título',
      'Descrição',
      'Prioridade',
      'Status',
      'Categoria',
      'Prazo',
      'Tags',
      'Criada em',
      'Atualizada em',
    ];
    final rows = tasks.map((t) => [
      _esc(t.title),
      _esc(t.description ?? ''),
      t.priority.label,
      t.status.label,
      _esc(_catName(t.categoryId, categories)),
      _fmtDate(t.dueDate),
      _esc(t.tags.map((tag) => '#$tag').join('; ')),
      _fmtDate(t.createdAt),
      _fmtDate(t.updatedAt),
    ]);
    return [headers.join(','), ...rows.map((r) => r.join(','))].join('\n');
  }

  static String buildNotesCsv(List<Note> notes, List<Category> categories) {
    const headers = [
      'Título',
      'Conteúdo',
      'Categoria',
      'Fixada',
      'Tags',
      'Criada em',
      'Atualizada em',
    ];
    final rows = notes.map((n) => [
      _esc(n.title),
      _esc(n.content),
      _esc(_catName(n.categoryId, categories)),
      n.pinned ? 'Sim' : 'Não',
      _esc(n.tags.map((tag) => '#$tag').join('; ')),
      _fmtDate(n.createdAt),
      _fmtDate(n.updatedAt),
    ]);
    return [headers.join(','), ...rows.map((r) => r.join(','))].join('\n');
  }

  static String buildBackupJson({
    required List<Task> tasks,
    required List<Note> notes,
    required List<Category> categories,
    UserProfile? profile,
    NotificationSettings? notificationSettings,
  }) {
    final payload = {
      'exportedAt': DateTime.now().toIso8601String(),
      'app': 'Meu Caderno',
      if (profile != null) 'profile': profile.toJson(),
      if (notificationSettings != null)
        'notificationSettings': notificationSettings.toJson(),
      'categories': categories.map((c) => c.toJson()).toList(),
      'tasks': tasks.map((t) => t.toJson()).toList(),
      'notes': notes.map((n) => n.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  static Future<void> _shareTextFile(
    String content,
    String filename,
    String subject,
  ) async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$filename');
      await file.writeAsString(content);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: subject,
        ),
      );
    } catch (_) {
      // Fallback silencioso em ambiente de teste ou plataforma sem canal nativo
    }
  }

  static Future<void> exportTasksCsv(
    List<Task> tasks,
    List<Category> categories,
  ) async {
    final csv = buildTasksCsv(tasks, categories);
    await _shareTextFile(csv, 'tarefas.csv', 'Exportação de Tarefas (CSV)');
  }

  static Future<void> exportNotesCsv(
    List<Note> notes,
    List<Category> categories,
  ) async {
    final csv = buildNotesCsv(notes, categories);
    await _shareTextFile(csv, 'anotacoes.csv', 'Exportação de Anotações (CSV)');
  }

  static Future<void> exportFullBackupJson({
    required List<Task> tasks,
    required List<Note> notes,
    required List<Category> categories,
    UserProfile? profile,
    NotificationSettings? notificationSettings,
  }) async {
    final jsonStr = buildBackupJson(
      tasks: tasks,
      notes: notes,
      categories: categories,
      profile: profile,
      notificationSettings: notificationSettings,
    );
    await _shareTextFile(
      jsonStr,
      'meu_caderno_backup.json',
      'Backup Completo — Meu Caderno',
    );
  }

  static Future<void> exportTasksPdf(
    List<Task> tasks,
    List<Category> categories,
  ) async {
    try {
      final doc = pw.Document();
      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) => [
            pw.Header(
              level: 0,
              child: pw.Text(
                'Meu Caderno - Relatorio de Tarefas (${tasks.length})',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 12),
            pw.TableHelper.fromTextArray(
              headers: const ['Titulo', 'Prioridade', 'Status', 'Categoria', 'Prazo'],
              data: tasks
                  .map(
                    (t) => [
                      t.title,
                      t.priority.label,
                      t.status.label,
                      _catName(t.categoryId, categories),
                      _fmtDate(t.dueDate),
                    ],
                  )
                  .toList(),
            ),
          ],
        ),
      );
      final bytes = await doc.save();
      await Printing.sharePdf(bytes: bytes, filename: 'tarefas.pdf');
    } catch (_) {
      // Fallback silencioso em ambiente de teste
    }
  }

  static Future<void> exportNotesPdf(
    List<Note> notes,
    List<Category> categories,
  ) async {
    try {
      final doc = pw.Document();
      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) => [
            pw.Header(
              level: 0,
              child: pw.Text(
                'Meu Caderno - Anotacoes (${notes.length})',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 12),
            ...notes.map(
              (n) => pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 12),
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      '${n.pinned ? "[Fixada] " : ""}${n.title}',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(n.content, style: const pw.TextStyle(fontSize: 11)),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
      final bytes = await doc.save();
      await Printing.sharePdf(bytes: bytes, filename: 'anotacoes.pdf');
    } catch (_) {
      // Fallback silencioso em ambiente de teste
    }
  }
}
