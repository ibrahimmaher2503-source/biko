import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Card showing fare breakdown: total, commission, and net earning.
class FareBreakdownCard extends StatelessWidget {
  const FareBreakdownCard({
    required this.totalFare,
    required this.commission,
    required this.netEarning,
    required this.commissionRate,
    super.key,
  });

  final double totalFare;
  final double commission;
  final double netEarning;
  final double commissionRate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = theme.extension<AppColorsExtension>()!;

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'trip_complete.fare_breakdown'.tr,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            // Total fare
            _FareRow(
              label: 'trip_complete.total_fare'.tr,
              amount: totalFare,
              style: theme.textTheme.bodyMedium!,
            ),
            const SizedBox(height: 8),

            // Commission
            _FareRow(
              label:
                  '${'trip_complete.commission'.tr} (${(commissionRate * 100).toStringAsFixed(0)}%)',
              amount: -commission,
              style: theme.textTheme.bodyMedium!.copyWith(color: ext.textMuted),
            ),

            const SizedBox(height: 12),
            Divider(color: ext.border),
            const SizedBox(height: 12),

            // Net earning
            _FareRow(
              label: 'trip_complete.net_earning'.tr,
              amount: netEarning,
              style: theme.textTheme.titleMedium!.copyWith(
                fontWeight: FontWeight.bold,
                color: ext.success,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FareRow extends StatelessWidget {
  const _FareRow({
    required this.label,
    required this.amount,
    required this.style,
  });

  final String label;
  final double amount;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final prefix = amount < 0 ? '-' : '';
    final displayAmount = amount.abs().toStringAsFixed(0);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text('$prefix$displayAmount ${'common.egp'.tr}', style: style),
      ],
    );
  }
}
