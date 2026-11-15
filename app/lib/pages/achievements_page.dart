import 'package:app/models/models.dart';
import 'package:app/themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AchievementsPage extends StatelessWidget {
  const AchievementsPage({
    required this.tasks,
    required this.badges,
    required this.totalPoints,
    required this.currentLevel,
    required this.pointsToNextLevel,
    required this.streakDays,
    super.key,
  });

  final List<Task> tasks;
  final List<AchievementBadge> badges;
  final int totalPoints;
  final int currentLevel;
  final int pointsToNextLevel;
  final int streakDays;

  @override
  Widget build(BuildContext context) {
    final unlocked = badges.where((b) => b.isUnlocked).toList();
    final locked = badges.where((b) => !b.isUnlocked).toList();
    final completedCount = tasks
        .where((t) => t.status == TaskStatus.done)
        .length;
    final highPriorityDone = tasks
        .where((t) => t.priority == Priority.high && t.status == TaskStatus.done)
        .length;

    final levelProgress = ((100 - pointsToNextLevel) / 100).clamp(0.0, 1.0);
    final badgePct = badges.isNotEmpty
        ? ((unlocked.length / badges.length) * 100).round()
        : 0;

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
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.trophy,
                        size: 28,
                        color: AppColors.onPrimary,
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Conquistas',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.onPrimary,
                                ),
                          ),
                          const Text(
                            'Desbloqueie medalhas completando tarefas',
                            style: TextStyle(
                              fontFamily: 'Lora',
                              fontSize: 12,
                              color: AppColors.onMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${unlocked.length}/${badges.length}',
                        style: const TextStyle(
                          fontFamily: 'Playfair Display',
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onPrimary,
                        ),
                      ),
                      const Text(
                        'desbloqueadas',
                        style: TextStyle(
                          fontFamily: 'Lora',
                          fontSize: 11,
                          color: AppColors.onMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Level Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBackGround,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'NÍVEL',
                              style: TextStyle(
                                fontFamily: 'Lora',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.onMuted,
                              ),
                            ),
                            Text(
                              '$currentLevel',
                              style: const TextStyle(
                                fontFamily: 'Playfair Display',
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                color: AppColors.onPrimary,
                              ),
                            ),
                          ],
                        ),
                        Icon(
                          LucideIcons.star,
                          size: 30,
                          color: AppColors.primary.withValues(alpha: 0.35),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Próximo nível',
                          style: TextStyle(
                            fontFamily: 'Lora',
                            fontSize: 12,
                            color: AppColors.onMuted,
                          ),
                        ),
                        Text(
                          '${(levelProgress * 100).round()}%',
                          style: const TextStyle(
                            fontFamily: 'Lora',
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: levelProgress,
                        minHeight: 8,
                        backgroundColor: AppColors.muted,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Divider(color: AppColors.border, height: 1),
                    const SizedBox(height: 8),
                    Text(
                      '$totalPoints pontos totais • $pointsToNextLevel pts para o próximo nível',
                      style: const TextStyle(
                        fontFamily: 'Lora',
                        fontSize: 12,
                        color: AppColors.onMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Streak + Progress row
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackGround,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.border,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.flame,
                            size: 26,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'SEQUÊNCIA',
                                style: TextStyle(
                                  fontFamily: 'Lora',
                                  fontSize: 10,
                                  color: AppColors.onMuted,
                                ),
                              ),
                              Text(
                                '$streakDays',
                                style: const TextStyle(
                                  fontFamily: 'Playfair Display',
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text(
                                'dias seguidos',
                                style: TextStyle(
                                  fontFamily: 'Lora',
                                  fontSize: 11,
                                  color: AppColors.onMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackGround,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.border,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'PROGRESSO',
                                style: TextStyle(
                                  fontFamily: 'Lora',
                                  fontSize: 10,
                                  color: AppColors.onMuted,
                                ),
                              ),
                              Text(
                                '$badgePct%',
                                style: const TextStyle(
                                  fontFamily: 'Playfair Display',
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${unlocked.length} de ${badges.length}',
                                style: const TextStyle(
                                  fontFamily: 'Lora',
                                  fontSize: 11,
                                  color: AppColors.onMuted,
                                ),
                              ),
                            ],
                          ),
                          Icon(
                            LucideIcons.award,
                            size: 24,
                            color: AppColors.primary.withValues(alpha: 0.35),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 4 Quick Stats
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.8,
                children: [
                  _QuickStatBox(
                    emoji: '✅',
                    value: '$completedCount',
                    label: 'Tarefas Concluídas',
                  ),
                  _QuickStatBox(
                    emoji: '⚡',
                    value: '$highPriorityDone',
                    label: 'Prioridade Alta',
                  ),
                  _QuickStatBox(
                    emoji: '🔥',
                    value: '$streakDays',
                    label: 'Sequência',
                  ),
                  _QuickStatBox(
                    emoji: '⭐',
                    value: '$totalPoints',
                    label: 'Pontos Totais',
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Unlocked Badges
              Row(
                children: [
                  const Icon(
                    LucideIcons.star,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Medalhas Desbloqueadas (${unlocked.length})',
                    style: const TextStyle(
                      fontFamily: 'Playfair Display',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (unlocked.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.muted.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Nenhuma medalha desbloqueada ainda. Comece a completar tarefas!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Lora',
                      fontSize: 13,
                      color: AppColors.onMuted,
                    ),
                  ),
                )
              else
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.9,
                  children: unlocked
                      .map((b) => _BadgeCardWidget(badge: b))
                      .toList(),
                ),
              const SizedBox(height: 24),

              // Locked Badges
              Row(
                children: [
                  const Icon(
                    LucideIcons.award,
                    size: 20,
                    color: AppColors.onMuted,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Próximas Medalhas (${locked.length})',
                    style: const TextStyle(
                      fontFamily: 'Playfair Display',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.9,
                children: locked
                    .map((b) => _BadgeCardWidget(badge: b))
                    .toList(),
              ),
              const SizedBox(height: 24),

              // Como Desbloquear Medalhas
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.cardBackGround,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Como Desbloquear Medalhas',
                      style: TextStyle(
                        fontFamily: 'Playfair Display',
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...badges.map(
                      (b) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.muted.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Text(
                              b.icon,
                              style: const TextStyle(fontSize: 20),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    b.name,
                                    style: const TextStyle(
                                      fontFamily: 'Lora',
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.onPrimary,
                                    ),
                                  ),
                                  Text(
                                    b.description,
                                    style: const TextStyle(
                                      fontFamily: 'Lora',
                                      fontSize: 11,
                                      color: AppColors.onMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Sistema de Pontos
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.cardBackGround,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sistema de Pontos',
                      style: TextStyle(
                        fontFamily: 'Playfair Display',
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onPrimary,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Ganhe pontos completando tarefas e desbloqueando medalhas:',
                      style: TextStyle(
                        fontFamily: 'Lora',
                        fontSize: 13,
                        color: AppColors.onPrimary,
                      ),
                    ),
                    SizedBox(height: 8),
                    _PointRuleBullet('10 pontos por tarefa concluída'),
                    _PointRuleBullet(
                      'Bônus de prioridade: +100% para alta, +50% para média',
                    ),
                    _PointRuleBullet(
                      'Bônus de velocidade: +5 pontos se concluir no mesmo dia',
                    ),
                    _PointRuleBullet(
                      'Bônus de sequência: +5 pontos por dia de sequência',
                    ),
                    _PointRuleBullet(
                      'Bônus de categoria: +2 pontos por 5 tarefas na mesma categoria',
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Acumule 100 pontos para subir de nível!',
                      style: TextStyle(
                        fontFamily: 'Lora',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickStatBox extends StatelessWidget {
  const _QuickStatBox({
    required this.emoji,
    required this.value,
    required this.label,
  });

  final String emoji;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.cardBackGround,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Playfair Display',
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.onPrimary,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Lora',
              fontSize: 11,
              color: AppColors.onMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeCardWidget extends StatelessWidget {
  const _BadgeCardWidget({required this.badge});

  final AchievementBadge badge;

  @override
  Widget build(BuildContext context) {
    final isUnlocked = badge.isUnlocked;
    final (bgColor, borderColor) = switch (badge.rarity) {
      BadgeRarity.common => (
        const Color(0xFFF3F4F6),
        const Color(0xFFD1D5DB),
      ),
      BadgeRarity.uncommon => (
        const Color(0xFFF0FDF4),
        const Color(0xFF86EFAC),
      ),
      BadgeRarity.rare => (
        const Color(0xFFEFF6FF),
        const Color(0xFF93C5FD),
      ),
      BadgeRarity.epic => (
        const Color(0xFFFAF5FF),
        const Color(0xFFD8B4FE),
      ),
      BadgeRarity.legendary => (
        const Color(0xFFFEFCE8),
        const Color(0xFFFDE047),
      ),
    };

    return Tooltip(
      message: '${badge.name}: ${badge.description}',
      child: Opacity(
        opacity: isUnlocked ? 1.0 : 0.55,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isUnlocked ? bgColor : AppColors.muted,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isUnlocked ? borderColor : AppColors.border,
              width: 1.5,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(badge.icon, style: const TextStyle(fontSize: 24)),
                  const SizedBox(height: 6),
                  Text(
                    badge.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Lora',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onPrimary,
                    ),
                  ),
                ],
              ),
              if (!isUnlocked)
                const Positioned(
                  top: 2,
                  right: 2,
                  child: Icon(
                    LucideIcons.lock,
                    size: 13,
                    color: AppColors.onMuted,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PointRuleBullet extends StatelessWidget {
  const _PointRuleBullet(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'Lora',
                fontSize: 12,
                color: AppColors.onMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
