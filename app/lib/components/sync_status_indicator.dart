import 'dart:async';
import 'package:app/models/models.dart';
import 'package:app/themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SyncStatusIndicator extends StatefulWidget {
  const SyncStatusIndicator({
    required this.state,
    this.pendingCount = 0,
    this.onTap,
    super.key,
  });

  final SyncState state;
  final int pendingCount;
  final VoidCallback? onTap;

  @override
  State<SyncStatusIndicator> createState() => _SyncStatusIndicatorState();
}

class _SyncStatusIndicatorState extends State<SyncStatusIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spinController;
  bool _recentlySyncedHighlight = false;
  Timer? _fadeTimer;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (widget.state == SyncState.syncing) {
      _spinController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant SyncStatusIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state == SyncState.syncing && !_spinController.isAnimating) {
      _spinController.repeat();
    } else if (widget.state != SyncState.syncing &&
        _spinController.isAnimating) {
      _spinController.stop();
      _spinController.reset();
    }

    if (oldWidget.state == SyncState.syncing &&
        widget.state == SyncState.synced) {
      setState(() => _recentlySyncedHighlight = true);
      _fadeTimer?.cancel();
      _fadeTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() => _recentlySyncedHighlight = false);
        }
      });
    }
  }

  @override
  void dispose() {
    _fadeTimer?.cancel();
    _spinController.dispose();
    super.dispose();
  }

  String _tooltipMessage() {
    return switch (widget.state) {
      SyncState.localOnly => 'Modo Offline (dados salvos neste dispositivo)',
      SyncState.syncing => 'Sincronizando em segundo plano...',
      SyncState.synced => 'Sincronizado na nuvem',
      SyncState.pendingOffline => widget.pendingCount > 0
          ? 'Salvo no dispositivo • ${widget.pendingCount} pendência(s) aguardando conexão'
          : 'Salvo no dispositivo • Aguardando conexão',
    };
  }

  @override
  Widget build(BuildContext context) {
    // No modo 100% offline sem conta, não polui a AppBar
    if (widget.state == SyncState.localOnly) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = isDark ? AppColors.darkOnMuted : AppColors.onMuted;

    return Tooltip(
      message: _tooltipMessage(),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: switch (widget.state) {
              SyncState.syncing => Row(
                key: const ValueKey('syncing'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  RotationTransition(
                    turns: _spinController,
                    child: Icon(
                      LucideIcons.refreshCw,
                      size: 14,
                      color: AppColors.primary.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.75),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              SyncState.pendingOffline => Stack(
                key: const ValueKey('pendingOffline'),
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    LucideIcons.cloudOff,
                    size: 15,
                    color: mutedColor.withValues(alpha: 0.75),
                  ),
                  if (widget.pendingCount > 0)
                    Positioned(
                      top: -2,
                      right: -3,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.chartPriorityMedium,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              SyncState.synced => AnimatedOpacity(
                key: const ValueKey('synced'),
                duration: const Duration(milliseconds: 600),
                opacity: _recentlySyncedHighlight ? 0.95 : 0.38,
                child: const Icon(
                  LucideIcons.cloudCheck,
                  size: 16,
                  color: Color(0xFF4A7C59),
                ),
              ),
              SyncState.localOnly => const SizedBox.shrink(),
            },
          ),
        ),
      ),
    );
  }
}
