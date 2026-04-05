/**
 * AppLayout — Main application shell
 * Design: Warm Paper Notebook — sidebar (leather) + main content (parchment)
 * Responsive: mobile drawer + desktop persistent sidebar
 * Enhanced: Notification badges for upcoming deadlines
 */

import { useState } from 'react';
import { Link, useLocation } from 'wouter';
import {
  CheckSquare,
  FileText,
  LayoutDashboard,
  ChevronLeft,
  ChevronRight,
  BookOpen,
  Tag,
  Menu,
  X,
  BarChart3,
  Trophy,
} from 'lucide-react';
import { cn } from '@/lib/utils';
import { useNotificationContext } from '@/contexts/NotificationContext';
import { NotificationBadge } from './NotificationBadge';

interface NavItem {
  icon: React.ReactNode;
  label: string;
  href: string;
  showBadge?: boolean;
}

function NavItemWithBadge({
  item,
  isActive,
  collapsed,
  onClick,
  badgeCount,
}: {
  item: NavItem;
  isActive: boolean;
  collapsed: boolean;
  onClick?: () => void;
  badgeCount?: number;
}) {
  return (
    <Link href={item.href} onClick={onClick}>
      <div className={cn(
        'flex items-center gap-3 px-3 py-2.5 rounded-md transition-all duration-150 relative',
        'text-sidebar-foreground/70 hover:text-sidebar-foreground hover:bg-sidebar-accent',
        isActive && 'bg-sidebar-accent text-sidebar-foreground font-medium shadow-sm',
        collapsed && 'justify-center px-2'
      )}>
        <span className="shrink-0">{item.icon}</span>
        {!collapsed && (
          <span className="font-body text-sm truncate flex-1">{item.label}</span>
        )}
        {badgeCount && badgeCount > 0 && !collapsed && (
          <span className="shrink-0 ml-auto">
            <NotificationBadge
              critical={0}
              high={badgeCount}
              medium={0}
              size="sm"
            />
          </span>
        )}
      </div>
    </Link>
  );
}

interface SidebarContentProps {
  collapsed: boolean;
  location: string;
  onNavClick?: () => void;
  notificationCounts?: { critical: number; high: number; medium: number };
}

function SidebarContent({
  collapsed,
  location,
  onNavClick,
  notificationCounts = { critical: 0, high: 0, medium: 0 },
}: SidebarContentProps) {
  const NAV_ITEMS: NavItem[] = [
    { icon: <LayoutDashboard size={18} />, label: 'Visão Geral', href: '/', showBadge: true },
    { icon: <CheckSquare size={18} />, label: 'Tarefas', href: '/tasks', showBadge: true },
    { icon: <FileText size={18} />, label: 'Anotações', href: '/notes' },
    { icon: <Tag size={18} />, label: 'Categorias', href: '/categories' },
    { icon: <BarChart3 size={18} />, label: 'Relatórios', href: '/reports' },
    { icon: <Trophy size={18} />, label: 'Conquistas', href: '/achievements' },
  ];

  return (
    <div className="relative z-10 flex flex-col h-full">
      {/* Logo */}
      <div className={cn(
        'flex items-center gap-3 px-4 py-5 border-b border-sidebar-border',
        collapsed && 'justify-center px-2'
      )}>
        <div className="shrink-0 w-9 h-9 rounded-full bg-sidebar-primary flex items-center justify-center shadow-sm relative">
          <BookOpen size={17} className="text-sidebar-primary-foreground" />
          {(notificationCounts.critical > 0 || notificationCounts.high > 0) && !collapsed && (
            <div className="absolute -top-1 -right-1 w-4 h-4 bg-destructive rounded-full flex items-center justify-center">
              <span className="text-white text-xs font-bold">
                {notificationCounts.critical > 0 ? notificationCounts.critical : notificationCounts.high}
              </span>
            </div>
          )}
        </div>
        {!collapsed && (
          <div>
            <p className="font-display text-sidebar-foreground font-semibold text-sm leading-tight">
              Meu Caderno
            </p>
            <p className="font-accent text-sidebar-foreground/60 text-xs">
              tarefas & notas
            </p>
          </div>
        )}
      </div>

      {/* Navigation */}
      <nav className="flex-1 py-4 px-2 space-y-0.5">
        {NAV_ITEMS.map((item) => {
          const isActive = location === item.href;
          const badgeCount = item.showBadge
            ? notificationCounts.critical + notificationCounts.high
            : 0;

          return (
            <NavItemWithBadge
              key={item.href}
              item={item}
              isActive={isActive}
              collapsed={collapsed}
              onClick={onNavClick}
              badgeCount={badgeCount}
            />
          );
        })}
      </nav>

      {/* Footer */}
      <div className="px-3 py-4 border-t border-sidebar-border">
        <p className={cn(
          'font-accent text-sidebar-foreground/40 text-xs text-center',
          collapsed && 'hidden'
        )}>
          Suas ideias, organizadas.
        </p>
      </div>
    </div>
  );
}

