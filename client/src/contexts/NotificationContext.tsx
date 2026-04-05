/**
 * NotificationContext — Global notification state
 * Design: Warm Paper Notebook
 */

import { createContext, useContext, ReactNode } from 'react';
import { useNotifications } from '@/hooks/useNotifications';
import { Task } from '@/hooks/useStore';

interface NotificationContextType {
  notifications: ReturnType<typeof useNotifications>['notifications'];
  count: ReturnType<typeof useNotifications>['count'];
  requestNotificationPermission: () => Promise<boolean>;
}

const NotificationContext = createContext<NotificationContextType | null>(null);

export function NotificationProvider({
  children,
  tasks,
}: {
  children: ReactNode;
  tasks: Task[];
}) {
  const { notifications, count, requestNotificationPermission } = useNotifications(tasks);

  return (
    <NotificationContext.Provider value={{ notifications, count, requestNotificationPermission }}>
      {children}
    </NotificationContext.Provider>
  );
}

export function useNotificationContext() {
  const ctx = useContext(NotificationContext);
  if (!ctx) throw new Error('useNotificationContext must be used within NotificationProvider');
  return ctx;
}
