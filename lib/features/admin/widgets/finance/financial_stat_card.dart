import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Stat card for financial dashboards showing a title, value,
/// optional percent change indicator, and icon.
class FinancialStatCard extends StatelessWidget {
  const FinancialStatCard({
    required this.title,
    required this.value,
    required this.icon,
    super.key,
    this.changePercent,
    this.color,
    this.onTap,
  });

  final String title;
  final String value;
  final double? changePercent;
  final IconData icon;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;
    final effectiveColor = color ?? theme.colorScheme.primary;

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: effectiveColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(
                    AppTheme.radiusDefault,
                  ),
                ),
                child: Icon(icon, color: effectiveColor, size: 22),
              ),
              const Spacer(),
              if (changePercent != null) _buildChangeIndicator(colors),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title.tr,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.textMuted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChangeIndicator(AppColorsExtension colors) {
    final isPositive = changePercent! >= 0;
    final changeColor = isPositive ? colors.success : const Color(0xFFEF4444);
    final arrow = isPositive ? Icons.arrow_upward : Icons.arrow_downward;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: changeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(arrow, size: 14, color: changeColor),
          const SizedBox(width: 2),
          Text(
            '${changePercent!.abs().toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: changeColor,
            ),
          ),
        ],
      ),
    );
  }
}
