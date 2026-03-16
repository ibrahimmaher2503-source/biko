import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_card.dart';
import 'package:biko/features/admin/models/driver_earnings_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DriverEarningsCard extends StatelessWidget {
  const DriverEarningsCard({
    required this.earnings,
    super.key,
  });

  final DriverEarningsModel earnings;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    final theme = Theme.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'admin.drivers.earnings_summary'.tr,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          _EarningsRow(
            label: 'admin.drivers.gross_earnings'.tr,
            value: '${earnings.grossEarnings.toStringAsFixed(0)} '
                '${'common.egp'.tr}',
            color: colors.success,
          ),
          const Divider(height: 20),
          _EarningsRow(
            label: 'admin.drivers.commission'.tr,
            value:
                '-${earnings.commission.toStringAsFixed(0)} ${'common.egp'.tr}',
            color: theme.colorScheme.error,
          ),
          const Divider(height: 20),
          _EarningsRow(
            label: 'admin.drivers.tips'.tr,
            value: '+${earnings.tips.toStringAsFixed(0)} ${'common.egp'.tr}',
            color: colors.info,
          ),
          const Divider(height: 20),
          _EarningsRow(
            label: 'admin.drivers.bonuses'.tr,
            value:
                '+${earnings.bonuses.toStringAsFixed(0)} ${'common.egp'.tr}',
            color: colors.warning,
          ),
          const Divider(height: 20),
          _EarningsRow(
            label: 'admin.drivers.net_earnings'.tr,
            value: '${earnings.netEarnings.toStringAsFixed(0)} '
                '${'common.egp'.tr}',
            isBold: true,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.surfaceContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'admin.drivers.total_trips'.tr,
                      style: TextStyle(
                        color: colors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '${earnings.totalTrips}',
                      style: theme.textTheme.titleSmall,
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'admin.drivers.avg_per_trip'.tr,
                      style: TextStyle(
                        color: colors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '${earnings.avgEarningPerTrip.toStringAsFixed(1)} '
                      '${'common.egp'.tr}',
                      style: theme.textTheme.titleSmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EarningsRow extends StatelessWidget {
  const _EarningsRow({
    required this.label,
    required this.value,
    this.color,
    this.isBold = false,
  });

  final String label;
  final String value;
  final Color? color;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isBold
              ? Theme.of(context).textTheme.titleSmall
              : Theme.of(context).textTheme.bodyMedium,
        ),
        Text(
          value,
          style: (isBold
                  ? Theme.of(context).textTheme.titleSmall
                  : Theme.of(context).textTheme.bodyMedium)
              ?.copyWith(color: color),
        ),
      ],
    );
  }
}
