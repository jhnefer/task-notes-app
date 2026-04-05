/**
 * ExportMenu — Export data in various formats
 * Design: Warm Paper Notebook
 */

import { Download, FileText, Sheet } from 'lucide-react';
import { Task, Note } from '@/hooks/useStore';
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';
import { Button } from '@/components/ui/button';
import {
  exportTasksToCSV,
  exportTasksToPDF,
  exportNotesToCSV,
  exportNotesToPDF,
} from '@/lib/export';
import { toast } from 'sonner';

interface ExportMenuProps {
  tasks?: Task[];
  notes?: Note[];
  categories: { id: string; name: string }[];
  variant?: 'default' | 'outline';
  size?: 'default' | 'sm';
}

export function ExportMenu({
  tasks = [],
  notes = [],
  categories,
  variant = 'outline',
  size = 'default',
}: ExportMenuProps) {
  const handleExportTasksCSV = () => {
    if (tasks.length === 0) {
      toast.error('Nenhuma tarefa para exportar');
      return;
    }
    try {
      exportTasksToCSV(tasks, categories);
      toast.success(`${tasks.length} tarefas exportadas para CSV`);
    } catch (error) {
      toast.error('Erro ao exportar tarefas');
      console.error(error);
    }
  };

  const handleExportTasksPDF = () => {
    if (tasks.length === 0) {
      toast.error('Nenhuma tarefa para exportar');
      return;
    }
    try {
      exportTasksToPDF(tasks, categories);
      toast.success(`${tasks.length} tarefas exportadas para PDF`);
    } catch (error) {
      toast.error('Erro ao exportar tarefas');
      console.error(error);
    }
  };

  const handleExportNotesCSV = () => {
    if (notes.length === 0) {
      toast.error('Nenhuma anotação para exportar');
      return;
    }
    try {
      exportNotesToCSV(notes, categories);
      toast.success(`${notes.length} anotações exportadas para CSV`);
    } catch (error) {
      toast.error('Erro ao exportar anotações');
      console.error(error);
    }
  };

  const handleExportNotesPDF = () => {
    if (notes.length === 0) {
      toast.error('Nenhuma anotação para exportar');
      return;
    }
    try {
      exportNotesToPDF(notes, categories);
      toast.success(`${notes.length} anotações exportadas para PDF`);
    } catch (error) {
      toast.error('Erro ao exportar anotações');
      console.error(error);
    }
  };

  const hasData = tasks.length > 0 || notes.length > 0;

  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <Button
          variant={variant}
          size={size}
          className="font-body gap-2"
          disabled={!hasData}
        >
          <Download size={16} />
          Exportar
        </Button>
      </DropdownMenuTrigger>
      <DropdownMenuContent align="end" className="w-56">
        {tasks.length > 0 && (
          <>
            <div className="px-2 py-1.5">
              <p className="font-body text-xs font-semibold text-muted-foreground uppercase">
                Tarefas ({tasks.length})
              </p>
            </div>
            <DropdownMenuItem onClick={handleExportTasksCSV} className="font-body gap-2 cursor-pointer">
              <Sheet size={14} />
              Exportar como CSV
            </DropdownMenuItem>
            <DropdownMenuItem onClick={handleExportTasksPDF} className="font-body gap-2 cursor-pointer">
              <FileText size={14} />
              Exportar como PDF
            </DropdownMenuItem>
          </>
        )}

        {tasks.length > 0 && notes.length > 0 && <DropdownMenuSeparator />}

        {notes.length > 0 && (
          <>
            <div className="px-2 py-1.5">
              <p className="font-body text-xs font-semibold text-muted-foreground uppercase">
                Anotações ({notes.length})
              </p>
            </div>
            <DropdownMenuItem onClick={handleExportNotesCSV} className="font-body gap-2 cursor-pointer">
              <Sheet size={14} />
              Exportar como CSV
            </DropdownMenuItem>
            <DropdownMenuItem onClick={handleExportNotesPDF} className="font-body gap-2 cursor-pointer">
              <FileText size={14} />
              Exportar como PDF
            </DropdownMenuItem>
          </>
        )}
      </DropdownMenuContent>
    </DropdownMenu>
  );
}
