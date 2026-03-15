import 'package:biko/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Two-column leaderboard showing top drivers and top customers by amount.
class FinancialLeaderboard extends StatelessWidget {
  const FinancialLeaderboard({
    required this.topDrivers,
    required this.topCustomers,
    super.key,
  });

  final List<Map<String, dynamic>> topDrivers;
  final List<Map<String, dynamic>> topCustomers;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildColumn(
            context,
            title: 'finance.top_drivers'.tr,
            items: topDrivers,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildColumn(
            context,
            title: 'finance.top_customers'.tr,
            items: topCustomers,
          ),
        ),
      ],
    );
  }

  Widget _buildColumn(
    BuildContext context, {
    required String title,
    required List<Map<String, dynamic>> items,
  }) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'common.no_data'.tr,
              style: TextStyle(color: colors.textMuted, fontSize: 13),
            ),
          )
        else
          ...items.asMap().entries.map((entry) {
            final rank = entry.key + 1;
            final item = entry.value;
            final name = item['name'] as String? ?? '';
            final amount = item['amount'] as num? ?? 0;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    child: Text(
                      '$rank.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: rank <= 3
                            ? theme.colorScheme.primary
                            : colors.textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      name,
                      style: theme.textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  Text(
                    '${amount.toStringAsFixed(0)} ${'common.egp'.tr}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}
