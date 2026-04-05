/**
 * Dashboard — Overview page
 * Design: Warm Paper Notebook — parchment background, ruled lines, ink typography
 */

import { useMemo } from 'react';
import { Link } from 'wouter';
import {
  CheckSquare,
  Clock,
  AlertTriangle,
  FileText,
  TrendingUp,
  ArrowRight,
  Pin,
  Calendar,
  Sparkles,
} from 'lucide-react';
import { useApp } from '@/contexts/AppContext';
import { useNotificationContext } from '@/contexts/NotificationContext';
import { NotificationAlert } from '@/components/NotificationBadge';
import { NotificationPanel } from '@/components/NotificationPanel';
import { ResetDataButton } from '@/components/ResetDataButton';
import { cn } from '@/lib/utils';
import { format, isPast, isToday, isTomorrow } from 'date-fns';
import { ptBR } from 'date-fns/locale';

function formatDueDate(dateStr?: string) {
  if (!dateStr) return null;
  const d = new Date(dateStr);
  if (isToday(d)) return 'Hoje';
  if (isTomorrow(d)) return 'Amanhã';
  return format(d, "d 'de' MMM", { locale: ptBR });
}

function StatCard({
  icon,
  label,
  value,
  accentColor,
  sub,
  delay = 0,
}: {
  icon: React.ReactNode;
  label: string;
  value: number | string;
  accentColor?: string;
  sub?: string;
  delay?: number;
}) {
  return (
    <div
      className="bg-card border border-border rounded-xl p-5 relative overflow-hidden shadow-sm hover:shadow-md transition-all duration-200 hover:-translate-y-0.5"
      style={{ animationDelay: `${delay}ms` }}
    >
      <div className="flex items-start justify-between">
        <div>
          <p className="font-body text-muted-foreground text-sm mb-1">{label}</p>
          <p className="font-display text-3xl font-bold" style={{ color: accentColor || 'inherit' }}>
            {value}
          </p>
          {sub && <p className="font-body text-xs text-muted-foreground mt-1">{sub}</p>}
        </div>
        <div
          className="p-2.5 rounded-xl"
          style={{ backgroundColor: accentColor ? `${accentColor}18` : undefined }}
        >
          {icon}
        </div>
      </div>
      {/* Decorative corner */}
      <div
        className="absolute bottom-0 right-0 w-16 h-16 rounded-tl-full opacity-5"
        style={{ backgroundColor: accentColor || '#C0533A' }}
      />
    </div>
  );
}

