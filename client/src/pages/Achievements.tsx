/**
 * Achievements — Gamification achievements and badges page
 * Design: Warm Paper Notebook
 */

import { useMemo } from 'react';
import { Trophy, Star, Flame, Award } from 'lucide-react';
import { useGamificationContext } from '@/contexts/GamificationContext';
import { useApp } from '@/contexts/AppContext';
import { cn } from '@/lib/utils';
import { LevelDisplay, StreakDisplay, BadgeGrid, BadgeCard } from '@/components/GamificationWidgets';
import { Badge } from '@/hooks/useGamification';

export default function Achievements() {
  const { state, getAllBadges } = useGamificationContext();
  const { tasks } = useApp();

  const badges = getAllBadges();
  const unlockedBadges = useMemo(() => badges.filter(b => b.unlockedAt), [badges]);
  const lockedBadges = useMemo(() => badges.filter(b => !b.unlockedAt), [badges]);

  const completedCount = tasks.filter(t => t.status === 'done').length;
  const highPriorityCount = tasks.filter(t => t.priority === 'high' && t.status === 'done').length;

  return (
    <div className="min-h-full">
      {/* Header */}
      <div className="px-8 py-6 border-b border-border bg-card/50">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="font-display text-3xl font-bold text-foreground flex items-center gap-2">
              <Trophy size={32} />
              Conquistas
            </h1>
            <p className="font-body text-sm text-muted-foreground mt-0.5">
              Desbloqueie medalhas completando tarefas
            </p>
          </div>
          <div className="text-right">
            <p className="font-display text-2xl font-bold text-foreground">
              {unlockedBadges.length}/{badges.length}
            </p>
            <p className="font-body text-xs text-muted-foreground">medalhas desbloqueadas</p>
          </div>
        </div>
      </div>

      {/* Main Content */}
      <div className="px-8 py-6 space-y-8">
        {/* Top Stats */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <LevelDisplay />
          <StreakDisplay />
          <div className="bg-card border border-border rounded-lg p-4">
            <div className="flex items-start justify-between">
              <div>
                <p className="font-body text-xs text-muted-foreground uppercase">Progresso</p>
                <p className="font-display text-2xl font-bold text-foreground mt-1">
                  {Math.round((unlockedBadges.length / badges.length) * 100)}%
                </p>
              </div>
              <Award size={28} className="text-primary/30" />
            </div>
            <p className="font-body text-xs text-muted-foreground mt-3">
              {unlockedBadges.length} de {badges.length} medalhas
            </p>
          </div>
        </div>

        {/* Quick Stats */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <StatCard
            label="Tarefas Concluídas"
            value={completedCount}
            icon="✅"
          />
          <StatCard
            label="Prioridade Alta"
            value={highPriorityCount}
            icon="⚡"
          />
          <StatCard
            label="Sequência"
            value={state.streakDays}
            icon="🔥"
          />
          <StatCard
            label="Pontos Totais"
            value={state.totalPoints}
            icon="⭐"
          />
        </div>

        {/* Unlocked Badges */}
        <div>
          <div className="mb-6">
            <h2 className="font-display text-xl font-semibold text-foreground flex items-center gap-2 mb-4">
              <Star size={24} className="text-primary" />
              Medalhas Desbloqueadas ({unlockedBadges.length})
            </h2>
            {unlockedBadges.length > 0 ? (
              <div className="grid grid-cols-3 sm:grid-cols-4 md:grid-cols-5 lg:grid-cols-6 gap-3">
                {unlockedBadges.map(badge => (
                  <BadgeCard key={badge.id} badge={badge} />
                ))}
              </div>
            ) : (
              <div className="text-center py-8 bg-muted/30 rounded-lg">
                <p className="font-body text-muted-foreground">
                  Nenhuma medalha desbloqueada ainda. Comece a completar tarefas!
                </p>
              </div>
            )}
          </div>
        </div>

        {/* Locked Badges */}
        <div>
          <h2 className="font-display text-xl font-semibold text-foreground flex items-center gap-2 mb-4">
            <Award size={24} className="text-muted-foreground" />
            Próximas Medalhas ({lockedBadges.length})
          </h2>
          {lockedBadges.length > 0 ? (
            <div className="grid grid-cols-3 sm:grid-cols-4 md:grid-cols-5 lg:grid-cols-6 gap-3">
              {lockedBadges.map(badge => (
                <BadgeCard key={badge.id} badge={badge} />
              ))}
            </div>
          ) : (
            <div className="text-center py-8 bg-muted/30 rounded-lg">
              <p className="font-body text-muted-foreground">
                Parabéns! Você desbloqueou todas as medalhas! 🎉
              </p>
            </div>
          )}
        </div>

        {/* Badge Details */}
        <div className="bg-card border border-border rounded-lg p-6">
          <h2 className="font-display text-lg font-semibold text-foreground mb-4">
            Como Desbloquear Medalhas
          </h2>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <BadgeExplanation
              icon="✅"
              title="Conquistador"
              description="Conclua sua primeira tarefa"
            />
            <BadgeExplanation
              icon="🎯"
              title="Cinco Vitórias"
              description="Conclua 5 tarefas"
            />
            <BadgeExplanation
              icon="🏆"
              title="Dez Vezes Campeão"
              description="Conclua 10 tarefas"
            />
            <BadgeExplanation
              icon="👑"
              title="Mestre das Tarefas"
              description="Conclua 50 tarefas"
            />
            <BadgeExplanation
              icon="⭐"
              title="Lenda Viva"
              description="Conclua 100 tarefas"
            />
            <BadgeExplanation
              icon="🔥"
              title="Sequência de 3"
              description="Conclua tarefas por 3 dias consecutivos"
            />
            <BadgeExplanation
              icon="🌟"
              title="Semana Perfeita"
              description="Conclua tarefas por 7 dias consecutivos"
            />
            <BadgeExplanation
              icon="💎"
              title="Mês Implacável"
              description="Conclua tarefas por 30 dias consecutivos"
            />
            <BadgeExplanation
              icon="⚡"
              title="Domador de Prioridades"
              description="Conclua 10 tarefas de alta prioridade"
            />
            <BadgeExplanation
              icon="📚"
              title="Especialista em Categorias"
              description="Conclua 5 tarefas em uma mesma categoria"
            />
            <BadgeExplanation
              icon="⚡"
              title="Demônio da Velocidade"
              description="Conclua uma tarefa em menos de 1 hora"
            />
            <BadgeExplanation
              icon="🎨"
              title="Perfeccionista"
              description="Conclua uma tarefa de alta prioridade com prazo"
            />
          </div>
        </div>

        {/* Points System */}
        <div className="bg-card border border-border rounded-lg p-6">
          <h2 className="font-display text-lg font-semibold text-foreground mb-4">
            Sistema de Pontos
          </h2>
          <div className="space-y-3 font-body text-sm">
            <p className="text-foreground">
              Ganhe pontos completando tarefas e desbloqueando medalhas:
            </p>
            <ul className="space-y-2 text-muted-foreground">
              <li className="flex items-center gap-2">
                <span className="text-primary">•</span>
                <span><strong>10 pontos</strong> por tarefa concluída</span>
              </li>
              <li className="flex items-center gap-2">
                <span className="text-primary">•</span>
                <span><strong>Bônus de prioridade:</strong> +50% para alta, +50% para média</span>
              </li>
              <li className="flex items-center gap-2">
                <span className="text-primary">•</span>
                <span><strong>Bônus de velocidade:</strong> +5 pontos se concluir no mesmo dia</span>
              </li>
              <li className="flex items-center gap-2">
                <span className="text-primary">•</span>
                <span><strong>Bônus de sequência:</strong> +5 pontos por dia de sequência</span>
              </li>
              <li className="flex items-center gap-2">
                <span className="text-primary">•</span>
                <span><strong>Bônus de categoria:</strong> +2 pontos por 5 tarefas na mesma categoria</span>
              </li>
            </ul>
            <p className="text-foreground mt-4">
              Acumule <strong>100 pontos</strong> para subir de nível!
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}

/**
 * Stat Card Component
 */
function StatCard({ label, value, icon }: { label: string; value: number; icon: string }) {
  return (
    <div className="bg-card border border-border rounded-lg p-3 text-center">
      <div className="text-2xl mb-1">{icon}</div>
      <p className="font-display font-bold text-foreground text-lg">{value}</p>
      <p className="font-body text-xs text-muted-foreground">{label}</p>
    </div>
  );
}

/**
 * Badge Explanation Component
 */
function BadgeExplanation({ icon, title, description }: { icon: string; title: string; description: string }) {
  return (
    <div className="flex items-start gap-3 p-3 bg-muted/30 rounded-lg">
      <div className="text-2xl shrink-0">{icon}</div>
      <div className="min-w-0">
        <p className="font-body font-semibold text-foreground text-sm">{title}</p>
        <p className="font-body text-xs text-muted-foreground">{description}</p>
      </div>
    </div>
  );
}
