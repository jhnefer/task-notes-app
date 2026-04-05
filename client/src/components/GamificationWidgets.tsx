/**
 * GamificationWidgets — UI components for gamification
 * Design: Warm Paper Notebook
 */

import { useGamificationContext } from '@/contexts/GamificationContext';
import { Badge } from '@/hooks/useGamification';
import { cn } from '@/lib/utils';
import { Star, Award, Flame, Lock } from 'lucide-react';

/**
 * Level and Points Display
 */
export function LevelDisplay() {
  const { state, getLevelProgress } = useGamificationContext();
  const progress = getLevelProgress();

  return (
    <div className="bg-card border border-border rounded-lg p-4 space-y-3">
      <div className="flex items-center justify-between">
        <div>
          <p className="font-body text-xs text-muted-foreground uppercase">Nível</p>
          <p className="font-display text-3xl font-bold text-foreground">{state.currentLevel}</p>
        </div>
        <Star size={32} className="text-primary/30" />
      </div>

      {/* Progress Bar */}
      <div className="space-y-1">
        <div className="flex items-center justify-between">
          <p className="font-body text-xs text-muted-foreground">Próximo nível</p>
          <p className="font-body text-xs font-semibold text-foreground">{Math.round(progress)}%</p>
        </div>
        <div className="w-full h-2 bg-muted rounded-full overflow-hidden">
          <div
            className="h-full bg-gradient-to-r from-primary to-primary/70 transition-all duration-300"
            style={{ width: `${progress}%` }}
          />
        </div>
      </div>

      {/* Points */}
      <div className="pt-2 border-t border-border">
        <p className="font-body text-sm">
          <span className="font-semibold text-foreground">{state.totalPoints}</span>
          <span className="text-muted-foreground ml-1">pontos totais</span>
        </p>
        <p className="font-body text-xs text-muted-foreground mt-1">
          {state.pointsToNextLevel} pontos para o próximo nível
        </p>
      </div>
    </div>
  );
}

/**
 * Streak Display
 */
export function StreakDisplay() {
  const { state } = useGamificationContext();

  return (
    <div className="bg-card border border-border rounded-lg p-4">
      <div className="flex items-center gap-3">
        <div className="text-3xl">
          <Flame size={28} className="text-[#C0533A]" />
        </div>
        <div>
          <p className="font-body text-xs text-muted-foreground uppercase">Sequência</p>
          <p className="font-display text-2xl font-bold text-foreground">{state.streakDays}</p>
          <p className="font-body text-xs text-muted-foreground">dias consecutivos</p>
        </div>
      </div>
    </div>
  );
}

/**
 * Badge Grid
 */
export function BadgeGrid() {
  const { getAllBadges } = useGamificationContext();
  const badges = getAllBadges();

  return (
    <div className="grid grid-cols-3 sm:grid-cols-4 md:grid-cols-5 gap-3">
      {badges.map(badge => (
        <BadgeCard key={badge.id} badge={badge} />
      ))}
    </div>
  );
}

/**
 * Individual Badge Card
 */
export function BadgeCard({ badge }: { badge: Badge }) {
  const isUnlocked = !!badge.unlockedAt;

  const rarityColors = {
    common: 'bg-gray-100 border-gray-300',
    uncommon: 'bg-green-50 border-green-300',
    rare: 'bg-blue-50 border-blue-300',
    epic: 'bg-purple-50 border-purple-300',
    legendary: 'bg-yellow-50 border-yellow-300',
  };

  const rarityLabels = {
    common: 'Comum',
    uncommon: 'Incomum',
    rare: 'Raro',
    epic: 'Épico',
    legendary: 'Lendário',
  };

  return (
    <div
      className={cn(
        'relative aspect-square rounded-lg border-2 flex flex-col items-center justify-center p-2 transition-all',
        isUnlocked ? rarityColors[badge.rarity] : 'bg-muted border-muted-foreground/20',
        isUnlocked ? 'cursor-pointer hover:shadow-md' : 'opacity-50'
      )}
      title={isUnlocked ? `${badge.name} - ${badge.description}` : 'Bloqueado'}
    >
      {!isUnlocked && (
        <div className="absolute inset-0 flex items-center justify-center bg-black/10 rounded-md">
          <Lock size={16} className="text-muted-foreground" />
        </div>
      )}

      <div className="text-2xl mb-1">{badge.icon}</div>
      <p className="font-body text-xs font-semibold text-center text-foreground line-clamp-2">
        {badge.name}
      </p>

      {isUnlocked && badge.unlockedAt && (
        <p className="font-body text-xs text-muted-foreground mt-1">
          {new Date(badge.unlockedAt).toLocaleDateString('pt-BR')}
        </p>
      )}
    </div>
  );
}

/**
 * Points Breakdown Tooltip
 */
export function PointsBreakdownDisplay({
  breakdown,
}: {
  breakdown: {
    basePoints: number;
    priorityBonus: number;
    speedBonus: number;
    streakBonus: number;
    categoryBonus: number;
    totalPoints: number;
  };
}) {
  return (
    <div className="bg-card border border-border rounded-lg p-3 space-y-2 text-sm">
      <div className="flex justify-between font-body">
        <span className="text-muted-foreground">Pontos base:</span>
        <span className="font-semibold text-foreground">+{breakdown.basePoints}</span>
      </div>

      {breakdown.priorityBonus > 0 && (
        <div className="flex justify-between font-body">
          <span className="text-muted-foreground">Bônus prioridade:</span>
          <span className="font-semibold text-foreground">+{breakdown.priorityBonus}</span>
        </div>
      )}

      {breakdown.speedBonus > 0 && (
        <div className="flex justify-between font-body">
          <span className="text-muted-foreground">Bônus velocidade:</span>
          <span className="font-semibold text-foreground">+{breakdown.speedBonus}</span>
        </div>
      )}

      {breakdown.streakBonus > 0 && (
        <div className="flex justify-between font-body">
          <span className="text-muted-foreground">Bônus sequência:</span>
          <span className="font-semibold text-foreground">+{breakdown.streakBonus}</span>
        </div>
      )}

      {breakdown.categoryBonus > 0 && (
        <div className="flex justify-between font-body">
          <span className="text-muted-foreground">Bônus categoria:</span>
          <span className="font-semibold text-foreground">+{breakdown.categoryBonus}</span>
        </div>
      )}

      <div className="border-t border-border pt-2 flex justify-between font-body font-semibold">
        <span className="text-foreground">Total:</span>
        <span className="text-primary text-lg">+{breakdown.totalPoints}</span>
      </div>
    </div>
  );
}

/**
 * Achievement Notification
 */
export function AchievementNotification({
  badge,
  onClose,
}: {
  badge: Badge;
  onClose: () => void;
}) {
  return (
    <div className="fixed bottom-4 right-4 bg-card border-2 border-primary rounded-lg p-4 shadow-lg animate-in slide-in-from-bottom-4 max-w-sm">
      <div className="flex items-start gap-3">
        <div className="text-4xl">{badge.icon}</div>
        <div className="flex-1">
          <p className="font-display font-bold text-foreground">Conquista Desbloqueada!</p>
          <p className="font-body font-semibold text-foreground mt-1">{badge.name}</p>
          <p className="font-body text-sm text-muted-foreground">{badge.description}</p>
          <p className="font-body text-xs text-muted-foreground mt-2 capitalize">
            Raridade: {badge.rarity}
          </p>
        </div>
        <button
          onClick={onClose}
          className="text-muted-foreground hover:text-foreground transition-colors"
        >
          ✕
        </button>
      </div>
    </div>
  );
}
