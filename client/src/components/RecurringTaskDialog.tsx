/**
 * RecurringTaskDialog — Dialog for creating recurring tasks
 * Design: Warm Paper Notebook
 */

import { useState } from 'react';
import { Task, Priority, TaskStatus, RecurrenceFrequency, RecurrenceRule } from '@/hooks/useStore';
import { cn } from '@/lib/utils';
import { Calendar, Repeat2, X } from 'lucide-react';
import { Button } from '@/components/ui/button';
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
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import { Label } from '@/components/ui/label';
import { toast } from 'sonner';
import { getIntervalLabel } from '@/lib/recurrence';

interface RecurringTaskFormData {
  title: string;
  description: string;
  priority: Priority;
  categoryId: string;
  dueDate: string;
  frequency: RecurrenceFrequency;
  interval: number;
  maxOccurrences: number;
  endDate: string;
  useEndDate: boolean;
}

const EMPTY_FORM: RecurringTaskFormData = {
  title: '',
  description: '',
  priority: 'medium',
  categoryId: '',
  dueDate: '',
  frequency: 'weekly',
  interval: 1,
  maxOccurrences: 12,
  endDate: '',
  useEndDate: false,
};

interface RecurringTaskDialogProps {
  open: boolean;
  onClose: () => void;
  onSave: (task: Omit<Task, 'id' | 'createdAt' | 'updatedAt'> & { recurrence: RecurrenceRule }) => void;
  categories: { id: string; name: string }[];
}

