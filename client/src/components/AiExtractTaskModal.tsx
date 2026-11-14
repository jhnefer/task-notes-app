import { useState, useEffect } from "react";
import {
  Sparkles,
  Loader2,
  Calendar,
  AlertCircle,
  Plus,
  Trash2,
  CheckCircle2,
  ArrowRight,
  Target,
  FileText,
} from "lucide-react";
import { nanoid } from "nanoid";
import { useApp } from "@/contexts/AppContext";
import { Note } from "@/hooks/useStore";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Label } from "@/components/ui/label";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from "@/components/ui/dialog";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { toast } from "sonner";

interface AiExtractTaskModalProps {
  open: boolean;
  onClose: () => void;
  note?: Note | null;
}

interface EditableSubtask {
  id: string;
  title: string;
  priority: "low" | "medium" | "high";
  completed: boolean;
}

export function AiExtractTaskModal({ open, onClose, note }: AiExtractTaskModalProps) {
  const { addTask, categories } = useApp();
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Estados dos campos extraídos e editáveis pela pessoa
  const [title, setTitle] = useState("");
  const [description, setDescription] = useState("");
  const [dueDate, setDueDate] = useState("");
  const [priority, setPriority] = useState<"low" | "medium" | "high">("medium");
  const [categoryId, setCategoryId] = useState("");
  const [tags, setTags] = useState("");
  const [subtasks, setSubtasks] = useState<EditableSubtask[]>([]);
  const [uncertainties, setUncertainties] = useState<string[]>([]);
  const [hasExtracted, setHasExtracted] = useState(false);
  const [newSubtaskInput, setNewSubtaskInput] = useState("");
  const [saving, setSaving] = useState(false);

  const handleExtract = async () => {
    if (!note) return;

    const fullText = `${note.title}\n\n${note.content || ""}`.trim();
    if (!fullText) {
      toast.error("A nota está vazia para análise.");
      return;
    }

    setLoading(true);
    setError(null);

    try {
      const response = await fetch("/api/ai/extract-task", {
        method: "POST",
        credentials: "include",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          text: fullText,
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

      // Preenche os campos para a confirmação da pessoa
      setTitle(data.title || note.title);
      setDescription(data.description || note.content || "");
      setDueDate(data.dueDate || "");
      setPriority(data.priority || "medium");
      setCategoryId(note.categoryId || "");
      setTags(note.tags ? note.tags.join(", ") : "");
      setUncertainties(data.uncertainties || []);

      const formattedSubtasks: EditableSubtask[] = (data.subtasks || []).map((s: any) => ({
        id: nanoid(),
        title: s.title,
        priority: s.priority || "medium",
        completed: false,
      }));
      setSubtasks(formattedSubtasks);
      setHasExtracted(true);
      toast.success("Dados estruturados e analisados pelo Gemini!");
    } catch (err: any) {
      setError(err.message || "Erro de conexão com a IA.");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    if (open && note) {
      setHasExtracted(false);
      setError(null);
      handleExtract();
    }
  }, [open, note?.id]);

  const handleAddSubtask = () => {
    if (!newSubtaskInput.trim()) return;
    setSubtasks(prev => [
      ...prev,
      {
        id: nanoid(),
        title: newSubtaskInput.trim(),
        priority: priority,
        completed: false,
      },
    ]);
    setNewSubtaskInput("");
  };

  const handleRemoveSubtask = (id: string) => {
    setSubtasks(prev => prev.filter(s => s.id !== id));
  };

  const handleSave = () => {
    if (!title.trim()) {
      toast.error("O título da tarefa é obrigatório.");
      return;
    }

    setSaving(true);

    let formattedDueDate: string | undefined = undefined;
    if (dueDate && dueDate.trim()) {
      const dateStr = dueDate.includes("T") ? dueDate : `${dueDate}T12:00:00Z`;
      const parsed = new Date(dateStr);
      if (!isNaN(parsed.getTime())) {
        formattedDueDate = parsed.toISOString();
      }
    }

    const sanitizedSubtasks = subtasks.map(s => ({
      id: s.id || nanoid(),
      title: s.title.trim(),
      completed: !!s.completed,
      priority: (["low", "medium", "high"].includes(s.priority) ? s.priority : "medium") as "low" | "medium" | "high",
    }));

    const payload = {
      title: title.trim(),
      description: description.trim() || undefined,
      dueDate: formattedDueDate,
      priority,
      status: "pending" as const,
      categoryId: categoryId || undefined,
      tags: tags
        .split(",")
        .map(t => t.trim())
        .filter(Boolean),
      subtasks: sanitizedSubtasks,
    };

    addTask(payload, {
      onSuccess: () => {
        setSaving(false);
        toast.success("Tarefa criada com sucesso a partir da anotação!");
        onClose();
      },
      onError: (err: any) => {
        setSaving(false);
        const msg = err?.response?.data?.errors
          ? Object.entries(err.response.data.errors)
              .map(([k, v]) => `${k}: ${v}`)
              .join(", ")
          : err?.response?.data?.error || err.message || "Erro desconhecido";
        toast.error(`Erro ao salvar tarefa: ${msg}`);
      },
    });
  };

  return (
    <Dialog open={open} onOpenChange={v => !v && onClose()}>
      <DialogContent className="max-w-xl bg-card border-border max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <div className="flex items-center gap-2">
            <div className="p-1.5 rounded-lg bg-indigo-50 dark:bg-indigo-950/60 text-indigo-600 dark:text-indigo-400">
              <Sparkles className="w-5 h-5 animate-pulse" />
            </div>
            <div>
              <DialogTitle className="font-display text-lg text-foreground">
                Transformar Anotação em Tarefa com IA
              </DialogTitle>
              <p className="text-xs text-muted-foreground mt-0.5">
                Revise os prazos, prioridades e subtarefas identificadas antes de salvar.
              </p>
            </div>
          </div>
        </DialogHeader>

        {loading ? (
          <div className="py-12 flex flex-col items-center justify-center space-y-3">
            <Loader2 className="w-8 h-8 animate-spin text-indigo-600" />
            <p className="text-sm font-medium text-foreground">
              Extraindo campos, interpretando datas e gerando submetas...
            </p>
            <p className="text-xs text-muted-foreground">
              Utilizando modelos Gemini de baixa latência
            </p>
          </div>
        ) : error ? (
          <div className="py-6 space-y-4 text-center">
            <div className="p-3 bg-red-50 dark:bg-red-950/40 border border-red-200 dark:border-red-900 rounded-lg text-red-700 dark:text-red-400 text-xs">
              {error}
            </div>
            <Button onClick={handleExtract} variant="outline" size="sm" className="gap-2">
              <Sparkles className="w-4 h-4 text-indigo-500" />
              Tentar Novamente
            </Button>
          </div>
        ) : (
          <div className="space-y-4 py-2 text-sm">
            {/* Aviso de Incertezas / Ambiguidade (Pessoa no controle) */}
            {uncertainties.length > 0 && (
              <div className="p-3 rounded-lg bg-amber-50 dark:bg-amber-950/40 border border-amber-200 dark:border-amber-800/80 text-xs text-amber-900 dark:text-amber-200 space-y-1">
                <div className="flex items-center gap-1.5 font-semibold">
                  <AlertCircle className="w-4 h-4 text-amber-600 dark:text-amber-400 shrink-0" />
                  <span>Pontos de Atenção identificados na nota:</span>
                </div>
                <ul className="list-disc list-inside space-y-0.5 text-[11px] opacity-90 pl-1">
                  {uncertainties.map((u, idx) => (
                    <li key={idx}>{u}</li>
                  ))}
                </ul>
              </div>
            )}

            {/* Título da Tarefa */}
            <div>
              <Label className="text-xs font-semibold text-foreground mb-1 block">
                Título da Tarefa *
              </Label>
              <Input
                value={title}
                onChange={e => setTitle(e.target.value)}
                placeholder="Título da tarefa..."
                className="font-medium bg-background border-border text-sm"
              />
            </div>

            {/* Descrição / Resumo */}
            <div>
              <Label className="text-xs font-semibold text-foreground mb-1 block">
                Resumo / Contexto
              </Label>
              <Textarea
                value={description}
                onChange={e => setDescription(e.target.value)}
                rows={2}
                placeholder="Detalhes da tarefa..."
                className="text-xs bg-background border-border resize-none"
              />
            </div>

            {/* Prazo e Prioridade Sugeridos */}
            <div className="grid grid-cols-2 gap-3">
              <div>
                <Label className="text-xs font-semibold text-foreground mb-1 flex items-center justify-between">
                  <span>Prazo Sugerido</span>
                  {dueDate && (
                    <span className="text-[10px] text-indigo-600 dark:text-indigo-400 font-normal">
                      ✓ Detectado
                    </span>
                  )}
                </Label>
                <div className="relative">
                  <Input
                    type="date"
                    value={dueDate}
                    onChange={e => setDueDate(e.target.value)}
                    className="text-xs bg-background border-border font-mono"
                  />
                </div>
              </div>

              <div>
                <Label className="text-xs font-semibold text-foreground mb-1 block">
                  Prioridade
                </Label>
                <Select value={priority} onValueChange={(v: any) => setPriority(v)}>
                  <SelectTrigger className="text-xs bg-background border-border h-9">
                    <SelectValue placeholder="Selecione..." />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="low">Baixa</SelectItem>
                    <SelectItem value="medium">Média</SelectItem>
                    <SelectItem value="high">Alta (Urgente)</SelectItem>
                  </SelectContent>
                </Select>
              </div>
            </div>

            {/* Submetas extraídas pela IA */}
            <div className="space-y-2 pt-2 border-t border-border">
              <div className="flex items-center justify-between">
                <Label className="text-xs font-semibold text-foreground flex items-center gap-1.5">
                  <Target size={14} className="text-indigo-500" />
                  Subtarefas Sugeridas ({subtasks.length})
                </Label>
                <span className="text-[11px] text-muted-foreground">
                  Começam com verbo de ação
                </span>
              </div>

              {subtasks.length > 0 ? (
                <div className="space-y-1.5 max-h-44 overflow-y-auto pr-1">
                  {subtasks.map((st) => (
                    <div
                      key={st.id}
                      className="flex items-center justify-between p-2 rounded-lg border border-border bg-muted/40 text-xs group"
                    >
                      <div className="flex items-center gap-2 flex-1 min-w-0 mr-2">
                        <CheckCircle2 className="w-3.5 h-3.5 text-emerald-500 shrink-0" />
                        <Input
                          value={st.title}
                          onChange={e => {
                            const updated = subtasks.map(s =>
                              s.id === st.id ? { ...s, title: e.target.value } : s
                            );
                            setSubtasks(updated);
                          }}
                          className="h-6 text-xs bg-transparent border-0 shadow-none px-1 py-0 focus-visible:ring-1"
                        />
                      </div>
                      <div className="flex items-center gap-1.5 shrink-0">
                        <span
                          className={`px-1.5 py-0.5 text-[10px] rounded font-medium ${
                            st.priority === "high"
                              ? "bg-red-100 text-red-700 dark:bg-red-950/60 dark:text-red-400"
                              : st.priority === "medium"
                              ? "bg-amber-100 text-amber-700 dark:bg-amber-950/60 dark:text-amber-400"
                              : "bg-blue-100 text-blue-700 dark:bg-blue-950/60 dark:text-blue-400"
                          }`}
                        >
                          {st.priority === "high" ? "Alta" : st.priority === "medium" ? "Média" : "Baixa"}
                        </span>
                        <button
                          type="button"
                          onClick={() => handleRemoveSubtask(st.id)}
                          className="text-muted-foreground hover:text-destructive p-1 rounded opacity-0 group-hover:opacity-100 transition-opacity"
                        >
                          <Trash2 size={12} />
                        </button>
                      </div>
                    </div>
                  ))}
                </div>
              ) : (
                <p className="text-xs text-muted-foreground italic">Nenhuma subtarefa necessária.</p>
              )}

              {/* Adicionar subtarefa manual rápida */}
              <div className="flex items-center gap-2 pt-1">
                <Input
                  value={newSubtaskInput}
                  onChange={e => setNewSubtaskInput(e.target.value)}
                  onKeyDown={e => e.key === "Enter" && (e.preventDefault(), handleAddSubtask())}
                  placeholder="Adicionar outra subtarefa..."
                  className="h-7 text-xs bg-background border-border"
                />
                <Button
                  type="button"
                  variant="outline"
                  size="sm"
                  onClick={handleAddSubtask}
                  className="h-7 text-xs px-2 shrink-0 gap-1"
                >
                  <Plus size={12} />
                  Adicionar
                </Button>
              </div>
            </div>
          </div>
        )}

        <DialogFooter className="gap-2 pt-2 border-t border-border">
          <Button variant="outline" onClick={onClose} size="sm" className="text-xs">
            Cancelar
          </Button>
          <Button
            onClick={handleSave}
            disabled={loading || saving || !title.trim()}
            size="sm"
            className="text-xs bg-indigo-600 hover:bg-indigo-700 text-white gap-1.5"
          >
            {saving ? (
              <>
                <Loader2 size={14} className="animate-spin" />
                Salvando Tarefa...
              </>
            ) : (
              <>
                <CheckCircle2 size={14} />
                Confirmar e Criar Tarefa
              </>
            )}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
