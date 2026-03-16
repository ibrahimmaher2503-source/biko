import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_card.dart';
import 'package:biko/features/admin/models/finance/commission_breakdown_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Card displaying commission breakdown by type (ride, c2c, b2b)
/// with amounts and percentage rates.
class CommissionBreakdownCard extends StatelessWidget {
  const CommissionBreakdownCard({
    required this.data,
    super.key,
  });

  final CommissionBreakdownModel data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'finance.commission_breakdown'.tr,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${'finance.total'.tr}: '
            '${data.totalCommission.toStringAsFixed(0)} '
            '${'common.egp'.tr}',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Divider(color: colors.borderSubtle, height: 1),
          const SizedBox(height: 16),
          _buildRow(
            context,
            label: 'finance.ride'.tr,
            amount: data.rideCommission,
            rate: data.rideRate,
            color: colors.info,
            colors: colors,
          ),
          const SizedBox(height: 12),
          _buildRow(
            context,
            label: 'finance.c2c'.tr,
            amount: data.c2cCommission,
            rate: data.c2cRate,
            color: colors.success,
            colors: colors,
          ),
          const SizedBox(height: 12),
          _buildRow(
            context,
            label: 'finance.b2b'.tr,
            amount: data.b2bCommission,
            rate: data.b2bRate,
            color: colors.warning,
            colors: colors,
          ),
        ],
      ),
    );
  }

  Widget _buildRow(
    BuildContext context, {
    required String label,
    required double amount,
    required double rate,
    required Color color,
    required AppColorsExtension colors,
  }) {
    final theme = Theme.of(context);
    final fraction = data.totalCommission > 0
        ? amount / data.totalCommission
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(label, style: theme.textTheme.bodyMedium),
            const Spacer(),
            Text(
              '${amount.toStringAsFixed(0)} ${'common.egp'.tr}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '(${rate.toStringAsFixed(1)}%)',
              style: TextStyle(fontSize: 12, color: colors.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 4,
            backgroundColor: colors.surfaceContainer,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
