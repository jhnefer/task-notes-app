/**
 * useNotifications — Notification system for upcoming deadlines
 * Design: Warm Paper Notebook
 */

import { useMemo, useEffect, useRef } from 'react';
import { Task } from './useStore';
import { differenceInHours, isPast, isToday, isTomorrow } from 'date-fns';

export interface TaskNotification {
  taskId: string;
  title: string;
  dueDate: string;
  hoursUntilDue: number;
  urgency: 'critical' | 'high' | 'medium' | 'low';
  message: string;
}

export function useNotifications(tasks: Task[]) {
  const notificationsSent = useRef<Set<string>>(new Set());

  // Calcular tarefas com notificações
  const notifications = useMemo(() => {
    const now = new Date();
    const result: TaskNotification[] = [];

    tasks.forEach(task => {
      // Ignorar tarefas concluídas
      if (task.status === 'done') return;

      // Ignorar tarefas sem prazo
      if (!task.dueDate) return;

      const dueDate = new Date(task.dueDate);
      const hoursUntilDue = differenceInHours(dueDate, now);

      // Ignorar tarefas com prazo muito distante (> 48 horas)
      if (hoursUntilDue > 48) return;

      // Ignorar tarefas com prazo passado (já em atraso)
      if (hoursUntilDue < 0) {
        result.push({
          taskId: task.id,
          title: task.title,
          dueDate: task.dueDate,
          hoursUntilDue,
          urgency: 'critical',
          message: 'Tarefa em atraso',
        });
        return;
      }

      // Determinar urgência
      let urgency: 'critical' | 'high' | 'medium' | 'low';
      let message: string;

      if (hoursUntilDue <= 1) {
        urgency = 'critical';
        message = 'Vence em menos de 1 hora';
      } else if (hoursUntilDue <= 6) {
        urgency = 'high';
        message = `Vence em ${Math.round(hoursUntilDue)}h`;
      } else if (hoursUntilDue <= 24) {
        urgency = 'medium';
        if (isToday(dueDate)) {
          message = 'Vence hoje';
        } else {
          message = `Vence em ${Math.round(hoursUntilDue)}h`;
        }
      } else {
        urgency = 'low';
        if (isTomorrow(dueDate)) {
          message = 'Vence amanhã';
        } else {
          message = `Vence em ${Math.round(hoursUntilDue / 24)} dias`;
        }
      }

      result.push({
        taskId: task.id,
        title: task.title,
        dueDate: task.dueDate,
        hoursUntilDue,
        urgency,
        message,
      });
    });

    // Ordenar por urgência (mais urgentes primeiro)
    return result.sort((a, b) => {
      const urgencyOrder = { critical: 0, high: 1, medium: 2, low: 3 };
      return urgencyOrder[a.urgency] - urgencyOrder[b.urgency];
    });
  }, [tasks]);

  // Enviar notificações do navegador
  useEffect(() => {
    notifications.forEach(notif => {
      // Verificar se já foi enviada nesta sessão
      if (notificationsSent.current.has(notif.taskId)) return;

      // Apenas enviar para notificações críticas e altas
      if (notif.urgency !== 'critical' && notif.urgency !== 'high') return;

      // Verificar permissão
      if ('Notification' in window && Notification.permission === 'granted') {
        new Notification('⏰ Prazo Próximo', {
          body: `${notif.title}\n${notif.message}`,
          icon: '/favicon.ico',
          tag: `task-${notif.taskId}`,
          requireInteraction: notif.urgency === 'critical',
        });
        notificationsSent.current.add(notif.taskId);
      }
    });
  }, [notifications]);

  // Solicitar permissão de notificação
  const requestNotificationPermission = async () => {
    if ('Notification' in window) {
      if (Notification.permission === 'granted') {
        return true;
      }
      if (Notification.permission !== 'denied') {
        const permission = await Notification.requestPermission();
        return permission === 'granted';
      }
    }
    return false;
  };

  // Contar notificações por urgência
  const count = {
    total: notifications.length,
    critical: notifications.filter(n => n.urgency === 'critical').length,
    high: notifications.filter(n => n.urgency === 'high').length,
    medium: notifications.filter(n => n.urgency === 'medium').length,
    low: notifications.filter(n => n.urgency === 'low').length,
  };

  return {
    notifications,
    count,
    requestNotificationPermission,
  };
}
