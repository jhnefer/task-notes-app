/**
 * App — Root component with routing and global providers
 * Design: Warm Paper Notebook
 */

import { Toaster } from "@/components/ui/sonner";
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

function App() {
  return (
    <ErrorBoundary>
      <ThemeProvider defaultTheme="light">
        <AppProvider>
          <GamificationProvider>
            <TooltipProvider>
              <Toaster richColors position="top-right" />
              <AppWithNotifications />
            </TooltipProvider>
          </GamificationProvider>
        </AppProvider>
      </ThemeProvider>
    </ErrorBoundary>
  );
}

export default App;
