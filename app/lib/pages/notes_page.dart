import 'package:app/components/note_dialog.dart';
import 'package:app/models/models.dart';
import 'package:app/themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({
    required this.notes,
    required this.categories,
    required this.onAddNote,
    required this.onUpdateNote,
    required this.onDeleteNote,
    required this.onTogglePin,
    super.key,
  });

  final List<Note> notes;
  final List<Category> categories;
  final ValueChanged<Note> onAddNote;
  final ValueChanged<Note> onUpdateNote;
  final ValueChanged<String> onDeleteNote;
  final ValueChanged<String> onTogglePin;

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final _searchController = TextEditingController();
  String _search = '';
  String _filterCategory = 'all';

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

  List<Note> get _filteredNotes {
    return widget.notes.where((n) {
      final q = _search.toLowerCase();
      final matchSearch =
          q.isEmpty ||
          n.title.toLowerCase().contains(q) ||
          n.content.toLowerCase().contains(q) ||
          n.tags.any((t) => t.toLowerCase().contains(q));
      final matchCat =
          _filterCategory == 'all' ||
          (_filterCategory == 'none'
              ? n.categoryId == null
              : n.categoryId == _filterCategory);
      return matchSearch && matchCat;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredNotes;
    final pinned = filtered.where((n) => n.pinned).toList();
    final unpinned = filtered.where((n) => !n.pinned).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              SizedBox(
                width: double.infinity,
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 10,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Anotações',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.onPrimary,
                              ),
                        ),
                        Text(
                          '${filtered.length} de ${widget.notes.length} anotações',
                          style: const TextStyle(
                            fontFamily: 'Lora',
                            fontSize: 13,
                            color: AppColors.onMuted,
                          ),
                        ),
                      ],
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        
                        FilledButton.icon(
                          onPressed: () {
                            showNoteDialog(
                              context,
                              categories: widget.categories,
                              onSave: widget.onAddNote,
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
                            'Nova Anotação',
                            style: TextStyle(fontFamily: 'Lora', fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Search + Category Filter
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _search = v),
                      style: const TextStyle(fontFamily: 'Lora', fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Buscar anotações...',
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
                  SizedBox(
                    width: 150,
                    child: DropdownButtonFormField<String>(
                      initialValue: _filterCategory,
                      isExpanded: true,
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: AppColors.cardBackGround,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
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
                      items: [
                        const DropdownMenuItem(
                          value: 'all',
                          child: Text(
                            'Todas',
                            style: TextStyle(fontFamily: 'Lora', fontSize: 12),
                          ),
                        ),
                        const DropdownMenuItem(
                          value: 'none',
                          child: Text(
                            'Sem categoria',
                            style: TextStyle(fontFamily: 'Lora', fontSize: 12),
                          ),
                        ),
                        ...widget.categories.map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(
                              c.name,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Lora',
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _filterCategory = v);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              if (pinned.isNotEmpty) ...[
                _NotesSectionHeader(
                  icon: LucideIcons.pin,
                  title: 'Fixadas',
                  count: pinned.length,
                  iconColor: AppColors.primary,
                ),
                const SizedBox(height: 12),
                ...pinned.map(
                  (note) => _NoteCard(
                    note: note,
                    categoryName: _getCategoryName(note.categoryId),
                    onTogglePin: () => widget.onTogglePin(note.id),
                    onEdit: () {
                      showNoteDialog(
                        context,
                        note: note,
                        categories: widget.categories,
                        onSave: widget.onUpdateNote,
                      );
                    },
                    onDelete: () => widget.onDeleteNote(note.id),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              if (unpinned.isNotEmpty) ...[
                _NotesSectionHeader(
                  icon: LucideIcons.fileText,
                  title: pinned.isNotEmpty ? 'Outras Anotações' : 'Anotações',
                  count: unpinned.length,
                  iconColor: AppColors.onMuted,
                ),
                const SizedBox(height: 12),
                ...unpinned.map(
                  (note) => _NoteCard(
                    note: note,
                    categoryName: _getCategoryName(note.categoryId),
                    onTogglePin: () => widget.onTogglePin(note.id),
                    onEdit: () {
                      showNoteDialog(
                        context,
                        note: note,
                        categories: widget.categories,
                        onSave: widget.onUpdateNote,
                      );
                    },
                    onDelete: () => widget.onDeleteNote(note.id),
                  ),
                ),
              ],

              if (filtered.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Column(
                      children: [
                        Text(
                          'Nenhuma anotação encontrada',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(color: AppColors.onMuted),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _search.isNotEmpty || _filterCategory != 'all'
                              ? 'Tente ajustar a busca'
                              : 'Clique em "Nova Anotação" para começar',
                          style: const TextStyle(
                            fontFamily: 'Caveat',
                            fontSize: 18,
                            color: AppColors.onMuted,
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
    );
  }
}

class _NotesSectionHeader extends StatelessWidget {
  const _NotesSectionHeader({
    required this.icon,
    required this.title,
    required this.count,
    required this.iconColor,
  });

  final IconData icon;
  final String title;
  final int count;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: iconColor),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.only(bottom: 2),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: AppColors.primary.withValues(alpha: 0.4),
                width: 2,
              ),
            ),
          ),
          child: Text(
            title,
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
          '$count',
          style: const TextStyle(
            fontFamily: 'Caveat',
            fontSize: 17,
            color: AppColors.onMuted,
          ),
        ),
      ],
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({
    required this.note,
    required this.categoryName,
    required this.onTogglePin,
    required this.onEdit,
    required this.onDelete,
  });

  final Note note;
  final String categoryName;
  final VoidCallback onTogglePin;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final parsedDate = DateTime.tryParse(note.updatedAt);
    final dateStr = parsedDate != null
        ? DateFormat('d MMM yyyy', 'pt_BR').format(parsedDate)
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: note.pinned
            ? AppColors.primary.withValues(alpha: 0.05)
            : AppColors.cardBackGround,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: note.pinned
              ? AppColors.primary.withValues(alpha: 0.35)
              : AppColors.border,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  note.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Playfair Display',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onPrimary,
                  ),
                ),
              ),
              if (note.pinned)
                const Icon(
                  LucideIcons.pin,
                  size: 14,
                  color: AppColors.primary,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            note.content.isEmpty ? 'Sem conteúdo' : note.content,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Lora',
              fontSize: 13,
              fontStyle: note.content.isEmpty
                  ? FontStyle.italic
                  : FontStyle.normal,
              color: AppColors.onMuted,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
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
                  child: Text(
                    categoryName,
                    style: const TextStyle(
                      fontFamily: 'Lora',
                      fontSize: 11,
                      color: AppColors.onMuted,
                    ),
                  ),
                ),
              ...note.tags.take(3).map(
                (t) => Text(
                  '#$t',
                  style: const TextStyle(
                    fontFamily: 'Lora',
                    fontSize: 11,
                    color: AppColors.onMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateStr,
                style: const TextStyle(
                  fontFamily: 'Caveat',
                  fontSize: 14,
                  color: AppColors.onMuted,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: note.pinned ? 'Desafixar' : 'Fixar',
                    onPressed: onTogglePin,
                    icon: Icon(
                      note.pinned ? LucideIcons.pinOff : LucideIcons.pin,
                      size: 15,
                      color: AppColors.onMuted,
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
            ],
          ),
        ],
      ),
    );
  }
}
