import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/features/admin/models/finance/daily_revenue_model.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// Stacked bar chart showing ride, delivery, and b2b revenue by date.
class RevenueByTypeChart extends StatelessWidget {
  const RevenueByTypeChart({
    required this.data,
    super.key,
  });

  final List<DailyRevenueModel> data;

  static const Color _rideColor = Color(0xFF2563EB);
  static const Color _deliveryColor = Color(0xFF16A34A);
  static const Color _b2bColor = Color(0xFFF97316);

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

    final maxTotal = sortedData
        .map((e) => e.tripRevenue + e.deliveryRevenue)
        .reduce((a, b) => a > b ? a : b);
    final yMax = (maxTotal * 1.2).ceilToDouble();

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsetsDirectional.only(end: 16, top: 16),
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: yMax > 0 ? yMax : 100,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final entry = sortedData[group.x];
                      final label = DateFormat('d MMM').format(entry.date);
                      return BarTooltipItem(
                        '$label\n',
                        TextStyle(color: colors.surfaceElevated, fontSize: 12),
                        children: [
                          TextSpan(
                            text: '${'finance.ride'.tr}: '
                                '${entry.tripRevenue.toStringAsFixed(0)}\n',
                            style: const TextStyle(
                              color: _rideColor,
                              fontSize: 11,
                            ),
                          ),
                          TextSpan(
                            text: '${'finance.delivery'.tr}: '
                                '${entry.deliveryRevenue.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: _deliveryColor,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                gridData: FlGridData(
                  drawVerticalLine: false,
                  horizontalInterval: yMax > 0 ? yMax / 5 : 1,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: colors.borderSubtle,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(),
                  topTitles: const AxisTitles(),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) => Text(
                        _formatAmount(value),
                        style: TextStyle(
                          fontSize: 10,
                          color: colors.textMuted,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
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
                barGroups: sortedData.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.tripRevenue +
                            entry.value.deliveryRevenue,
                        width: sortedData.length > 14 ? 8 : 16,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                        rodStackItems: [
                          BarChartRodStackItem(
                            0,
                            entry.value.tripRevenue,
                            _rideColor,
                          ),
                          BarChartRodStackItem(
                            entry.value.tripRevenue,
                            entry.value.tripRevenue +
                                entry.value.deliveryRevenue,
                            _deliveryColor,
                          ),
                        ],
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _legendDot(_rideColor, 'finance.ride'.tr, theme, colors),
            const SizedBox(width: 16),
            _legendDot(_deliveryColor, 'finance.delivery'.tr, theme, colors),
            const SizedBox(width: 16),
            _legendDot(_b2bColor, 'finance.b2b'.tr, theme, colors),
          ],
        ),
      ],
    );
  }

  Widget _legendDot(
    Color color,
    String label,
    ThemeData theme,
    AppColorsExtension colors,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(color: colors.textMuted),
        ),
      ],
    );
  }

  String _formatAmount(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toStringAsFixed(0);
  }
}
