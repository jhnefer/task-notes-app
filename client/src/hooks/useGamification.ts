/**
 * useGamification — Gamification system with points, badges, and achievements
 * Design: Warm Paper Notebook
 */

import { useState, useEffect, useCallback } from 'react';
import { Task } from './useStore';
import { nanoid } from 'nanoid';

export type BadgeType = 
  | 'first_task' 
  | 'first_completion' 
  | 'five_completed' 
  | 'ten_completed' 
  | 'fifty_completed' 
  | 'hundred_completed'
  | 'streak_3_days'
  | 'streak_7_days'
  | 'streak_30_days'
  | 'high_priority_master'
  | 'category_master'
  | 'speed_demon'
  | 'perfectionist'
  | 'night_owl'
  | 'early_bird';

export interface Badge {
  id: BadgeType;
  name: string;
  description: string;
  icon: string; // emoji or icon name
  unlockedAt?: string; // ISO date string
  rarity: 'common' | 'uncommon' | 'rare' | 'epic' | 'legendary';
}

export interface GamificationState {
  totalPoints: number;
  currentLevel: number;
  pointsToNextLevel: number;
  badges: Badge[];
  streakDays: number;
  lastActivityDate?: string;
  tasksCompletedThisWeek: number;
  tasksCompletedThisMonth: number;
}

export interface PointsBreakdown {
  basePoints: number;
  priorityBonus: number;
  speedBonus: number;
  streakBonus: number;
  categoryBonus: number;
  totalPoints: number;
}

const BADGE_DEFINITIONS: Record<BadgeType, Omit<Badge, 'unlockedAt'>> = {
  first_task: {
    id: 'first_task',
    name: 'Primeiro Passo',
    description: 'Crie sua primeira tarefa',
    icon: '🚀',
    rarity: 'common',
  },
  first_completion: {
    id: 'first_completion',
    name: 'Conquistador',
    description: 'Conclua sua primeira tarefa',
    icon: '✅',
    rarity: 'common',
  },
  five_completed: {
    id: 'five_completed',
    name: 'Cinco Vitórias',
    description: 'Conclua 5 tarefas',
    icon: '🎯',
    rarity: 'uncommon',
  },
  ten_completed: {
    id: 'ten_completed',
    name: 'Dez Vezes Campeão',
    description: 'Conclua 10 tarefas',
    icon: '🏆',
    rarity: 'uncommon',
  },
  fifty_completed: {
    id: 'fifty_completed',
    name: 'Mestre das Tarefas',
    description: 'Conclua 50 tarefas',
    icon: '👑',
    rarity: 'rare',
  },
  hundred_completed: {
    id: 'hundred_completed',
    name: 'Lenda Viva',
    description: 'Conclua 100 tarefas',
    icon: '⭐',
    rarity: 'legendary',
  },
  streak_3_days: {
    id: 'streak_3_days',
    name: 'Sequência de 3',
    description: 'Conclua tarefas por 3 dias consecutivos',
    icon: '🔥',
    rarity: 'uncommon',
  },
  streak_7_days: {
    id: 'streak_7_days',
    name: 'Semana Perfeita',
    description: 'Conclua tarefas por 7 dias consecutivos',
    icon: '🌟',
    rarity: 'rare',
  },
  streak_30_days: {
    id: 'streak_30_days',
    name: 'Mês Implacável',
    description: 'Conclua tarefas por 30 dias consecutivos',
    icon: '💎',
    rarity: 'epic',
  },
  high_priority_master: {
    id: 'high_priority_master',
    name: 'Domador de Prioridades',
    description: 'Conclua 10 tarefas de alta prioridade',
    icon: '⚡',
    rarity: 'rare',
  },
  category_master: {
    id: 'category_master',
    name: 'Especialista em Categorias',
    description: 'Conclua 5 tarefas em uma mesma categoria',
    icon: '📚',
    rarity: 'uncommon',
  },
  speed_demon: {
    id: 'speed_demon',
    name: 'Demônio da Velocidade',
    description: 'Conclua uma tarefa em menos de 1 hora',
    icon: '⚡',
    rarity: 'rare',
  },
  perfectionist: {
    id: 'perfectionist',
    name: 'Perfeccionista',
    description: 'Conclua uma tarefa de alta prioridade com prazo',
    icon: '🎨',
    rarity: 'uncommon',
  },
  night_owl: {
    id: 'night_owl',
    name: 'Coruja Noturna',
    description: 'Conclua uma tarefa entre 22h e 6h',
    icon: '🦉',
    rarity: 'uncommon',
  },
  early_bird: {
    id: 'early_bird',
    name: 'Madrugador',
    description: 'Conclua uma tarefa entre 5h e 8h',
    icon: '🌅',
    rarity: 'uncommon',
  },
};

