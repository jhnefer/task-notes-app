/**
 * useStore — Local storage persistence for tasks and notes
 * Design: Warm Paper Notebook
 */

import { useState, useEffect, useCallback } from 'react';
import { nanoid } from 'nanoid';

export type Priority = 'high' | 'medium' | 'low';
export type TaskStatus = 'pending' | 'in_progress' | 'done';
export type RecurrenceFrequency = 'daily' | 'weekly' | 'monthly';

export interface Category {
  id: string;
  name: string;
  color: string; // tailwind color class or hex
  icon: string;  // lucide icon name
}

export interface RecurrenceRule {
  frequency: RecurrenceFrequency;
  interval: number; // repeat every N days/weeks/months
  endDate?: string; // ISO date string - when to stop generating occurrences
  maxOccurrences?: number; // maximum number of occurrences to generate
}

export interface Task {
  id: string;
  title: string;
  description?: string;
  priority: Priority;
  status: TaskStatus;
  categoryId?: string;
  dueDate?: string; // ISO date string
  createdAt: string;
  updatedAt: string;
  tags: string[];
  recurrence?: RecurrenceRule; // if set, this is a recurring task
  parentTaskId?: string; // if set, this task is an occurrence of a recurring task
  occurrenceDate?: string; // ISO date string - the date this occurrence is for
}

export interface Note {
  id: string;
  title: string;
  content: string;
  categoryId?: string;
  createdAt: string;
  updatedAt: string;
  tags: string[];
  pinned: boolean;
}

interface AppState {
  tasks: Task[];
  notes: Note[];
  categories: Category[];
}

const DEFAULT_CATEGORIES: Category[] = [
  { id: 'personal', name: 'Pessoal', color: '#C0533A', icon: 'User' },
  { id: 'work', name: 'Trabalho', color: '#4A7C59', icon: 'Briefcase' },
  { id: 'studies', name: 'Estudos', color: '#7C5A3A', icon: 'BookOpen' },
  { id: 'health', name: 'Saúde', color: '#A05C7A', icon: 'Heart' },
  { id: 'finance', name: 'Finanças', color: '#5A7C3A', icon: 'DollarSign' },
];

const DEFAULT_TASKS: Task[] = [
  {
    id: nanoid(),
    title: '⚠️ CRÍTICO: Enviar proposta ao cliente',
    description: 'Proposta de projeto para o cliente XYZ. Vence em menos de 1 hora!',
    priority: 'high',
    status: 'pending',
    categoryId: 'work',
    dueDate: new Date(Date.now() + 45 * 60 * 1000).toISOString(),
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
    tags: ['urgente', 'cliente'],
  },
  {
    id: nanoid(),
    title: 'Revisar relatório mensal',
    description: 'Verificar os números do mês e preparar apresentação para a reunião.',
    priority: 'high',
    status: 'in_progress',
    categoryId: 'work',
    dueDate: new Date(Date.now() + 3 * 60 * 60 * 1000).toISOString(),
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
    tags: ['reunião', 'relatório'],
  },
  {
    id: nanoid(),
    title: 'Comprar mantimentos',
    description: 'Arroz, feijão, azeite, frutas e legumes.',
    priority: 'medium',
    status: 'pending',
    categoryId: 'personal',
    dueDate: new Date(Date.now() + 30 * 60 * 1000).toISOString(),
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
    tags: ['compras'],
  },
  {
    id: nanoid(),
    title: 'Estudar TypeScript avançado',
    description: 'Capítulos 5 a 8 do livro de TypeScript.',
    priority: 'low',
    status: 'pending',
    categoryId: 'studies',
    dueDate: new Date(Date.now() + 20 * 60 * 60 * 1000).toISOString(),
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
    tags: ['programação', 'aprendizado'],
  },
  {
    id: nanoid(),
    title: 'Consulta médica de rotina',
    description: 'Agendar e comparecer à consulta anual.',
    priority: 'medium',
    status: 'done',
    categoryId: 'health',
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
    tags: ['saúde'],
  },
];

const DEFAULT_NOTES: Note[] = [
  {
    id: nanoid(),
    title: 'Ideias para o projeto',
    content: 'Algumas ideias que surgiram durante a reunião de brainstorming:\n\n- Implementar sistema de notificações\n- Adicionar modo escuro\n- Integrar com calendário\n- Criar relatórios semanais automáticos\n\nPreciso discutir com a equipe na próxima semana.',
    categoryId: 'work',
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
    tags: ['projeto', 'ideias'],
    pinned: true,
  },
  {
    id: nanoid(),
    title: 'Receita de pão caseiro',
    content: 'Ingredientes:\n- 500g de farinha de trigo\n- 10g de fermento biológico\n- 1 colher de sal\n- 300ml de água morna\n- 2 colheres de azeite\n\nModo de preparo: misturar todos os ingredientes, sovar por 10 minutos, deixar descansar por 1 hora e assar a 200°C por 35 minutos.',
    categoryId: 'personal',
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
    tags: ['culinária', 'receita'],
    pinned: false,
  },
  {
    id: nanoid(),
    title: 'Resumo: Clean Code',
    content: 'Principais conceitos do livro Clean Code de Robert C. Martin:\n\n1. Nomes significativos — use nomes que revelam intenção\n2. Funções pequenas — cada função deve fazer uma única coisa\n3. Comentários — código bom não precisa de comentários óbvios\n4. Formatação — consistência é fundamental\n5. Tratamento de erros — prefira exceções a códigos de retorno',
    categoryId: 'studies',
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
    tags: ['livro', 'programação', 'resumo'],
    pinned: false,
  },
];

