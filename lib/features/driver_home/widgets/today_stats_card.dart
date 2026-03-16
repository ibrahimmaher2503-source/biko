import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Card showing today's trip count and earnings.
///
/// Matches stitch design: section header with icon,
/// stat items in tinted circle containers with divider.
class TodayStatsCard extends StatelessWidget {
  const TodayStatsCard({
    required this.tripCount,
    required this.totalEarned,
    super.key,
  });

  final int tripCount;
  final double totalEarned;

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
            // Section header with icon
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(
                      AppTheme.radiusLarge,
                    ),
                  ),
                  child: const Icon(
                    Icons.bar_chart_rounded,
                    color: AppTheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'driver_home.today_stats'.tr,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Stats row
            Row(
              children: [
                // Trip count
                Expanded(
                  child: _StatItem(
                    icon: Icons.two_wheeler,
                    iconColor: AppTheme.primary,
                    label: 'driver_home.trips'.tr,
                    value: '$tripCount',
                  ),
                ),
                // Vertical divider
                Container(
                  width: 1,
                  height: 56,
                  color: ext.borderSubtle,
                ),
                // Earnings
                Expanded(
                  child: _StatItem(
                    icon: Icons.payments_outlined,
                    iconColor: ext.success,
                    label: 'driver_home.earned'.tr,
                    value:
                        '${totalEarned.toStringAsFixed(0)} ${'common.egp'.tr}',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = theme.extension<AppColorsExtension>()!;

    return Column(
      children: [
        // Icon in tinted circle
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        const SizedBox(height: 10),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: ext.textMuted,
          ),
        ),
      ],
    );
  }
}
