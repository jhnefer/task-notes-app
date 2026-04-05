/**
 * Analytics utilities for generating reports and statistics
 * Design: Warm Paper Notebook
 */

import { Task } from '@/hooks/useStore';
import { startOfDay, endOfDay, startOfWeek, endOfWeek, startOfMonth, endOfMonth, subDays, subMonths, format } from 'date-fns';
import { ptBR } from 'date-fns/locale';

export interface DailyStats {
  date: string;
  completed: number;
  pending: number;
  inProgress: number;
  total: number;
}

export interface WeeklyStats {
  week: string;
  completed: number;
  pending: number;
  inProgress: number;
  total: number;
  startDate: Date;
  endDate: Date;
}

export interface MonthlyStats {
  month: string;
  completed: number;
  pending: number;
  inProgress: number;
  total: number;
  startDate: Date;
  endDate: Date;
}

export interface PriorityStats {
  priority: 'high' | 'medium' | 'low';
  completed: number;
  pending: number;
  inProgress: number;
  total: number;
}

export interface CategoryStats {
  categoryId: string;
  categoryName: string;
  completed: number;
  pending: number;
  inProgress: number;
  total: number;
  completionRate: number;
}

export interface OverallStats {
  totalTasks: number;
  completedTasks: number;
  pendingTasks: number;
  inProgressTasks: number;
  completionRate: number;
  averageCompletionTime: number; // in days
  tasksCompletedThisWeek: number;
  tasksCompletedThisMonth: number;
  productivityTrend: 'up' | 'down' | 'stable';
}

/**
 * Get daily statistics for the last N days
 */
export function getDailyStats(tasks: Task[], days: number = 30): DailyStats[] {
  const stats: DailyStats[] = [];
  const today = new Date();

  for (let i = days - 1; i >= 0; i--) {
    const date = subDays(today, i);
    const dateStr = format(date, 'yyyy-MM-dd');
    const dayStart = startOfDay(date);
    const dayEnd = endOfDay(date);

    const dayTasks = tasks.filter(t => {
      const createdAt = new Date(t.createdAt);
      return createdAt >= dayStart && createdAt <= dayEnd;
    });

    stats.push({
      date: dateStr,
      completed: dayTasks.filter(t => t.status === 'done').length,
      pending: dayTasks.filter(t => t.status === 'pending').length,
      inProgress: dayTasks.filter(t => t.status === 'in_progress').length,
      total: dayTasks.length,
    });
  }

  return stats;
}

/**
 * Get weekly statistics for the last N weeks
 */
export function getWeeklyStats(tasks: Task[], weeks: number = 12): WeeklyStats[] {
  const stats: WeeklyStats[] = [];
  const today = new Date();

  for (let i = weeks - 1; i >= 0; i--) {
    const date = subDays(today, i * 7);
    const weekStart = startOfWeek(date, { weekStartsOn: 1 }); // Monday
    const weekEnd = endOfWeek(date, { weekStartsOn: 1 });

    const weekTasks = tasks.filter(t => {
      const createdAt = new Date(t.createdAt);
      return createdAt >= weekStart && createdAt <= weekEnd;
    });

    const weekLabel = `${format(weekStart, 'd MMM', { locale: ptBR })} - ${format(weekEnd, 'd MMM', { locale: ptBR })}`;

    stats.push({
      week: weekLabel,
      completed: weekTasks.filter(t => t.status === 'done').length,
      pending: weekTasks.filter(t => t.status === 'pending').length,
      inProgress: weekTasks.filter(t => t.status === 'in_progress').length,
      total: weekTasks.length,
      startDate: weekStart,
      endDate: weekEnd,
    });
  }

  return stats;
}

/**
 * Get monthly statistics for the last N months
 */
export function getMonthlyStats(tasks: Task[], months: number = 12): MonthlyStats[] {
  const stats: MonthlyStats[] = [];
  const today = new Date();

  for (let i = months - 1; i >= 0; i--) {
    const date = subMonths(today, i);
    const monthStart = startOfMonth(date);
    const monthEnd = endOfMonth(date);

    const monthTasks = tasks.filter(t => {
      const createdAt = new Date(t.createdAt);
      return createdAt >= monthStart && createdAt <= monthEnd;
    });

    const monthLabel = format(date, 'MMMM yyyy', { locale: ptBR });

    stats.push({
      month: monthLabel.charAt(0).toUpperCase() + monthLabel.slice(1),
      completed: monthTasks.filter(t => t.status === 'done').length,
      pending: monthTasks.filter(t => t.status === 'pending').length,
      inProgress: monthTasks.filter(t => t.status === 'in_progress').length,
      total: monthTasks.length,
      startDate: monthStart,
      endDate: monthEnd,
    });
  }

  return stats;
}

/**
 * Get statistics by priority
 */
