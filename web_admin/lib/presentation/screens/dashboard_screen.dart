import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_models/shared_models.dart';

import '../providers.dart';
import '../widgets/common.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);

    return dashboardAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text('$e', style: const TextStyle(color: UniHubColors.textSecondary)),
      ),
      data: (d) {
        final checkinDelta = _deltaLabel(d.monthCheckins, d.prevMonthCheckins);
        final revenueDelta = _deltaLabel(d.estimatedRevenue, d.prevMonthRevenue);

        return RefreshIndicator(
          color: UniHubColors.accent,
          onRefresh: () async => ref.invalidate(dashboardProvider),
          child: ListView(
            padding: const EdgeInsets.all(UniHubSpacing.x8),
            children: [
              PageTitle(
                'Dashboard',
                subtitle: 'Visão do mês corrente',
                action: IconButton(
                  onPressed: () => ref.invalidate(dashboardProvider),
                  icon: const Icon(LucideIcons.refreshCw,
                      size: 18, color: UniHubColors.textSecondary),
                  tooltip: 'Atualizar',
                ),
              ),
              const SizedBox(height: UniHubSpacing.x8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: MetricBlock(
                      label: 'Check-ins no mês',
                      value: '${d.monthCheckins}',
                      detail: checkinDelta,
                    ),
                  ),
                  Expanded(
                    child: MetricBlock(
                      label: 'Alunos únicos',
                      value: '${d.uniqueStudents}',
                      detail: 'atendidos no mês',
                    ),
                  ),
                  Expanded(
                    child: MetricBlock(
                      label: 'Receita estimada de repasse',
                      value: formatBRL(d.estimatedRevenue),
                      detail: revenueDelta,
                      highlight: true,
                    ),
                  ),
                  Expanded(
                    child: MetricBlock(
                      label: 'Mês anterior',
                      value: formatBRL(d.prevMonthRevenue),
                      detail: '${d.prevMonthCheckins} check-ins',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: UniHubSpacing.x10),
              const Divider(),
              const SizedBox(height: UniHubSpacing.x8),
              const Text(
                'Check-ins por dia — últimos 30 dias',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: UniHubSpacing.x6),
              SizedBox(height: 220, child: _DailyChart(data: d.checkinsByDay)),
              const SizedBox(height: UniHubSpacing.x10),
              const Divider(),
              const SizedBox(height: UniHubSpacing.x8),
              const Text(
                'Check-ins por faixa de horário — onde a capacidade ociosa é preenchida',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: UniHubSpacing.x6),
              SizedBox(height: 220, child: _HourRangeChart(data: d.checkinsByHourRange)),
            ],
          ),
        );
      },
    );
  }

  String _deltaLabel(num current, num previous) {
    if (previous == 0) return 'sem base de comparação';
    final pct = ((current - previous) / previous * 100).round();
    return pct >= 0 ? '+$pct% vs. mês anterior' : '$pct% vs. mês anterior';
  }
}

/// Linha de check-ins diários: traço laranja fino, grade discreta.
class _DailyChart extends StatelessWidget {
  const _DailyChart({required this.data});

  final List<DailyCount> data;

  @override
  Widget build(BuildContext context) {
    final maxY = data.fold<int>(0, (m, d) => d.count > m ? d.count : m).toDouble() + 1;

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: UniHubColors.divider, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: maxY > 8 ? (maxY / 4).ceilToDouble() : 1,
              getTitlesWidget: (value, _) => Text(
                value.toInt().toString(),
                style: const TextStyle(fontSize: 11, color: UniHubColors.textSecondary),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 7,
              getTitlesWidget: (value, _) {
                final i = value.toInt();
                if (i < 0 || i >= data.length) return const SizedBox.shrink();
                final day = data[i].date.substring(8, 10);
                final month = data[i].date.substring(5, 7);
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '$day/$month',
                    style: const TextStyle(fontSize: 11, color: UniHubColors.textSecondary),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => UniHubColors.textPrimary,
            getTooltipItems: (spots) => spots
                .map((s) => LineTooltipItem(
                      '${data[s.x.toInt()].date.substring(8, 10)}/${data[s.x.toInt()].date.substring(5, 7)}: ${s.y.toInt()} check-ins',
                      const TextStyle(color: Colors.white, fontSize: 12),
                    ))
                .toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (final (i, d) in data.indexed) FlSpot(i.toDouble(), d.count.toDouble()),
            ],
            isCurved: false,
            color: UniHubColors.accent,
            barWidth: 2,
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );
  }
}

/// Barras por faixa de horário.
class _HourRangeChart extends StatelessWidget {
  const _HourRangeChart({required this.data});

  final List<HourRangeCount> data;

  @override
  Widget build(BuildContext context) {
    final maxCount = data.fold<int>(0, (m, d) => d.count > m ? d.count : m);
    final maxY = (maxCount + 2).toDouble();

    return BarChart(
      BarChartData(
        minY: 0,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: UniHubColors.divider, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: maxY > 8 ? (maxY / 4).ceilToDouble() : 1,
              getTitlesWidget: (value, _) => Text(
                value.toInt().toString(),
                style: const TextStyle(fontSize: 11, color: UniHubColors.textSecondary),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, _) {
                final i = value.toInt();
                if (i < 0 || i >= data.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    data[i].label,
                    style: const TextStyle(fontSize: 11, color: UniHubColors.textSecondary),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => UniHubColors.textPrimary,
            getTooltipItem: (group, _, rod, _) => BarTooltipItem(
              '${data[group.x].label}: ${rod.toY.toInt()} check-ins',
              const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ),
        barGroups: [
          for (final (i, d) in data.indexed)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: d.count.toDouble(),
                  width: 28,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                  // A barra de pico ganha o laranja; as demais ficam neutras
                  color: d.count == maxCount && maxCount > 0
                      ? UniHubColors.accent
                      : UniHubColors.border,
                ),
              ],
            ),
        ],
      ),
    );
  }
}
