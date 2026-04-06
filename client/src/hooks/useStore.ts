/**
 * useStore — Integrated with Backend (SQLite + Drizzle)
 * Using TanStack Query for synchronization
 */

import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import axios from 'axios';
import { 
  Task, Note, Category, NewTask, NewNote, NewCategory,
  Priority, TaskStatus, RecurrenceRule, RecurrenceFrequency,
  PRIORITY_OPTIONS, STATUS_OPTIONS, RECURRENCE_FREQUENCIES
} from '@shared/schema';

// Re-exportando tipos e constantes para manter compatibilidade e facilitar uso
export type { Task, Note, Category, NewTask, NewNote, NewCategory, Priority, TaskStatus, RecurrenceRule, RecurrenceFrequency };
export { PRIORITY_OPTIONS, STATUS_OPTIONS, RECURRENCE_FREQUENCIES };

const api = axios.create({ baseURL: '/api' });

// Função auxiliar para limpar dados do SQLite (null -> undefined, string tags -> array)
const cleanTask = (t: any): Task => ({
  ...t,
  description: t.description || '',
  categoryId: t.categoryId || undefined,
  dueDate: t.dueDate || undefined,
  tags: typeof t.tags === 'string' ? JSON.parse(t.tags) : (t.tags || []),
  recurrence: t.recurrence ? JSON.parse(t.recurrence) : undefined,
  parentTaskId: t.parentTaskId || undefined,
  occurrenceDate: t.occurrenceDate || undefined,
});

const cleanNote = (n: any): Note => ({
  ...n,
  categoryId: n.categoryId || undefined,
  tags: typeof n.tags === 'string' ? JSON.parse(n.tags) : (n.tags || []),
});

export function useStore() {
  const queryClient = useQueryClient();

  // --- Queries ---

  const { data: tasks = [] } = useQuery<Task[]>({
    queryKey: ['tasks'],
    queryFn: async () => {
      const res = await api.get('/tasks');
      return res.data.map(cleanTask);
    },
  });

  const { data: notes = [] } = useQuery<Note[]>({
    queryKey: ['notes'],
    queryFn: async () => {
      const res = await api.get('/notes');
      return res.data.map(cleanNote);
    },
  });

  const { data: categories = [] } = useQuery<Category[]>({
    queryKey: ['categories'],
    queryFn: async () => (await api.get('/categories')).data,
  });

  // --- Mutations (Tasks) ---

  const addTaskMutation = useMutation({
    mutationFn: async (task: NewTask) => (await api.post('/tasks', task)).data,
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['tasks'] }),
  });

  const updateTaskMutation = useMutation({
    mutationFn: async ({ id, updates }: { id: string; updates: Partial<Task> }) => {
      const payload = { ...updates };
      if (payload.tags) (payload as any).tags = JSON.stringify(payload.tags);
      if (payload.recurrence) (payload as any).recurrence = JSON.stringify(payload.recurrence);
      return (await api.patch(`/tasks/${id}`, payload)).data;
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['tasks'] }),
  });

  const deleteTaskMutation = useMutation({
    mutationFn: async (id: string) => (await api.delete(`/tasks/${id}`)).data,
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['tasks'] }),
  });

  const toggleTaskStatusMutation = useMutation({
    mutationFn: async (id: string) => {
      const task = tasks.find(t => t.id === id);
      if (!task) return;
      const nextStatus = task.status === 'done' ? 'pending' : 'done';
      return (await api.patch(`/tasks/${id}`, { status: nextStatus })).data;
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['tasks'] }),
  });

  // --- Mutations (Notes) ---

  const addNoteMutation = useMutation({
    mutationFn: async (note: NewNote) => (await api.post('/notes', note)).data,
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['notes'] }),
  });

  const updateNoteMutation = useMutation({
    mutationFn: async ({ id, updates }: { id: string; updates: Partial<Note> }) => {
      const payload = { ...updates };
      if (payload.tags) (payload as any).tags = JSON.stringify(payload.tags);
      return (await api.patch(`/notes/${id}`, payload)).data;
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['notes'] }),
  });

  const deleteNoteMutation = useMutation({
    mutationFn: async (id: string) => (await api.delete(`/notes/${id}`)).data,
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['notes'] }),
  });

  const toggleNotePinMutation = useMutation({
    mutationFn: async (id: string) => {
      const note = notes.find(n => n.id === id);
      if (!note) return;
      return (await api.patch(`/notes/${id}`, { pinned: !note.pinned })).data;
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['notes'] }),
  });

  // --- Mutations (Categories) ---

  const addCategoryMutation = useMutation({
    mutationFn: async (cat: NewCategory) => (await api.post('/categories', cat)).data,
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['categories'] }),
  });

  const deleteCategoryMutation = useMutation({
    mutationFn: async (id: string) => (await api.delete(`/categories/${id}`)).data,
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['categories'] }),
  });

  // --- Stats ---

  const stats = {
    total: tasks.length,
    done: tasks.filter(t => t.status === 'done').length,
    inProgress: tasks.filter(t => t.status === 'in_progress').length,
    pending: tasks.filter(t => t.status === 'pending').length,
    overdue: tasks.filter(t =>
      t.dueDate && new Date(t.dueDate) < new Date() && t.status !== 'done'
    ).length,
    notes: notes.length,
  };

  return {
    tasks,
    notes,
    categories,
    stats,
    addTask: (task: any) => addTaskMutation.mutate(task),
    updateTask: (id: string, updates: any) => updateTaskMutation.mutate({ id, updates }),
    deleteTask: (id: string) => deleteTaskMutation.mutate(id),
    toggleTaskStatus: (id: string) => toggleTaskStatusMutation.mutate(id),
    addNote: (note: any) => addNoteMutation.mutate(note),
    updateNote: (id: string, updates: any) => updateNoteMutation.mutate({ id, updates }),
    deleteNote: (id: string) => deleteNoteMutation.mutate(id),
    toggleNotePin: (id: string) => toggleNotePinMutation.mutate(id),
    addCategory: (cat: any) => addCategoryMutation.mutate(cat),
    deleteCategory: (id: string) => deleteCategoryMutation.mutate(id),
    addRecurringTask: (task: any) => addTaskMutation.mutate(task),
  };
}
