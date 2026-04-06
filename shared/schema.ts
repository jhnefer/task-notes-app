import { z } from "zod";
import { sqliteTable, text, integer } from "drizzle-orm/sqlite-core";
import { createInsertSchema } from "drizzle-zod";

// --- Definições de Tipos Básicos ---

export const PRIORITY_OPTIONS = ["low", "medium", "high"] as const;
export const STATUS_OPTIONS = ["pending", "in_progress", "done"] as const;
export const RECURRENCE_FREQUENCIES = ["daily", "weekly", "monthly"] as const;

export type Priority = (typeof PRIORITY_OPTIONS)[number];
export type TaskStatus = (typeof STATUS_OPTIONS)[number];
export type RecurrenceFrequency = (typeof RECURRENCE_FREQUENCIES)[number];

export interface RecurrenceRule {
  frequency: RecurrenceFrequency;
  interval: number;
  endDate?: string;
  maxOccurrences?: number;
}

// --- Definições de Tabelas (Drizzle) ---

export const users = sqliteTable("users", {
  id: text("id").primaryKey(), // nanoid
  username: text("username").notNull().unique(),
  password: text("password").notNull(),
});

export const categories = sqliteTable("categories", {
  id: text("id").primaryKey(),
  userId: text("user_id").notNull().references(() => users.id),
  name: text("name").notNull(),
  color: text("color").notNull(),
  icon: text("icon").notNull(),
});

export const tasks = sqliteTable("tasks", {
  id: text("id").primaryKey(),
  userId: text("user_id").notNull().references(() => users.id),
  title: text("title").notNull(),
  description: text("description").default(""),
  priority: text("priority", { enum: PRIORITY_OPTIONS }).notNull().default("medium"),
  status: text("status", { enum: STATUS_OPTIONS }).notNull().default("pending"),
  categoryId: text("category_id").references(() => categories.id),
  dueDate: text("due_date"),
  createdAt: text("created_at").notNull(),
  updatedAt: text("updated_at").notNull(),
  tags: text("tags").notNull().default("[]"),
  recurrence: text("recurrence"),
  parentTaskId: text("parent_task_id"),
  occurrenceDate: text("occurrence_date"),
});

export const notes = sqliteTable("notes", {
  id: text("id").primaryKey(),
  userId: text("user_id").notNull().references(() => users.id),
  title: text("title").notNull(),
  content: text("content").notNull(),
  categoryId: text("category_id").references(() => categories.id),
  createdAt: text("created_at").notNull(),
  updatedAt: text("updated_at").notNull(),
  tags: text("tags").notNull().default("[]"),
  pinned: integer("pinned", { mode: "boolean" }).notNull().default(false),
});

// --- Esquemas de Validação (Zod) ---

export const insertUserSchema = createInsertSchema(users).omit({ id: true });

export const insertTaskSchema = createInsertSchema(tasks, {
  dueDate: z.string().datetime().optional(),
  tags: z.array(z.string()).optional(),
}).omit({
  id: true,
  userId: true,
  createdAt: true,
  updatedAt: true,
});

export const insertNoteSchema = createInsertSchema(notes, {
  tags: z.array(z.string()).optional(),
}).omit({
  id: true,
  userId: true,
  createdAt: true,
  updatedAt: true,
});

export const insertCategorySchema = createInsertSchema(categories).omit({
  id: true,
  userId: true,
});

// --- Interfaces para o Frontend ---

export type User = Omit<typeof users.$inferSelect, 'password'>;
export type Category = typeof categories.$inferSelect;

type DrizzleTask = typeof tasks.$inferSelect;
export interface Task extends Omit<DrizzleTask, 'tags' | 'description' | 'categoryId' | 'dueDate' | 'recurrence' | 'parentTaskId' | 'occurrenceDate' | 'priority' | 'status'> {
  tags: string[];
  description?: string;
  categoryId?: string;
  dueDate?: string;
  priority: Priority;
  status: TaskStatus;
  recurrence?: RecurrenceRule;
  parentTaskId?: string;
  occurrenceDate?: string;
}

export interface Note extends Omit<typeof notes.$inferSelect, 'tags' | 'categoryId'> {
  tags: string[];
  categoryId?: string;
}

export type NewTask = z.infer<typeof insertTaskSchema>;
export type NewNote = z.infer<typeof insertNoteSchema>;
export type NewCategory = z.infer<typeof insertCategorySchema>;
