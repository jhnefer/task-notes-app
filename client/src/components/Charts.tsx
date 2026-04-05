/**
 * Chart components for analytics and reports
 * Design: Warm Paper Notebook
 */

import {
  LineChart,
  Line,
  BarChart,
  Bar,
  PieChart,
  Pie,
  Cell,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
} from 'recharts';
import { DailyStats, WeeklyStats, MonthlyStats, PriorityStats, CategoryStats } from '@/lib/analytics';

const COLORS = {
  done: '#4A7C59',
  pending: '#B45309',
  inProgress: '#C0533A',
  high: '#C0533A',
  medium: '#B45309',
  low: '#4A7C59',
};

interface ChartProps {
  height?: number;
  className?: string;
}

/**
 * Daily tasks chart (line chart)
 */
export function DailyTasksChart({ data, height = 300, className = '' }: ChartProps & { data: DailyStats[] }) {
  return (
    <div className={className}>
      <ResponsiveContainer width="100%" height={height}>
        <LineChart data={data} margin={{ top: 5, right: 30, left: 0, bottom: 5 }}>
          <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
          <XAxis
            dataKey="date"
            tick={{ fontSize: 12 }}
            stroke="#9ca3af"
          />
          <YAxis tick={{ fontSize: 12 }} stroke="#9ca3af" />
          <Tooltip
            contentStyle={{
              backgroundColor: '#fff',
              border: '1px solid #e5e7eb',
              borderRadius: '6px',
            }}
            labelStyle={{ color: '#333' }}
          />
          <Legend />
          <Line
            type="monotone"
            dataKey="completed"
            stroke={COLORS.done}
            strokeWidth={2}
            name="Concluídas"
            dot={false}
          />
          <Line
            type="monotone"
            dataKey="pending"
            stroke={COLORS.pending}
            strokeWidth={2}
            name="Pendentes"
            dot={false}
          />
          <Line
            type="monotone"
            dataKey="inProgress"
            stroke={COLORS.inProgress}
            strokeWidth={2}
            name="Em andamento"
            dot={false}
          />
        </LineChart>
      </ResponsiveContainer>
    </div>
  );
}

/**
 * Weekly tasks chart (bar chart)
 */
export function WeeklyTasksChart({ data, height = 300, className = '' }: ChartProps & { data: WeeklyStats[] }) {
  return (
    <div className={className}>
      <ResponsiveContainer width="100%" height={height}>
        <BarChart data={data} margin={{ top: 5, right: 30, left: 0, bottom: 5 }}>
          <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
          <XAxis
            dataKey="week"
            tick={{ fontSize: 12 }}
            stroke="#9ca3af"
            angle={-45}
            textAnchor="end"
            height={80}
          />
          <YAxis tick={{ fontSize: 12 }} stroke="#9ca3af" />
          <Tooltip
            contentStyle={{
              backgroundColor: '#fff',
              border: '1px solid #e5e7eb',
              borderRadius: '6px',
            }}
            labelStyle={{ color: '#333' }}
          />
          <Legend />
          <Bar dataKey="completed" fill={COLORS.done} name="Concluídas" />
          <Bar dataKey="pending" fill={COLORS.pending} name="Pendentes" />
          <Bar dataKey="inProgress" fill={COLORS.inProgress} name="Em andamento" />
        </BarChart>
      </ResponsiveContainer>
    </div>
  );
}

/**
 * Monthly tasks chart (bar chart)
 */
export function MonthlyTasksChart({ data, height = 300, className = '' }: ChartProps & { data: MonthlyStats[] }) {
  return (
    <div className={className}>
      <ResponsiveContainer width="100%" height={height}>
        <BarChart data={data} margin={{ top: 5, right: 30, left: 0, bottom: 5 }}>
          <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
          <XAxis
            dataKey="month"
            tick={{ fontSize: 12 }}
            stroke="#9ca3af"
            angle={-45}
            textAnchor="end"
            height={80}
          />
          <YAxis tick={{ fontSize: 12 }} stroke="#9ca3af" />
          <Tooltip
            contentStyle={{
              backgroundColor: '#fff',
              border: '1px solid #e5e7eb',
              borderRadius: '6px',
            }}
            labelStyle={{ color: '#333' }}
          />
          <Legend />
          <Bar dataKey="completed" fill={COLORS.done} name="Concluídas" />
          <Bar dataKey="pending" fill={COLORS.pending} name="Pendentes" />
          <Bar dataKey="inProgress" fill={COLORS.inProgress} name="Em andamento" />
        </BarChart>
      </ResponsiveContainer>
    </div>
  );
}