interface AppLayoutProps {
  children: React.ReactNode;
}

export default function AppLayout({ children }: AppLayoutProps) {
  const [collapsed, setCollapsed] = useState(false);
  const [mobileOpen, setMobileOpen] = useState(false);
  const [location] = useLocation();
  const { count } = useNotificationContext();

  const sidebarStyle = {
    backgroundImage: `url(https://d2xsxph8kpxj0f.cloudfront.net/310519663518148515/oNcz3mW7GMkmCQSg8sx7vf/sidebar-texture-JvgZKoBVTXuN9cSqHj6HSX.webp)`,
    backgroundSize: 'cover',
    backgroundPosition: 'center',
  };

  return (
    <div className="flex h-screen overflow-hidden bg-background">
      {/* Mobile overlay */}
      {mobileOpen && (
        <div
          className="fixed inset-0 bg-black/50 z-30 lg:hidden"
          onClick={() => setMobileOpen(false)}
        />
      )}

      {/* Mobile sidebar (drawer) */}
      <aside
        className={cn(
          'fixed inset-y-0 left-0 z-40 w-56 flex flex-col h-full',
          'border-r border-sidebar-border',
          'transition-transform duration-300 ease-in-out',
          'lg:hidden',
          mobileOpen ? 'translate-x-0' : '-translate-x-full'
        )}
        style={sidebarStyle}
      >
        <div className="absolute inset-0 bg-sidebar/85" />
        <div className="relative z-10 flex flex-col h-full">
          <div className="flex items-center justify-between px-4 py-5 border-b border-sidebar-border">
            <div className="flex items-center gap-3">
              <div className="shrink-0 w-9 h-9 rounded-full bg-sidebar-primary flex items-center justify-center relative">
                <BookOpen size={17} className="text-sidebar-primary-foreground" />
                {(count.critical > 0 || count.high > 0) && (
                  <div className="absolute -top-1 -right-1 w-4 h-4 bg-destructive rounded-full flex items-center justify-center">
                    <span className="text-white text-xs font-bold">
                      {count.critical > 0 ? count.critical : count.high}
                    </span>
                  </div>
                )}
              </div>
              <div>
                <p className="font-display text-sidebar-foreground font-semibold text-sm leading-tight">
                  Meu Caderno
                </p>
                <p className="font-accent text-sidebar-foreground/60 text-xs">
                  tarefas & notas
                </p>
              </div>
            </div>
            <button
              onClick={() => setMobileOpen(false)}
              className="p-1 rounded text-sidebar-foreground/60 hover:text-sidebar-foreground"
            >
              <X size={18} />
            </button>
          </div>
          <SidebarContent
            collapsed={false}
            location={location}
            onNavClick={() => setMobileOpen(false)}
            notificationCounts={count}
          />
        </div>
      </aside>

      {/* Desktop sidebar */}
      <aside
        className={cn(
          'hidden lg:flex flex-col h-full transition-all duration-300 ease-in-out relative shrink-0',
          'border-r border-sidebar-border',
          collapsed ? 'w-16' : 'w-56'
        )}
        style={sidebarStyle}
      >
        <div className="absolute inset-0 bg-sidebar/80" />
        <div className="relative z-10 flex flex-col h-full">
          <SidebarContent
            collapsed={collapsed}
            location={location}
            notificationCounts={count}
          />
          {/* Collapse button */}
          <div className="absolute -right-3 top-1/2 -translate-y-1/2">
            <button
              onClick={() => setCollapsed(c => !c)}
              className={cn(
                'w-6 h-6 rounded-full border border-border bg-card',
                'flex items-center justify-center',
                'text-muted-foreground hover:text-foreground',
                'shadow-sm hover:shadow transition-all'
              )}
            >
              {collapsed ? <ChevronRight size={12} /> : <ChevronLeft size={12} />}
            </button>
          </div>
        </div>
      </aside>

      {/* Main content */}
      <div className="flex-1 flex flex-col overflow-hidden">
        {/* Mobile top bar */}
        <div className="lg:hidden flex items-center justify-between px-4 py-3 border-b border-border bg-card/80 backdrop-blur-sm">
          <button
            onClick={() => setMobileOpen(true)}
            className="p-1.5 rounded-md text-muted-foreground hover:text-foreground hover:bg-muted transition-colors"
          >
            <Menu size={20} />
          </button>
          <div className="flex items-center gap-2">
            <BookOpen size={16} className="text-primary" />
            <span className="font-display text-foreground font-semibold text-sm">Meu Caderno</span>
          </div>
          {(count.critical > 0 || count.high > 0) && (
            <NotificationBadge
              critical={count.critical}
              high={count.high}
              medium={0}
              size="sm"
            />
          )}
        </div>

        <main className="flex-1 overflow-auto">
          {children}
        </main>
      </div>
    </div>
  );
}
