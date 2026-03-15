import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Card showing this week's total earnings summary.
///
/// Matches stitch design: section header with tinted icon,
/// large prominent amount, and subtle trending indicator.
class EarningsSummaryCard extends StatelessWidget {
  const EarningsSummaryCard({required this.weeklyEarnings, super.key});

  final double weeklyEarnings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = theme.extension<AppColorsExtension>()!;

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: ext.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(
                      AppTheme.radiusLarge,
                    ),
                  ),
                  child: Icon(
                    Icons.trending_up_rounded,
                    color: ext.success,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'driver_home.weekly_earnings'.tr,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                // Trend badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: ext.successBg,
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.trending_up, color: ext.success, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'driver_home.this_week'.tr,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: ext.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Large amount
            Text(
              '${weeklyEarnings.toStringAsFixed(0)} ${'common.egp'.tr}',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: ext.success,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
