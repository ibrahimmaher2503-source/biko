import 'package:biko/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Banner shown after 60 seconds with no bids, suggesting to raise the offer.
class SearchTimeoutWidget extends StatelessWidget {
  const SearchTimeoutWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.warningBg,
        borderRadius: BorderRadius.circular(AppTheme.radiusDefault),
        border: Border.all(color: colors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.access_time, size: 20, color: colors.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'bids.raise_offer'.tr,
              style: theme.textTheme.bodySmall?.copyWith(color: colors.warning),
            ),
          ),
        ],
      ),
    );
  }
}
