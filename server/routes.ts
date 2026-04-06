import type { Express } from "express";
import { createServer, type Server } from "http";
import { db } from "./db.ts";
import { 
  tasks, notes, categories, 
  insertTaskSchema, insertNoteSchema, insertCategorySchema 
} from "../shared/schema.ts";
import { eq, desc, and } from "drizzle-orm";
import { isAuthenticated } from "./auth.ts";
import { nanoid } from "nanoid";

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
      tags: typeof t.tags === 'string' ? JSON.parse(t.tags) : [],
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
    const newTask = {
      ...result.data,
      id: nanoid(),
      userId: user.id,
      createdAt: now,
      updatedAt: now,
      tags: JSON.stringify(result.data.tags || []),
    };
    await db.insert(tasks).values(newTask as any);
    res.status(201).json({ ...newTask, tags: result.data.tags || [] });
  });

  app.patch("/api/tasks/:id", isAuthenticated, async (req, res) => {
    const user = req.user as any;
    const { id } = req.params;
    const updates = { ...req.body, updatedAt: new Date().toISOString() };
    if (updates.tags) updates.tags = JSON.stringify(updates.tags);
    
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

  const httpServer = createServer(app);
  return httpServer;
}
