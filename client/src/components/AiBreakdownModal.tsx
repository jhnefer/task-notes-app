import { useState } from "react";
import { Sparkles, Loader2, Plus, CheckCircle2 } from "lucide-react";
import { Button } from "@/components/ui/button";

interface Subtask {
  title: string;
  priority: "high" | "medium" | "low";
}

interface AiBreakdownModalProps {
  taskTitle: string;
  onAddSubtasks?: (subtasks: Subtask[]) => void;
}

export function AiBreakdownModal({ taskTitle, onAddSubtasks }: AiBreakdownModalProps) {
  const [loading, setLoading] = useState(false);
  const [subtasks, setSubtasks] = useState<Subtask[]>([]);
  const [error, setError] = useState<string | null>(null);

  const handleGenerate = async () => {
    if (!taskTitle.trim()) return;

    setLoading(true);
    setError(null);

    try {
      const response = await fetch("/api/ai/breakdown", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ goal: taskTitle }),
      });

      const data = await response.json();

      if (!response.ok) {
        throw new Error(data.error || "Erro ao gerar subtarefas.");
      }

      setSubtasks(data.subtasks);
    } catch (err: any) {
      setError(err.message || "Não foi possível conectar à IA.");
    } finally {
      setLoading(false);
    }
  };

  const handleApply = () => {
    if (onAddSubtasks && subtasks.length > 0) {
      onAddSubtasks(subtasks);
      setSubtasks([]);
    }
  };

  return (
    <div className="p-4 my-3 border rounded-xl bg-slate-50 dark:bg-slate-900 border-slate-200 dark:border-slate-800 space-y-3">
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
              A gerar...
            </>
          ) : (
            <>
              <Sparkles className="w-3.5 h-3.5 text-indigo-500" />
              Decompor Meta
            </>
          )}
        </Button>
      </div>

      {error && <p className="text-xs text-red-500">{error}</p>}

      {subtasks.length > 0 && (
        <div className="space-y-2 pt-2 border-t border-slate-200 dark:border-slate-800">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold text-slate-500 uppercase">
              Subtarefas Geradas:
            </span>
            <Button
              type="button"
              size="sm"
              onClick={handleApply}
              className="h-7 text-xs bg-indigo-600 hover:bg-indigo-700 text-white gap-1"
            >
              <Plus className="w-3.5 h-3.5" />
              Adicionar à Tarefa
            </Button>
          </div>

          <ul className="space-y-1.5">
            {subtasks.map((item, index) => (
              <li
                key={index}
                className="flex items-center justify-between p-2 text-xs bg-white dark:bg-slate-800 rounded-md border border-slate-200 dark:border-slate-700"
              >
                <div className="flex items-center gap-2">
                  <CheckCircle2 className="w-3.5 h-3.5 text-emerald-500" />
                  <span>{item.title}</span>
                </div>
                <span
                  className={`px-1.5 py-0.5 text-[10px] rounded font-medium ${
                    item.priority === "high"
                      ? "bg-red-100 text-red-700"
                      : item.priority === "medium"
                      ? "bg-amber-100 text-amber-700"
                      : "bg-blue-100 text-blue-700"
                  }`}
                >
                  {item.priority}
                </span>
              </li>
            ))}
          </ul>
        </div>
      )}
    </div>
  );
}