import 'package:app/models/models.dart';
import 'package:app/themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

const List<String> kCategoryIconOptions = [
  'User',
  'Briefcase',
  'BookOpen',
  'Heart',
  'DollarSign',
  'Home',
  'Star',
  'Zap',
  'Globe',
  'Music',
  'Camera',
  'Coffee',
  'Smile',
  'Target',
  'Award',
];

const List<String> kCategoryColorOptions = [
  '#C0533A',
  '#4A7C59',
  '#7C5A3A',
  '#A05C7A',
  '#5A7C3A',
  '#3A5A7C',
  '#7C3A5A',
  '#5A3A7C',
  '#7C7A3A',
  '#3A7C7A',
  '#B45309',
  '#0F766E',
  '#6D28D9',
  '#BE185D',
  '#1D4ED8',
];

Future<void> showCategoryDialog(
  BuildContext context, {
  required ValueChanged<Category> onSave,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => _CategoryDialog(onSave: onSave),
  );
}

class _CategoryDialog extends StatefulWidget {
  const _CategoryDialog({required this.onSave});

  final ValueChanged<Category> onSave;

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  final _nameController = TextEditingController();
  String _selectedColor = kCategoryColorOptions.first;
  String _selectedIcon = kCategoryIconOptions.first;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Color _parseHex(String hex) {
    final cleaned = hex.replaceFirst('#', '');
    final val = int.tryParse('FF$cleaned', radix: 16);
    return val != null ? Color(val) : AppColors.primary;
  }

  void _handleSave() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('O nome é obrigatório.')),
      );
      return;
    }

    final cat = Category(
      id: 'cat-${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      color: _selectedColor,
      icon: _selectedIcon,
    );

    widget.onSave(cat);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final previewName = _nameController.text.trim();
    final initial = previewName.isNotEmpty
        ? previewName[0].toUpperCase()
        : '?';

    return Dialog(
      backgroundColor: AppColors.cardBackGround,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Nova Categoria',
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
                const SizedBox(height: 10),

                const Text(
                  'Nome *',
                  style: TextStyle(
                    fontFamily: 'Lora',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _nameController,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(fontFamily: 'Lora', fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Nome da categoria...',
                    isDense: true,
                    filled: true,
                    fillColor: AppColors.background,
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
                const SizedBox(height: 16),

                const Text(
                  'Cor',
                  style: TextStyle(
                    fontFamily: 'Lora',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: kCategoryColorOptions.map((c) {
                    final isSelected = _selectedColor == c;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedColor = c),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: _parseHex(c),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? AppColors.onPrimary
                                : Colors.transparent,
                            width: 2.5,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                const Text(
                  'Ícone',
                  style: TextStyle(
                    fontFamily: 'Lora',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: kCategoryIconOptions.map((i) {
                    final isSelected = _selectedIcon == i;
                    return InkWell(
                      onTap: () => setState(() => _selectedIcon = i),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.background,
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.border,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          i,
                          style: TextStyle(
                            fontFamily: 'Lora',
                            fontSize: 12,
                            color: isSelected
                                ? Colors.white
                                : AppColors.onMuted,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Preview
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.muted,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: _parseHex(_selectedColor),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          initial,
                          style: const TextStyle(
                            fontFamily: 'Playfair Display',
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              previewName.isEmpty
                                  ? 'Nome da categoria'
                                  : previewName,
                              style: const TextStyle(
                                fontFamily: 'Lora',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.onPrimary,
                              ),
                            ),
                            Text(
                              'Ícone: $_selectedIcon',
                              style: const TextStyle(
                                fontFamily: 'Caveat',
                                fontSize: 14,
                                color: AppColors.onMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

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
                    FilledButton(
                      onPressed: _handleSave,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text(
                        'Criar Categoria',
                        style: TextStyle(fontFamily: 'Lora'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
