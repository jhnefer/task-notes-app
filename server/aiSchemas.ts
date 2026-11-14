import { z } from "zod";

export const aiExtractedSubtaskSchema = z.object({
  title: z.string().min(1, "O título da subtarefa é obrigatório"),
  priority: z.enum(["low", "medium", "high"]).nullable().optional().default("medium"),
  dueDate: z
    .string()
    .regex(/^\d{4}-\d{2}-\d{2}$/, "Data deve estar no formato AAAA-MM-DD")
    .nullable()
    .optional(),
});

export const aiTaskExtractionSchema = z.object({
  title: z.string().min(1, "O título é obrigatório"),
  description: z.string().default(""),
  dueDate: z
    .string()
    .regex(/^\d{4}-\d{2}-\d{2}$/, "Data deve estar no formato AAAA-MM-DD")
    .nullable()
    .optional(),
  priority: z.enum(["low", "medium", "high"]).nullable().optional(),
  subtasks: z.array(aiExtractedSubtaskSchema).default([]),
  uncertainties: z.array(z.string()).default([]),
});

export type AIExtractedSubtask = z.infer<typeof aiExtractedSubtaskSchema>;
export type AITaskExtraction = z.infer<typeof aiTaskExtractionSchema>;
