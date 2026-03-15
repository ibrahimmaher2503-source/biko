import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_card.dart';
import 'package:biko/core/widgets/app_empty_state.dart';
import 'package:biko/core/widgets/app_loading.dart';
import 'package:biko/features/admin/controllers/admin_driver_earnings_controller.dart';
import 'package:biko/features/admin/widgets/finance/financial_stat_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' hide TextDirection;

/// Admin screen showing detailed earnings breakdown for a single driver,
/// including gross earnings, commission, tips, bonuses, and per-trip average.
class AdminDriverEarningsDetailScreen extends StatelessWidget {
  const AdminDriverEarningsDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AdminDriverEarningsController>();
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    final theme = Theme.of(context);
    final numberFormat = NumberFormat.currency(
      symbol: 'EGP ',
      decimalDigits: 2,
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Obx(() {
        if (controller.isLoading.value &&
            controller.selectedDriver.value == null) {
          return const Center(child: AppLoading());
        }

        final driver = controller.selectedDriver.value;
        if (driver == null) {
          return Center(
            child: AppEmptyState(
              icon: Icons.person_search,
              title: 'admin.finance.no_driver_selected'.tr,
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with back button
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Directionality.of(context) == TextDirection.rtl
                          ? Icons.arrow_forward
                          : Icons.arrow_back,
                    ),
                    onPressed: () => Get.back<void>(),
                    tooltip: 'common.back'.tr,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          driver.driverName,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'admin.finance.earnings_detail'.tr,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Earnings stat cards
              LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount = 1;
                  if (constraints.maxWidth > 1200) {
                    crossAxisCount = 4;
                  } else if (constraints.maxWidth > 800) {
                    crossAxisCount = 2;
                  }

                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: crossAxisCount == 1 ? 2.5 : 2.0,
                    children: [
                      FinancialStatCard(
                        title: 'admin.finance.gross_earnings',
                        value: numberFormat.format(driver.grossEarnings),
                        icon: Icons.payments,
                        color: theme.colorScheme.primary,
                      ),
                      FinancialStatCard(
                        title: 'admin.finance.net_earnings',
                        value: numberFormat.format(driver.netEarnings),
                        icon: Icons.account_balance_wallet,
                        color: colors.success,
                      ),
                      FinancialStatCard(
                        title: 'admin.finance.total_tips',
                        value: numberFormat.format(driver.tips),
                        icon: Icons.volunteer_activism,
                        color: colors.info,
                      ),
                      FinancialStatCard(
                        title: 'admin.finance.total_bonuses',
                        value: numberFormat.format(driver.bonuses),
                        icon: Icons.card_giftcard,
                        color: colors.warning,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // Detailed breakdown card
              _buildBreakdownCard(
                context,
                driver,
                colors,
                theme,
                numberFormat,
              ),
              const SizedBox(height: 24),

              // Performance metrics
              _buildPerformanceCard(
                context,
                driver,
                colors,
                theme,
                numberFormat,
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildBreakdownCard(
    BuildContext context,
    dynamic driver,
    AppColorsExtension colors,
    ThemeData theme,
    NumberFormat numberFormat,
  ) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'admin.finance.earnings_breakdown'.tr,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          _buildBreakdownRow(
            'admin.finance.gross_earnings'.tr,
            numberFormat.format(driver.grossEarnings),
            colors,
            theme,
          ),
          Divider(color: colors.borderSubtle),
          _buildBreakdownRow(
            'admin.finance.commission_deducted'.tr,
            '- ${numberFormat.format(driver.commission)}',
            colors,
            theme,
            valueColor: theme.colorScheme.error,
          ),
          Divider(color: colors.borderSubtle),
          _buildBreakdownRow(
            'admin.finance.total_tips'.tr,
            '+ ${numberFormat.format(driver.tips)}',
            colors,
            theme,
            valueColor: colors.success,
          ),
          Divider(color: colors.borderSubtle),
          _buildBreakdownRow(
            'admin.finance.total_bonuses'.tr,
            '+ ${numberFormat.format(driver.bonuses)}',
            colors,
            theme,
            valueColor: colors.success,
          ),
          const SizedBox(height: 8),
          Divider(color: colors.border, thickness: 2),
          const SizedBox(height: 8),
          _buildBreakdownRow(
            'admin.finance.net_earnings'.tr,
            numberFormat.format(driver.netEarnings),
            colors,
            theme,
            isBold: true,
            valueColor: colors.success,
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(
    String label,
    String value,
    AppColorsExtension colors,
    ThemeData theme, {
    Color? valueColor,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceCard(
    BuildContext context,
    dynamic driver,
    AppColorsExtension colors,
    ThemeData theme,
    NumberFormat numberFormat,
  ) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'admin.finance.performance'.tr,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 600;

              final items = [
                _buildMetric(
                  'admin.finance.total_trips'.tr,
                  driver.totalTrips.toString(),
                  Icons.directions_bike,
                  theme.colorScheme.primary,
                  colors,
                  theme,
                ),
                _buildMetric(
                  'admin.finance.avg_per_trip'.tr,
                  numberFormat.format(driver.avgPerTrip),
                  Icons.trending_up,
                  colors.success,
                  colors,
                  theme,
                ),
              ];

              if (isWide) {
                return Row(
                  children: items
                      .map((w) => Expanded(child: w))
                      .toList(),
                );
              }

              return Column(children: items);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(
    String label,
    String value,
    IconData icon,
    Color color,
    AppColorsExtension colors,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppTheme.radiusDefault),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusDefault),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
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
