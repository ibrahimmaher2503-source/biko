import 'package:biko/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Displays "Recommended Fare" label on the left and
/// a red-outlined "Fair Price: EGP XX" badge on the right.
///
/// Matches the stitch design with the trending-up icon
/// inside the badge.
class FareBadge extends StatelessWidget {
  const FareBadge({required this.price, super.key});

  final int price;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: "Recommended Fare" label
          Text(
            'trip.recommended_fare'.tr,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.textMuted,
              decoration: TextDecoration.underline,
              decorationColor: colors.textMuted,
            ),
          ),

          // Right: "Fair Price: EGP XX" badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              border: Border.all(color: AppTheme.primary),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.trending_up,
                  color: AppTheme.primary,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  'trip.fair_price'.trParams({'price': price.toString()}),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
