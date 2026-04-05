/**
 * GamificationContext — Global gamification state
 * Design: Warm Paper Notebook
 */

import { createContext, useContext, ReactNode } from 'react';
import { useGamification, GamificationState, BadgeType, PointsBreakdown } from '@/hooks/useGamification';
import { Task } from '@/hooks/useStore';

interface GamificationContextType {
  state: GamificationState;
  calculatePoints: (task: Task, tasks: Task[]) => PointsBreakdown;
  awardPoints: (points: number) => void;
  unlockBadge: (badgeType: BadgeType) => void;
  checkBadges: (tasks: Task[]) => void;
  updateStreak: (tasks: Task[]) => void;
  getBadge: (badgeType: BadgeType) => any;
  getAllBadges: () => any[];
  getLevelProgress: () => number;
}

const GamificationContext = createContext<GamificationContextType | undefined>(undefined);

export function GamificationProvider({ children }: { children: ReactNode }) {
  const gamification = useGamification();

  return (
    <GamificationContext.Provider value={gamification}>
      {children}
    </GamificationContext.Provider>
  );
}

export function useGamificationContext() {
  const context = useContext(GamificationContext);
  if (!context) {
    throw new Error('useGamificationContext must be used within GamificationProvider');
  }
  return context;
}
