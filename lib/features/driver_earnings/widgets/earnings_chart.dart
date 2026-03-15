import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_card.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Bar chart showing daily earnings for the selected period.
///
/// Matches stitch design: rounded bars with primary color,
/// subtle grid, and clean axis labels.
class EarningsChart extends StatelessWidget {
  const EarningsChart({required this.data, required this.labels, super.key});

  final List<double> data;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = theme.extension<AppColorsExtension>()!;
    final maxY =
        data.isEmpty ? 100.0 : data.reduce((a, b) => a > b ? a : b) * 1.3;

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  maxY: maxY == 0 ? 100 : maxY,
                  barGroups: List.generate(
                    data.length,
                    (index) => BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: data[index],
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              AppTheme.primary,
                              AppTheme.primary.withValues(alpha: 0.7),
                            ],
                          ),
                          width: data.length > 15 ? 8 : 20,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6),
                          ),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: maxY == 0 ? 100 : maxY,
                            color: ext.surfaceContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(),
                    topTitles: const AxisTitles(),
                    rightTitles: const AxisTitles(),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx >= 0 && idx < labels.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                labels[idx],
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: ext.textMuted,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIdx, rod, rodIdx) {
                        return BarTooltipItem(
                          '${rod.toY.toStringAsFixed(0)} EGP',
                          theme.textTheme.labelSmall!.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
