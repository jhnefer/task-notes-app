/**
 * Tasks — Full task management page
 * Design: Warm Paper Notebook — ruled lines, ink typography, terracotta accents
 */

import { useState, useMemo } from 'react';
import {
  Plus,
  Search,
  Filter,
  Check,
  Trash2,
  Edit3,
  Calendar,
  Tag,
  ChevronDown,
  X,
  Clock,
  AlertCircle,
  LayoutList,
  Columns3,
  Repeat2,
} from 'lucide-react';
import { useApp } from '@/contexts/AppContext';
import { Task, Priority, TaskStatus } from '@/hooks/useStore';
import { cn } from '@/lib/utils';
import { format, isPast, isToday, isTomorrow } from 'date-fns';
import { ptBR } from 'date-fns/locale';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from '@/components/ui/dialog';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { Textarea } from '@/components/ui/textarea';
import { Label } from '@/components/ui/label';
import { toast } from 'sonner';
import { KanbanBoard } from '@/components/KanbanBoard';
import { ExportMenu } from '@/components/ExportMenu';
import { RecurringTaskDialog } from '@/components/RecurringTaskDialog';
import { isTaskOccurrence } from '@/lib/recurrence';

const PRIORITY_LABELS: Record<Priority, string> = {
  high: 'Alta',
  medium: 'Média',
  low: 'Baixa',
};

const STATUS_LABELS: Record<TaskStatus, string> = {
  pending: 'Pendente',
  in_progress: 'Em andamento',
  done: 'Concluída',
};

const PRIORITY_COLORS: Record<Priority, string> = {
  high: 'text-[#C0533A] bg-[#C0533A]/10 border-[#C0533A]/30',
  medium: 'text-[#B45309] bg-[#B45309]/10 border-[#B45309]/30',
  low: 'text-[#4A7C59] bg-[#4A7C59]/10 border-[#4A7C59]/30',
};

const STATUS_COLORS: Record<TaskStatus, string> = {
  pending: 'text-muted-foreground bg-muted',
  in_progress: 'text-amber-700 bg-amber-100',
  done: 'text-[#4A7C59] bg-[#4A7C59]/10',
};

function formatDueDate(dateStr?: string) {
  if (!dateStr) return null;
  const d = new Date(dateStr);
  if (isToday(d)) return 'Hoje';
  if (isTomorrow(d)) return 'Amanhã';
  return format(d, "d 'de' MMM", { locale: ptBR });
}

interface TaskFormData {
  title: string;
  description: string;
  priority: Priority;
  status: TaskStatus;
  categoryId: string;
  dueDate: string;
  tags: string;
}

const EMPTY_FORM: TaskFormData = {
  title: '',
  description: '',
  priority: 'medium',
  status: 'pending',
  categoryId: '',
  dueDate: '',
  tags: '',
};

