import 'package:biko/features/admin/models/finance/wallet_summary_model.dart';
import 'package:biko/features/admin/widgets/finance/financial_stat_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Row of FinancialStatCards showing wallet summary:
/// customer balance, driver balance, recent top-ups, recent spending.
class WalletSummaryCards extends StatelessWidget {
  const WalletSummaryCards({
    required this.data,
    super.key,
  });

  final WalletSummaryModel data;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        SizedBox(
          width: 240,
          child: FinancialStatCard(
            title: 'finance.customer_balance',
            value: '${data.totalCustomerBalance.toStringAsFixed(0)} '
                '${'common.egp'.tr}',
            icon: Icons.account_balance_wallet_outlined,
            color: const Color(0xFF2563EB),
          ),
        ),
        SizedBox(
          width: 240,
          child: FinancialStatCard(
            title: 'finance.driver_balance',
            value: '${data.totalDriverBalance.toStringAsFixed(0)} '
                '${'common.egp'.tr}',
            icon: Icons.two_wheeler_outlined,
            color: const Color(0xFF16A34A),
          ),
        ),
        SizedBox(
          width: 240,
          child: FinancialStatCard(
            title: 'finance.recent_top_ups',
            value: '${data.recentTopUps.toStringAsFixed(0)} '
                '${'common.egp'.tr}',
            icon: Icons.add_circle_outline,
            color: const Color(0xFFF97316),
          ),
        ),
        SizedBox(
          width: 240,
          child: FinancialStatCard(
            title: 'finance.recent_spending',
            value: '${data.recentSpending.toStringAsFixed(0)} '
                '${'common.egp'.tr}',
            icon: Icons.shopping_bag_outlined,
            color: const Color(0xFF8B5CF6),
          ),
        ),
      ],
    );
  }
}
