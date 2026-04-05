/**
 * Reports — Comprehensive analytics and productivity dashboard
 * Design: Warm Paper Notebook — data visualization with warm colors
 */

import { useState, useMemo } from 'react';
import { TrendingUp, Calendar, BarChart3, PieChart as PieChartIcon, Target } from 'lucide-react';
import { useApp } from '@/contexts/AppContext';
import { cn } from '@/lib/utils';
import {
  getDailyStats,
  getWeeklyStats,
  getMonthlyStats,
  getPriorityStats,
  getCategoryStats,
  getOverallStats,
  getProductivityScore,
  getProductivityLevel,
} from '@/lib/analytics';
import {
  DailyTasksChart,
  WeeklyTasksChart,
  MonthlyTasksChart,
  PriorityChart,
  CategoryCompletionChart,
  CompletionGauge,
} from '@/components/Charts';
import { Button } from '@/components/ui/button';

type TimeRange = 'week' | 'month' | 'year';

export default function Reports() {
  const { tasks, categories } = useApp();
  const [timeRange, setTimeRange] = useState<TimeRange>('month');

  // Calculate all analytics
  const dailyStats = useMemo(() => getDailyStats(tasks, 30), [tasks]);
  const weeklyStats = useMemo(() => getWeeklyStats(tasks, 12), [tasks]);
  const monthlyStats = useMemo(() => getMonthlyStats(tasks, 12), [tasks]);
  const priorityStats = useMemo(() => getPriorityStats(tasks), [tasks]);
  const categoryStats = useMemo(() => getCategoryStats(tasks, categories), [tasks, categories]);
  const overallStats = useMemo(() => getOverallStats(tasks), [tasks]);
  const productivityScore = useMemo(() => getProductivityScore(overallStats), [overallStats]);
  const productivityLevel = useMemo(() => getProductivityLevel(productivityScore), [productivityScore]);

  // Get chart data based on time range
  const getChartData = () => {
    switch (timeRange) {
      case 'week':
        return weeklyStats.slice(-4); // Last 4 weeks
      case 'month':
        return monthlyStats.slice(-12); // Last 12 months
      case 'year':
        return monthlyStats; // All months
      default:
        return monthlyStats;
    }
  };

  const chartData = getChartData();

  return (
    <div className="min-h-full">
      {/* Header */}
      <div className="px-8 py-6 border-b border-border bg-card/50">
        <div className="flex items-center justify-between mb-4">
          <div>
            <h1 className="font-display text-3xl font-bold text-foreground flex items-center gap-2">
              <BarChart3 size={32} />
              Relatórios
            </h1>
            <p className="font-body text-sm text-muted-foreground mt-0.5">
              Análise de produtividade e progresso
            </p>
          </div>
        </div>

        {/* Time Range Filter */}
        <div className="flex items-center gap-2 bg-muted p-1 rounded-lg w-fit">
          <button
            onClick={() => setTimeRange('week')}
            className={cn(
              'px-3 py-1.5 rounded transition-colors font-body text-sm',
              timeRange === 'week'
                ? 'bg-background text-foreground shadow-sm'
                : 'text-muted-foreground hover:text-foreground'
            )}
          >
            Semana
          </button>
          <button
            onClick={() => setTimeRange('month')}
            className={cn(
              'px-3 py-1.5 rounded transition-colors font-body text-sm',
              timeRange === 'month'
                ? 'bg-background text-foreground shadow-sm'
                : 'text-muted-foreground hover:text-foreground'
            )}
          >
            Mês
          </button>
          <button
            onClick={() => setTimeRange('year')}
            className={cn(
              'px-3 py-1.5 rounded transition-colors font-body text-sm',
              timeRange === 'year'
                ? 'bg-background text-foreground shadow-sm'
                : 'text-muted-foreground hover:text-foreground'
            )}
          >
            Ano
          </button>
        </div>
      </div>

      {/* Main Content */}
      <div className="px-8 py-6 space-y-8">
        {/* Overall Stats Cards */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          {/* Total Tasks */}
          <div className="bg-card border border-border rounded-lg p-4">
            <div className="flex items-start justify-between mb-2">
              <div>
                <p className="font-body text-xs text-muted-foreground uppercase">Total de Tarefas</p>
                <p className="font-display text-2xl font-bold text-foreground mt-1">
                  {overallStats.totalTasks}
                </p>
              </div>
              <Target size={24} className="text-primary/30" />
            </div>
            <p className="font-body text-xs text-muted-foreground">
              {overallStats.completedTasks} concluídas
            </p>
          </div>

          {/* Completion Rate */}
          <div className="bg-card border border-border rounded-lg p-4">
            <div className="flex items-start justify-between mb-2">
              <div>
                <p className="font-body text-xs text-muted-foreground uppercase">Taxa de Conclusão</p>
                <p className="font-display text-2xl font-bold text-foreground mt-1">
                  {Math.round(overallStats.completionRate)}%
                </p>
              </div>
              <PieChartIcon size={24} className="text-primary/30" />
            </div>
            <p className="font-body text-xs text-muted-foreground">
              {overallStats.completedTasks} de {overallStats.totalTasks} tarefas
            </p>
          </div>

          {/* This Week */}
          <div className="bg-card border border-border rounded-lg p-4">
            <div className="flex items-start justify-between mb-2">
              <div>
                <p className="font-body text-xs text-muted-foreground uppercase">Esta Semana</p>
                <p className="font-display text-2xl font-bold text-foreground mt-1">
                  {overallStats.tasksCompletedThisWeek}
                </p>
              </div>
              <Calendar size={24} className="text-primary/30" />
            </div>
            <p className="font-body text-xs text-muted-foreground">
              tarefas concluídas
            </p>
          </div>

          {/* Productivity Score */}
          <div className="bg-card border border-border rounded-lg p-4">
            <div className="flex items-start justify-between mb-2">
              <div>
                <p className="font-body text-xs text-muted-foreground uppercase">Produtividade</p>
                <p className="font-display text-2xl font-bold text-foreground mt-1">
                  {productivityScore}
                </p>
              </div>
              <TrendingUp
                size={24}
                className={cn(
                  'transition-colors',
                  overallStats.productivityTrend === 'up' ? 'text-[#4A7C59]' : 'text-[#C0533A]'
                )}
              />
            </div>
            <p className="font-body text-xs text-muted-foreground">
              {productivityLevel}
            </p>
          </div>
        </div>

        {/* Productivity Gauge */}
        <div className="bg-card border border-border rounded-lg p-6">
          <h2 className="font-display text-lg font-semibold text-foreground mb-6">Taxa de Conclusão</h2>
          <div className="flex justify-center">
            <CompletionGauge rate={overallStats.completionRate} />
          </div>
        </div>

        {/* Charts Grid */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {/* Daily Tasks Chart */}
          <div className="bg-card border border-border rounded-lg p-6">
            <h2 className="font-display text-lg font-semibold text-foreground mb-4">
              Tarefas por Dia (Últimos 30 dias)
            </h2>
            <DailyTasksChart data={dailyStats} height={300} />
          </div>

          {/* Priority Distribution */}
          <div className="bg-card border border-border rounded-lg p-6">
            <h2 className="font-display text-lg font-semibold text-foreground mb-4">
              Distribuição por Prioridade
            </h2>
            <PriorityChart data={priorityStats} height={300} />
          </div>

          {/* Weekly/Monthly Chart */}
          <div className="bg-card border border-border rounded-lg p-6 lg:col-span-2">
            <h2 className="font-display text-lg font-semibold text-foreground mb-4">
              {timeRange === 'week' ? 'Tarefas por Semana' : 'Tarefas por Mês'}
            </h2>
            {timeRange === 'week' ? (
              <WeeklyTasksChart data={chartData as any} height={350} />
            ) : (
              <MonthlyTasksChart data={chartData as any} height={350} />
            )}
          </div>

          {/* Category Completion */}
          {categoryStats.length > 0 && (
            <div className="bg-card border border-border rounded-lg p-6 lg:col-span-2">
              <h2 className="font-display text-lg font-semibold text-foreground mb-4">
                Taxa de Conclusão por Categoria
              </h2>
              <CategoryCompletionChart data={categoryStats} height={300} />
            </div>
          )}
        </div>

        {/* Detailed Stats Table */}
        <div className="bg-card border border-border rounded-lg p-6">
          <h2 className="font-display text-lg font-semibold text-foreground mb-4">
            Estatísticas Detalhadas
          </h2>
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b border-border">
                  <th className="text-left py-2 px-4 font-body text-sm font-semibold text-foreground">
                    Métrica
                  </th>
                  <th className="text-right py-2 px-4 font-body text-sm font-semibold text-foreground">
                    Valor
                  </th>
                </tr>
              </thead>
              <tbody>
                <tr className="border-b border-border hover:bg-muted/30 transition-colors">
                  <td className="py-3 px-4 font-body text-sm text-foreground">Total de Tarefas</td>
                  <td className="text-right py-3 px-4 font-body text-sm text-foreground font-semibold">
                    {overallStats.totalTasks}
                  </td>
                </tr>
                <tr className="border-b border-border hover:bg-muted/30 transition-colors">
                  <td className="py-3 px-4 font-body text-sm text-foreground">Tarefas Concluídas</td>
                  <td className="text-right py-3 px-4 font-body text-sm text-foreground font-semibold">
                    {overallStats.completedTasks}
                  </td>
                </tr>
                <tr className="border-b border-border hover:bg-muted/30 transition-colors">
                  <td className="py-3 px-4 font-body text-sm text-foreground">Tarefas Pendentes</td>
                  <td className="text-right py-3 px-4 font-body text-sm text-foreground font-semibold">
                    {overallStats.pendingTasks}
                  </td>
                </tr>
                <tr className="border-b border-border hover:bg-muted/30 transition-colors">
                  <td className="py-3 px-4 font-body text-sm text-foreground">Em Andamento</td>
                  <td className="text-right py-3 px-4 font-body text-sm text-foreground font-semibold">
                    {overallStats.inProgressTasks}
                  </td>
                </tr>
                <tr className="border-b border-border hover:bg-muted/30 transition-colors">
                  <td className="py-3 px-4 font-body text-sm text-foreground">Taxa de Conclusão</td>
                  <td className="text-right py-3 px-4 font-body text-sm text-foreground font-semibold">
                    {Math.round(overallStats.completionRate)}%
                  </td>
                </tr>
                <tr className="border-b border-border hover:bg-muted/30 transition-colors">
                  <td className="py-3 px-4 font-body text-sm text-foreground">Concluídas Esta Semana</td>
                  <td className="text-right py-3 px-4 font-body text-sm text-foreground font-semibold">
                    {overallStats.tasksCompletedThisWeek}
                  </td>
                </tr>
                <tr className="border-b border-border hover:bg-muted/30 transition-colors">
                  <td className="py-3 px-4 font-body text-sm text-foreground">Concluídas Este Mês</td>
                  <td className="text-right py-3 px-4 font-body text-sm text-foreground font-semibold">
                    {overallStats.tasksCompletedThisMonth}
                  </td>
                </tr>
                <tr className="hover:bg-muted/30 transition-colors">
                  <td className="py-3 px-4 font-body text-sm text-foreground">Tendência de Produtividade</td>
                  <td className="text-right py-3 px-4 font-body text-sm text-foreground font-semibold">
                    <span
                      className={cn(
                        'px-2 py-1 rounded-full text-xs font-semibold',
                        overallStats.productivityTrend === 'up'
                          ? 'bg-[#4A7C59]/10 text-[#4A7C59]'
                          : overallStats.productivityTrend === 'down'
                            ? 'bg-[#C0533A]/10 text-[#C0533A]'
                            : 'bg-muted text-muted-foreground'
                      )}
                    >
                      {overallStats.productivityTrend === 'up'
                        ? '📈 Subindo'
                        : overallStats.productivityTrend === 'down'
                          ? '📉 Caindo'
                          : '➡️ Estável'}
                    </span>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  );
}
