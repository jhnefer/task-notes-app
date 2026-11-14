import { useState } from "react";
import { Sparkles, Loader2, Plus, CheckCircle2, Calendar, AlertCircle, X, Check, ShieldAlert } from "lucide-react";
import { Button } from "@/components/ui/button";

export interface SubtaskItem {
  title: string;
  priority: "high" | "medium" | "low";
  dueDate?: string | null;
}

interface AiBreakdownModalProps {
  taskTitle: string;
  onAddSubtasks?: (subtasks: SubtaskItem[]) => void;
  onApplySuggestions?: (suggestions: {
    dueDate?: string | null;
    priority?: "high" | "medium" | "low" | null;
    description?: string;
  }) => void;
}

export function AiBreakdownModal({ taskTitle, onAddSubtasks, onApplySuggestions }: AiBreakdownModalProps) {
  const [loading, setLoading] = useState(false);
  const [subtasks, setSubtasks] = useState<SubtaskItem[]>([]);
  const [suggestedDueDate, setSuggestedDueDate] = useState<string | null>(null);
  const [suggestedPriority, setSuggestedPriority] = useState<"high" | "medium" | "low" | null>(null);
  const [suggestedDescription, setSuggestedDescription] = useState<string | null>(null);
  const [uncertainties, setUncertainties] = useState<string[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [appliedMeta, setAppliedMeta] = useState(false);

  const handleGenerate = async () => {
    if (!taskTitle.trim()) return;

    setLoading(true);
    setError(null);
    setAppliedMeta(false);

    try {
      const response = await fetch("/api/ai/breakdown", {
        method: "POST",
        credentials: "include",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          goal: taskTitle,
          referenceDate: new Date().toISOString(),
          timeZone: Intl.DateTimeFormat().resolvedOptions().timeZone || "America/Fortaleza",
        }),
      });

      if (!response.ok) {
        let errorMsg = `Erro ${response.status}`;
        try {
          const errData = await response.json();
          errorMsg = errData.error || errorMsg;
        } catch {
          const txt = await response.text();
          if (txt) errorMsg = txt;
        }
        throw new Error(errorMsg);
      }

      const data = await response.json();

      setSubtasks(data.subtasks || []);
      setSuggestedDueDate(data.dueDate || null);
      setSuggestedPriority(data.priority || null);
      setSuggestedDescription(data.description || null);
      setUncertainties(data.uncertainties || []);
    } catch (err: any) {
      setError(err.message || "Não foi possível conectar à IA.");
    } finally {
      setLoading(false);
    }
  };

  const handleApplySubtasks = () => {
    if (onAddSubtasks && subtasks.length > 0) {
      onAddSubtasks(subtasks);
      setSubtasks([]);
    }
  };

  const handleApplyMetadata = () => {
    if (onApplySuggestions && (suggestedDueDate || suggestedPriority || suggestedDescription)) {
      onApplySuggestions({
        dueDate: suggestedDueDate,
        priority: suggestedPriority,
        description: suggestedDescription || undefined,
      });
      setAppliedMeta(true);
    }
  };

  const handleApplyAll = () => {
    handleApplyMetadata();
    handleApplySubtasks();
  };

  const removeSubtask = (index: number) => {
    setSubtasks(prev => prev.filter((_, i) => i !== index));
  };

  const priorityLabelMap: Record<string, { label: string; class: string }> = {
    high: { label: "Alta", class: "bg-red-100 text-red-700 dark:bg-red-950/60 dark:text-red-400 border-red-200" },
    medium: { label: "Média", class: "bg-amber-100 text-amber-700 dark:bg-amber-950/60 dark:text-amber-400 border-amber-200" },
    low: { label: "Baixa", class: "bg-blue-100 text-blue-700 dark:bg-blue-950/60 dark:text-blue-400 border-blue-200" },
  };

  const hasExtractions = subtasks.length > 0 || suggestedDueDate || suggestedPriority || uncertainties.length > 0;

  return (
    <div className="p-4 my-3 border rounded-xl bg-slate-50 dark:bg-slate-900/80 border-slate-200 dark:border-slate-800 space-y-3">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-2 text-sm font-medium">
          <Sparkles className="w-4 h-4 text-indigo-500 animate-pulse" />
          <span>Sugestão Inteligente (Gemini IA)</span>
        </div>

        <Button
          type="button"
          variant="outline"
          size="sm"
          onClick={handleGenerate}
          disabled={loading || !taskTitle.trim()}
          className="gap-1.5 text-xs border-indigo-200 dark:border-indigo-800 hover:bg-indigo-50 dark:hover:bg-indigo-950/50"
        >
          {loading ? (
            <>
              <Loader2 className="w-3.5 h-3.5 animate-spin text-indigo-600" />
              A analisar...
            </>
          ) : (
            <>
              <Sparkles className="w-3.5 h-3.5 text-indigo-500" />
              Analisar e Decompor
            </>
          )}
        </Button>
      </div>

      {error && <p className="text-xs text-red-500 font-medium">{error}</p>}

      {hasExtractions && (
        <div className="space-y-3 pt-2 border-t border-slate-200 dark:border-slate-800">
          {/* Alertas de Incerteza da IA */}
          {uncertainties.length > 0 && (
            <div className="p-2.5 rounded-lg bg-amber-50 dark:bg-amber-950/40 border border-amber-200 dark:border-amber-800/60 text-xs text-amber-900 dark:text-amber-300 space-y-1">
              <div className="flex items-center gap-1.5 font-semibold">
                <AlertCircle className="w-3.5 h-3.5 text-amber-600 shrink-0" />
                <span>Observações da IA (revisão necessária):</span>
              </div>
              <ul className="list-disc list-inside space-y-0.5 text-[11px] opacity-90 pl-1">
                {uncertainties.map((u, i) => (
                  <li key={i}>{u}</li>
                ))}
              </ul>
            </div>
          )}

          {/* Sugestões de Prazo e Prioridade da Tarefa Principal */}
          {(suggestedDueDate || suggestedPriority) && (
            <div className="p-2.5 rounded-lg bg-indigo-50/60 dark:bg-indigo-950/30 border border-indigo-100 dark:border-indigo-900/40 flex items-center justify-between text-xs">
              <div className="space-y-1">
                <span className="font-semibold text-indigo-950 dark:text-indigo-200 block text-[11px] uppercase tracking-wider">
                  Campos sugeridos pela IA:
                </span>
                <div className="flex flex-wrap items-center gap-2">
                  {suggestedDueDate && (
                    <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-md font-mono text-[11px] bg-white dark:bg-slate-800 border border-indigo-200 dark:border-indigo-800 text-indigo-900 dark:text-indigo-300">
                      <Calendar className="w-3 h-3 text-indigo-500" />
                      Prazo: {suggestedDueDate}
                    </span>
                  )}
                  {suggestedPriority && (
                    <span
                      className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-md text-[11px] font-medium border ${
                        priorityLabelMap[suggestedPriority]?.class || ""
                      }`}
                    >
                      Prioridade: {priorityLabelMap[suggestedPriority]?.label || suggestedPriority}
                    </span>
                  )}
                </div>
              </div>

              {onApplySuggestions && (
                <Button
                  type="button"
                  size="sm"
                  variant={appliedMeta ? "ghost" : "outline"}
                  onClick={handleApplyMetadata}
                  disabled={appliedMeta}
                  className="h-7 text-xs border-indigo-200 dark:border-indigo-800 text-indigo-700 dark:text-indigo-300 gap-1 shrink-0 ml-2"
                >
                  {appliedMeta ? (
                    <>
                      <Check className="w-3 h-3 text-emerald-600" />
                      Aplicado
                    </>
                  ) : (
                    "Aplicar Prazo/Prioridade"
                  )}
                </Button>
              )}
            </div>
          )}

          {/* Lista de Subtarefas */}
          {subtasks.length > 0 && (
            <div className="space-y-2">
              <div className="flex items-center justify-between">
                <span className="text-xs font-semibold text-slate-500 uppercase">
                  Subtarefas Geradas ({subtasks.length}):
                </span>
                <div className="flex items-center gap-1.5">
                  {(suggestedDueDate || suggestedPriority) && onApplySuggestions && (
                    <Button
                      type="button"
                      size="sm"
                      onClick={handleApplyAll}
                      className="h-7 text-xs bg-indigo-600 hover:bg-indigo-700 text-white gap-1"
                    >
                      <Plus className="w-3.5 h-3.5" />
                      Aplicar Tudo
                    </Button>
                  )}
                  <Button
                    type="button"
                    size="sm"
                    variant={suggestedDueDate || suggestedPriority ? "outline" : "default"}
                    onClick={handleApplySubtasks}
                    className={`h-7 text-xs ${
                      !(suggestedDueDate || suggestedPriority)
                        ? "bg-indigo-600 hover:bg-indigo-700 text-white"
                        : "border-slate-300 dark:border-slate-700"
                    } gap-1`}
                  >
                    <Plus className="w-3.5 h-3.5" />
                    Adicionar Subtarefas
                  </Button>
                </div>
              </div>

              <ul className="space-y-1.5">
                {subtasks.map((item, index) => (
                  <li
                    key={index}
                    className="flex items-center justify-between p-2 text-xs bg-white dark:bg-slate-800 rounded-md border border-slate-200 dark:border-slate-700 group hover:border-indigo-300 dark:hover:border-indigo-700 transition-colors"
                  >
                    <div className="flex items-center gap-2 min-w-0 pr-2">
                      <CheckCircle2 className="w-3.5 h-3.5 text-emerald-500 shrink-0" />
                      <span className="truncate">{item.title}</span>
                    </div>
                    <div className="flex items-center gap-1.5 shrink-0">
                      {item.dueDate && (
                        <span className="text-[10px] text-muted-foreground font-mono flex items-center gap-0.5">
                          <Calendar className="w-2.5 h-2.5" />
                          {item.dueDate}
                        </span>
                      )}
                      <span
                        className={`px-1.5 py-0.5 text-[10px] rounded font-medium border ${
                          priorityLabelMap[item.priority]?.class || "bg-slate-100 text-slate-700"
                        }`}
                      >
                        {priorityLabelMap[item.priority]?.label || item.priority}
                      </span>
                      <button
                        type="button"
                        onClick={() => removeSubtask(index)}
                        className="text-slate-400 hover:text-red-500 p-0.5 rounded opacity-0 group-hover:opacity-100 transition-opacity"
                        title="Remover subtarefa"
                      >
                        <X className="w-3 h-3" />
                      </button>
                    </div>
                  </li>
                ))}
              </ul>
            </div>
          )}
        </div>
      )}
    </div>
  );
}
