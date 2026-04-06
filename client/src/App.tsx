/**
 * App — Root component with routing and global providers
 * Design: Warm Paper Notebook
 */

import { Toaster } from "@/components/ui/sonner";
import { toast } from "sonner";
import { TooltipProvider } from "@/components/ui/tooltip";
import NotFound from "@/pages/NotFound";
import { Route, Switch } from "wouter";
import ErrorBoundary from "./components/ErrorBoundary";
import { ThemeProvider } from "./contexts/ThemeContext";
import { AppProvider, useApp } from "./contexts/AppContext";
import { NotificationProvider } from "./contexts/NotificationContext";
import { GamificationProvider } from "./contexts/GamificationContext";
import AppLayout from "./components/AppLayout";
import Dashboard from "./pages/Dashboard";
import Tasks from "./pages/Tasks";
import Notes from "./pages/Notes";
import Categories from "./pages/Categories";
import Reports from "./pages/Reports";
import Achievements from "./pages/Achievements";
import AuthPage from "./pages/Auth";
import { useAuth } from "./hooks/useAuth";
import { QueryClientProvider, QueryClient, QueryCache, MutationCache } from "@tanstack/react-query";
import { persistQueryClient } from '@tanstack/react-query-persist-client';
import { createSyncStoragePersister } from '@tanstack/query-sync-storage-persister';
import { ReactQueryDevtools } from "@tanstack/react-query-devtools";
import { Loader2 } from "lucide-react";

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 5 * 60 * 1000,
      gcTime: 1000 * 60 * 60 * 24, // Manter em cache por 24 horas
      refetchOnWindowFocus: false,
      retry: 1,
    },
  },
  queryCache: new QueryCache({
    onError: (error: any) => {
      if (error?.response?.status !== 401) {
        toast.error(`Erro na busca: ${error.message || "Falha ao carregar dados"}`);
      }
    },
  }),
  mutationCache: new MutationCache({
    onError: (error: any) => {
      toast.error(`Erro na operação: ${error.message || "Falha ao salvar dados"}`);
    },
  }),
});

// Configura a persistência do cache no localStorage (PWA / Offline support)
const localStoragePersister = createSyncStoragePersister({
  storage: window.localStorage,
});

persistQueryClient({
  queryClient,
  persister: localStoragePersister,
  maxAge: 1000 * 60 * 60 * 24, // 24 horas
});

function Router() {
  return (
    <AppLayout>
      <Switch>
        <Route path="/" component={Dashboard} />
        <Route path="/tasks" component={Tasks} />
        <Route path="/notes" component={Notes} />
        <Route path="/categories" component={Categories} />
        <Route path="/reports" component={Reports} />
        <Route path="/achievements" component={Achievements} />
        <Route path="/404" component={NotFound} />
        <Route component={NotFound} />
      </Switch>
    </AppLayout>
  );
}

function AppWithNotifications() {
  const { tasks } = useApp();
  return (
    <NotificationProvider tasks={tasks}>
      <Router />
    </NotificationProvider>
  );
}

function AuthGuard() {
  const { user, isLoading } = useAuth();

  if (isLoading) {
    return (
      <div className="h-screen w-screen flex items-center justify-center bg-background">
        <Loader2 className="h-8 w-8 animate-spin text-primary" />
      </div>
    );
  }

  if (!user) {
    return <AuthPage />;
  }

  return (
    <AppProvider>
      <GamificationProvider>
        <AppWithNotifications />
      </GamificationProvider>
    </AppProvider>
  );
}

function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <ErrorBoundary>
        <ThemeProvider defaultTheme="light">
          <TooltipProvider>
            <Toaster richColors position="top-right" />
            <AuthGuard />
          </TooltipProvider>
        </ThemeProvider>
      </ErrorBoundary>
      <ReactQueryDevtools initialIsOpen={false} />
    </QueryClientProvider>
  );
}

export default App;
