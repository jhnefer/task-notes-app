import type { Express } from "express";
import { createServer, type Server } from "http";
import { db } from "./db.ts";
import { tasks, notes, categories, insertTaskSchema, insertNoteSchema, insertCategorySchema } from "../shared/schema.ts";
import { eq, desc, and } from "drizzle-orm";
import { isAuthenticated } from "./auth.ts";
import { nanoid } from "nanoid";
import { extractTaskWithGemini } from "./aiService.ts";

// Helper seguro para parsing de JSON arrays (evita double-encoding ou erro se vier string)
function safeParseArray<T = any>(val: any): T[] {
  if (!val) return [];
  if (Array.isArray(val)) return val;
  if (typeof val === 'string') {
    try {
      const parsed = JSON.parse(val);
      if (typeof parsed === 'string') {
        try {
          const second = JSON.parse(parsed);
          return Array.isArray(second) ? second : [];
        } catch {
          return [];
        }
      }
      return Array.isArray(parsed) ? parsed : [];
    } catch {
      return [];
    }
  }
  return [];
}

export function registerRoutes(app: Express): Server {
  // --- API: Categorias ---
  app.get("/api/categories", isAuthenticated, async (req, res) => {
    const user = req.user as any;
    const allCategories = await db.select().from(categories).where(eq(categories.userId, user.id));
    res.json(allCategories);
  });

  app.post("/api/categories", isAuthenticated, async (req, res) => {
    const user = req.user as any;
    const result = insertCategorySchema.safeParse(req.body);
    if (!result.success) {
      return res.status(400).json({ errors: result.error.flatten().fieldErrors });
    }
    const newCategory = { ...result.data, id: nanoid(), userId: user.id };
    await db.insert(categories).values(newCategory);
    res.status(201).json(newCategory);
  });

  app.delete("/api/categories/:id", isAuthenticated, async (req, res) => {
    const user = req.user as any;
    await db.delete(categories).where(and(eq(categories.id, req.params.id), eq(categories.userId, user.id)));
    res.status(204).end();
  });

  // --- API: Tarefas ---
  app.get("/api/tasks", isAuthenticated, async (req, res) => {
    const user = req.user as any;
    const allTasks = await db.select()
      .from(tasks)
      .where(eq(tasks.userId, user.id))
      .orderBy(desc(tasks.createdAt));
    
    const formatted = allTasks.map(t => ({
      ...t,
      tags: safeParseArray(t.tags),
      subtasks: safeParseArray(t.subtasks),
    }));
    res.json(formatted);
  });

  app.post("/api/tasks", isAuthenticated, async (req, res) => {
    const user = req.user as any;

    // Normalização defensiva do payload para evitar erros 400 em variações de status ou data
    const body = { ...req.body };
    if (body.status === 'todo') {
      body.status = 'pending';
    }
    if (body.dueDate && typeof body.dueDate === 'string' && !body.dueDate.includes('T')) {
      const parsed = new Date(body.dueDate + 'T12:00:00Z');
      if (!isNaN(parsed.getTime())) {
        body.dueDate = parsed.toISOString();
      }
    }
    if (body.dueDate === '' || body.dueDate === null) {
      body.dueDate = undefined;
    }

    const result = insertTaskSchema.safeParse(body);
    if (!result.success) {
      console.error("Erro de validação em POST /api/tasks:", result.error.flatten());
      return res.status(400).json({ errors: result.error.flatten().fieldErrors });
    }
    const now = new Date().toISOString();
    const cleanTags = safeParseArray(result.data.tags);
    const cleanSubtasks = safeParseArray(result.data.subtasks);
    const newTask = {
      ...result.data,
      id: nanoid(),
      userId: user.id,
      createdAt: now,
      updatedAt: now,
      tags: JSON.stringify(cleanTags),
      subtasks: JSON.stringify(cleanSubtasks),
    };
    await db.insert(tasks).values(newTask as any);
    res.status(201).json({ ...newTask, tags: cleanTags, subtasks: cleanSubtasks });
  });

  app.patch("/api/tasks/:id", isAuthenticated, async (req, res) => {
    const user = req.user as any;
    const { id } = req.params;
    const updates = { ...req.body, updatedAt: new Date().toISOString() };
    
    // Normalizar tags e subtasks se fornecidos
    if (updates.tags !== undefined) {
      updates.tags = JSON.stringify(safeParseArray(updates.tags));
    }
    if (updates.subtasks !== undefined) {
      updates.subtasks = JSON.stringify(safeParseArray(updates.subtasks));
    }
    
    // Regra de integridade: se tentar mudar o status da tarefa principal para "done",
    // impede caso existam submetas pendentes
    if (updates.status === 'done') {
      const [existingTask] = await db.select().from(tasks).where(and(eq(tasks.id, id), eq(tasks.userId, user.id)));
      if (existingTask) {
        const subtasksToCheck = updates.subtasks !== undefined
          ? safeParseArray(updates.subtasks)
          : safeParseArray(existingTask.subtasks);
        
        const hasUnfinishedSubtasks = subtasksToCheck.some((s: any) => !s.completed);
        if (hasUnfinishedSubtasks) {
          return res.status(400).json({ 
            error: "Não é possível concluir a meta maior enquanto houver submetas pendentes." 
          });
        }
      }
    }

    await db.update(tasks)
      .set(updates)
      .where(and(eq(tasks.id, id), eq(tasks.userId, user.id)));
    res.json({ message: "Tarefa atualizada" });
  });

  app.delete("/api/tasks/:id", isAuthenticated, async (req, res) => {
    const user = req.user as any;
    await db.delete(tasks).where(and(eq(tasks.id, req.params.id), eq(tasks.userId, user.id)));
    res.status(204).end();
  });

  // --- API: Notas ---
  app.get("/api/notes", isAuthenticated, async (req, res) => {
    const user = req.user as any;
    const allNotes = await db.select()
      .from(notes)
      .where(eq(notes.userId, user.id))
      .orderBy(desc(notes.createdAt));
    
    const formatted = allNotes.map(n => ({
      ...n,
      tags: typeof n.tags === 'string' ? JSON.parse(n.tags) : [],
    }));
    res.json(formatted);
  });

  app.post("/api/notes", isAuthenticated, async (req, res) => {
    const user = req.user as any;
    const result = insertNoteSchema.safeParse(req.body);
    if (!result.success) {
      return res.status(400).json({ errors: result.error.flatten().fieldErrors });
    }
    const now = new Date().toISOString();
    const newNote = {
      ...result.data,
      id: nanoid(),
      userId: user.id,
      createdAt: now,
      updatedAt: now,
      tags: JSON.stringify(result.data.tags || []),
    };
    await db.insert(notes).values(newNote as any);
    res.status(201).json({ ...newNote, tags: result.data.tags || [] });
  });

  app.patch("/api/notes/:id", isAuthenticated, async (req, res) => {
    const user = req.user as any;
    const { id } = req.params;
    const updates = { ...req.body, updatedAt: new Date().toISOString() };
    if (updates.tags) updates.tags = JSON.stringify(updates.tags);
    
    await db.update(notes)
      .set(updates)
      .where(and(eq(notes.id, id), eq(notes.userId, user.id)));
    res.json({ message: "Nota atualizada" });
  });

  app.delete("/api/notes/:id", isAuthenticated, async (req, res) => {
    const user = req.user as any;
    await db.delete(notes).where(and(eq(notes.id, req.params.id), eq(notes.userId, user.id)));
    res.status(204).end();
  });

  // --- API: IA Task Extraction & Breakdown ---
  app.post("/api/ai/extract-task", async (req, res) => {
    try {
      const { text, referenceDate, timeZone } = req.body;

      if (!text || typeof text !== "string" || !text.trim()) {
        return res.status(400).json({ error: "O campo 'text' é obrigatório." });
      }

      const apiKey = process.env.GEMINI_API_KEY;
      if (!apiKey) {
        console.error("ERRO: GEMINI_API_KEY não foi encontrada no .env");
        return res.status(500).json({ error: "Chave da API Gemini não configurada." });
      }

      const extracted = await extractTaskWithGemini(apiKey, {
        text: text.trim(),
        referenceDate: referenceDate || new Date().toISOString(),
        timeZone: timeZone || "America/Fortaleza",
      });

      return res.json(extracted);
    } catch (error: any) {
      console.error("Erro na rota /api/ai/extract-task:", error?.message || error);
      return res.status(500).json({
        error: error?.message || "Não foi possível extrair a tarefa com IA no momento.",
      });
    }
  });

  // Mantém retrocompatibilidade com o modal de subtarefas existente
  app.post("/api/ai/breakdown", async (req, res) => {
    try {
      const { goal, referenceDate, timeZone } = req.body;

      if (!goal || typeof goal !== "string") {
        return res.status(400).json({ error: "O campo 'goal' é obrigatório." });
      }

      const apiKey = process.env.GEMINI_API_KEY;
      if (!apiKey) {
        console.error("ERRO: GEMINI_API_KEY não foi encontrada no .env");
        return res.status(500).json({ error: "Chave da API não configurada." });
      }

      const extracted = await extractTaskWithGemini(apiKey, {
        text: goal,
        referenceDate: referenceDate || new Date().toISOString(),
        timeZone: timeZone || "America/Fortaleza",
      });

      // Retorna tanto o formato legado (subtasks com title e priority) quanto os novos campos extraídos
      return res.json({
        title: extracted.title,
        dueDate: extracted.dueDate,
        priority: extracted.priority,
        description: extracted.description,
        uncertainties: extracted.uncertainties,
        subtasks: extracted.subtasks.map((s) => ({
          title: s.title,
          priority: s.priority || "medium",
          dueDate: s.dueDate || null,
        })),
      });
    } catch (error: any) {
      console.error("Erro geral na rota /api/ai/breakdown:", error?.message || error);
      return res.status(500).json({ 
        error: "Não foi possível gerar as subtarefas no momento." 
      });
    }
  });
  const httpServer = createServer(app);
  return httpServer;
}