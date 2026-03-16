import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/features/admin/models/finance/payment_success_model.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Bar chart showing payment success rate per method.
class PaymentSuccessChart extends StatelessWidget {
  const PaymentSuccessChart({
    required this.data,
    super.key,
  });

  final List<PaymentSuccessModel> data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;

    if (data.isEmpty) {
      return Center(
        child: Text(
          'admin.finance.no_payment_data'.tr,
          style: TextStyle(color: colors.textMuted),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 16, top: 16),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 100,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final entry = data[group.x];
                return BarTooltipItem(
                  '${entry.method}\n',
                  TextStyle(color: colors.surfaceElevated, fontSize: 12),
                  children: [
                    TextSpan(
                      text: '${entry.successRate.toStringAsFixed(1)}% '
                          '${'admin.finance.success_rate'.tr}\n',
                      style: TextStyle(
                        color: colors.success,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(
                      text: '${entry.successCount}/${entry.totalAttempts}',
                      style: const TextStyle(fontSize: 10),
                    ),
                  ],
                );
              },
            ),
          ),
          gridData: FlGridData(
            drawVerticalLine: false,
            horizontalInterval: 20,
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
                reservedSize: 40,
                interval: 20,
                getTitlesWidget: (value, meta) => Text(
                  '${value.toInt()}%',
                  style: TextStyle(fontSize: 10, color: colors.textMuted),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= data.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      data[index].method,
                      style: TextStyle(
                        fontSize: 10,
                        color: colors.textMuted,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: data.asMap().entries.map((entry) {
            final rate = entry.value.successRate;
            final barColor = rate >= 90
                ? colors.success
                : rate >= 70
                    ? colors.warning
                    : theme.colorScheme.error;

            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: rate,
                  width: 28,
                  color: barColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
