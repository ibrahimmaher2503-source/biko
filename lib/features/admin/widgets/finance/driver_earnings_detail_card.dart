import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_card.dart';
import 'package:biko/features/admin/models/finance/driver_earnings_report_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Detailed earnings breakdown card for a single driver.
class DriverEarningsDetailCard extends StatelessWidget {
  const DriverEarningsDetailCard({
    required this.data,
    super.key,
  });

  final DriverEarningsReportModel data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.primary.withValues(
                  alpha: 0.1,
                ),
                child: Icon(
                  Icons.person_rounded,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.driverName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${data.totalTrips} ${'finance.trips'.tr}',
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'finance.net'.tr,
                    style: TextStyle(fontSize: 11, color: colors.textMuted),
                  ),
                  Text(
                    '${data.netEarnings.toStringAsFixed(0)} '
                    '${'common.egp'.tr}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.success,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: colors.borderSubtle, height: 1),
          const SizedBox(height: 16),
          _row(
            theme,
            colors,
            label: 'finance.gross'.tr,
            value: data.grossEarnings,
          ),
          _row(
            theme,
            colors,
            label: 'finance.commission'.tr,
            value: -data.commission,
            isNegative: true,
          ),
          _row(
            theme,
            colors,
            label: 'finance.tips'.tr,
            value: data.tips,
          ),
          _row(
            theme,
            colors,
            label: 'finance.bonuses'.tr,
            value: data.bonuses,
          ),
          const SizedBox(height: 8),
          Divider(color: colors.border, height: 1),
          const SizedBox(height: 8),
          _row(
            theme,
            colors,
            label: 'finance.avg_per_trip'.tr,
            value: data.avgPerTrip,
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _row(
    ThemeData theme,
    AppColorsExtension colors, {
    required String label,
    required double value,
    bool isNegative = false,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.textMuted,
              fontWeight: isBold ? FontWeight.w600 : null,
            ),
          ),
          Text(
            '${value < 0 ? '-' : ''}${value.abs().toStringAsFixed(0)} '
            '${'common.egp'.tr}',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: isNegative ? theme.colorScheme.error : null,
            ),
          ),
        ],
      ),
    );
  }
}
