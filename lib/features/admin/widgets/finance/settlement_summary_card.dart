import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/features/admin/models/finance/settlement_summary_model.dart';
import 'package:biko/features/admin/widgets/finance/financial_stat_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Card showing settlement summary: drivers to pay, total amount,
/// and pending settlement count.
class SettlementSummaryCard extends StatelessWidget {
  const SettlementSummaryCard({
    required this.data,
    super.key,
  });

  final SettlementSummaryModel data;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        SizedBox(
          width: 220,
          child: FinancialStatCard(
            title: 'finance.drivers_to_pay',
            value: data.driversToPayCount.toString(),
            icon: Icons.people_outline,
            color: colors.info,
          ),
        ),
        SizedBox(
          width: 220,
          child: FinancialStatCard(
            title: 'finance.total_amount',
            value: '${data.totalAmount.toStringAsFixed(0)} ${'common.egp'.tr}',
            icon: Icons.payments_outlined,
            color: colors.success,
          ),
        ),
        SizedBox(
          width: 220,
          child: FinancialStatCard(
            title: 'finance.pending_settlements',
            value: data.pendingSettlements.toString(),
            icon: Icons.hourglass_empty_rounded,
            color: colors.warning,
          ),
        ),
      ],
    );
  }
}
