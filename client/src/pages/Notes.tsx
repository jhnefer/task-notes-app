/**
 * Notes — Full notes management page
 * Design: Warm Paper Notebook — ruled paper, ink typography, handwriting accents
 */

import { useState, useMemo } from 'react';
import {
  Plus,
  Search,
  Pin,
  PinOff,
  Trash2,
  Edit3,
  Tag,
  X,
  FileText,
  Save,
  Sparkles,
} from 'lucide-react';
import { useApp } from '@/contexts/AppContext';
import { Note } from '@/hooks/useStore';
import { cn } from '@/lib/utils';
import { format } from 'date-fns';
import { ptBR } from 'date-fns/locale';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import { Label } from '@/components/ui/label';
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
import { toast } from 'sonner';
import { AiExtractTaskModal } from '@/components/AiExtractTaskModal';

interface NoteFormData {
  title: string;
  content: string;
  categoryId: string;
  tags: string;
  pinned: boolean;
}

const EMPTY_FORM: NoteFormData = {
  title: '',
  content: '',
  categoryId: '',
  tags: '',
  pinned: false,
};

function NoteDialog({
  open,
  onClose,
  note,
  onExtractTask,
}: {
  open: boolean;
  onClose: () => void;
  note?: Note;
  onExtractTask?: (note: Note) => void;
}) {
  const { addNote, updateNote, categories } = useApp();
  const [form, setForm] = useState<NoteFormData>(
    note
      ? {
          title: note.title,
          content: note.content,
          categoryId: note.categoryId ?? '',
          tags: note.tags.join(', '),
          pinned: note.pinned,
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
      content: form.content,
      categoryId: form.categoryId || undefined,
      tags: form.tags
        .split(',')
        .map(t => t.trim())
        .filter(Boolean),
      pinned: form.pinned,
    };
    if (note) {
      updateNote(note.id, payload);
      toast.success('Anotação atualizada!');
    } else {
      addNote(payload);
      toast.success('Anotação criada!');
    }
    onClose();
  };

  return (
    <Dialog open={open} onOpenChange={v => !v && onClose()}>
      <DialogContent className="max-w-2xl bg-card border-border">
        <DialogHeader>
          <DialogTitle className="font-display text-xl text-foreground">
            {note ? 'Editar Anotação' : 'Nova Anotação'}
          </DialogTitle>
        </DialogHeader>
        <div className="space-y-4 py-2">
          <div>
            <Label className="font-body text-sm text-foreground mb-1.5 block">Título *</Label>
            <Input
              value={form.title}
              onChange={e => setForm(f => ({ ...f, title: e.target.value }))}
              placeholder="Título da anotação..."
              className="font-display text-lg bg-background border-border"
            />
          </div>
          <div>
            <Label className="font-body text-sm text-foreground mb-1.5 block">Conteúdo</Label>
            <Textarea
              value={form.content}
              onChange={e => setForm(f => ({ ...f, content: e.target.value }))}
              placeholder="Escreva suas anotações aqui..."
              rows={10}
              className="font-body bg-background border-border resize-none ruled-lines leading-8"
            />
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
              <Label className="font-body text-sm text-foreground mb-1.5 block">
                Tags <span className="text-muted-foreground">(separadas por vírgula)</span>
              </Label>
              <Input
                value={form.tags}
                onChange={e => setForm(f => ({ ...f, tags: e.target.value }))}
                placeholder="ideia, projeto, referência..."
                className="font-body bg-background border-border"
              />
            </div>
          </div>
          <div className="flex items-center gap-2">
            <button
              onClick={() => setForm(f => ({ ...f, pinned: !f.pinned }))}
              className={cn(
                'flex items-center gap-2 px-3 py-1.5 rounded-md border font-body text-sm transition-colors',
                form.pinned
                  ? 'bg-primary/10 border-primary/30 text-primary'
                  : 'border-border text-muted-foreground hover:text-foreground hover:bg-muted'
              )}
            >
              <Pin size={14} />
              {form.pinned ? 'Fixada' : 'Fixar nota'}
            </button>
          </div>
        </div>
        <DialogFooter className="gap-2 sm:justify-between">
          <div>
            {note && onExtractTask && (
              <Button
                type="button"
                variant="outline"
                size="sm"
                onClick={() => {
                  onClose();
                  onExtractTask(note);
                }}
                className="font-body gap-1.5 text-xs border-indigo-200 text-indigo-700 dark:border-indigo-800 dark:text-indigo-300 hover:bg-indigo-50 dark:hover:bg-indigo-950/50"
              >
                <Sparkles size={13} className="text-indigo-500" />
                Extrair Tarefa com IA
              </Button>
            )}
          </div>
          <div className="flex items-center gap-2">
            <Button variant="outline" onClick={onClose} className="font-body">
              Cancelar
            </Button>
            <Button onClick={handleSave} className="font-body bg-primary text-primary-foreground hover:bg-primary/90 gap-2">
              <Save size={14} />
              {note ? 'Salvar' : 'Criar Anotação'}
            </Button>
          </div>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}

function NoteCard({
  note,
  onEdit,
  onExtractTask,
}: {
  note: Note;
  onEdit: (n: Note) => void;
  onExtractTask?: (n: Note) => void;
}) {
  const { deleteNote, toggleNotePin, categories } = useApp();
  const catName = categories.find(c => c.id === note.categoryId)?.name;

  return (
    <div className={cn(
      'journal-card p-4 group relative',
      note.pinned ? 'bg-[#FFFDF3] border-[#DECEB4]' : 'bg-[#FFFDF9]'
    )}>
      {/* Washi tape decorativa no topo das notas fixadas */}
      {note.pinned && (
        <div className="washi-tape washi-tape-sage" />
      )}

      {/* Pin indicator */}
      {note.pinned && (
        <div className="absolute top-3 right-3">
          <Pin size={13} className="text-primary fill-primary/20" />
        </div>
      )}

      <div className="flex items-start justify-between gap-2 mb-2">
        <h3 className="font-display text-base font-semibold text-foreground line-clamp-1 pr-4">
          {note.title}
        </h3>
      </div>

      <p className="font-body text-sm text-muted-foreground line-clamp-3 mb-3 leading-relaxed">
        {note.content || <span className="italic">Sem conteúdo</span>}
      </p>

      <div className="flex items-center flex-wrap gap-1.5 mb-3">
        {catName && (
          <span className="font-body text-xs text-[#736353] bg-[#F6F1E8] px-2 py-0.5 rounded-[3px] border border-[#E8DEC8]">
            {catName}
          </span>
        )}
        {note.tags.slice(0, 3).map(tag => (
          <span key={tag} className="font-accent text-sm text-[#736353] bg-[#F6F1E8] px-2 py-0.5 rounded-[3px] border border-[#E8DEC8]">
            #{tag}
          </span>
        ))}
      </div>

      <div className="flex items-center justify-between">
        <span className="font-accent text-xs text-muted-foreground">
          {format(new Date(note.updatedAt), "d MMM yyyy", { locale: ptBR })}
        </span>
        <div className="flex items-center gap-1 opacity-100 sm:opacity-0 sm:group-hover:opacity-100 transition-opacity">
          {onExtractTask && (
            <button
              onClick={() => onExtractTask(note)}
              className="p-1 rounded hover:bg-indigo-50 dark:hover:bg-indigo-950/60 text-muted-foreground hover:text-indigo-600 dark:hover:text-indigo-400 transition-colors"
              title="Transformar em Tarefa com IA"
            >
              <Sparkles size={14} />
            </button>
          )}
          <button
            onClick={() => toggleNotePin(note.id)}
            className="p-1 rounded hover:bg-muted text-muted-foreground hover:text-foreground transition-colors"
            title={note.pinned ? 'Desafixar' : 'Fixar'}
          >
            {note.pinned ? <PinOff size={14} /> : <Pin size={14} />}
          </button>
          <button
            onClick={() => onEdit(note)}
            className="p-1 rounded hover:bg-muted text-muted-foreground hover:text-foreground transition-colors"
          >
            <Edit3 size={14} />
          </button>
          <button
            onClick={() => { deleteNote(note.id); toast.success('Anotação removida.'); }}
            className="p-1 rounded hover:bg-destructive/10 text-muted-foreground hover:text-destructive transition-colors"
          >
            <Trash2 size={14} />
          </button>
        </div>
      </div>
    </div>
  );
}

export default function Notes() {
  const { notes, categories } = useApp();
  const [search, setSearch] = useState('');
  const [filterCategory, setFilterCategory] = useState('all');
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editingNote, setEditingNote] = useState<Note | undefined>();
  const [extractingNote, setExtractingNote] = useState<Note | null>(null);

  const filtered = useMemo(() => {
    return notes.filter(n => {
      const matchSearch =
        !search ||
        n.title.toLowerCase().includes(search.toLowerCase()) ||
        n.content.toLowerCase().includes(search.toLowerCase()) ||
        n.tags.some(t => t.toLowerCase().includes(search.toLowerCase()));
      const matchCat =
        filterCategory === 'all' ||
        (filterCategory === 'none' ? !n.categoryId : n.categoryId === filterCategory);
      return matchSearch && matchCat;
    });
  }, [notes, search, filterCategory]);

  const pinned = filtered.filter(n => n.pinned);
  const unpinned = filtered.filter(n => !n.pinned);

  const handleEdit = (note: Note) => {
    setEditingNote(note);
    setDialogOpen(true);
  };

  const handleClose = () => {
    setDialogOpen(false);
    setEditingNote(undefined);
  };

  return (
    <div className="min-h-full">
      {/* Header */}
      <div className="px-4 sm:px-6 md:px-8 py-5 border-b border-border bg-card/50">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 mb-4">
          <div>
            <h1 className="font-display text-2xl sm:text-3xl font-bold text-foreground">Anotações</h1>
            <p className="font-body text-xs sm:text-sm text-muted-foreground mt-0.5">
              {filtered.length} de {notes.length} anotações
            </p>
          </div>
          <Button
            onClick={() => { setEditingNote(undefined); setDialogOpen(true); }}
            size="sm"
            className="font-body bg-primary text-primary-foreground hover:bg-primary/90 gap-1.5 text-xs sm:text-sm self-start sm:self-auto"
          >
            <Plus size={15} />
            Nova Anotação
          </Button>
        </div>

        <div className="flex gap-2 sm:gap-3">
          <div className="relative flex-1">
            <Search size={15} className="absolute left-3 top-1/2 -translate-y-1/2 text-muted-foreground" />
            <Input
              value={search}
              onChange={e => setSearch(e.target.value)}
              placeholder="Buscar anotações..."
              className="pl-9 font-body bg-background border-border text-sm"
            />
          </div>
          <Select value={filterCategory} onValueChange={setFilterCategory}>
            <SelectTrigger className="w-36 sm:w-44 font-body bg-background border-border text-xs sm:text-sm">
              <Tag size={14} className="mr-1 text-muted-foreground" />
              <SelectValue placeholder="Categoria" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">Todas</SelectItem>
              <SelectItem value="none">Sem categoria</SelectItem>
              {categories.map(c => (
                <SelectItem key={c.id} value={c.id}>{c.name}</SelectItem>
              ))}
            </SelectContent>
          </Select>
          {(search || filterCategory !== 'all') && (
            <Button
              variant="ghost"
              size="icon"
              onClick={() => { setSearch(''); setFilterCategory('all'); }}
              className="text-muted-foreground hover:text-foreground shrink-0"
            >
              <X size={16} />
            </Button>
          )}
        </div>
      </div>

      <div className="px-4 sm:px-6 md:px-8 py-5 space-y-8">
        {/* Pinned notes */}
        {pinned.length > 0 && (
          <div>
            <div className="flex items-center gap-2 mb-3">
              <Pin size={14} className="text-primary" />
              <h2 className="font-display text-lg font-semibold text-foreground ink-underline">
                Fixadas
              </h2>
              <span className="font-accent text-muted-foreground text-sm">{pinned.length}</span>
            </div>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              {pinned.map(note => (
                <NoteCard key={note.id} note={note} onEdit={handleEdit} onExtractTask={setExtractingNote} />
              ))}
            </div>
          </div>
        )}

        {/* All notes */}
        {unpinned.length > 0 && (
          <div>
            <div className="flex items-center gap-2 mb-3">
              <FileText size={14} className="text-muted-foreground" />
              <h2 className="font-display text-lg font-semibold text-foreground ink-underline">
                {pinned.length > 0 ? 'Outras Anotações' : 'Anotações'}
              </h2>
              <span className="font-accent text-muted-foreground text-sm">{unpinned.length}</span>
            </div>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              {unpinned.map(note => (
                <NoteCard key={note.id} note={note} onEdit={handleEdit} onExtractTask={setExtractingNote} />
              ))}
            </div>
          </div>
        )}

        {filtered.length === 0 && (
          <div className="text-center py-16">
            <p className="font-display text-2xl text-muted-foreground mb-2">Nenhuma anotação encontrada</p>
            <p className="font-accent text-muted-foreground">
              {search || filterCategory !== 'all'
                ? 'Tente ajustar a busca'
                : 'Clique em "Nova Anotação" para começar'}
            </p>
          </div>
        )}
      </div>

      <NoteDialog open={dialogOpen} onClose={handleClose} note={editingNote} onExtractTask={setExtractingNote} />

      <AiExtractTaskModal
        open={!!extractingNote}
        onClose={() => setExtractingNote(null)}
        note={extractingNote}
      />
    </div>
  );
}
