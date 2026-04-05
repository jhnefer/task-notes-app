/**
 * NotificationPanel — Detailed notification list and settings
 * Design: Warm Paper Notebook
 */

import { useState } from 'react';
import { Bell, X, Clock, AlertTriangle, AlertCircle, CheckCircle2 } from 'lucide-react';
import { useNotificationContext } from '@/contexts/NotificationContext';
import { cn } from '@/lib/utils';
import { Button } from '@/components/ui/button';
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import { toast } from 'sonner';

export function NotificationPanel() {
  const [open, setOpen] = useState(false);
  const { notifications, count, requestNotificationPermission } = useNotificationContext();

  const handleEnableNotifications = async () => {
    const granted = await requestNotificationPermission();
    if (granted) {
      toast.success('Notificações do navegador ativadas!');
    } else {
      toast.error('Permissão de notificações negada.');
    }
  };

  const getUrgencyIcon = (urgency: string) => {
    switch (urgency) {
      case 'critical':
        return <AlertTriangle size={16} className="text-destructive" />;
      case 'high':
        return <AlertCircle size={16} className="text-amber-500" />;
      case 'medium':
        return <Clock size={16} className="text-primary" />;
      default:
        return <Clock size={16} className="text-muted-foreground" />;
    }
  };

  const getUrgencyLabel = (urgency: string) => {
    switch (urgency) {
      case 'critical':
        return 'Crítico';
      case 'high':
        return 'Urgente';
      case 'medium':
        return 'Próximo';
      default:
        return 'Baixo';
    }
  };

  const getUrgencyColor = (urgency: string) => {
    switch (urgency) {
      case 'critical':
        return 'bg-destructive/10 text-destructive border-destructive/30';
      case 'high':
        return 'bg-amber-50 text-amber-900 border-amber-200';
      case 'medium':
        return 'bg-primary/10 text-primary border-primary/30';
      default:
        return 'bg-muted text-muted-foreground border-border';
    }
  };

  return (
    <>
      {/* Trigger button */}
      <button
        onClick={() => setOpen(true)}
        className="relative p-2 rounded-lg text-muted-foreground hover:text-foreground hover:bg-muted transition-colors"
        title="Notificações"
      >
        <Bell size={18} />
        {(count.critical > 0 || count.high > 0) && (
          <span className="absolute top-0 right-0 w-2 h-2 bg-destructive rounded-full animate-pulse" />
        )}
      </button>

      {/* Panel dialog */}
      <Dialog open={open} onOpenChange={setOpen}>
        <DialogContent className="max-w-2xl bg-card border-border">
          <DialogHeader className="flex items-center justify-between">
            <DialogTitle className="font-display text-xl text-foreground flex items-center gap-2">
              <Bell size={20} className="text-primary" />
              Notificações
            </DialogTitle>
          </DialogHeader>

          <div className="space-y-4 py-2">
            {/* Enable browser notifications */}
            {typeof window !== 'undefined' && 'Notification' in window && (
              <div className="p-3 bg-muted/50 rounded-lg border border-border">
                <div className="flex items-start justify-between">
                  <div>
                    <p className="font-body text-sm font-medium text-foreground">
                      Notificações do Navegador
                    </p>
                    <p className="font-body text-xs text-muted-foreground mt-0.5">
                      Receba alertas mesmo quando não estiver na aba
                    </p>
                  </div>
                  <Button
                    size="sm"
                    onClick={handleEnableNotifications}
                    className="font-body bg-primary text-primary-foreground hover:bg-primary/90"
                  >
                    Ativar
                  </Button>
                </div>
              </div>
            )}

            {/* Notification stats */}
            <div className="grid grid-cols-4 gap-2">
              <div className="bg-destructive/10 rounded-lg p-2 text-center">
                <p className="font-display text-lg font-bold text-destructive">{count.critical}</p>
                <p className="font-body text-xs text-muted-foreground">Crítico</p>
              </div>
              <div className="bg-amber-50 rounded-lg p-2 text-center">
                <p className="font-display text-lg font-bold text-amber-700">{count.high}</p>
                <p className="font-body text-xs text-muted-foreground">Urgente</p>
              </div>
              <div className="bg-primary/10 rounded-lg p-2 text-center">
                <p className="font-display text-lg font-bold text-primary">{count.medium}</p>
                <p className="font-body text-xs text-muted-foreground">Próximo</p>
              </div>
              <div className="bg-muted rounded-lg p-2 text-center">
                <p className="font-display text-lg font-bold text-muted-foreground">{count.low}</p>
                <p className="font-body text-xs text-muted-foreground">Baixo</p>
              </div>
            </div>

            {/* Notifications list */}
            {notifications.length === 0 ? (
              <div className="text-center py-8">
                <CheckCircle2 size={32} className="text-[#4A7C59] mx-auto mb-2" />
                <p className="font-display text-lg text-muted-foreground">Nenhuma notificação</p>
                <p className="font-body text-xs text-muted-foreground mt-1">
                  Todas as tarefas estão em dia!
                </p>
              </div>
            ) : (
              <div className="space-y-2 max-h-96 overflow-y-auto">
                {notifications.map(notif => (
                  <div
                    key={notif.taskId}
                    className={cn(
                      'flex items-start gap-3 p-3 rounded-lg border',
                      getUrgencyColor(notif.urgency)
                    )}
                  >
                    <div className="shrink-0 mt-0.5">
                      {getUrgencyIcon(notif.urgency)}
                    </div>
                    <div className="flex-1 min-w-0">
                      <p className="font-body text-sm font-medium truncate">
                        {notif.title}
                      </p>
                      <p className="font-body text-xs mt-0.5 opacity-75">
                        {notif.message}
                      </p>
                    </div>
                    <span className={cn(
                      'shrink-0 font-accent text-xs px-2 py-1 rounded-full',
                      'bg-white/50'
                    )}>
                      {getUrgencyLabel(notif.urgency)}
                    </span>
                  </div>
                ))}
              </div>
            )}

            {/* Footer info */}
            <div className="text-center pt-2 border-t border-border">
              <p className="font-body text-xs text-muted-foreground">
                Notificações são verificadas a cada vez que você abre ou atualiza a página
              </p>
            </div>
          </div>
        </DialogContent>
      </Dialog>
    </>
  );
}