/**
 * Priority distribution chart (pie chart)
 */
export function PriorityChart({ data, height = 300, className = '' }: ChartProps & { data: PriorityStats[] }) {
  const chartData = data.map(item => ({
    name: item.priority === 'high' ? 'Alta' : item.priority === 'medium' ? 'Média' : 'Baixa',
    value: item.total,
    color: item.priority === 'high' ? COLORS.high : item.priority === 'medium' ? COLORS.medium : COLORS.low,
  }));

  return (
    <div className={className}>
      <ResponsiveContainer width="100%" height={height}>
        <PieChart>
          <Pie
            data={chartData}
            cx="50%"
            cy="50%"
            labelLine={false}
            label={({ name, value }) => `${name}: ${value}`}
            outerRadius={80}
            fill="#8884d8"
            dataKey="value"
          >
            {chartData.map((entry, index) => (
              <Cell key={`cell-${index}`} fill={entry.color} />
            ))}
          </Pie>
          <Tooltip
            contentStyle={{
              backgroundColor: '#fff',
              border: '1px solid #e5e7eb',
              borderRadius: '6px',
            }}
            labelStyle={{ color: '#333' }}
          />
        </PieChart>
      </ResponsiveContainer>
    </div>
  );
}

/**
 * Category completion rate chart (bar chart)
 */
export function CategoryCompletionChart({ data, height = 300, className = '' }: ChartProps & { data: CategoryStats[] }) {
  const chartData = data.filter(item => item.total > 0);

  return (
    <div className={className}>
      <ResponsiveContainer width="100%" height={height}>
        <BarChart
          data={chartData}
          margin={{ top: 5, right: 30, left: 0, bottom: 5 }}
          layout="vertical"
        >
          <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
          <XAxis type="number" tick={{ fontSize: 12 }} stroke="#9ca3af" />
          <YAxis
            dataKey="categoryName"
            type="category"
            tick={{ fontSize: 12 }}
            stroke="#9ca3af"
            width={100}
          />
          <Tooltip
            contentStyle={{
              backgroundColor: '#fff',
              border: '1px solid #e5e7eb',
              borderRadius: '6px',
            }}
            labelStyle={{ color: '#333' }}
            formatter={(value) => `${Math.round(value as number)}%`}
          />
          <Bar dataKey="completionRate" fill={COLORS.done} name="Taxa de Conclusão (%)" />
        </BarChart>
      </ResponsiveContainer>
    </div>
  );
}

/**
 * Completion rate gauge (simple visual)
 */
export function CompletionGauge({ rate, className = '' }: { rate: number; className?: string }) {
  const getColor = () => {
    if (rate >= 80) return '#4A7C59';
    if (rate >= 60) return '#B45309';
    if (rate >= 40) return '#C0533A';
    return '#999';
  };

  return (
    <div className={`flex flex-col items-center ${className}`}>
      <div className="relative w-32 h-32 rounded-full border-8 border-muted flex items-center justify-center" style={{ borderColor: '#e5e7eb' }}>
        <div
          className="absolute w-32 h-32 rounded-full flex items-center justify-center"
          style={{
            background: `conic-gradient(${getColor()} 0deg ${(rate / 100) * 360}deg, #e5e7eb ${(rate / 100) * 360}deg 360deg)`,
          }}
        >
          <div className="w-28 h-28 rounded-full bg-background flex items-center justify-center">
            <div className="text-center">
              <div className="font-display text-3xl font-bold text-foreground">{Math.round(rate)}%</div>
              <div className="font-body text-xs text-muted-foreground">Conclusão</div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