const STORAGE_KEY = 'task-notes-app-data';

function loadState(): AppState {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (raw) {
      return JSON.parse(raw);
    }
  } catch {
    // ignore parse errors
  }
  return {
    tasks: DEFAULT_TASKS,
    notes: DEFAULT_NOTES,
    categories: DEFAULT_CATEGORIES,
  };
}

function saveState(state: AppState) {
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(state));
  } catch {
    // ignore storage errors
  }
}

export function useStore() {
  const [state, setState] = useState<AppState>(loadState);

  useEffect(() => {
    saveState(state);
  }, [state]);

  // ── Tasks ──────────────────────────────────────────────

  const addTask = useCallback((task: Omit<Task, 'id' | 'createdAt' | 'updatedAt'>) => {
    const now = new Date().toISOString();
    setState(s => ({
      ...s,
      tasks: [{ ...task, id: nanoid(), createdAt: now, updatedAt: now }, ...s.tasks],
    }));
  }, []);

  const updateTask = useCallback((id: string, updates: Partial<Task>) => {
    setState(s => ({
      ...s,
      tasks: s.tasks.map(t =>
        t.id === id ? { ...t, ...updates, updatedAt: new Date().toISOString() } : t
      ),
    }));
  }, []);

  const deleteTask = useCallback((id: string) => {
    setState(s => ({
      ...s,
      // Delete the task and all its occurrences if it's a recurring task
      tasks: s.tasks.filter(t => t.id !== id && t.parentTaskId !== id),
    }));
  }, []);

  const toggleTaskStatus = useCallback((id: string) => {
    setState(s => ({
      ...s,
      tasks: s.tasks.map(t => {
        if (t.id !== id) return t;
        const next: TaskStatus = t.status === 'done' ? 'pending' : 'done';
        return { ...t, status: next, updatedAt: new Date().toISOString() };
      }),
    }));
  }, []);

  const addRecurringTask = useCallback(
    (task: Omit<Task, 'id' | 'createdAt' | 'updatedAt'> & { recurrence: RecurrenceRule }) => {
      const now = new Date().toISOString();
      const parentTask: Task = {
        ...task,
        id: nanoid(),
        createdAt: now,
        updatedAt: now,
      };

      // Import generateOccurrences dynamically to avoid circular dependency
      import('@/lib/recurrence').then(({ generateOccurrences }) => {
        const occurrences = generateOccurrences(parentTask as Task & { recurrence: RecurrenceRule });
        setState(s => ({
          ...s,
          tasks: [parentTask, ...occurrences, ...s.tasks],
        }));
      });
    },
    []
  );

  // ── Notes ──────────────────────────────────────────────

  const addNote = useCallback((note: Omit<Note, 'id' | 'createdAt' | 'updatedAt'>) => {
    const now = new Date().toISOString();
    setState(s => ({
      ...s,
      notes: [{ ...note, id: nanoid(), createdAt: now, updatedAt: now }, ...s.notes],
    }));
  }, []);

  const updateNote = useCallback((id: string, updates: Partial<Note>) => {
    setState(s => ({
      ...s,
      notes: s.notes.map(n =>
        n.id === id ? { ...n, ...updates, updatedAt: new Date().toISOString() } : n
      ),
    }));
  }, []);

  const deleteNote = useCallback((id: string) => {
    setState(s => ({ ...s, notes: s.notes.filter(n => n.id !== id) }));
  }, []);

  const toggleNotePin = useCallback((id: string) => {
    setState(s => ({
      ...s,
      notes: s.notes.map(n =>
        n.id === id ? { ...n, pinned: !n.pinned, updatedAt: new Date().toISOString() } : n
      ),
    }));
  }, []);

  // ── Categories ─────────────────────────────────────────

  const addCategory = useCallback((cat: Omit<Category, 'id'>) => {
    setState(s => ({
      ...s,
      categories: [...s.categories, { ...cat, id: nanoid() }],
    }));
  }, []);

  const deleteCategory = useCallback((id: string) => {
    setState(s => ({ ...s, categories: s.categories.filter(c => c.id !== id) }));
  }, []);

  // ── Stats ──────────────────────────────────────────────

  const stats = {
    total: state.tasks.length,
    done: state.tasks.filter(t => t.status === 'done').length,
    inProgress: state.tasks.filter(t => t.status === 'in_progress').length,
    pending: state.tasks.filter(t => t.status === 'pending').length,
    overdue: state.tasks.filter(t =>
      t.dueDate && new Date(t.dueDate) < new Date() && t.status !== 'done'
    ).length,
    notes: state.notes.length,
  };

  return {
    tasks: state.tasks,
    notes: state.notes,
    categories: state.categories,
    stats,
    addTask,
    updateTask,
    deleteTask,
    toggleTaskStatus,
    addRecurringTask,
    addNote,
    updateNote,
    deleteNote,
    toggleNotePin,
    addCategory,
    deleteCategory,
  };
}
