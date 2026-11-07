/**
- Tasks — Full task management page
- Design: Warm Paper Notebook — ruled lines, ink typography, terracotta accents
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
  Target,
} from 'lucide-react';
import { useApp } from '@/contexts/AppContext';
import { Task, Priority, TaskStatus, Subtask } from '@/hooks/useStore';
import { nanoid } from 'nanoid';
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
import { AiBreakdownModal } from '@/components/AiBreakdownModal';

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
  subtasks: Subtask[];
}

const EMPTY_FORM: TaskFormData = {
  title: '',
  description: '',
  priority: 'medium',
  status: 'pending',
  categoryId: '',
  dueDate: '',
  tags: '',
  subtasks: [],
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
  const [newSubtaskTitle, setNewSubtaskTitle] = useState('');
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
          subtasks: task.subtasks ? [...task.subtasks] : [],
        }
      : EMPTY_FORM
  );

  const handleAddManualSubtask = () => {
    if (!newSubtaskTitle.trim()) return;
    const newSub: Subtask = {
      id: nanoid(),
      title: newSubtaskTitle.trim(),
      completed: false,
      priority: form.priority,
    };
    setForm(f => ({
      ...f,
      subtasks: [...f.subtasks, newSub],
    }));
    setNewSubtaskTitle('');
  };

  const handleSave = () => {
    if (!form.title.trim()) {
      toast.error('O título é obrigatório.');
      return;
    }

    // Regra: Bloquear conclusão da meta se houver submetas pendentes
    if (form.status === 'done' && form.subtasks.length > 0) {
      const pendingCount = form.subtasks.filter(s => !s.completed).length;
      if (pendingCount > 0) {
        toast.warning(
          `Esta meta possui ${pendingCount} submeta${pendingCount > 1 ? 's' : ''} pendente${pendingCount > 1 ? 's' : ''}. Complete todas antes de finalizá-la!`,
          { icon: '⚠️' }
        );
        return;
      }
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
      subtasks: form.subtasks,
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
      <DialogContent className="max-w-lg bg-card border-border max-h-[90vh] overflow-y-auto">
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

          {/* MÓDULO DA IA: Decomposição de tarefas pelo Gemini em Submetas */}
          <AiBreakdownModal
            taskTitle={form.title}
            onAddSubtasks={(subtasks) => {
              const formatted: Subtask[] = subtasks.map(st => ({
                id: nanoid(),
                title: st.title,
                completed: false,
                priority: st.priority,
              }));
              setForm(f => ({
                ...f,
                subtasks: [...f.subtasks, ...formatted],
              }));
              toast.success(`${formatted.length} submetas adicionadas à meta!`);
            }}
          />

          {/* LISTA INTERATIVA DE SUBMETAS */}
          <div className="space-y-2 pt-2 border-t border-border">
            <div className="flex items-center justify-between">
              <Label className="font-body text-sm font-semibold text-foreground flex items-center gap-1.5">
                <Target size={15} className="text-primary" />
                Submetas ({form.subtasks.filter(s => s.completed).length}/{form.subtasks.length})
              </Label>
              {form.subtasks.length > 0 && (
                <span className="text-xs text-muted-foreground font-mono">
                  {Math.round((form.subtasks.filter(s => s.completed).length / form.subtasks.length) * 100)}% concluídas
                </span>
              )}
            </div>

            {form.subtasks.length > 0 ? (
              <div className="space-y-1.5 max-h-48 overflow-y-auto pr-1">
                {form.subtasks.map((st, idx) => (
                  <div
                    key={st.id || idx}
                    className="flex items-center justify-between p-2 rounded-lg border border-border bg-muted/40 text-xs"
                  >
                    <div className="flex items-center gap-2 flex-1 min-w-0 mr-2">
                      <input
                        type="checkbox"
                        checked={st.completed}
                        onChange={(e) => {
                          const updated = form.subtasks.map((item, i) =>
                            i === idx ? { ...item, completed: e.target.checked } : item
                          );
                          setForm(f => ({ ...f, subtasks: updated }));
                        }}
                        className="rounded border-border text-primary focus:ring-primary w-3.5 h-3.5 cursor-pointer"
                      />
                      <span className={cn('truncate', st.completed && 'line-through text-muted-foreground')}>
                        {st.title}
                      </span>
                    </div>
                    <div className="flex items-center gap-1.5 shrink-0">
                      <span className={cn(
                        'px-1.5 py-0.5 rounded text-[10px] font-medium uppercase',
                        st.priority === 'high' ? 'bg-red-100 text-red-700 dark:bg-red-950 dark:text-red-300' :
                        st.priority === 'medium' ? 'bg-amber-100 text-amber-700 dark:bg-amber-950 dark:text-amber-300' :
                        'bg-blue-100 text-blue-700 dark:bg-blue-950 dark:text-blue-300'
                      )}>
                        {st.priority}
                      </span>
                      <button
                        type="button"
                        onClick={() => {
                          setForm(f => ({
                            ...f,
                            subtasks: f.subtasks.filter((_, i) => i !== idx),
                          }));
                        }}
                        className="p-1 hover:text-destructive text-muted-foreground transition-colors"
                        title="Remover submeta"
                      >
                        <Trash2 size={12} />
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            ) : (
              <p className="text-xs text-muted-foreground italic">Nenhuma submeta adicionada ainda.</p>
            )}

            {/* Adicionar submeta manual */}
            <div className="flex items-center gap-2 pt-1">
              <Input
                placeholder="Adicionar submeta manual..."
                value={newSubtaskTitle}
                onChange={e => setNewSubtaskTitle(e.target.value)}
                onKeyDown={e => {
                  if (e.key === 'Enter') {
                    e.preventDefault();
                    handleAddManualSubtask();
                  }
                }}
                className="h-8 text-xs bg-background border-border flex-1"
              />
              <Button
                type="button"
                variant="outline"
                size="sm"
                onClick={handleAddManualSubtask}
                disabled={!newSubtaskTitle.trim()}
                className="h-8 px-2.5 text-xs gap-1 border-border"
              >
                <Plus size={13} />
                Adicionar
              </Button>
            </div>
          </div>

          <div>
            <Label className="font-body text-sm text-foreground mb-1.5 block">Descrição</Label>
            <Textarea
              value={form.description}
              onChange={e => setForm(f => ({ ...f, description: e.target.value }))}
              placeholder="Detalhes adicionais..."
              rows={4}
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
  const { tasks, categories, toggleTaskStatus, toggleSubtask, deleteTask, updateTask, addRecurringTask } = useApp();
  const [search, setSearch] = useState('');
  const [filterPriority, setFilterPriority] = useState<Priority | 'all'>('all');
  const [filterStatus, setFilterStatus] = useState<TaskStatus | 'all'>('all');
  const [filterCategory, setFilterCategory] = useState<string>('all');
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editingTask, setEditingTask] = useState<Task | undefined>();
  const [showFilters, setShowFilters] = useState(false);
  const [viewMode, setViewMode] = useState<'list' | 'kanban'>('list');
  const [recurringDialogOpen, setRecurringDialogOpen] = useState(false);
  const [expandedTasks, setExpandedTasks] = useState<Record<string, boolean>>({});

  const toggleExpandTask = (id: string) => {
    setExpandedTasks(prev => ({ ...prev, [id]: !prev[id] }));
  };

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
    if (!task) return;

    if (newStatus === 'done' && task.subtasks && task.subtasks.length > 0) {
      const pendingCount = task.subtasks.filter(s => !s.completed).length;
      if (pendingCount > 0) {
        toast.warning(
          `Esta meta possui ${pendingCount} submeta${pendingCount > 1 ? 's' : ''} pendente${pendingCount > 1 ? 's' : ''}. Complete todas antes de finalizá-la!`,
          { icon: '⚠️' }
        );
        return;
      }
    }

    updateTask(taskId, { status: newStatus });
    toast.success('Tarefa movida!');
  };

  const handleToggleTask = (task: Task) => {
    if (task.status !== 'done' && task.subtasks && task.subtasks.length > 0) {
      const pendingCount = task.subtasks.filter(s => !s.completed).length;
      if (pendingCount > 0) {
        toast.warning(
          `Esta meta possui ${pendingCount} submeta${pendingCount > 1 ? 's' : ''} pendente${pendingCount > 1 ? 's' : ''}. Complete todas antes de finalizá-la!`,
          { icon: '⚠️' }
        );
        return;
      }
    }
    toggleTaskStatus(task.id);
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
                        onClick={() => handleToggleTask(task)}
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
                          <p className="font-body text-xs text-muted-foreground mt-0.5 line-clamp-2 whitespace-pre-line">
                            {task.description}
                          </p>
                        )}

                        {/* Módulo de Submetas da Meta Maior */}
                        {task.subtasks && task.subtasks.length > 0 && (() => {
                          const completedCount = task.subtasks.filter(s => s.completed).length;
                          const totalCount = task.subtasks.length;
                          const pct = Math.round((completedCount / totalCount) * 100);
                          const isExpanded = !!expandedTasks[task.id];

                          return (
                            <div className="mt-3 pt-2.5 border-t border-border/60">
                              <div 
                                onClick={() => toggleExpandTask(task.id)}
                                className="flex items-center justify-between cursor-pointer py-1 group/sub"
                              >
                                <div className="flex items-center gap-2 text-xs font-medium text-foreground">
                                  <Target size={13} className="text-primary" />
                                  <span>Submetas ({completedCount}/{totalCount})</span>
                                  <span className="text-[11px] text-muted-foreground font-mono">({pct}%)</span>
                                </div>
                                <div className="flex items-center gap-1 text-xs text-muted-foreground group-hover/sub:text-foreground transition-colors">
                                  <span className="text-[11px]">{isExpanded ? 'Ocultar' : 'Ver submetas'}</span>
                                  <ChevronDown size={13} className={cn('transition-transform duration-200', isExpanded && 'rotate-180')} />
                                </div>
                              </div>

                              {/* Barra de progresso */}
                              <div className="w-full bg-muted rounded-full h-1.5 mt-1 overflow-hidden">
                                <div 
                                  className={cn(
                                    'h-1.5 transition-all duration-300 rounded-full',
                                    pct === 100 ? 'bg-emerald-500' : 'bg-primary'
                                  )} 
                                  style={{ width: `${pct}%` }} 
                                />
                              </div>

                              {/* Lista interativa de submetas */}
                              {isExpanded && (
                                <div className="mt-2.5 space-y-1.5 pl-1">
                                  {task.subtasks.map(st => (
                                    <div 
                                      key={st.id}
                                      onClick={(e) => {
                                        e.stopPropagation();
                                        toggleSubtask(task.id, st.id);
                                      }}
                                      className="flex items-center justify-between p-1.5 rounded hover:bg-muted/60 cursor-pointer text-xs transition-colors"
                                    >
                                      <div className="flex items-center gap-2 flex-1 min-w-0">
                                        <div className={cn(
                                          'w-4 h-4 rounded border flex items-center justify-center transition-all shrink-0',
                                          st.completed 
                                            ? 'bg-emerald-500 border-emerald-500 text-white' 
                                            : 'border-border hover:border-primary'
                                        )}>
                                          {st.completed && <Check size={10} />}
                                        </div>
                                        <span className={cn('truncate', st.completed && 'line-through text-muted-foreground')}>
                                          {st.title}
                                        </span>
                                      </div>
                                      <span className={cn(
                                        'text-[9px] uppercase px-1 rounded font-medium shrink-0 ml-2',
                                        st.priority === 'high' ? 'text-red-600 bg-red-50 dark:bg-red-950/50' :
                                        st.priority === 'medium' ? 'text-amber-600 bg-amber-50 dark:bg-amber-950/50' :
                                        'text-blue-600 bg-blue-50 dark:bg-blue-950/50'
                                      )}>
                                        {st.priority}
                                      </span>
                                    </div>
                                  ))}
                                </div>
                              )}
                            </div>
                          );
                        })()}

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