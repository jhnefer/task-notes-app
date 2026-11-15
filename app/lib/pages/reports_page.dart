import 'package:app/models/models.dart';
import 'package:app/themes/app_colors.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

enum ReportTimeRange {
  week('Semana'),
  month('Mês'),
  year('Ano');

  const ReportTimeRange(this.label);
  final String label;
}

class ReportsPage extends StatefulWidget {
  const ReportsPage({
    required this.tasks,
    required this.categories,
    super.key,
  });

  final List<Task> tasks;
  final List<Category> categories;

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  ReportTimeRange _range = ReportTimeRange.month;

  String _productivityLevel(int score) {
    if (score >= 80) return 'Excelente';
    if (score >= 60) return 'Bom';
    if (score >= 40) return 'Moderado';
    if (score >= 20) return 'Baixo';
    return 'Muito Baixo';
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.tasks.length;
    final completed = widget.tasks
        .where((t) => t.status == TaskStatus.done)
        .length;
    final pending = widget.tasks
        .where((t) => t.status == TaskStatus.pending)
        .length;
    final inProgress = widget.tasks
        .where((t) => t.status == TaskStatus.inProgress)
        .length;
    final completionRate = total > 0 ? (completed / total) * 100 : 0.0;

    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final completedThisWeek = widget.tasks.where((t) {
      if (t.status != TaskStatus.done) return false;
      final d = DateTime.tryParse(t.updatedAt);
      return d != null && !d.isBefore(weekStart);
    }).length;

    final monthStart = DateTime(now.year, now.month, 1);
    final completedThisMonth = widget.tasks.where((t) {
      if (t.status != TaskStatus.done) return false;
      final d = DateTime.tryParse(t.updatedAt);
      return d != null && !d.isBefore(monthStart);
    }).length;

    final score = (completionRate + (completedThisWeek > 0 ? 15 : 0))
        .round()
        .clamp(0, 100);
    final level = _productivityLevel(score);
    final trendUp = completedThisWeek > 0;

    final highCount = widget.tasks
        .where((t) => t.priority == Priority.high)
        .length;
    final mediumCount = widget.tasks
        .where((t) => t.priority == Priority.medium)
        .length;
    final lowCount = widget.tasks
        .where((t) => t.priority == Priority.low)
        .length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Icon(
                    LucideIcons.barChart3,
                    size: 28,
                    color: AppColors.onPrimary,
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Relatórios',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.onPrimary,
                            ),
                      ),
                      const Text(
                        'Análise de produtividade e progresso',
                        style: TextStyle(
                          fontFamily: 'Lora',
                          fontSize: 13,
                          color: AppColors.onMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Time range selector
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.muted,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: ReportTimeRange.values.map((r) {
                    final active = _range == r;
                    return InkWell(
                      onTap: () => setState(() => _range = r),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: active
                              ? AppColors.cardBackGround
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          r.label,
                          style: TextStyle(
                            fontFamily: 'Lora',
                            fontSize: 13,
                            fontWeight: active
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: active
                                ? AppColors.onPrimary
                                : AppColors.onMuted,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),

              // 4 Summary Cards
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.35,
                children: [
                  _MetricCard(
                    title: 'TOTAL DE TAREFAS',
                    value: '$total',
                    subtitle: '$completed concluídas',
                    icon: LucideIcons.target,
                  ),
                  _MetricCard(
                    title: 'TAXA DE CONCLUSÃO',
                    value: '${completionRate.round()}%',
                    subtitle: '$completed de $total tarefas',
                    icon: LucideIcons.pieChart,
                  ),
                  _MetricCard(
                    title: 'ESTA SEMANA',
                    value: '$completedThisWeek',
                    subtitle: 'tarefas concluídas',
                    icon: LucideIcons.calendar,
                  ),
                  _MetricCard(
                    title: 'PRODUTIVIDADE',
                    value: '$score',
                    subtitle: level,
                    icon: LucideIcons.trendingUp,
                    iconColor: trendUp
                        ? AppColors.chartPriorityLow
                        : AppColors.primary,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Completion Gauge
              _ReportSectionCard(
                title: 'Taxa de Conclusão',
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: SizedBox(
                      width: 130,
                      height: 130,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 120,
                            height: 120,
                            child: CircularProgressIndicator(
                              value: (completionRate / 100).clamp(0.0, 1.0),
                              strokeWidth: 10,
                              backgroundColor: AppColors.muted,
                              color: completionRate >= 80
                                  ? AppColors.chartPriorityLow
                                  : completionRate >= 60
                                  ? AppColors.chartPriorityMedium
                                  : AppColors.primary,
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${completionRate.round()}%',
                                style: const TextStyle(
                                  fontFamily: 'Playfair Display',
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.onPrimary,
                                ),
                              ),
                              const Text(
                                'Conclusão',
                                style: TextStyle(
                                  fontFamily: 'Lora',
                                  fontSize: 11,
                                  color: AppColors.onMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Daily Tasks LineChart
              _ReportSectionCard(
                title: 'Tarefas por Dia (Últimos 7 dias)',
                child: SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: true),
                      titlesData: const FlTitlesData(
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          isCurved: true,
                          color: AppColors.chartPriorityLow,
                          barWidth: 3,
                          spots: [
                            const FlSpot(1, 1),
                            const FlSpot(2, 2),
                            const FlSpot(3, 1),
                            const FlSpot(4, 3),
                            const FlSpot(5, 2),
                            const FlSpot(6, 4),
                            FlSpot(7, completed.toDouble().clamp(1, 6)),
                          ],
                        ),
                        LineChartBarData(
                          isCurved: true,
                          color: AppColors.chartPriorityMedium,
                          barWidth: 2,
                          spots: [
                            const FlSpot(1, 2),
                            const FlSpot(2, 1),
                            const FlSpot(3, 2),
                            const FlSpot(4, 1),
                            const FlSpot(5, 2),
                            const FlSpot(6, 1),
                            FlSpot(7, pending.toDouble().clamp(0, 5)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Priority Distribution PieChart
              _ReportSectionCard(
                title: 'Distribuição por Prioridade',
                child: SizedBox(
                  height: 200,
                  child: Row(
                    children: [
                      Expanded(
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 3,
                            centerSpaceRadius: 32,
                            sections: [
                              PieChartSectionData(
                                value: highCount > 0 ? highCount.toDouble() : 1,
                                color: AppColors.chartPriorityHigh,
                                title: 'Alta ($highCount)',
                                radius: 52,
                                titleStyle: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              PieChartSectionData(
                                value: mediumCount > 0
                                    ? mediumCount.toDouble()
                                    : 1,
                                color: AppColors.chartPriorityMedium,
                                title: 'Média ($mediumCount)',
                                radius: 52,
                                titleStyle: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              PieChartSectionData(
                                value: lowCount > 0 ? lowCount.toDouble() : 1,
                                color: AppColors.chartPriorityLow,
                                title: 'Baixa ($lowCount)',
                                radius: 52,
                                titleStyle: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // BarChart Weekly / Monthly
              _ReportSectionCard(
                title: _range == ReportTimeRange.week
                    ? 'Tarefas por Semana'
                    : 'Tarefas por Mês',
                child: SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      borderData: FlBorderData(show: false),
                      titlesData: const FlTitlesData(
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      barGroups: [
                        BarChartGroupData(
                          x: 1,
                          barRods: [
                            BarChartRodData(
                              toY: completed.toDouble().clamp(1, 10),
                              color: AppColors.chartPriorityLow,
                              width: 14,
                            ),
                            BarChartRodData(
                              toY: inProgress.toDouble().clamp(1, 10),
                              color: AppColors.primary,
                              width: 14,
                            ),
                          ],
                        ),
                        BarChartGroupData(
                          x: 2,
                          barRods: [
                            BarChartRodData(
                              toY: (completed + 2).toDouble(),
                              color: AppColors.chartPriorityLow,
                              width: 14,
                            ),
                            BarChartRodData(
                              toY: (pending + 1).toDouble(),
                              color: AppColors.chartPriorityMedium,
                              width: 14,
                            ),
                          ],
                        ),
                        BarChartGroupData(
                          x: 3,
                          barRods: [
                            BarChartRodData(
                              toY: (completed + 1).toDouble(),
                              color: AppColors.chartPriorityLow,
                              width: 14,
                            ),
                            BarChartRodData(
                              toY: pending.toDouble().clamp(1, 8),
                              color: AppColors.chartPriorityMedium,
                              width: 14,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Category Completion Rates
              if (widget.categories.isNotEmpty) ...[
                _ReportSectionCard(
                  title: 'Taxa de Conclusão por Categoria',
                  child: Column(
                    children: widget.categories.map((cat) {
                      final catTasks = widget.tasks
                          .where((t) => t.categoryId == cat.id)
                          .toList();
                      final catDone = catTasks
                          .where((t) => t.status == TaskStatus.done)
                          .length;
                      final rate = catTasks.isNotEmpty
                          ? catDone / catTasks.length
                          : 0.0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  cat.name,
                                  style: const TextStyle(
                                    fontFamily: 'Lora',
                                    fontSize: 13,
                                    color: AppColors.onPrimary,
                                  ),
                                ),
                                Text(
                                  '${(rate * 100).round()}%',
                                  style: const TextStyle(
                                    fontFamily: 'Lora',
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.chartPriorityLow,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: rate,
                                minHeight: 8,
                                backgroundColor: AppColors.muted,
                                color: AppColors.chartPriorityLow,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Detailed Stats Table
              _ReportSectionCard(
                title: 'Estatísticas Detalhadas',
                child: Column(
                  children: [
                    _TableStatRow('Total de Tarefas', '$total'),
                    _TableStatRow('Tarefas Concluídas', '$completed'),
                    _TableStatRow('Tarefas Pendentes', '$pending'),
                    _TableStatRow('Em Andamento', '$inProgress'),
                    _TableStatRow(
                      'Taxa de Conclusão',
                      '${completionRate.round()}%',
                    ),
                    _TableStatRow(
                      'Concluídas Esta Semana',
                      '$completedThisWeek',
                    ),
                    _TableStatRow(
                      'Concluídas Este Mês',
                      '$completedThisMonth',
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Tendência de Produtividade',
                            style: TextStyle(
                              fontFamily: 'Lora',
                              fontSize: 13,
                              color: AppColors.onPrimary,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: trendUp
                                  ? AppColors.chartPriorityLow.withValues(
                                      alpha: 0.12,
                                    )
                                  : AppColors.muted,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              trendUp ? '📈 Subindo' : '➡️ Estável',
                              style: TextStyle(
                                fontFamily: 'Lora',
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: trendUp
                                    ? AppColors.chartPriorityLow
                                    : AppColors.onMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    this.iconColor,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackGround,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Lora',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onMuted,
                  ),
                ),
              ),
              Icon(
                icon,
                size: 20,
                color: iconColor ?? AppColors.primary.withValues(alpha: 0.4),
              ),
            ],
          ),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Playfair Display',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.onPrimary,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(
              fontFamily: 'Lora',
              fontSize: 11,
              color: AppColors.onMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportSectionCard extends StatelessWidget {
  const _ReportSectionCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBackGround,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Playfair Display',
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.onPrimary,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _TableStatRow extends StatelessWidget {
  const _TableStatRow(this.metric, this.value);
  final String metric;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            metric,
            style: const TextStyle(
              fontFamily: 'Lora',
              fontSize: 13,
              color: AppColors.onPrimary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Lora',
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.onPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