function TaskDialog({
  open,
  onClose,
  task,
}: {
  open: boolean;
  onClose: () => void;
  task?: Task;
}) {
  const { addTask, updateTask, categories } = useApp();
  const [form, setForm] = useState<TaskFormData>(
    task
      ? {
          title: task.title,
          description: task.description ?? '',
          priority: task.priority,
          status: task.status,
          categoryId: task.categoryId ?? '',
          dueDate: task.dueDate ? task.dueDate.substring(0, 10) : '',
          tags: task.tags.join(', '),
        }
      : EMPTY_FORM
  );

  const handleSave = () => {
    if (!form.title.trim()) {
      toast.error('O título é obrigatório.');
      return;
    }
    const payload = {
      title: form.title.trim(),
      description: form.description.trim() || undefined,
      priority: form.priority,
      status: form.status,
      categoryId: form.categoryId || undefined,
      dueDate: form.dueDate ? new Date(form.dueDate).toISOString() : undefined,
      tags: form.tags
        .split(',')
        .map(t => t.trim())
        .filter(Boolean),
    };
    if (task) {
      updateTask(task.id, payload);
      toast.success('Tarefa atualizada!');
    } else {
      addTask(payload);
      toast.success('Tarefa criada!');
    }
    onClose();
  };

  return (
    <Dialog open={open} onOpenChange={v => !v && onClose()}>
      <DialogContent className="max-w-lg bg-card border-border">
        <DialogHeader>
          <DialogTitle className="font-display text-xl text-foreground">
            {task ? 'Editar Tarefa' : 'Nova Tarefa'}
          </DialogTitle>
        </DialogHeader>
        <div className="space-y-4 py-2">
          <div>
            <Label className="font-body text-sm text-foreground mb-1.5 block">Título *</Label>
            <Input
              value={form.title}
              onChange={e => setForm(f => ({ ...f, title: e.target.value }))}
              placeholder="O que precisa ser feito?"
              className="font-body bg-background border-border"
            />
          </div>
          <div>
            <Label className="font-body text-sm text-foreground mb-1.5 block">Descrição</Label>
            <Textarea
              value={form.description}
              onChange={e => setForm(f => ({ ...f, description: e.target.value }))}
              placeholder="Detalhes adicionais..."
              rows={3}
              className="font-body bg-background border-border resize-none"
            />
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div>
              <Label className="font-body text-sm text-foreground mb-1.5 block">Prioridade</Label>
              <Select
                value={form.priority}
                onValueChange={v => setForm(f => ({ ...f, priority: v as Priority }))}
              >
                <SelectTrigger className="font-body bg-background border-border">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="high">Alta</SelectItem>
                  <SelectItem value="medium">Média</SelectItem>
                  <SelectItem value="low">Baixa</SelectItem>
                </SelectContent>
              </Select>
            </div>
            <div>
              <Label className="font-body text-sm text-foreground mb-1.5 block">Status</Label>
              <Select
                value={form.status}
                onValueChange={v => setForm(f => ({ ...f, status: v as TaskStatus }))}
              >
                <SelectTrigger className="font-body bg-background border-border">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="pending">Pendente</SelectItem>
                  <SelectItem value="in_progress">Em andamento</SelectItem>
                  <SelectItem value="done">Concluída</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div>
              <Label className="font-body text-sm text-foreground mb-1.5 block">Categoria</Label>
              <Select
                value={form.categoryId || 'none'}
                onValueChange={v => setForm(f => ({ ...f, categoryId: v === 'none' ? '' : v }))}
              >
                <SelectTrigger className="font-body bg-background border-border">
                  <SelectValue placeholder="Selecionar..." />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="none">Sem categoria</SelectItem>
                  {categories.map(c => (
                    <SelectItem key={c.id} value={c.id}>{c.name}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div>
              <Label className="font-body text-sm text-foreground mb-1.5 block">Prazo</Label>
              <Input
                type="date"
                value={form.dueDate}
                onChange={e => setForm(f => ({ ...f, dueDate: e.target.value }))}
                className="font-body bg-background border-border"
              />
            </div>
          </div>
          <div>
            <Label className="font-body text-sm text-foreground mb-1.5 block">
              Tags <span className="text-muted-foreground">(separadas por vírgula)</span>
            </Label>
            <Input
              value={form.tags}
              onChange={e => setForm(f => ({ ...f, tags: e.target.value }))}
              placeholder="trabalho, urgente, reunião..."
              className="font-body bg-background border-border"
            />
          </div>
        </div>
        <DialogFooter className="gap-2">
          <Button variant="outline" onClick={onClose} className="font-body">
            Cancelar
          </Button>
          <Button onClick={handleSave} className="font-body bg-primary text-primary-foreground hover:bg-primary/90">
            {task ? 'Salvar' : 'Criar Tarefa'}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}

export default function Tasks() {
  const { tasks, categories, toggleTaskStatus, deleteTask, updateTask, addRecurringTask } = useApp();
  const [search, setSearch] = useState('');
  const [filterPriority, setFilterPriority] = useState<Priority | 'all'>('all');
  const [filterStatus, setFilterStatus] = useState<TaskStatus | 'all'>('all');
  const [filterCategory, setFilterCategory] = useState<string>('all');
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editingTask, setEditingTask] = useState<Task | undefined>();
  const [showFilters, setShowFilters] = useState(false);
  const [viewMode, setViewMode] = useState<'list' | 'kanban'>('list');
  const [recurringDialogOpen, setRecurringDialogOpen] = useState(false);

  const filtered = useMemo(() => {
    return tasks.filter(t => {
      const matchSearch =
        !search ||
        t.title.toLowerCase().includes(search.toLowerCase()) ||
        t.description?.toLowerCase().includes(search.toLowerCase()) ||
        t.tags.some(tag => tag.toLowerCase().includes(search.toLowerCase()));
      const matchPriority = filterPriority === 'all' || t.priority === filterPriority;
      const matchStatus = filterStatus === 'all' || t.status === filterStatus;
      const matchCategory =
        filterCategory === 'all' ||
        (filterCategory === 'none' ? !t.categoryId : t.categoryId === filterCategory);
      return matchSearch && matchPriority && matchStatus && matchCategory;
    });
  }, [tasks, search, filterPriority, filterStatus, filterCategory]);

  const grouped = useMemo(() => {
    const groups: Record<string, Task[]> = {
      in_progress: [],
      pending: [],
      done: [],
    };
    filtered.forEach(t => groups[t.status].push(t));
    return groups;
  }, [filtered]);

  const getCategoryName = (id?: string) =>
    categories.find(c => c.id === id)?.name ?? '';

  const handleEdit = (task: Task) => {
    setEditingTask(task);
    setDialogOpen(true);
  };

  const handleDelete = (id: string) => {
    deleteTask(id);
    toast.success('Tarefa removida.');
  };

  const handleDialogClose = () => {
    setDialogOpen(false);
    setEditingTask(undefined);
  };

  const handleStatusChange = (taskId: string, newStatus: TaskStatus) => {
    const task = tasks.find(t => t.id === taskId);
    if (task) {
      updateTask(taskId, { status: newStatus });
      toast.success('Tarefa movida!');
    }
  };

  const activeFilters =
    (filterPriority !== 'all' ? 1 : 0) +
    (filterStatus !== 'all' ? 1 : 0) +
    (filterCategory !== 'all' ? 1 : 0);

  return (
    <div className="min-h-full">
      {/* Header */}
      <div className="px-8 py-6 border-b border-border bg-card/50">
        <div className="flex items-center justify-between mb-4">
          <div>
            <h1 className="font-display text-3xl font-bold text-foreground">Tarefas</h1>
            <p className="font-body text-sm text-muted-foreground mt-0.5">
              {filtered.length} de {tasks.length} tarefas
            </p>
          </div>
          <div className="flex items-center gap-2">
            <ExportMenu tasks={filtered} categories={categories} />
            <Button
              onClick={() => setRecurringDialogOpen(true)}
              variant="outline"
              className="font-body gap-2 border-border"
              title="Criar tarefa recorrente"
            >
              <Repeat2 size={16} />
              Recorrente
            </Button>
            <Button
              onClick={() => { setEditingTask(undefined); setDialogOpen(true); }}
              className="font-body bg-primary text-primary-foreground hover:bg-primary/90 gap-2"
            >
              <Plus size={16} />
              Nova Tarefa
            </Button>
          </div>
        </div>

        {/* View toggle + Search + Filter */}
        <div className="flex gap-3 items-center">
          <div className="flex items-center gap-1 bg-muted p-1 rounded-lg">
            <button
              onClick={() => setViewMode('list')}
              className={cn(
                'p-2 rounded transition-colors',
                viewMode === 'list'
                  ? 'bg-background text-foreground shadow-sm'
                  : 'text-muted-foreground hover:text-foreground'
              )}
              title="Visualização em lista"
            >
              <LayoutList size={16} />
            </button>
            <button
              onClick={() => setViewMode('kanban')}
              className={cn(
                'p-2 rounded transition-colors',
                viewMode === 'kanban'
                  ? 'bg-background text-foreground shadow-sm'
                  : 'text-muted-foreground hover:text-foreground'
              )}
              title="Visualização Kanban"
            >
              <Columns3 size={16} />
            </button>
          </div>
          <div className="relative flex-1">
            <Search size={15} className="absolute left-3 top-1/2 -translate-y-1/2 text-muted-foreground" />
            <Input
              value={search}
              onChange={e => setSearch(e.target.value)}
              placeholder="Buscar tarefas..."
              className="pl-9 font-body bg-background border-border"
            />
          </div>
          <Button
            variant="outline"
            onClick={() => setShowFilters(f => !f)}
            className={cn('font-body gap-2 border-border', showFilters && 'bg-muted')}
          >
            <Filter size={15} />
            Filtros
            {activeFilters > 0 && (
              <span className="bg-primary text-primary-foreground text-xs rounded-full w-4 h-4 flex items-center justify-center">
                {activeFilters}
              </span>
            )}
            <ChevronDown size={14} className={cn('transition-transform', showFilters && 'rotate-180')} />
          </Button>
        </div>

        {/* Filter panel */}
        {showFilters && (
          <div className="mt-3 flex flex-wrap gap-3 p-4 bg-muted/50 rounded-lg border border-border">
            <div className="flex items-center gap-2">
              <span className="font-body text-xs text-muted-foreground">Prioridade:</span>
              <Select value={filterPriority} onValueChange={v => setFilterPriority(v as Priority | 'all')}>
                <SelectTrigger className="h-8 w-32 font-body text-xs bg-background border-border">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">Todas</SelectItem>
                  <SelectItem value="high">Alta</SelectItem>
                  <SelectItem value="medium">Média</SelectItem>
                  <SelectItem value="low">Baixa</SelectItem>
                </SelectContent>
              </Select>
            </div>
            <div className="flex items-center gap-2">
              <span className="font-body text-xs text-muted-foreground">Status:</span>
              <Select value={filterStatus} onValueChange={v => setFilterStatus(v as TaskStatus | 'all')}>
                <SelectTrigger className="h-8 w-36 font-body text-xs bg-background border-border">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">Todos</SelectItem>
                  <SelectItem value="pending">Pendente</SelectItem>
                  <SelectItem value="in_progress">Em andamento</SelectItem>
                  <SelectItem value="done">Concluída</SelectItem>
                </SelectContent>
              </Select>
            </div>
            <div className="flex items-center gap-2">
              <span className="font-body text-xs text-muted-foreground">Categoria:</span>
              <Select value={filterCategory} onValueChange={setFilterCategory}>
                <SelectTrigger className="h-8 w-36 font-body text-xs bg-background border-border">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">Todas</SelectItem>
                  <SelectItem value="none">Sem categoria</SelectItem>
                  {categories.map(c => (
                    <SelectItem key={c.id} value={c.id}>{c.name}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            {activeFilters > 0 && (
              <button
                onClick={() => { setFilterPriority('all'); setFilterStatus('all'); setFilterCategory('all'); }}
                className="flex items-center gap-1 font-body text-xs text-destructive hover:underline"
              >
                <X size={12} /> Limpar filtros
              </button>
            )}
          </div>
        )}
      </div>

      {/* Content */}
      <div className="px-8 py-6">
        {viewMode === 'kanban' ? (
          /* Kanban view */
          <KanbanBoard
            tasks={filtered}
            onStatusChange={handleStatusChange}
            onEdit={handleEdit}
            onDelete={handleDelete}
            getCategoryName={getCategoryName}
          />
        ) : (
          /* List view */
          <div className="space-y-8">
        {(['in_progress', 'pending', 'done'] as TaskStatus[]).map(status => {
          const group = grouped[status];
          if (group.length === 0) return null;
          return (
            <div key={status}>
              <div className="flex items-center gap-3 mb-3">
                <h2 className="font-display text-lg font-semibold text-foreground ink-underline">
                  {STATUS_LABELS[status]}
                </h2>
                <span className="font-accent text-muted-foreground text-sm">
                  {group.length}
                </span>
              </div>
              <div className="space-y-2">
                {group.map(task => {
                  const due = formatDueDate(task.dueDate);
                  const isLate = task.dueDate && isPast(new Date(task.dueDate)) && task.status !== 'done';
                  return (
                    <div
                      key={task.id}
                      className={cn(
                        'bg-card border border-border rounded-lg px-4 py-3.5',
                        'flex items-start gap-4 group hover:shadow-sm transition-shadow',
                        `priority-${task.priority}`,
                        task.status === 'done' && 'opacity-70'
                      )}
                    >
                      {/* Checkbox */}
                      <button
                        onClick={() => toggleTaskStatus(task.id)}
                        className={cn(
                          'mt-0.5 shrink-0 w-5 h-5 rounded border-2 flex items-center justify-center transition-all',
                          task.status === 'done'
                            ? 'bg-[#4A7C59] border-[#4A7C59]'
                            : 'border-border hover:border-primary'
                        )}
                      >
                        {task.status === 'done' && <Check size={12} className="text-white" />}
                      </button>

                      {/* Content */}
                      <div className="flex-1 min-w-0">
                        <div className="flex items-start justify-between gap-2">
                          <p className={cn(
                            'font-body text-sm font-medium text-foreground',
                            task.status === 'done' && 'line-through text-muted-foreground'
                          )}>
                            {task.title}
                          </p>
                          {/* Actions */}
                          <div className="flex items-center gap-1 opacity-0 group-hover:opacity-100 transition-opacity shrink-0">
                            <button
                              onClick={() => handleEdit(task)}
                              className="p-1 rounded hover:bg-muted text-muted-foreground hover:text-foreground transition-colors"
                            >
                              <Edit3 size={14} />
                            </button>
                            <button
                              onClick={() => handleDelete(task.id)}
                              className="p-1 rounded hover:bg-destructive/10 text-muted-foreground hover:text-destructive transition-colors"
                            >
                              <Trash2 size={14} />
                            </button>
                          </div>
                        </div>

                        {task.description && (
                          <p className="font-body text-xs text-muted-foreground mt-0.5 line-clamp-1">
                            {task.description}
                          </p>
                        )}

                        <div className="flex items-center flex-wrap gap-2 mt-2">
                          <span className={cn(
                            'font-accent text-xs px-2 py-0.5 rounded-full border',
                            PRIORITY_COLORS[task.priority]
                          )}>
                            {PRIORITY_LABELS[task.priority]}
                          </span>

                          {getCategoryName(task.categoryId) && (
                            <span className="font-body text-xs text-muted-foreground flex items-center gap-1">
                              <Tag size={10} />
                              {getCategoryName(task.categoryId)}
                            </span>
                          )}

                          {due && (
                            <span className={cn(
                              'font-body text-xs flex items-center gap-1',
                              isLate ? 'text-destructive' : 'text-muted-foreground'
                            )}>
                              {isLate ? <AlertCircle size={10} /> : <Clock size={10} />}
                              {due}
                            </span>
                          )}

                          {task.tags.map(tag => (
                            <span key={tag} className="font-body text-xs text-muted-foreground bg-muted px-1.5 py-0.5 rounded">
                              #{tag}
                            </span>
                          ))}
                        </div>
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>
          );
        })}

            {filtered.length === 0 && (
              <div className="text-center py-16">
                <p className="font-display text-2xl text-muted-foreground mb-2">Nenhuma tarefa encontrada</p>
                <p className="font-accent text-muted-foreground">
                  {search || activeFilters > 0
                    ? 'Tente ajustar os filtros de busca'
                    : 'Clique em "Nova Tarefa" para começar'}
                </p>
              </div>
            )}
          </div>
        )}
      </div>

      <TaskDialog open={dialogOpen} onClose={handleDialogClose} task={editingTask} />
      <RecurringTaskDialog
        open={recurringDialogOpen}
        onClose={() => setRecurringDialogOpen(false)}
        onSave={addRecurringTask}
        categories={categories}
      />
    </div>
  );
}
