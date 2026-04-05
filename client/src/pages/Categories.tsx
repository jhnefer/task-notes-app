/**
 * Categories — Category management page
 * Design: Warm Paper Notebook
 */

import { useState } from 'react';
import { Plus, Trash2, Tag, CheckSquare, FileText } from 'lucide-react';
import { useApp } from '@/contexts/AppContext';
import { Category } from '@/hooks/useStore';
import { cn } from '@/lib/utils';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from '@/components/ui/dialog';
import { toast } from 'sonner';

const ICON_OPTIONS = [
  'User', 'Briefcase', 'BookOpen', 'Heart', 'DollarSign',
  'Home', 'Star', 'Zap', 'Globe', 'Music',
  'Camera', 'Coffee', 'Smile', 'Target', 'Award',
];

const COLOR_OPTIONS = [
  '#C0533A', '#4A7C59', '#7C5A3A', '#A05C7A', '#5A7C3A',
  '#3A5A7C', '#7C3A5A', '#5A3A7C', '#7C7A3A', '#3A7C7A',
  '#B45309', '#0F766E', '#6D28D9', '#BE185D', '#1D4ED8',
];

function CategoryDialog({
  open,
  onClose,
}: {
  open: boolean;
  onClose: () => void;
}) {
  const { addCategory } = useApp();
  const [name, setName] = useState('');
  const [color, setColor] = useState(COLOR_OPTIONS[0]);
  const [icon, setIcon] = useState(ICON_OPTIONS[0]);

  const handleSave = () => {
    if (!name.trim()) {
      toast.error('O nome é obrigatório.');
      return;
    }
    addCategory({ name: name.trim(), color, icon });
    toast.success('Categoria criada!');
    setName('');
    setColor(COLOR_OPTIONS[0]);
    setIcon(ICON_OPTIONS[0]);
    onClose();
  };

  return (
    <Dialog open={open} onOpenChange={v => !v && onClose()}>
      <DialogContent className="max-w-md bg-card border-border">
        <DialogHeader>
          <DialogTitle className="font-display text-xl text-foreground">
            Nova Categoria
          </DialogTitle>
        </DialogHeader>
        <div className="space-y-4 py-2">
          <div>
            <Label className="font-body text-sm text-foreground mb-1.5 block">Nome *</Label>
            <Input
              value={name}
              onChange={e => setName(e.target.value)}
              placeholder="Nome da categoria..."
              className="font-body bg-background border-border"
            />
          </div>
          <div>
            <Label className="font-body text-sm text-foreground mb-2 block">Cor</Label>
            <div className="flex flex-wrap gap-2">
              {COLOR_OPTIONS.map(c => (
                <button
                  key={c}
                  onClick={() => setColor(c)}
                  className={cn(
                    'w-7 h-7 rounded-full border-2 transition-all',
                    color === c ? 'border-foreground scale-110' : 'border-transparent'
                  )}
                  style={{ backgroundColor: c }}
                />
              ))}
            </div>
          </div>
          <div>
            <Label className="font-body text-sm text-foreground mb-2 block">Ícone</Label>
            <div className="flex flex-wrap gap-2">
              {ICON_OPTIONS.map(i => (
                <button
                  key={i}
                  onClick={() => setIcon(i)}
                  className={cn(
                    'px-2.5 py-1 rounded border font-body text-xs transition-colors',
                    icon === i
                      ? 'bg-primary text-primary-foreground border-primary'
                      : 'border-border text-muted-foreground hover:text-foreground hover:bg-muted'
                  )}
                >
                  {i}
                </button>
              ))}
            </div>
          </div>

          {/* Preview */}
          <div className="flex items-center gap-3 p-3 bg-muted rounded-lg">
            <div
              className="w-8 h-8 rounded-full flex items-center justify-center text-white text-xs font-bold"
              style={{ backgroundColor: color }}
            >
              {name.charAt(0).toUpperCase() || '?'}
            </div>
            <div>
              <p className="font-body text-sm font-medium text-foreground">
                {name || 'Nome da categoria'}
              </p>
              <p className="font-accent text-xs text-muted-foreground">
                Ícone: {icon}
              </p>
            </div>
          </div>
        </div>
        <DialogFooter className="gap-2">
          <Button variant="outline" onClick={onClose} className="font-body">
            Cancelar
          </Button>
          <Button onClick={handleSave} className="font-body bg-primary text-primary-foreground hover:bg-primary/90">
            Criar Categoria
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}

export default function Categories() {
  const { categories, tasks, notes, deleteCategory } = useApp();
  const [dialogOpen, setDialogOpen] = useState(false);

  const getCategoryStats = (catId: string) => ({
    tasks: tasks.filter(t => t.categoryId === catId).length,
    notes: notes.filter(n => n.categoryId === catId).length,
    done: tasks.filter(t => t.categoryId === catId && t.status === 'done').length,
  });

  const handleDelete = (cat: Category) => {
    const stats = getCategoryStats(cat.id);
    if (stats.tasks > 0 || stats.notes > 0) {
      toast.error(`Esta categoria possui ${stats.tasks} tarefa(s) e ${stats.notes} anotação(ões). Remova-as primeiro.`);
      return;
    }
    deleteCategory(cat.id);
    toast.success('Categoria removida.');
  };

  return (
    <div className="min-h-full">
      {/* Header */}
      <div className="px-8 py-6 border-b border-border bg-card/50">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="font-display text-3xl font-bold text-foreground">Categorias</h1>
            <p className="font-body text-sm text-muted-foreground mt-0.5">
              {categories.length} categorias criadas
            </p>
          </div>
          <Button
            onClick={() => setDialogOpen(true)}
            className="font-body bg-primary text-primary-foreground hover:bg-primary/90 gap-2"
          >
            <Plus size={16} />
            Nova Categoria
          </Button>
        </div>
      </div>

      <div className="px-8 py-6">
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {categories.map(cat => {
            const stats = getCategoryStats(cat.id);
            const progress = stats.tasks > 0
              ? Math.round((stats.done / stats.tasks) * 100)
              : 0;

            return (
              <div
                key={cat.id}
                className="bg-card border border-border rounded-lg p-5 group hover:shadow-md transition-shadow"
              >
                <div className="flex items-start justify-between mb-4">
                  <div className="flex items-center gap-3">
                    <div
                      className="w-10 h-10 rounded-full flex items-center justify-center text-white font-display font-bold text-lg"
                      style={{ backgroundColor: cat.color }}
                    >
                      {cat.name.charAt(0).toUpperCase()}
                    </div>
                    <div>
                      <h3 className="font-display text-base font-semibold text-foreground">
                        {cat.name}
                      </h3>
                      <p className="font-accent text-xs text-muted-foreground">
                        {cat.icon}
                      </p>
                    </div>
                  </div>
                  <button
                    onClick={() => handleDelete(cat)}
                    className="p-1.5 rounded opacity-0 group-hover:opacity-100 hover:bg-destructive/10 text-muted-foreground hover:text-destructive transition-all"
                  >
                    <Trash2 size={14} />
                  </button>
                </div>

                <div className="grid grid-cols-2 gap-3 mb-4">
                  <div className="bg-muted rounded-lg p-3 text-center">
                    <div className="flex items-center justify-center gap-1 mb-1">
                      <CheckSquare size={12} className="text-muted-foreground" />
                      <span className="font-body text-xs text-muted-foreground">Tarefas</span>
                    </div>
                    <p className="font-display text-xl font-bold text-foreground">{stats.tasks}</p>
                  </div>
                  <div className="bg-muted rounded-lg p-3 text-center">
                    <div className="flex items-center justify-center gap-1 mb-1">
                      <FileText size={12} className="text-muted-foreground" />
                      <span className="font-body text-xs text-muted-foreground">Notas</span>
                    </div>
                    <p className="font-display text-xl font-bold text-foreground">{stats.notes}</p>
                  </div>
                </div>

                {stats.tasks > 0 && (
                  <div>
                    <div className="flex items-center justify-between mb-1">
                      <span className="font-body text-xs text-muted-foreground">Progresso</span>
                      <span className="font-accent text-xs" style={{ color: cat.color }}>
                        {progress}%
                      </span>
                    </div>
                    <div className="h-1.5 bg-muted rounded-full overflow-hidden">
                      <div
                        className="h-full rounded-full transition-all duration-500"
                        style={{ width: `${progress}%`, backgroundColor: cat.color }}
                      />
                    </div>
                    <p className="font-body text-xs text-muted-foreground mt-1">
                      {stats.done} de {stats.tasks} concluídas
                    </p>
                  </div>
                )}

                {stats.tasks === 0 && stats.notes === 0 && (
                  <p className="font-accent text-xs text-muted-foreground text-center py-2">
                    Nenhum item nesta categoria
                  </p>
                )}
              </div>
            );
          })}
        </div>

        {categories.length === 0 && (
          <div className="text-center py-16">
            <Tag size={32} className="text-muted-foreground mx-auto mb-3" />
            <p className="font-display text-2xl text-muted-foreground mb-2">Nenhuma categoria</p>
            <p className="font-accent text-muted-foreground">
              Crie categorias para organizar suas tarefas e anotações
            </p>
          </div>
        )}
      </div>

      <CategoryDialog open={dialogOpen} onClose={() => setDialogOpen(false)} />
    </div>
  );
}
