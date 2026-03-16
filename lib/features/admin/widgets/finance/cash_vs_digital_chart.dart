import 'package:biko/core/theme/app_theme.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// Line chart comparing cash vs digital payment trends over time.
class CashVsDigitalChart extends StatelessWidget {
  const CashVsDigitalChart({
    required this.data,
    super.key,
  });

  /// Each map should contain 'date' (DateTime), 'cash' (num), 'digital' (num).
  final List<Map<String, dynamic>> data;

  static const Color _cashColor = Color(0xFFF97316);
  static const Color _digitalColor = Color(0xFF2563EB);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;

    if (data.isEmpty) {
      return Center(
        child: Text(
          'finance.no_payment_data'.tr,
          style: TextStyle(color: colors.textMuted),
        ),
      );
    }

    final sortedData = List<Map<String, dynamic>>.from(data)
      ..sort((a, b) {
        final dateA = a['date'] as DateTime;
        final dateB = b['date'] as DateTime;
        return dateA.compareTo(dateB);
      });

    final allValues = sortedData.expand((e) {
      final cash = (e['cash'] as num?)?.toDouble() ?? 0;
      final digital = (e['digital'] as num?)?.toDouble() ?? 0;
      return [cash, digital];
    });
    final maxVal = allValues.isEmpty
        ? 100.0
        : allValues.reduce((a, b) => a > b ? a : b);
    final yMax = (maxVal * 1.2).ceilToDouble();

    return Column(
      children: [
        Expanded(
          child: Padding(
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
                      interval: _calculateInterval(sortedData.length),
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= sortedData.length) {
                          return const SizedBox.shrink();
                        }
                        final date =
                            sortedData[index]['date'] as DateTime;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            DateFormat('d/M').format(date),
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
                  _buildLine(sortedData, 'cash', _cashColor),
                  _buildLine(sortedData, 'digital', _digitalColor),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final isCash = spot.barIndex == 0;
                        return LineTooltipItem(
                          '${isCash ? 'finance.cash'.tr : 'finance.digital'.tr}'
                          '\n${spot.y.toStringAsFixed(0)} ${'common.egp'.tr}',
                          TextStyle(
                            color: isCash ? _cashColor : _digitalColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _legendDot(_cashColor, 'finance.cash'.tr, theme, colors),
            const SizedBox(width: 24),
            _legendDot(_digitalColor, 'finance.digital'.tr, theme, colors),
          ],
        ),
      ],
    );
  }

  LineChartBarData _buildLine(
    List<Map<String, dynamic>> sortedData,
    String key,
    Color color,
  ) {
    return LineChartBarData(
      spots: sortedData.asMap().entries.map((entry) {
        final value = (entry.value[key] as num?)?.toDouble() ?? 0;
        return FlSpot(entry.key.toDouble(), value);
      }).toList(),
      isCurved: true,
      curveSmoothness: 0.3,
      color: color,
      barWidth: 2.5,
      isStrokeCapRound: true,
      dotData: FlDotData(show: sortedData.length <= 14),
      belowBarData: BarAreaData(
        show: true,
        color: color.withValues(alpha: 0.08),
      ),
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

  double _calculateInterval(int length) {
    if (length <= 7) return 1;
    if (length <= 14) return 2;
    if (length <= 30) return 5;
    return (length / 6).roundToDouble();
  }
}
