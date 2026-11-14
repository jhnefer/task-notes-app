import { GoogleGenAI } from "@google/genai";
import { aiTaskExtractionSchema, type AITaskExtraction } from "./aiSchemas.ts";

let cachedAIClient: { key: string; client: GoogleGenAI } | null = null;

export function getAIClient(apiKey: string): GoogleGenAI {
  const trimmed = apiKey.trim();
  if (!cachedAIClient || cachedAIClient.key !== trimmed) {
    cachedAIClient = { key: trimmed, client: new GoogleGenAI({ apiKey: trimmed } as any) };
  }
  return cachedAIClient.client;
}

// Lista ordenada de modelos para contingência progressiva
export const FAST_AI_MODELS = [
  "gemini-3.5-flash",
  "gemini-3.5-flash-lite",
  "gemini-3.6-flash",
  "gemini-2.5-flash",
  "gemini-2.0-flash",
  "gemini-1.5-flash",
  "gemini-3.8-flash",
];

export interface TaskExtractionContext {
  text: string;
  referenceDate?: string; // ISO ou AAAA-MM-DD
  timeZone?: string;      // ex: "America/Fortaleza" ou "America/Sao_Paulo"
}

export function buildPrompt(params: { text: string; referenceDate?: string; timeZone?: string }): { prompt: string; systemInstruction: string } {
  const timeZone = params.timeZone || "America/Fortaleza";
  const now = params.referenceDate ? new Date(params.referenceDate) : new Date();

  // Formatar data em português com fuso especificado
  const dateFormatter = new Intl.DateTimeFormat("pt-BR", {
    timeZone,
    weekday: "long",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  });
  
  const isoDate = new Intl.DateTimeFormat("en-CA", {
    timeZone,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).format(now); // AAAA-MM-DD

  const formattedNow = dateFormatter.format(now); // ex: "quinta-feira, 12/11/2026"

  const systemInstruction = `Você é um assistente de produtividade especializado em extrair tarefas acionáveis e estruturadas a partir de notas, anotações rápidas ou transcrições de reunião.`;

  const prompt = `--- CONTEXTO TEMPORAL CRÍTICO ---
Hoje é: ${formattedNow} (${isoDate}).
Fuso horário de referência: ${timeZone}.

--- TEXTO DE ENTRADA ---
"${params.text}"

--- INSTRUÇÕES E REGRAS RÍGIDAS ---
1. EXTRAÇÃO DE CAMPOS:
   - "title": Título claro, conciso e acionável para a tarefa principal.
   - "description": Resumo do objetivo ou contexto da tarefa principal.
   - "dueDate": Data limite no formato estrito "AAAA-MM-DD" OU null.
   - "priority": Prioridade ("high", "medium", "low") OU null.
   - "subtasks": Lista de até 4 subtarefas práticas e ordenadas logicamente. Cada uma com "title", "priority" ("high" | "medium" | "low") e "dueDate" ("AAAA-MM-DD" | null).
   - "uncertainties": Lista de strings relatando dúvidas, ambiguidades ou dados ausentes na nota (ex: "Mês não especificado para o dia 10", "Prazo conflitante mencionado").

2. REGRAS PARA DATAS (Cálculo a partir de hoje: ${isoDate}):
   - Se o texto disser "amanhã", "sexta", "semana que vem": calcule a data exata AAAA-MM-DD com base na data de hoje.
   - Se disser apenas "até dia 10" (sem mês): assuma o próximo dia 10 que ainda não passou (ou o mês atual se hoje for antes do dia 10).
   - SEMPRE retorne em formato "AAAA-MM-DD".
   - REGRA DO NULL: Se o texto NÃO contiver indicação de prazo, retorne ESTRITAMENTE null. NUNCA invente uma data!

3. REGRAS PARA PRIORIDADE:
   - "high": Menções como "urgente", "crítico", "prioridade máxima", "bloqueante", "para hoje" ou prazo em até 2 dias.
   - "low": Menções como "sem pressa", "quando der", "backlog", "baixa prioridade".
   - "medium": Tarefa com importância normal especificada.
   - REGRA DO NULL: Se a nota NÃO der indicação de urgência ou importância, retorne ESTRITAMENTE null. NUNCA invente prioridade!

4. REGRAS PARA SUBTAREFAS:
   - Cada subtarefa deve ser acionável e começar preferencialmente com um verbo de ação no infinitivo.
   - Máximo de 4 subtarefas.
   - Não repita o título da tarefa principal.

--- FORMATO DE RESPOSTA ---
Retorne EXCLUSIVAMENTE um objeto JSON válido (sem tags markdown, sem explicações extras) compatível com o schema:
{
  "title": string,
  "description": string,
  "dueDate": string | null,
  "priority": "high" | "medium" | "low" | null,
  "subtasks": [
    { "title": string, "priority": "high" | "medium" | "low", "dueDate": string | null }
  ],
  "uncertainties": string[]
}`;

  return { prompt, systemInstruction };
}

/**
 * Motor de contingência heurística para alta resiliência:
 * Caso todos os modelos da API remota estejam em pico de demanda (503) ou com timeout,
 * extrai os campos estruturados localmente para a pessoa revisar sem interrupção de fluxo.
 */
export function heuristicTaskExtraction(context: TaskExtractionContext, reason?: string): AITaskExtraction {
  const text = context.text.trim();
  const lines = text.split("\n").map(l => l.trim()).filter(Boolean);
  const firstLine = lines[0] || "Nova Tarefa Extraída";

  const title = firstLine.length > 70 ? firstLine.substring(0, 70) + "..." : firstLine;
  const description = lines.length > 1 ? lines.slice(1).join("\n") : text;

  const now = context.referenceDate ? new Date(context.referenceDate) : new Date();
  let dueDate: string | null = null;
  const uncertainties: string[] = [];

  if (reason) {
    uncertainties.push(reason);
  }

  // Detecção de data relativa: amanhã
  if (/amanh[ãa]/i.test(text)) {
    const tomorrow = new Date(now);
    tomorrow.setDate(tomorrow.getDate() + 1);
    dueDate = tomorrow.toISOString().substring(0, 10);
  }
  // Detecção de data: hoje
  else if (/hoje/i.test(text)) {
    dueDate = now.toISOString().substring(0, 10);
  }
  // Detecção de data: dia DD (sem mês)
  else if (/dia\s+(\d{1,2})/i.test(text)) {
    const match = text.match(/dia\s+(\d{1,2})/i);
    if (match) {
      const day = parseInt(match[1], 10);
      const target = new Date(now);
      if (day <= now.getDate()) {
        target.setMonth(target.getMonth() + 1);
      }
      target.setDate(day);
      dueDate = target.toISOString().substring(0, 10);
      uncertainties.push(`Prazo estimado para o dia ${day} (mês não informado na nota).`);
    }
  }
  // Detecção de data no formato DD/MM/AAAA ou DD/MM
  else if (/(\d{1,2})[/.-](\d{1,2})(?:[/.-](\d{4}))?/.test(text)) {
    const match = text.match(/(\d{1,2})[/.-](\d{1,2})(?:[/.-](\d{4}))?/);
    if (match) {
      const d = parseInt(match[1], 10);
      const m = parseInt(match[2], 10) - 1;
      const y = match[3] ? parseInt(match[3], 10) : now.getFullYear();
      const target = new Date(y, m, d);
      if (!isNaN(target.getTime())) {
        dueDate = target.toISOString().substring(0, 10);
      }
    }
  }

  // Prioridade
  let priority: "high" | "medium" | "low" | null = null;
  if (/urgente|cr[íi]tico|bloqueante|prioridade m[áa]xima|hoje mesmo/i.test(text)) {
    priority = "high";
  } else if (/sem pressa|quando der|backlog|baixa prioridade/i.test(text)) {
    priority = "low";
  }

  // Subtarefas heurísticas acionáveis
  const subtasks: Array<{ title: string; priority: "high" | "medium" | "low"; dueDate: string | null }> = [];
  const bulletLines = lines.filter(l => /^[*-•\d+.]\s+/.test(l));
  if (bulletLines.length > 0) {
    bulletLines.slice(0, 4).forEach(l => {
      const cleanTitle = l.replace(/^[*-•\d+.]\s+/, "").trim();
      if (cleanTitle) {
        subtasks.push({
          title: cleanTitle,
          priority: priority || "medium",
          dueDate,
        });
      }
    });
  }

  if (subtasks.length === 0) {
    subtasks.push(
      { title: `Executar: ${title.toLowerCase()}`, priority: priority || "medium", dueDate },
      { title: "Revisar e validar resultado", priority: priority || "medium", dueDate }
    );
  }

  return {
    title,
    description,
    dueDate,
    priority,
    subtasks,
    uncertainties,
  };
}

export async function extractTaskWithGemini(
  apiKey: string,
  context: TaskExtractionContext
): Promise<AITaskExtraction> {
  const ai = getAIClient(apiKey);
  const { prompt, systemInstruction } = buildPrompt(context);

  let lastError: any = null;

  for (const model of FAST_AI_MODELS) {
    try {
      // Timeout aumentado para 12 segundos para acomodar picos de latência da API
      const response = await ai.models.generateContent({
        model,
        contents: prompt,
        config: {
          systemInstruction,
          temperature: 0.1, // Reduz alucinação e garante respostas determinísticas
          responseMimeType: "application/json",
          abortSignal: AbortSignal.timeout(12000),
        },
      });

      const text = response?.text;
      if (!text) {
        throw new Error(`Modelo ${model} retornou resposta vazia.`);
      }

      // Parsing do JSON retornado pelo Gemini
      let rawJson: any;
      try {
        rawJson = JSON.parse(text);
      } catch (parseErr) {
        const clean = text.replace(/```(?:json)?/gi, "").replace(/```/g, "").trim();
        rawJson = JSON.parse(clean);
      }

      // Validação com Zod
      const validated = aiTaskExtractionSchema.safeParse(rawJson);
      if (!validated.success) {
        console.warn(`[AI Validation Warning] Modelo ${model} gerou formato fora do schema:`, validated.error.flatten());
        throw new Error("Resposta da IA não passou na validação do schema.");
      }

      console.log(`✓ Tarefa extraída com sucesso pelo modelo: ${model}`);
      return validated.data;
    } catch (err: any) {
      lastError = err;
      const is503 = err?.message?.includes("503") || err?.message?.includes("high demand") || err?.status === 503;
      const isAborted = err?.message?.includes("aborted") || err?.name === "AbortError";
      
      console.warn(
        `Falha na extração com modelo ${model}:`,
        is503 ? "Status 503 (Serviço temporariamente sobrecarregado)" : (isAborted ? "Timeout de 12s excedido" : (err?.message || err))
      );

      // Pequena pausa se foi 503 para aliviar concorrência antes do próximo modelo
      if (is503) {
        await new Promise(r => setTimeout(r, 600));
      }
    }
  }

  // Contingência de alta disponibilidade: Se todos os modelos do Google falharem temporariamente (503 ou timeout)
  console.warn("⚠️ Todos os modelos remotos falharam. Acionando motor de contingência local...");
  return heuristicTaskExtraction(
    context,
    "Nota: Os servidores da IA estavam com alta demanda temporária (503). Os campos foram extraídos via modo de contingência local para você revisar."
  );
}
