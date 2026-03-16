import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Card showing projected revenue vs current revenue with a trend arrow.
class RevenueForecastCard extends StatelessWidget {
  const RevenueForecastCard({
    required this.projectedRevenue,
    required this.currentRevenue,
    super.key,
  });

  final double projectedRevenue;
  final double currentRevenue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;
    final isOnTrack = currentRevenue >= projectedRevenue * 0.8;
    final trendColor = isOnTrack ? colors.success : colors.warning;
    final trendIcon = isOnTrack
        ? Icons.trending_up_rounded
        : Icons.trending_down_rounded;
    final progress = projectedRevenue > 0
        ? (currentRevenue / projectedRevenue).clamp(0.0, 1.0)
        : 0.0;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_graph_rounded, color: colors.info, size: 20),
              const SizedBox(width: 8),
              Text(
                'admin.finance.revenue_forecast'.tr,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Icon(trendIcon, color: trendColor, size: 24),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'admin.finance.projected'.tr,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${projectedRevenue.toStringAsFixed(0)} '
                      '${'common.egp'.tr}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'admin.finance.current'.tr,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${currentRevenue.toStringAsFixed(0)} '
                      '${'common.egp'.tr}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: trendColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: colors.surfaceContainer,
              valueColor: AlwaysStoppedAnimation<Color>(trendColor),
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Text(
              '${(progress * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 11,
                color: colors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
