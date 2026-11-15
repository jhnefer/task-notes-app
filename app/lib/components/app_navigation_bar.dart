import 'package:app/themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AppNavigationBar extends StatelessWidget {
  const AppNavigationBar({
    required this.selectedIndex,
    this.onSelectIndex,
    this.urgentBadgeCount = 0,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int>? onSelectIndex;
  final int urgentBadgeCount;

  static const List<int> mainRouteIndices = [0, 1, 2, 4];

  static const List<({int routeIndex, String label, IconData icon, bool showBadge})>
  _items = [
    (
      routeIndex: 0,
      label: 'Início',
      icon: LucideIcons.layoutDashboard200,
      showBadge: true,
    ),
    (
      routeIndex: 1,
      label: 'Tarefas',
      icon: LucideIcons.checkSquare200,
      showBadge: true,
    ),
    (
      routeIndex: 2,
      label: 'Anotações',
      icon: LucideIcons.fileText200,
      showBadge: false,
    ),
    (
      routeIndex: 4,
      label: 'Relatórios',
      icon: LucideIcons.barChart3200,
      showBadge: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.background,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.cardBackGround,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: AppColors.border,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.secondary.withValues(alpha: 0.14),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: _items.map((item) {
                final isSelected = selectedIndex == item.routeIndex;
                final badgeText = item.showBadge && urgentBadgeCount > 0
                    ? '$urgentBadgeCount'
                    : null;

                return Expanded(
                  child: _NavPillItem(
                    label: item.label,
                    icon: item.icon,
                    selected: isSelected,
                    badge: badgeText,
                    onTap: () => onSelectIndex?.call(item.routeIndex),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavPillItem extends StatelessWidget {
  const _NavPillItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final String? badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fgColor = selected ? AppColors.cardBackGround : AppColors.onMuted;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.28),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    icon,
                    size: 19,
                    color: fgColor,
                  ),
                  if (badge != null)
                    Positioned(
                      top: -5,
                      right: -9,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4.5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.chartPriorityMedium
                              : AppColors.destructive,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: selected
                                ? AppColors.primary
                                : AppColors.cardBackGround,
                            width: 1.2,
                          ),
                        ),
                        child: Text(
                          badge!,
                          style: const TextStyle(
                            fontFamily: 'Lora',
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Lora',
                  fontSize: 11.5,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: fgColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
