/**
 * ResetDataButton — Debug utility to reset localStorage
 * Design: Warm Paper Notebook
 */

import { RotateCcw } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { toast } from 'sonner';

export function ResetDataButton() {
  const handleReset = () => {
    if (confirm('Isso vai resetar todos os dados para os padrões iniciais. Tem certeza?')) {
      localStorage.removeItem('task-notes-app-data');
      toast.success('Dados resetados! Recarregando página...');
      setTimeout(() => window.location.reload(), 500);
    }
  };

  return (
    <Button
      variant="outline"
      size="sm"
      onClick={handleReset}
      className="font-body gap-2 text-xs"
    >
      <RotateCcw size={12} />
      Resetar Dados
    </Button>
  );
}