export function getPriorityStats(tasks: Task[]): PriorityStats[] {
  return [
    {
      priority: 'high',
      completed: tasks.filter(t => t.priority === 'high' && t.status === 'done').length,
      pending: tasks.filter(t => t.priority === 'high' && t.status === 'pending').length,
      inProgress: tasks.filter(t => t.priority === 'high' && t.status === 'in_progress').length,
      total: tasks.filter(t => t.priority === 'high').length,
    },
    {
      priority: 'medium',
      completed: tasks.filter(t => t.priority === 'medium' && t.status === 'done').length,
      pending: tasks.filter(t => t.priority === 'medium' && t.status === 'pending').length,
      inProgress: tasks.filter(t => t.priority === 'medium' && t.status === 'in_progress').length,
      total: tasks.filter(t => t.priority === 'medium').length,
    },
    {
      priority: 'low',
      completed: tasks.filter(t => t.priority === 'low' && t.status === 'done').length,
      pending: tasks.filter(t => t.priority === 'low' && t.status === 'pending').length,
      inProgress: tasks.filter(t => t.priority === 'low' && t.status === 'in_progress').length,
      total: tasks.filter(t => t.priority === 'low').length,
    },
  ];
}

/**
 * Get statistics by category
 */
export function getCategoryStats(
  tasks: Task[],
  categories: { id: string; name: string }[]
): CategoryStats[] {
  return categories.map(cat => {
    const catTasks = tasks.filter(t => t.categoryId === cat.id);
    const completed = catTasks.filter(t => t.status === 'done').length;
    const total = catTasks.length;

    return {
      categoryId: cat.id,
      categoryName: cat.name,
      completed,
      pending: catTasks.filter(t => t.status === 'pending').length,
      inProgress: catTasks.filter(t => t.status === 'in_progress').length,
      total,
      completionRate: total > 0 ? (completed / total) * 100 : 0,
    };
  });
}

/**
 * Get overall statistics
 */
export function getOverallStats(tasks: Task[]): OverallStats {
  const totalTasks = tasks.length;
  const completedTasks = tasks.filter(t => t.status === 'done').length;
  const pendingTasks = tasks.filter(t => t.status === 'pending').length;
  const inProgressTasks = tasks.filter(t => t.status === 'in_progress').length;
  const completionRate = totalTasks > 0 ? (completedTasks / totalTasks) * 100 : 0;

  // Calculate tasks completed this week
  const weekStart = startOfWeek(new Date(), { weekStartsOn: 1 });
  const weekEnd = endOfWeek(new Date(), { weekStartsOn: 1 });
  const tasksCompletedThisWeek = tasks.filter(t => {
    const updatedAt = new Date(t.updatedAt);
    return t.status === 'done' && updatedAt >= weekStart && updatedAt <= weekEnd;
  }).length;

  // Calculate tasks completed this month
  const monthStart = startOfMonth(new Date());
  const monthEnd = endOfMonth(new Date());
  const tasksCompletedThisMonth = tasks.filter(t => {
    const updatedAt = new Date(t.updatedAt);
    return t.status === 'done' && updatedAt >= monthStart && updatedAt <= monthEnd;
  }).length;

  // Calculate productivity trend (compare this week vs last week)
  const lastWeekStart = startOfWeek(subDays(new Date(), 7), { weekStartsOn: 1 });
  const lastWeekEnd = endOfWeek(subDays(new Date(), 7), { weekStartsOn: 1 });
  const tasksCompletedLastWeek = tasks.filter(t => {
    const updatedAt = new Date(t.updatedAt);
    return t.status === 'done' && updatedAt >= lastWeekStart && updatedAt <= lastWeekEnd;
  }).length;

  let productivityTrend: 'up' | 'down' | 'stable' = 'stable';
  if (tasksCompletedThisWeek > tasksCompletedLastWeek) {
    productivityTrend = 'up';
  } else if (tasksCompletedThisWeek < tasksCompletedLastWeek) {
    productivityTrend = 'down';
  }

  // Calculate average completion time (simplified: based on tasks with dueDate)
  const completedWithDueDate = tasks.filter(t => t.status === 'done' && t.dueDate);
  const averageCompletionTime =
    completedWithDueDate.length > 0
      ? completedWithDueDate.reduce((sum, t) => {
          const dueDate = new Date(t.dueDate!);
          const createdDate = new Date(t.createdAt);
          const days = Math.floor((dueDate.getTime() - createdDate.getTime()) / (1000 * 60 * 60 * 24));
          return sum + days;
        }, 0) / completedWithDueDate.length
      : 0;

  return {
    totalTasks,
    completedTasks,
    pendingTasks,
    inProgressTasks,
    completionRate,
    averageCompletionTime: Math.round(averageCompletionTime),
    tasksCompletedThisWeek,
    tasksCompletedThisMonth,
    productivityTrend,
  };
}

/**
 * Get productivity score (0-100)
 */
export function getProductivityScore(stats: OverallStats): number {
  // Base score from completion rate
  let score = stats.completionRate;

  // Bonus for consistent activity
  if (stats.tasksCompletedThisWeek > 0) {
    score += 10;
  }

  // Bonus for upward trend
  if (stats.productivityTrend === 'up') {
    score += 10;
  }

  return Math.min(100, Math.round(score));
}

/**
 * Get productivity level description
 */
export function getProductivityLevel(score: number): string {
  if (score >= 80) return 'Excelente';
  if (score >= 60) return 'Bom';
  if (score >= 40) return 'Moderado';
  if (score >= 20) return 'Baixo';
  return 'Muito Baixo';
}
