import 'package:biko/core/theme/app_theme.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Pie chart showing distribution of top-up methods.
class TopUpMethodsChart extends StatelessWidget {
  const TopUpMethodsChart({
    required this.methodData,
    super.key,
  });

  final Map<String, double> methodData;

  static const List<Color> _chartColors = [
    Color(0xFF2563EB),
    Color(0xFF16A34A),
    Color(0xFFF97316),
    Color(0xFFEF4444),
    Color(0xFF8B5CF6),
    Color(0xFF06B6D4),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;

    if (methodData.isEmpty) {
      return Center(
        child: Text(
          'admin.finance.no_top_up_data'.tr,
          style: TextStyle(color: colors.textMuted),
        ),
      );
    }

    final total = methodData.values.fold<double>(0, (a, b) => a + b);
    final entries = methodData.entries.toList();

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: entries.asMap().entries.map((mapEntry) {
                final index = mapEntry.key;
                final entry = mapEntry.value;
                final percentage = total > 0
                    ? (entry.value / total * 100)
                    : 0.0;
                final colorIndex = index % _chartColors.length;

                return PieChartSectionData(
                  color: _chartColors[colorIndex],
                  value: entry.value,
                  title: '${percentage.toStringAsFixed(1)}%',
                  radius: 50,
                  titleStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: entries.asMap().entries.map((mapEntry) {
            final colorIndex = mapEntry.key % _chartColors.length;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _chartColors[colorIndex],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  mapEntry.value.key,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.textMuted,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}
