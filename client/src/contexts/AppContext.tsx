/**
 * AppContext — Global state provider
 * Design: Warm Paper Notebook
 */

import { createContext, useContext, ReactNode } from 'react';
import { useStore } from '@/hooks/useStore';

type StoreReturn = ReturnType<typeof useStore>;

const AppContext = createContext<StoreReturn | null>(null);

export function AppProvider({ children }: { children: ReactNode }) {
  const store = useStore();
  return <AppContext.Provider value={store}>{children}</AppContext.Provider>;
}

export function useApp() {
  const ctx = useContext(AppContext);
  if (!ctx) throw new Error('useApp must be used within AppProvider');
  return ctx;
}