export function RecurringTaskDialog({
  open,
  onClose,
  onSave,
  categories,
}: RecurringTaskDialogProps) {
  const [form, setForm] = useState<RecurringTaskFormData>(EMPTY_FORM);

  const handleSave = () => {
    if (!form.title.trim()) {
      toast.error('O título é obrigatório.');
      return;
    }
    if (!form.dueDate) {
      toast.error('A data de início é obrigatória.');
      return;
    }

    const recurrenceRule: RecurrenceRule = {
      frequency: form.frequency,
      interval: form.interval,
      maxOccurrences: form.maxOccurrences,
      endDate: form.useEndDate && form.endDate ? form.endDate : undefined,
    };

    const task: Omit<Task, 'id' | 'createdAt' | 'updatedAt'> & { recurrence: RecurrenceRule } = {
      title: form.title.trim(),
      description: form.description.trim() || undefined,
      priority: form.priority,
      status: 'pending' as TaskStatus,
      categoryId: form.categoryId || undefined,
      dueDate: new Date(form.dueDate).toISOString(),
      tags: [],
      recurrence: recurrenceRule,
    };

    onSave(task);
    setForm(EMPTY_FORM);
    onClose();
    toast.success('Tarefa recorrente criada!');
  };

  const handleClose = () => {
    setForm(EMPTY_FORM);
    onClose();
  };

  const recurrenceSummary = getIntervalLabel(form.frequency, form.interval);
  const occurrenceCount = form.useEndDate && form.endDate
    ? 'Até a data de término'
    : `${form.maxOccurrences} ocorrências`;

  return (
    <Dialog open={open} onOpenChange={v => !v && handleClose()}>
      <DialogContent className="max-w-2xl bg-card border-border">
        <DialogHeader>
          <DialogTitle className="font-display text-xl text-foreground flex items-center gap-2">
            <Repeat2 size={20} />
            Nova Tarefa Recorrente
          </DialogTitle>
        </DialogHeader>

        <div className="space-y-4 py-2">
          {/* Title */}
          <div>
            <Label className="font-body text-sm text-foreground mb-1.5 block">Título *</Label>
            <Input
              value={form.title}
              onChange={e => setForm(f => ({ ...f, title: e.target.value }))}
              placeholder="Título da tarefa..."
              className="font-display text-lg bg-background border-border"
            />
          </div>

          {/* Description */}
          <div>
            <Label className="font-body text-sm text-foreground mb-1.5 block">Descrição</Label>
            <Textarea
              value={form.description}
              onChange={e => setForm(f => ({ ...f, description: e.target.value }))}
              placeholder="Descrição da tarefa..."
              rows={3}
              className="font-body bg-background border-border resize-none"
            />
          </div>

          {/* Priority and Category */}
          <div className="grid grid-cols-2 gap-3">
            <div>
              <Label className="font-body text-sm text-foreground mb-1.5 block">Prioridade</Label>
              <Select value={form.priority} onValueChange={v => setForm(f => ({ ...f, priority: v as Priority }))}>
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
              <Label className="font-body text-sm text-foreground mb-1.5 block">Categoria</Label>
              <Select value={form.categoryId} onValueChange={v => setForm(f => ({ ...f, categoryId: v }))}>
                <SelectTrigger className="font-body bg-background border-border">
                  <SelectValue placeholder="Selecionar..." />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="">Sem categoria</SelectItem>
                  {categories.map(c => (
                    <SelectItem key={c.id} value={c.id}>{c.name}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          </div>

          {/* Start Date */}
          <div>
            <Label className="font-body text-sm text-foreground mb-1.5 block flex items-center gap-2">
              <Calendar size={14} />
              Data de Início *
            </Label>
            <Input
              type="date"
              value={form.dueDate}
              onChange={e => setForm(f => ({ ...f, dueDate: e.target.value }))}
              className="font-body bg-background border-border"
            />
          </div>

          {/* Recurrence Settings */}
          <div className="bg-muted/30 border border-border rounded-lg p-4 space-y-4">
            <h3 className="font-display font-semibold text-foreground flex items-center gap-2">
              <Repeat2 size={16} />
              Configuração de Recorrência
            </h3>

            {/* Frequency */}
            <div>
              <Label className="font-body text-sm text-foreground mb-1.5 block">Frequência</Label>
              <Select value={form.frequency} onValueChange={v => setForm(f => ({ ...f, frequency: v as RecurrenceFrequency }))}>
                <SelectTrigger className="font-body bg-background border-border">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="daily">Diariamente</SelectItem>
                  <SelectItem value="weekly">Semanalmente</SelectItem>
                  <SelectItem value="monthly">Mensalmente</SelectItem>
                </SelectContent>
              </Select>
            </div>

            {/* Interval */}
            <div>
              <Label className="font-body text-sm text-foreground mb-1.5 block">Intervalo</Label>
              <div className="flex items-center gap-2">
                <span className="font-body text-sm text-muted-foreground">Cada</span>
                <Input
                  type="number"
                  min="1"
                  max="365"
                  value={form.interval}
                  onChange={e => setForm(f => ({ ...f, interval: Math.max(1, parseInt(e.target.value) || 1) }))}
                  className="font-body bg-background border-border w-20"
                />
                <span className="font-body text-sm text-muted-foreground">
                  {form.frequency === 'daily' ? form.interval === 1 ? 'dia' : 'dias' : ''}
                  {form.frequency === 'weekly' ? form.interval === 1 ? 'semana' : 'semanas' : ''}
                  {form.frequency === 'monthly' ? form.interval === 1 ? 'mês' : 'meses' : ''}
                </span>
              </div>
              <p className="font-body text-xs text-muted-foreground mt-2">
                Resumo: {recurrenceSummary}
              </p>
            </div>

            {/* Max Occurrences vs End Date */}
            <div className="space-y-3">
              <div className="flex items-center gap-3">
                <input
                  type="radio"
                  id="max-occurrences"
                  checked={!form.useEndDate}
                  onChange={() => setForm(f => ({ ...f, useEndDate: false }))}
                  className="cursor-pointer"
                />
                <label htmlFor="max-occurrences" className="font-body text-sm text-foreground cursor-pointer flex-1">
                  Máximo de ocorrências
                </label>
                <Input
                  type="number"
                  min="1"
                  max="365"
                  value={form.maxOccurrences}
                  onChange={e => setForm(f => ({ ...f, maxOccurrences: Math.max(1, parseInt(e.target.value) || 1) }))}
                  disabled={form.useEndDate}
                  className="font-body bg-background border-border w-24"
                />
              </div>

              <div className="flex items-center gap-3">
                <input
                  type="radio"
                  id="end-date"
                  checked={form.useEndDate}
                  onChange={() => setForm(f => ({ ...f, useEndDate: true }))}
                  className="cursor-pointer"
                />
                <label htmlFor="end-date" className="font-body text-sm text-foreground cursor-pointer flex-1">
                  Data de término
                </label>
                <Input
                  type="date"
                  value={form.endDate}
                  onChange={e => setForm(f => ({ ...f, endDate: e.target.value }))}
                  disabled={!form.useEndDate}
                  className="font-body bg-background border-border w-40"
                />
              </div>
            </div>

            <p className="font-body text-xs text-muted-foreground bg-background/50 p-2 rounded">
              ℹ️ Serão geradas {form.useEndDate && form.endDate ? 'ocorrências até a data de término' : `${form.maxOccurrences} ocorrências`}
            </p>
          </div>
        </div>

        <DialogFooter className="gap-2">
          <Button variant="outline" onClick={handleClose} className="font-body">
            Cancelar
          </Button>
          <Button onClick={handleSave} className="font-body bg-primary text-primary-foreground hover:bg-primary/90 gap-2">
            <Repeat2 size={14} />
            Criar Tarefa Recorrente
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