export default function Dashboard() {
  const { tasks, notes, categories, stats } = useApp();
  const { count } = useNotificationContext();

  const progressPct = stats.total > 0
    ? Math.round((stats.done / stats.total) * 100)
    : 0;

  const upcomingTasks = useMemo(
    () =>
      tasks
        .filter(t => t.dueDate && t.status !== 'done')
        .sort((a, b) => new Date(a.dueDate!).getTime() - new Date(b.dueDate!).getTime())
        .slice(0, 5),
    [tasks]
  );

  const pinnedNotes = useMemo(
    () => notes.filter(n => n.pinned).slice(0, 3),
    [notes]
  );

  const recentTasks = useMemo(
    () => tasks.filter(t => t.status !== 'done').slice(0, 5),
    [tasks]
  );

  const getCategoryName = (id?: string) =>
    categories.find(c => c.id === id)?.name ?? '';

  const priorityLabel: Record<string, string> = {
    high: 'Alta',
    medium: 'Média',
    low: 'Baixa',
  };

  const priorityClass: Record<string, string> = {
    high: 'text-[#C0533A] bg-[#C0533A]/10',
    medium: 'text-[#B45309] bg-[#B45309]/10',
    low: 'text-[#4A7C59] bg-[#4A7C59]/10',
  };

  const greeting = () => {
    const h = new Date().getHours();
    if (h < 12) return 'Bom dia';
    if (h < 18) return 'Boa tarde';
    return 'Boa noite';
  };

  return (
    <div className="min-h-full">
      {/* Top bar with notification panel */}
      <div className="flex items-center justify-between px-6 md:px-8 py-3 border-b border-border bg-card/30 backdrop-blur-sm">
        <ResetDataButton />
        <NotificationPanel />
      </div>

      {/* Hero Header */}
      <div
        className="relative overflow-hidden"
        style={{
          backgroundImage: `url(https://d2xsxph8kpxj0f.cloudfront.net/310519663518148515/oNcz3mW7GMkmCQSg8sx7vf/hero-notebook-bg-E4SJboX8csg756B4GTphMv.webp)`,
          backgroundSize: 'cover',
          backgroundPosition: 'center top',
        }}
      >
        <div className="absolute inset-0 bg-gradient-to-b from-background/60 via-background/75 to-background" />
        <div className="relative z-10 px-6 md:px-8 py-10">
          <div className="flex items-start justify-between">
            <div>
              <p className="font-accent text-primary text-xl mb-1">
                {greeting()}! ✦
              </p>
              <h1 className="font-display text-4xl md:text-5xl font-bold text-foreground mb-3">
                Visão Geral
              </h1>
              <p className="font-body text-muted-foreground text-sm">
                {format(new Date(), "EEEE, d 'de' MMMM 'de' yyyy", { locale: ptBR })}
              </p>
            </div>
            <div className="hidden md:block text-right">
              <p className="font-accent text-muted-foreground text-sm">
                {stats.pending + stats.inProgress > 0
                  ? `${stats.pending + stats.inProgress} tarefas aguardando`
                  : 'Tudo em dia!'}
              </p>
              {stats.overdue > 0 && (
                <p className="font-body text-destructive text-xs mt-1">
                  ⚠ {stats.overdue} em atraso
                </p>
              )}
            </div>
          </div>
        </div>
      </div>

      <div className="px-6 md:px-8 py-6 space-y-6">
        {/* Notification alert */}
        {(count.critical > 0 || count.high > 0) && (
          <NotificationAlert critical={count.critical} high={count.high} />
        )}

        {/* Stats grid */}
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-3 md:gap-4">
          <StatCard
            icon={<CheckSquare size={20} style={{ color: '#C0533A' }} />}
            label="Concluídas"
            value={stats.done}
            accentColor="#C0533A"
            sub={`de ${stats.total} tarefas`}
            delay={0}
          />
          <StatCard
            icon={<Clock size={20} style={{ color: '#B45309' }} />}
            label="Em andamento"
            value={stats.inProgress}
            accentColor="#B45309"
            sub="tarefas ativas"
            delay={50}
          />
          <StatCard
            icon={<AlertTriangle size={20} style={{ color: stats.overdue > 0 ? '#DC2626' : '#9CA3AF' }} />}
            label="Em atraso"
            value={stats.overdue}
            accentColor={stats.overdue > 0 ? '#DC2626' : undefined}
            sub="precisam de atenção"
            delay={100}
          />
          <StatCard
            icon={<FileText size={20} style={{ color: '#4A7C59' }} />}
            label="Anotações"
            value={stats.notes}
            accentColor="#4A7C59"
            sub="registros salvos"
            delay={150}
          />
        </div>

        {/* Progress bar */}
        <div className="bg-card border border-border rounded-xl p-5 shadow-sm">
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center gap-2">
              <TrendingUp size={16} className="text-primary" />
              <span className="font-display font-semibold text-foreground">Progresso Geral</span>
            </div>
            <span className="font-accent text-3xl text-primary font-bold">{progressPct}%</span>
          </div>
          <div className="h-3 bg-muted rounded-full overflow-hidden">
            <div
              className="h-full rounded-full transition-all duration-1000 ease-out"
              style={{
                width: `${progressPct}%`,
                background: 'linear-gradient(90deg, #C0533A, #D97706)',
              }}
            />
          </div>
          <div className="flex items-center justify-between mt-2">
            <p className="font-body text-xs text-muted-foreground">
              {stats.done} de {stats.total} tarefas concluídas
            </p>
            {progressPct === 100 && (
              <div className="flex items-center gap-1 text-[#4A7C59]">
                <Sparkles size={12} />
                <span className="font-accent text-xs">Tudo concluído!</span>
              </div>
            )}
          </div>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-5">
          {/* Upcoming tasks */}
          <div className="lg:col-span-2 bg-card border border-border rounded-xl shadow-sm overflow-hidden">
            <div className="flex items-center justify-between px-5 py-4 border-b border-border bg-muted/30">
              <div className="flex items-center gap-2">
                <Calendar size={15} className="text-primary" />
                <h2 className="font-display font-semibold text-foreground">Próximos Prazos</h2>
              </div>
              <Link href="/tasks">
                <span className="font-body text-xs text-primary hover:underline flex items-center gap-1 transition-colors">
                  Ver todas <ArrowRight size={12} />
                </span>
              </Link>
            </div>
            <div className="divide-y divide-border">
              {upcomingTasks.length === 0 ? (
                <div className="px-5 py-10 text-center">
                  <Calendar size={28} className="text-muted-foreground/40 mx-auto mb-2" />
                  <p className="font-accent text-muted-foreground">Nenhuma tarefa com prazo</p>
                </div>
              ) : (
                upcomingTasks.map(task => {
                  const due = formatDueDate(task.dueDate);
                  const isLate = task.dueDate && isPast(new Date(task.dueDate));
                  return (
                    <div
                      key={task.id}
                      className={cn(
                        'flex items-center gap-4 px-5 py-3.5 hover:bg-muted/40 transition-colors',
                        `priority-${task.priority}`
                      )}
                    >
                      <div className="flex-1 min-w-0">
                        <p className="font-body text-sm font-medium text-foreground truncate">
                          {task.title}
                        </p>
                        {getCategoryName(task.categoryId) && (
                          <p className="font-body text-xs text-muted-foreground mt-0.5">
                            {getCategoryName(task.categoryId)}
                          </p>
                        )}
                      </div>
                      <div className="flex items-center gap-2 shrink-0">
                        <span className={cn(
                          'font-accent text-xs px-2 py-0.5 rounded-full',
                          priorityClass[task.priority]
                        )}>
                          {priorityLabel[task.priority]}
                        </span>
                        {due && (
                          <span className={cn(
                            'font-body text-xs font-medium',
                            isLate ? 'text-destructive' : 'text-muted-foreground'
                          )}>
                            {due}
                          </span>
                        )}
                      </div>
                    </div>
                  );
                })
              )}
            </div>
          </div>

          {/* Pinned notes */}
          <div className="bg-card border border-border rounded-xl shadow-sm overflow-hidden">
            <div className="flex items-center justify-between px-5 py-4 border-b border-border bg-muted/30">
              <div className="flex items-center gap-2">
                <Pin size={15} className="text-primary" />
                <h2 className="font-display font-semibold text-foreground">Notas Fixadas</h2>
              </div>
              <Link href="/notes">
                <span className="font-body text-xs text-primary hover:underline flex items-center gap-1">
                  Ver todas <ArrowRight size={12} />
                </span>
              </Link>
            </div>
            <div className="divide-y divide-border">
              {pinnedNotes.length === 0 ? (
                <div className="px-5 py-10 text-center">
                  <Pin size={28} className="text-muted-foreground/40 mx-auto mb-2" />
                  <p className="font-accent text-muted-foreground">Nenhuma nota fixada</p>
                </div>
              ) : (
                pinnedNotes.map(note => (
                  <Link key={note.id} href="/notes">
                    <div className="px-5 py-3.5 hover:bg-muted/40 transition-colors cursor-pointer">
                      <p className="font-body text-sm font-medium text-foreground truncate mb-1">
                        {note.title}
                      </p>
                      <p className="font-body text-xs text-muted-foreground line-clamp-2 leading-relaxed">
                        {note.content}
                      </p>
                    </div>
                  </Link>
                ))
              )}
            </div>
          </div>
        </div>

        {/* Recent tasks */}
        <div className="bg-card border border-border rounded-xl shadow-sm overflow-hidden">
          <div className="flex items-center justify-between px-5 py-4 border-b border-border bg-muted/30">
            <div className="flex items-center gap-2">
              <CheckSquare size={15} className="text-primary" />
              <h2 className="font-display font-semibold text-foreground">Tarefas Recentes</h2>
            </div>
            <Link href="/tasks">
              <span className="font-body text-xs text-primary hover:underline flex items-center gap-1">
                Gerenciar <ArrowRight size={12} />
              </span>
            </Link>
          </div>
          <div className="divide-y divide-border">
            {recentTasks.length === 0 ? (
              <div className="px-5 py-10 text-center">
                <CheckSquare size={28} className="text-[#4A7C59]/40 mx-auto mb-2" />
                <p className="font-accent text-muted-foreground">Todas as tarefas concluídas!</p>
              </div>
            ) : (
              recentTasks.map(task => (
                <div
                  key={task.id}
                  className={cn(
                    'flex items-center gap-4 px-5 py-3 hover:bg-muted/40 transition-colors',
                    `priority-${task.priority}`
                  )}
                >
                  <div className="flex-1 min-w-0">
                    <p className="font-body text-sm text-foreground truncate">{task.title}</p>
                  </div>
                  <span className={cn(
                    'font-body text-xs px-2 py-0.5 rounded-full',
                    task.status === 'in_progress'
                      ? 'bg-amber-100 text-amber-700'
                      : 'bg-muted text-muted-foreground'
                  )}>
                    {task.status === 'in_progress' ? 'Em andamento' : 'Pendente'}
                  </span>
                </div>
              ))
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
