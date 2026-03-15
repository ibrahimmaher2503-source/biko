import 'package:biko/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Row of 24 colored containers representing hourly revenue.
/// Darker color intensity means higher revenue. Tooltip on hover.
class HourlyHeatmap extends StatelessWidget {
  const HourlyHeatmap({
    required this.hourlyData,
    super.key,
  });

  final Map<int, double> hourlyData;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;

    final maxValue = hourlyData.values.isEmpty
        ? 1.0
        : hourlyData.values.reduce((a, b) => a > b ? a : b);
    final effectiveMax = maxValue > 0 ? maxValue : 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(24, (hour) {
            final value = hourlyData[hour] ?? 0.0;
            final intensity = (value / effectiveMax).clamp(0.0, 1.0);

            return Expanded(
              child: Tooltip(
                message: '${'finance.hour'.tr} $hour:00\n'
                    '${value.toStringAsFixed(0)} ${'common.egp'.tr}',
                child: Container(
                  height: 36,
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(
                      alpha: 0.1 + (intensity * 0.8),
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '0:00',
              style: TextStyle(fontSize: 10, color: colors.textMuted),
            ),
            Text(
              '6:00',
              style: TextStyle(fontSize: 10, color: colors.textMuted),
            ),
            Text(
              '12:00',
              style: TextStyle(fontSize: 10, color: colors.textMuted),
            ),
            Text(
              '18:00',
              style: TextStyle(fontSize: 10, color: colors.textMuted),
            ),
            Text(
              '23:00',
              style: TextStyle(fontSize: 10, color: colors.textMuted),
            ),
          ],
        ),
      ],
    );
  }
}