const POINTS_CONFIG = {
  basePoints: 10,
  levelThreshold: 100, // points needed per level
  priorityMultiplier: {
    high: 2.0,
    medium: 1.5,
    low: 1.0,
  },
  streakBonus: 5, // bonus per streak day
  speedBonus: 5, // bonus if completed same day
  categoryBonus: 2, // bonus for completing multiple in same category
};

const STORAGE_KEY = 'task-notes-app-gamification';

function loadGamificationState(): GamificationState {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (raw) {
      return JSON.parse(raw);
    }
  } catch {
    // ignore parse errors
  }
  return {
    totalPoints: 0,
    currentLevel: 1,
    pointsToNextLevel: POINTS_CONFIG.levelThreshold,
    badges: [],
    streakDays: 0,
    tasksCompletedThisWeek: 0,
    tasksCompletedThisMonth: 0,
  };
}

function saveGamificationState(state: GamificationState) {
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(state));
  } catch {
    // ignore storage errors
  }
}

export function useGamification() {
  const [state, setState] = useState<GamificationState>(loadGamificationState);

  useEffect(() => {
    saveGamificationState(state);
  }, [state]);

  /**
   * Calculate points for completing a task
   */
  const calculatePoints = useCallback((task: Task, tasks: Task[]): PointsBreakdown => {
    let basePoints = POINTS_CONFIG.basePoints;
    let priorityBonus = 0;
    let speedBonus = 0;
    let streakBonus = 0;
    let categoryBonus = 0;

    // Priority bonus
    const priorityMultiplier = POINTS_CONFIG.priorityMultiplier[task.priority];
    priorityBonus = Math.floor(basePoints * (priorityMultiplier - 1));

    // Speed bonus (completed same day as created)
    if (task.dueDate) {
      const createdDate = new Date(task.createdAt).toDateString();
      const dueDate = new Date(task.dueDate).toDateString();
      if (createdDate === dueDate) {
        speedBonus = POINTS_CONFIG.speedBonus;
      }
    }

    // Streak bonus
    streakBonus = state.streakDays * POINTS_CONFIG.streakBonus;

    // Category bonus (if multiple tasks in same category completed)
    if (task.categoryId) {
      const categoryTasks = tasks.filter(
        t => t.categoryId === task.categoryId && t.status === 'done'
      );
      if (categoryTasks.length >= 5) {
        categoryBonus = POINTS_CONFIG.categoryBonus;
      }
    }

    const totalPoints = basePoints + priorityBonus + speedBonus + streakBonus + categoryBonus;

    return {
      basePoints,
      priorityBonus,
      speedBonus,
      streakBonus,
      categoryBonus,
      totalPoints,
    };
  }, [state.streakDays]);

  /**
   * Award points for completing a task
   */
  const awardPoints = useCallback((points: number) => {
    setState(s => {
      let newPoints = s.totalPoints + points;
      let newLevel = s.currentLevel;
      let pointsToNextLevel = s.pointsToNextLevel - points;

      // Level up logic
      while (pointsToNextLevel <= 0) {
        newLevel++;
        pointsToNextLevel += POINTS_CONFIG.levelThreshold;
      }

      return {
        ...s,
        totalPoints: newPoints,
        currentLevel: newLevel,
        pointsToNextLevel,
      };
    });
  }, []);

  /**
   * Unlock a badge
   */
  const unlockBadge = useCallback((badgeType: BadgeType) => {
    setState(s => {
      // Check if badge already unlocked
      if (s.badges.some(b => b.id === badgeType)) {
        return s;
      }

      const badgeDef = BADGE_DEFINITIONS[badgeType];
      const newBadge: Badge = {
        ...badgeDef,
        unlockedAt: new Date().toISOString(),
      };

      return {
        ...s,
        badges: [...s.badges, newBadge],
      };
    });
  }, []);

  /**
   * Check and unlock badges based on task completion
   */
  const checkBadges = useCallback((tasks: Task[]) => {
    const completedCount = tasks.filter(t => t.status === 'done').length;

    // Completion milestones
    if (completedCount === 1) unlockBadge('first_completion');
    if (completedCount === 5) unlockBadge('five_completed');
    if (completedCount === 10) unlockBadge('ten_completed');
    if (completedCount === 50) unlockBadge('fifty_completed');
    if (completedCount === 100) unlockBadge('hundred_completed');

    // Priority master
    const highPriorityCompleted = tasks.filter(
      t => t.priority === 'high' && t.status === 'done'
    ).length;
    if (highPriorityCompleted >= 10) unlockBadge('high_priority_master');

    // Category master
    const categories = new Set(tasks.map(t => t.categoryId).filter(Boolean));
    Array.from(categories).forEach(categoryId => {
      const categoryCompleted = tasks.filter(
        t => t.categoryId === categoryId && t.status === 'done'
      ).length;
      if (categoryCompleted >= 5) {
        unlockBadge('category_master');
      }
    });
  }, [unlockBadge]);

  /**
   * Update streak based on task completion
   */
  const updateStreak = useCallback((tasks: Task[]) => {
    const today = new Date().toDateString();
    const yesterday = new Date(Date.now() - 86400000).toDateString();

    const completedToday = tasks.filter(t => {
      const updatedDate = new Date(t.updatedAt).toDateString();
      return t.status === 'done' && updatedDate === today;
    }).length;

    const completedYesterday = tasks.filter(t => {
      const updatedDate = new Date(t.updatedAt).toDateString();
      return t.status === 'done' && updatedDate === yesterday;
    }).length;

    setState(s => {
      let newStreak = s.streakDays;

      if (completedToday > 0) {
        if (completedYesterday > 0 || s.lastActivityDate === yesterday) {
          newStreak = s.streakDays + 1;
        } else {
          newStreak = 1;
        }

        // Check streak badges
        if (newStreak === 3) unlockBadge('streak_3_days');
        if (newStreak === 7) unlockBadge('streak_7_days');
        if (newStreak === 30) unlockBadge('streak_30_days');
      }

      return {
        ...s,
        streakDays: newStreak,
        lastActivityDate: today,
      };
    });
  }, [unlockBadge]);

  /**
   * Get badge by type
   */
  const getBadge = useCallback((badgeType: BadgeType): Badge | null => {
    return state.badges.find(b => b.id === badgeType) || null;
  }, [state.badges]);

  /**
   * Get all available badges (including locked ones)
   */
  const getAllBadges = useCallback((): Badge[] => {
    return Object.values(BADGE_DEFINITIONS).map(def => {
      const unlockedBadge = state.badges.find(b => b.id === def.id);
      return unlockedBadge || { ...def, unlockedAt: undefined };
    });
  }, [state.badges]);

  /**
   * Get progress to next level
   */
  const getLevelProgress = useCallback((): number => {
    const pointsEarned = POINTS_CONFIG.levelThreshold - state.pointsToNextLevel;
    return (pointsEarned / POINTS_CONFIG.levelThreshold) * 100;
  }, [state.pointsToNextLevel]);

  return {
    state,
    calculatePoints,
    awardPoints,
    unlockBadge,
    checkBadges,
    updateStreak,
    getBadge,
    getAllBadges,
    getLevelProgress,
  };
}
