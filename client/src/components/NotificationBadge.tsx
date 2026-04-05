/**
 * NotificationBadge — Visual indicator for upcoming deadlines
 * Design: Warm Paper Notebook
 */

import { cn } from '@/lib/utils';
import { AlertCircle, Clock, AlertTriangle } from 'lucide-react';

interface NotificationBadgeProps {
  critical: number;
  high: number;
  medium: number;
  size?: 'sm' | 'md' | 'lg';
  showLabel?: boolean;
}

export function NotificationBadge({
  critical,
  high,
  medium,
  size = 'md',
  showLabel = false,
}: NotificationBadgeProps) {
  const total = critical + high + medium;

  if (total === 0) return null;

  // Determinar cor e ícone baseado na urgência
  let bgColor = 'bg-muted';
  let textColor = 'text-muted-foreground';
  let icon = null;

  if (critical > 0) {
    bgColor = 'bg-destructive';
    textColor = 'text-white';
    icon = <AlertTriangle size={12} />;
  } else if (high > 0) {
    bgColor = 'bg-amber-500';
    textColor = 'text-white';
    icon = <AlertCircle size={12} />;
  } else if (medium > 0) {
    bgColor = 'bg-primary';
    textColor = 'text-primary-foreground';
    icon = <Clock size={12} />;
  }

  const sizeClass = {
    sm: 'px-1.5 py-0.5 text-xs',
    md: 'px-2 py-1 text-xs',
    lg: 'px-2.5 py-1.5 text-sm',
  }[size];

  return (
    <div className={cn(
      'inline-flex items-center gap-1 rounded-full font-semibold',
      bgColor,
      textColor,
      sizeClass
    )}>
      {icon}
      <span>{total}</span>
      {showLabel && (
        <span className="ml-0.5 text-xs opacity-75">
          {critical > 0 ? 'crítico' : high > 0 ? 'urgente' : 'próximo'}
        </span>
      )}
    </div>
  );
}

/**
 * NotificationAlert — Inline alert for dashboard
 */
export function NotificationAlert({
  critical,
  high,
}: {
  critical: number;
  high: number;
}) {
  if (critical === 0 && high === 0) return null;

  const isCritical = critical > 0;
  const message = isCritical
    ? `${critical} tarefa${critical > 1 ? 's' : ''} em atraso ou vencendo em breve!`
    : `${high} tarefa${high > 1 ? 's' : ''} vencendo nas próximas horas`;

  return (
    <div className={cn(
      'flex items-center gap-3 px-4 py-3 rounded-lg border',
      isCritical
        ? 'bg-destructive/10 border-destructive/30 text-destructive'
        : 'bg-amber-50 border-amber-200 text-amber-900'
    )}>
      <div className="shrink-0">
        {isCritical ? (
          <AlertTriangle size={18} />
        ) : (
          <AlertCircle size={18} />
        )}
      </div>
      <div className="flex-1">
        <p className="font-body text-sm font-medium">{message}</p>
      </div>
    </div>
  );
}
