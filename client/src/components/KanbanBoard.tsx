/**
 * KanbanBoard — Kanban view for tasks with drag-and-drop
 * Design: Warm Paper Notebook
 */

import { useState } from 'react';
import { Task, TaskStatus } from '@/hooks/useStore';
import { cn } from '@/lib/utils';
import { Trash2, Edit3, Check, Clock, AlertTriangle } from 'lucide-react';
import { RecurrenceBadge } from './RecurrenceBadge';

interface KanbanBoardProps {
  tasks: Task[];
  onStatusChange: (taskId: string, newStatus: TaskStatus) => void;
  onEdit: (task: Task) => void;
  onDelete: (taskId: string) => void;
  getCategoryName: (id?: string) => string;
}

const COLUMNS: { status: TaskStatus; label: string; color: string }[] = [
  { status: 'pending', label: 'Pendente', color: 'bg-slate-50 border-slate-200' },
  { status: 'in_progress', label: 'Em Andamento', color: 'bg-amber-50 border-amber-200' },
  { status: 'done', label: 'Concluída', color: 'bg-green-50 border-green-200' },
];

const PRIORITY_COLORS: Record<string, string> = {
  high: 'border-l-[#C0533A]',
  medium: 'border-l-[#B45309]',
  low: 'border-l-[#4A7C59]',
};

const PRIORITY_LABELS: Record<string, string> = {
  high: 'Alta',
  medium: 'Média',
  low: 'Baixa',
};

function KanbanCard({
  task,
  onStatusChange,
  onEdit,
  onDelete,
  getCategoryName,
}: {
  task: Task;
  onStatusChange: (status: TaskStatus) => void;
  onEdit: () => void;
  onDelete: () => void;
  getCategoryName: (id?: string) => string;
}) {
  const [draggedOver, setDraggedOver] = useState(false);

  const handleDragStart = (e: React.DragEvent) => {
    e.dataTransfer.effectAllowed = 'move';
    e.dataTransfer.setData('taskId', task.id);
  };

  const handleDragEnd = () => {
    setDraggedOver(false);
  };

  return (
    <div
      draggable
      onDragStart={handleDragStart}
      onDragEnd={handleDragEnd}
      className={cn(
        'bg-white rounded-lg border-l-4 p-3 shadow-sm hover:shadow-md',
        'transition-all duration-200 cursor-move group',
        'border-b border-r border-border',
        PRIORITY_COLORS[task.priority],
        draggedOver && 'opacity-50'
      )}
    >
      <div className="flex items-start justify-between gap-2 mb-2">
        <p className="font-body text-sm font-medium text-foreground flex-1 line-clamp-2">
          {task.title}
        </p>
        <div className="flex items-center gap-1 opacity-0 group-hover:opacity-100 transition-opacity shrink-0">
          <button
            onClick={onEdit}
            className="p-1 rounded hover:bg-muted text-muted-foreground hover:text-foreground transition-colors"
            title="Editar"
          >
            <Edit3 size={14} />
          </button>
          <button
            onClick={onDelete}
            className="p-1 rounded hover:bg-destructive/10 text-muted-foreground hover:text-destructive transition-colors"
            title="Deletar"
          >
            <Trash2 size={14} />
          </button>
        </div>
      </div>

      {task.description && (
        <p className="font-body text-xs text-muted-foreground line-clamp-2 mb-2">
          {task.description}
        </p>
      )}

      <div className="flex items-center flex-wrap gap-1.5">
        <span className="font-accent text-xs px-1.5 py-0.5 rounded-full bg-muted text-muted-foreground">
          {PRIORITY_LABELS[task.priority]}
        </span>
        {getCategoryName(task.categoryId) && (
          <span className="font-body text-xs text-muted-foreground bg-muted/50 px-1.5 py-0.5 rounded">
            {getCategoryName(task.categoryId)}
          </span>
        )}
        <RecurrenceBadge task={task} />
        {task.dueDate && (
          <span className="font-body text-xs text-muted-foreground flex items-center gap-0.5">
            <Clock size={10} />
            {new Date(task.dueDate).toLocaleDateString('pt-BR', {
              month: 'short',
              day: 'numeric',
            })}
          </span>
        )}
      </div>
    </div>
  );
}

function KanbanColumn({
  status,
  label,
  color,
  tasks,
  onStatusChange,
  onEdit,
  onDelete,
  getCategoryName,
}: {
  status: TaskStatus;
  label: string;
  color: string;
  tasks: Task[];
  onStatusChange: (taskId: string, newStatus: TaskStatus) => void;
  onEdit: (task: Task) => void;
  onDelete: (taskId: string) => void;
  getCategoryName: (id?: string) => string;
}) {
  const [draggedOver, setDraggedOver] = useState(false);

  const handleDragOver = (e: React.DragEvent) => {
    e.preventDefault();
    e.dataTransfer.dropEffect = 'move';
    setDraggedOver(true);
  };

  const handleDragLeave = () => {
    setDraggedOver(false);
  };

  const handleDrop = (e: React.DragEvent) => {
    e.preventDefault();
    setDraggedOver(false);
    const taskId = e.dataTransfer.getData('taskId');
    if (taskId) {
      onStatusChange(taskId, status);
    }
  };

  return (
    <div
      onDragOver={handleDragOver}
      onDragLeave={handleDragLeave}
      onDrop={handleDrop}
      className={cn(
        'flex flex-col rounded-lg border-2 p-4 min-h-96 transition-all',
        draggedOver ? 'border-primary bg-primary/5' : `${color} border-border`
      )}
    >
      <div className="flex items-center justify-between mb-4">
        <h3 className="font-display font-semibold text-foreground">{label}</h3>
        <span className="font-accent text-sm text-muted-foreground bg-muted px-2 py-0.5 rounded-full">
          {tasks.length}
        </span>
      </div>

      <div className="flex-1 space-y-2 overflow-y-auto">
        {tasks.length === 0 ? (
          <div className="flex items-center justify-center h-full text-center">
            <p className="font-accent text-muted-foreground text-sm">
              Nenhuma tarefa
            </p>
          </div>
        ) : (
          tasks.map(task => (
            <KanbanCard
              key={task.id}
              task={task}
              onStatusChange={() => onStatusChange(task.id, status)}
              onEdit={() => onEdit(task)}
              onDelete={() => onDelete(task.id)}
              getCategoryName={getCategoryName}
            />
          ))
        )}
      </div>
    </div>
  );
}

export function KanbanBoard({
  tasks,
  onStatusChange,
  onEdit,
  onDelete,
  getCategoryName,
}: KanbanBoardProps) {
  return (
    <div className="grid grid-cols-1 md:grid-cols-3 gap-4 auto-rows-max">
      {COLUMNS.map(column => (
        <KanbanColumn
          key={column.status}
          status={column.status}
          label={column.label}
          color={column.color}
          tasks={tasks.filter(t => t.status === column.status)}
          onStatusChange={onStatusChange}
          onEdit={onEdit}
          onDelete={onDelete}
          getCategoryName={getCategoryName}
        />
      ))}
    </div>
  );
}
