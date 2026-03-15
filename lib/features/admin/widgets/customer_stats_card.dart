import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class CustomerStatsCard extends StatelessWidget {
  const CustomerStatsCard({
    required this.totalTrips,
    required this.totalSpent,
    required this.walletBalance,
    this.lastTripDate,
    super.key,
  });

  final int totalTrips;
  final double totalSpent;
  final double walletBalance;
  final DateTime? lastTripDate;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    final theme = Theme.of(context);
    final fmt = DateFormat('dd/MM/yyyy');

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'admin.customers.stats'.tr,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatColumn(
                  label: 'admin.customers.total_trips'.tr,
                  value: '$totalTrips',
                  icon: Icons.directions_bike,
                  color: colors.info,
                ),
              ),
              Expanded(
                child: _StatColumn(
                  label: 'admin.customers.total_spent'.tr,
                  value: '${totalSpent.toStringAsFixed(0)} ${'common.egp'.tr}',
                  icon: Icons.payments_outlined,
                  color: colors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatColumn(
                  label: 'admin.customers.wallet_balance'.tr,
                  value:
                      '${walletBalance.toStringAsFixed(2)} ${'common.egp'.tr}',
                  icon: Icons.account_balance_wallet_outlined,
                  color: colors.warning,
                ),
              ),
              Expanded(
                child: _StatColumn(
                  label: 'admin.customers.last_trip'.tr,
                  value: lastTripDate != null
                      ? fmt.format(lastTripDate!)
                      : 'common.none'.tr,
                  icon: Icons.schedule,
                  color: colors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
