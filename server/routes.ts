import type { Express } from "express";
import { createServer, type Server } from "http";
import { db } from "./db.ts";
import { tasks, notes, categories, insertTaskSchema, insertNoteSchema, insertCategorySchema } from "../shared/schema.ts";
import { eq, desc, and } from "drizzle-orm";
import { isAuthenticated } from "./auth.ts";
import { nanoid } from "nanoid";
import { GoogleGenAI } from "@google/genai";

// Cache do cliente GoogleGenAI para reutilizar conexões HTTP (Keep-Alive)
let cachedAIClient: { key: string; client: GoogleGenAI } | null = null;
function getAIClient(apiKey: string): GoogleGenAI {
  const trimmed = apiKey.trim();
  if (!cachedAIClient || cachedAIClient.key !== trimmed) {
    cachedAIClient = { key: trimmed, client: new GoogleGenAI({ apiKey: trimmed } as any) };
  }
  return cachedAIClient.client;
}

// Modelos otimizados para estabilidade e velocidade:
// gemini-3.5-flash como principal para máxima estabilidade de tráfego (~1.7s constante)
// gemini-3.5-flash-lite e gemini-3.6-flash como contingência
const FAST_AI_MODELS = [
  "gemini-3.5-flash",
  "gemini-3.5-flash-lite",
  "gemini-3.6-flash",
];

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
    const result = insertTaskSchema.safeParse(req.body);
    if (!result.success) {
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

 // --- API: IA Breakdown ---
  app.post("/api/ai/breakdown", async (req, res) => {
    try {
      const { goal } = req.body;

      if (!goal || typeof goal !== "string") {
        return res.status(400).json({ error: "O campo 'goal' é obrigatório." });
      }

      const apiKey = process.env.GEMINI_API_KEY;

      if (!apiKey) {
        console.error("ERRO: GEMINI_API_KEY não foi encontrada no .env");
        return res.status(500).json({ error: "Chave da API não configurada." });
      }

      const ai = getAIClient(apiKey);

      const prompt = `Você é um assistente de produtividade.
Analise este objetivo: "${goal}".
Decomponha este objetivo em exatamente 3 subtarefas práticas e objetivas.

Retorne EXCLUSIVAMENTE um objeto JSON no seguinte formato:
{
  "subtasks": [
    { "title": "Descrição da subtarefa 1", "priority": "high" },
    { "title": "Descrição da subtarefa 2", "priority": "medium" },
    { "title": "Descrição da subtarefa 3", "priority": "low" }
  ]
}`;

      let responseText: string | null = null;
      let lastError: any = null;

      // Itera sobre os modelos rápidos com timeout individual de 5 segundos
      for (const model of FAST_AI_MODELS) {
        try {
          const response = await ai.models.generateContent({
            model,
            contents: prompt,
            config: {
              temperature: 0.2,
              responseMimeType: "application/json",
              abortSignal: AbortSignal.timeout(5000),
            },
          });

          if (response?.text) {
            responseText = response.text;
            console.log(`✓ IA Breakdown respondido com sucesso pelo modelo: ${model}`);
            break;
          }
        } catch (err: any) {
          lastError = err;
          console.warn(`Tentativa com ${model} falhou ou expirou timeout:`, err?.message || err);
        }
      }

      if (!responseText) {
        throw lastError || new Error("Nenhum modelo retornou resposta válida.");
      }

      const parsedData = JSON.parse(responseText);
      return res.json(parsedData);

    } catch (error) {
      console.error("Erro geral na rota de IA:", error);
      return res.status(500).json({ 
        error: "Não foi possível gerar as subtarefas no momento." 
      });
    }
  });
  const httpServer = createServer(app);
  return httpServer;
}