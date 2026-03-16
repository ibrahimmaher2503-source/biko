import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/features/admin/models/finance/daily_revenue_model.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// Line chart showing revenue trend over time.
class RevenueChart extends StatelessWidget {
  const RevenueChart({
    required this.data,
    super.key,
  });

  final List<DailyRevenueModel> data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;

    if (data.isEmpty) {
      return Center(
        child: Text(
          'finance.no_revenue_data'.tr,
          style: TextStyle(color: colors.textMuted),
        ),
      );
    }

    final sortedData = List<DailyRevenueModel>.from(data)
      ..sort((a, b) => a.date.compareTo(b.date));

    final maxRevenue = sortedData
        .map((e) => e.totalRevenue)
        .reduce((a, b) => a > b ? a : b);
    final yMax = (maxRevenue * 1.2).ceilToDouble();

    return Padding(
      padding: const EdgeInsets.only(right: 16, top: 16),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            drawVerticalLine: false,
            horizontalInterval: yMax > 0 ? yMax / 5 : 1,
            getDrawingHorizontalLine: (value) => FlLine(
              color: colors.borderSubtle,
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(),
            topTitles: const AxisTitles(),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 56,
                getTitlesWidget: (value, meta) => Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: Text(
                    _formatAmount(value),
                    style: TextStyle(
                      fontSize: 10,
                      color: colors.textMuted,
                    ),
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: _calculateInterval(sortedData.length),
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= sortedData.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      DateFormat('d/M').format(sortedData[index].date),
                      style: TextStyle(
                        fontSize: 10,
                        color: colors.textMuted,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minY: 0,
          maxY: yMax > 0 ? yMax : 100,
          lineBarsData: [
            LineChartBarData(
              spots: sortedData.asMap().entries.map((entry) {
                return FlSpot(
                  entry.key.toDouble(),
                  entry.value.totalRevenue,
                );
              }).toList(),
              isCurved: true,
              curveSmoothness: 0.3,
              color: theme.colorScheme.primary,
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: sortedData.length <= 14,
                getDotPainter: (spot, percent, barData, index) =>
                    FlDotCirclePainter(
                  radius: 3,
                  color: theme.colorScheme.primary,
                  strokeWidth: 1.5,
                  strokeColor: colors.surfaceElevated,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final entry = sortedData[spot.x.toInt()];
                  return LineTooltipItem(
                    '${DateFormat('d MMM').format(entry.date)}\n',
                    TextStyle(
                      color: colors.surfaceElevated,
                      fontSize: 12,
                    ),
                    children: [
                      TextSpan(
                        text: '${entry.totalRevenue.toStringAsFixed(0)} '
                            '${'common.egp'.tr}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  String _formatAmount(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toStringAsFixed(0);
  }

  double _calculateInterval(int length) {
    if (length <= 7) return 1;
    if (length <= 14) return 2;
    if (length <= 30) return 5;
    return (length / 6).roundToDouble();
  }
}
