/**
 * Recurrence utilities for generating task occurrences
 * Design: Warm Paper Notebook
 */

import { Task, RecurrenceRule, RecurrenceFrequency } from '@/hooks/useStore';
import { nanoid } from 'nanoid';
import { addDays, addWeeks, addMonths, startOfDay } from 'date-fns';

/**
 * Generate occurrences for a recurring task
 * Returns an array of task instances for each occurrence
 */
export function generateOccurrences(
  parentTask: Task & { recurrence: RecurrenceRule },
  startDate: Date = new Date()
): Task[] {
  if (!parentTask.recurrence) return [];

  const occurrences: Task[] = [];
  const rule = parentTask.recurrence;
  let currentDate = new Date(parentTask.dueDate || startDate);
  currentDate = startOfDay(currentDate);

  let count = 0;
  const maxOccurrences = rule.maxOccurrences || 12; // default to 12 occurrences
  const endDate = rule.endDate ? new Date(rule.endDate) : null;

  while (count < maxOccurrences) {
    if (endDate && currentDate > endDate) break;

    // Create occurrence task
    const occurrence: Task = {
      id: nanoid(),
      title: parentTask.title,
      description: parentTask.description,
      priority: parentTask.priority,
      status: 'pending',
      categoryId: parentTask.categoryId,
      dueDate: currentDate.toISOString(),
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
      tags: parentTask.tags,
      parentTaskId: parentTask.id,
      occurrenceDate: currentDate.toISOString(),
    };

    occurrences.push(occurrence);

    // Calculate next occurrence date
    currentDate = getNextOccurrenceDate(currentDate, rule.frequency, rule.interval);
    count++;
  }

  return occurrences;
}

/**
 * Calculate the next occurrence date based on frequency and interval
 */
function getNextOccurrenceDate(
  currentDate: Date,
  frequency: RecurrenceFrequency,
  interval: number = 1
): Date {
  switch (frequency) {
    case 'daily':
      return addDays(currentDate, interval);
    case 'weekly':
      return addWeeks(currentDate, interval);
    case 'monthly':
      return addMonths(currentDate, interval);
    default:
      return addDays(currentDate, interval);
  }
}

/**
 * Get frequency label in Portuguese
 */
export function getFrequencyLabel(frequency: RecurrenceFrequency): string {
  const labels: Record<RecurrenceFrequency, string> = {
    daily: 'Diariamente',
    weekly: 'Semanalmente',
    monthly: 'Mensalmente',
  };
  return labels[frequency];
}

/**
 * Get interval label (e.g., "cada 2 dias", "cada 3 semanas")
 */
export function getIntervalLabel(frequency: RecurrenceFrequency, interval: number): string {
  if (interval === 1) {
    return getFrequencyLabel(frequency);
  }

  const frequencyLabels: Record<RecurrenceFrequency, string> = {
    daily: interval === 1 ? 'dia' : 'dias',
    weekly: interval === 1 ? 'semana' : 'semanas',
    monthly: interval === 1 ? 'mês' : 'meses',
  };

  return `Cada ${interval} ${frequencyLabels[frequency]}`;
}

/**
 * Get next occurrence date after a given date
 */
export function getNextOccurrenceAfter(
  parentTask: Task & { recurrence: RecurrenceRule },
  afterDate: Date = new Date()
): Date | null {
  if (!parentTask.recurrence || !parentTask.dueDate) return null;

  const rule = parentTask.recurrence;
  let nextDate = new Date(parentTask.dueDate);

  // Keep generating dates until we find one after afterDate
  let iterations = 0;
  const maxIterations = 1000; // prevent infinite loops

  while (nextDate <= afterDate && iterations < maxIterations) {
    nextDate = getNextOccurrenceDate(nextDate, rule.frequency, rule.interval);
    iterations++;
  }

  // Check if we exceeded the end date or max occurrences
  if (rule.endDate && nextDate > new Date(rule.endDate)) {
    return null;
  }

  return nextDate;
}

/**
 * Check if a task is a recurring task
 */
export function isRecurringTask(task: Task): boolean {
  return !!task.recurrence;
}

/**
 * Check if a task is an occurrence of a recurring task
 */
export function isTaskOccurrence(task: Task): boolean {
  return !!task.parentTaskId;
}

/**
 * Get all occurrences of a recurring task from a task list
 */
export function getTaskOccurrences(parentTaskId: string, tasks: Task[]): Task[] {
  return tasks.filter(t => t.parentTaskId === parentTaskId);
}

/**
 * Get the parent recurring task for an occurrence
 */
export function getParentTask(occurrence: Task, tasks: Task[]): (Task & { recurrence: RecurrenceRule }) | null {
  if (!occurrence.parentTaskId) return null;
  const parent = tasks.find(t => t.id === occurrence.parentTaskId);
  if (parent && parent.recurrence) {
    return parent as Task & { recurrence: RecurrenceRule };
  }
  return null;
}

/**
 * Generate a summary of recurrence rule
 */
export function getRecurrenceSummary(rule: RecurrenceRule): string {
  const frequencyLabel = getIntervalLabel(rule.frequency, rule.interval);
  let summary = frequencyLabel;

  if (rule.maxOccurrences) {
    summary += ` (até ${rule.maxOccurrences} ocorrências)`;
  }

  if (rule.endDate) {
    const endDate = new Date(rule.endDate);
    summary += ` (até ${endDate.toLocaleDateString('pt-BR')})`;
  }

  return summary;
}
