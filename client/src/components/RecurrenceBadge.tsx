/**
 * RecurrenceBadge — Badge to show recurrence info
 * Design: Warm Paper Notebook
 */

import { Task } from '@/hooks/useStore';
import { Repeat2 } from 'lucide-react';
import { cn } from '@/lib/utils';
import { getRecurrenceSummary } from '@/lib/recurrence';

interface RecurrenceBadgeProps {
  task: Task;
  className?: string;
}

export function RecurrenceBadge({ task, className }: RecurrenceBadgeProps) {
  if (!task.recurrence) return null;

  const summary = getRecurrenceSummary(task.recurrence);

  return (
    <span
      className={cn(
        'font-body text-xs flex items-center gap-1 px-2 py-1 rounded-full',
        'bg-primary/10 text-primary border border-primary/20',
        className
      )}
      title={summary}
    >
      <Repeat2 size={10} />
      {summary}
    </span>
  );
}
