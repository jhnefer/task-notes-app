import 'package:app/models/models.dart';
import 'package:app/themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class NotificationBadge extends StatelessWidget {
  const NotificationBadge({
    required this.critical,
    required this.high,
    required this.medium,
    this.small = false,
    super.key,
  });

  final int critical;
  final int high;
  final int medium;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final total = critical + high + medium;
    if (total == 0) return const SizedBox.shrink();

    Color bgColor = AppColors.muted;
    Color textColor = AppColors.onMuted;
    IconData icon = LucideIcons.clock;

    if (critical > 0) {
      bgColor = AppColors.destructive;
      textColor = Colors.white;
      icon = LucideIcons.triangleAlert;
    } else if (high > 0) {
      bgColor = AppColors.chartPriorityMedium;
      textColor = Colors.white;
      icon = LucideIcons.circleAlert;
    } else if (medium > 0) {
      bgColor = AppColors.primary;
      textColor = Colors.white;
      icon = LucideIcons.clock;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 6 : 8,
        vertical: small ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: small ? 10 : 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            '$total',
            style: TextStyle(
              fontFamily: 'Lora',
              fontSize: small ? 11 : 12,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class NotificationAlert extends StatelessWidget {
  const NotificationAlert({
    required this.critical,
    required this.high,
    super.key,
  });

  final int critical;
  final int high;

  @override
  Widget build(BuildContext context) {
    if (critical == 0 && high == 0) return const SizedBox.shrink();

    final isCritical = critical > 0;
    final message = isCritical
        ? '$critical tarefa${critical > 1 ? 's' : ''} em atraso ou vencendo em breve!'
        : '$high tarefa${high > 1 ? 's' : ''} vencendo nas próximas horas';

    final bgColor = isCritical
        ? AppColors.destructive.withValues(alpha: 0.1)
        : const Color(0xFFFFFBEB);
    final borderColor = isCritical
        ? AppColors.destructive.withValues(alpha: 0.3)
        : const Color(0xFFFDE68A);
    final fgColor = isCritical
        ? AppColors.destructive
        : const Color(0xFF78350F);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            isCritical ? LucideIcons.triangleAlert : LucideIcons.circleAlert,
            size: 18,
            color: fgColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontFamily: 'Lora',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: fgColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> showNotificationPanelDialog(
  BuildContext context, {
  required List<TaskNotification> notifications,
  VoidCallback? onEnableNotifications,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => _NotificationPanelDialog(
      notifications: notifications,
      onEnableNotifications: onEnableNotifications,
    ),
  );
}

class _NotificationPanelDialog extends StatelessWidget {
  const _NotificationPanelDialog({
    required this.notifications,
    this.onEnableNotifications,
  });

  final List<TaskNotification> notifications;
  final VoidCallback? onEnableNotifications;

  int _countBy(NotificationUrgency u) =>
      notifications.where((n) => n.urgency == u).length;

  @override
  Widget build(BuildContext context) {
    final critical = _countBy(NotificationUrgency.critical);
    final high = _countBy(NotificationUrgency.high);
    final medium = _countBy(NotificationUrgency.medium);
    final low = _countBy(NotificationUrgency.low);

    return Dialog(
      backgroundColor: AppColors.cardBackGround,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 620),
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
                        LucideIcons.bell,
                        size: 20,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Notificações',
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
              const SizedBox(height: 12),

              // Ativar notificações nativas
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.muted.withValues(alpha: 0.6),
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Notificações do Dispositivo',
                            style: TextStyle(
                              fontFamily: 'Lora',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onPrimary,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Receba alertas de prazos mesmo com o app em segundo plano',
                            style: TextStyle(
                              fontFamily: 'Lora',
                              fontSize: 11,
                              color: AppColors.onMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () {
                        onEnableNotifications?.call();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Notificações do dispositivo ativadas!'),
                          ),
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                      ),
                      child: const Text(
                        'Ativar',
                        style: TextStyle(fontFamily: 'Lora', fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Stats
              Row(
                children: [
                  _UrgencyStatBox(
                    label: 'Crítico',
                    count: critical,
                    bgColor: AppColors.destructive.withValues(alpha: 0.1),
                    textColor: AppColors.destructive,
                  ),
                  const SizedBox(width: 8),
                  _UrgencyStatBox(
                    label: 'Urgente',
                    count: high,
                    bgColor: const Color(0xFFFFFBEB),
                    textColor: const Color(0xFFB45309),
                  ),
                  const SizedBox(width: 8),
                  _UrgencyStatBox(
                    label: 'Próximo',
                    count: medium,
                    bgColor: AppColors.primary.withValues(alpha: 0.1),
                    textColor: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  _UrgencyStatBox(
                    label: 'Baixo',
                    count: low,
                    bgColor: AppColors.muted,
                    textColor: AppColors.onMuted,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Lista de notificações
              Flexible(
                child: notifications.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 28),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                LucideIcons.circleCheck,
                                size: 36,
                                color: AppColors.chartPriorityLow,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Nenhuma notificação',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(color: AppColors.onMuted),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Todas as tarefas estão em dia!',
                                style: TextStyle(
                                  fontFamily: 'Lora',
                                  fontSize: 12,
                                  color: AppColors.onMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: notifications.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final notif = notifications[index];
                          return _NotificationTile(notification: notif);
                        },
                      ),
              ),

              const SizedBox(height: 12),
              const Divider(color: AppColors.border, height: 1),
              const SizedBox(height: 10),
              const Center(
                child: Text(
                  'Notificações são verificadas a cada atualização das tarefas',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Lora',
                    fontSize: 11,
                    color: AppColors.onMuted,
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

class _UrgencyStatBox extends StatelessWidget {
  const _UrgencyStatBox({
    required this.label,
    required this.count,
    required this.bgColor,
    required this.textColor,
  });

  final String label;
  final int count;
  final Color bgColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontFamily: 'Playfair Display',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Lora',
                fontSize: 11,
                color: AppColors.onMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification});

  final TaskNotification notification;

  @override
  Widget build(BuildContext context) {
    final (bgColor, borderColor, fgColor, icon, label) =
        switch (notification.urgency) {
          NotificationUrgency.critical => (
            AppColors.destructive.withValues(alpha: 0.1),
            AppColors.destructive.withValues(alpha: 0.3),
            AppColors.destructive,
            LucideIcons.triangleAlert,
            'Crítico',
          ),
          NotificationUrgency.high => (
            const Color(0xFFFFFBEB),
            const Color(0xFFFDE68A),
            const Color(0xFF78350F),
            LucideIcons.circleAlert,
            'Urgente',
          ),
          NotificationUrgency.medium => (
            AppColors.primary.withValues(alpha: 0.1),
            AppColors.primary.withValues(alpha: 0.3),
            AppColors.primary,
            LucideIcons.clock,
            'Próximo',
          ),
          NotificationUrgency.low => (
            AppColors.muted,
            AppColors.border,
            AppColors.onMuted,
            LucideIcons.clock,
            'Baixo',
          ),
        };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 16, color: fgColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: TextStyle(
                    fontFamily: 'Lora',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: fgColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  notification.message,
                  style: TextStyle(
                    fontFamily: 'Lora',
                    fontSize: 11,
                    color: fgColor.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Caveat',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: fgColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
