import { cn } from "@/lib/utils";
import { AlertTriangle, RotateCcw } from "lucide-react";
import { Component, ReactNode } from "react";
import { Button } from "./ui/button";

interface Props {
  children: ReactNode;
}

interface State {
  hasError: boolean;
  error: Error | null;
}

class ErrorBoundary extends Component<Props, State> {
  constructor(props: Props) {
    super(props);
    this.state = { hasError: false, error: null };
  }

  static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error };
  }

  componentDidCatch(error: Error, errorInfo: any) {
    console.error("ErrorBoundary capturou um erro:", error, errorInfo);
  }

  render() {
    if (this.state.hasError) {
      return (
        <div className="flex items-center justify-center min-h-screen p-8 bg-background">
          <div className="flex flex-col items-center w-full max-w-md p-8 text-center">
            <div className="w-16 h-16 rounded-full bg-destructive/10 flex items-center justify-center mb-6">
              <AlertTriangle size={32} className="text-destructive" />
            </div>

            <h2 className="font-display text-2xl font-bold mb-2">Ops! Algo deu errado.</h2>
            <p className="font-body text-muted-foreground mb-8">
              Ocorreu um erro inesperado na aplicação. Tente recarregar a página para continuar.
            </p>

            <Button
              onClick={() => window.location.reload()}
              className="gap-2 px-6"
            >
              <RotateCcw size={18} />
              Recarregar Página
            </Button>
            
            {process.env.NODE_ENV === 'development' && (
              <div className="mt-8 p-4 w-full rounded bg-muted text-left overflow-auto max-h-40 border border-border">
                <p className="text-xs font-mono text-destructive font-bold mb-1">Erro (apenas dev):</p>
                <pre className="text-[10px] text-muted-foreground whitespace-pre-wrap font-mono">
                  {this.state.error?.message}
                </pre>
              </div>
            )}
          </div>
        </div>
      );
    }

    return this.props.children;
  }
}

export default ErrorBoundary;
