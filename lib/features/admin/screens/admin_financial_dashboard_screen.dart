import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_card.dart';
import 'package:biko/core/widgets/app_loading.dart';
import 'package:biko/features/admin/controllers/admin_financial_dashboard_controller.dart';
import 'package:biko/features/admin/utils/admin_status_colors.dart';
import 'package:biko/features/admin/widgets/finance/financial_stat_card.dart';
import 'package:biko/features/admin/widgets/finance/payment_method_chart.dart';
import 'package:biko/features/admin/widgets/finance/revenue_chart.dart';
import 'package:biko/features/admin/widgets/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// Admin financial dashboard screen with revenue overview, charts,
/// commission breakdown, and recent transactions.
class AdminFinancialDashboardScreen extends StatelessWidget {
  const AdminFinancialDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AdminFinancialDashboardController>();
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    final theme = Theme.of(context);
    final numberFormat = NumberFormat.currency(
      symbol: 'EGP ',
      decimalDigits: 2,
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Obx(() {
        if (controller.isLoading.value && controller.summary.value == null) {
          return const Center(child: AppLoading());
        }

        return RefreshIndicator(
          onRefresh: controller.refreshData,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with date range picker
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'admin.finance.dashboard_title'.tr,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        _buildPeriodChips(controller, theme, colors),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: controller.refreshData,
                          tooltip: 'admin.common.refresh'.tr,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Summary stat cards
                _buildStatCards(
                  context,
                  controller,
                  colors,
                  theme,
                  numberFormat,
                ),
                const SizedBox(height: 24),

                // Revenue chart
                _buildRevenueChartSection(
                  context,
                  controller,
                  colors,
                  theme,
                ),
                const SizedBox(height: 24),

                // Two-column: Payment chart + Commission breakdown
                _buildTwoColumnSection(
                  context,
                  controller,
                  colors,
                  theme,
                  numberFormat,
                ),
                const SizedBox(height: 24),

                // Recent transactions + leaderboard
                _buildBottomSection(
                  context,
                  controller,
                  colors,
                  theme,
                  numberFormat,
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildPeriodChips(
    AdminFinancialDashboardController controller,
    ThemeData theme,
    AppColorsExtension colors,
  ) {
    return Obx(
      () => Wrap(
        spacing: 4,
        children: [
          _periodChip(
            'admin.common.today'.tr,
            'today',
            controller,
            theme,
            colors,
          ),
          _periodChip(
            'admin.common.last_7_days'.tr,
            'last_7_days',
            controller,
            theme,
            colors,
          ),
          _periodChip(
            'admin.common.last_30_days'.tr,
            'last_30_days',
            controller,
            theme,
            colors,
          ),
        ],
      ),
    );
  }

  Widget _periodChip(
    String label,
    String period,
    AdminFinancialDashboardController controller,
    ThemeData theme,
    AppColorsExtension colors,
  ) {
    final isSelected = controller.selectedPeriod.value == period;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => controller.setDateRange(period),
      selectedColor: theme.colorScheme.primary.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: isSelected ? theme.colorScheme.primary : colors.textMuted,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        fontSize: 13,
      ),
    );
  }

  Widget _buildStatCards(
    BuildContext context,
    AdminFinancialDashboardController controller,
    AppColorsExtension colors,
    ThemeData theme,
    NumberFormat numberFormat,
  ) {
    return Obx(() {
      final summary = controller.summary.value;
      if (summary == null) return const SizedBox.shrink();

      return LayoutBuilder(
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
                title: 'admin.finance.total_revenue',
                value: numberFormat.format(summary.totalRevenue),
                icon: Icons.attach_money,
                color: colors.success,
              ),
              FinancialStatCard(
                title: 'admin.finance.total_commission',
                value: numberFormat.format(summary.totalCommission),
                icon: Icons.percent,
                color: theme.colorScheme.primary,
              ),
              FinancialStatCard(
                title: 'admin.finance.net_profit',
                value: numberFormat.format(summary.netProfit),
                icon: Icons.trending_up,
                color: colors.info,
              ),
              FinancialStatCard(
                title: 'admin.finance.pending_payouts',
                value: numberFormat.format(summary.pendingPayouts),
                icon: Icons.schedule,
                color: colors.warning,
              ),
            ],
          );
        },
      );
    });
  }

  Widget _buildRevenueChartSection(
    BuildContext context,
    AdminFinancialDashboardController controller,
    AppColorsExtension colors,
    ThemeData theme,
  ) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'admin.finance.revenue_trend'.tr,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Obx(() {
            if (controller.revenueData.isEmpty) {
              return SizedBox(
                height: 300,
                child: Center(
                  child: Text(
                    'admin.finance.no_data'.tr,
                    style: TextStyle(color: colors.textMuted),
                  ),
                ),
              );
            }

            return SizedBox(
              height: 300,
              child: RevenueChart(data: controller.revenueData),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTwoColumnSection(
    BuildContext context,
    AdminFinancialDashboardController controller,
    AppColorsExtension colors,
    ThemeData theme,
    NumberFormat numberFormat,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 800;

        final paymentChart = AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'admin.finance.payment_distribution'.tr,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Obx(() {
                if (controller.paymentDistribution.isEmpty) {
                  return SizedBox(
                    height: 250,
                    child: Center(
                      child: Text(
                        'admin.finance.no_data'.tr,
                        style: TextStyle(color: colors.textMuted),
                      ),
                    ),
                  );
                }

                return SizedBox(
                  height: 280,
                  child: PaymentMethodChart(
                    data: controller.paymentDistribution,
                  ),
                );
              }),
            ],
          ),
        );

        final commissionCard = AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'admin.finance.commission_breakdown'.tr,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Obx(() {
                final breakdown = controller.commissionBreakdown.value;
                if (breakdown == null) {
                  return Center(
                    child: Text(
                      'admin.finance.no_data'.tr,
                      style: TextStyle(color: colors.textMuted),
                    ),
                  );
                }

                return Column(
                  children: [
                    _buildCommissionRow(
                      'admin.finance.ride_commission'.tr,
                      numberFormat.format(breakdown.rideCommission),
                      '${(breakdown.rideRate * 100).toStringAsFixed(1)}%',
                      colors,
                      theme,
                    ),
                    Divider(color: colors.borderSubtle),
                    _buildCommissionRow(
                      'admin.finance.c2c_commission'.tr,
                      numberFormat.format(breakdown.c2cCommission),
                      '${(breakdown.c2cRate * 100).toStringAsFixed(1)}%',
                      colors,
                      theme,
                    ),
                    Divider(color: colors.borderSubtle),
                    _buildCommissionRow(
                      'admin.finance.b2b_commission'.tr,
                      numberFormat.format(breakdown.b2bCommission),
                      '${(breakdown.b2bRate * 100).toStringAsFixed(1)}%',
                      colors,
                      theme,
                    ),
                    const SizedBox(height: 12),
                    Divider(color: colors.border),
                    _buildCommissionRow(
                      'admin.finance.total'.tr,
                      numberFormat.format(breakdown.totalCommission),
                      '',
                      colors,
                      theme,
                      isBold: true,
                    ),
                  ],
                );
              }),
            ],
          ),
        );

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: paymentChart),
              const SizedBox(width: 24),
              Expanded(child: commissionCard),
            ],
          );
        }

        return Column(
          children: [
            paymentChart,
            const SizedBox(height: 24),
            commissionCard,
          ],
        );
      },
    );
  }

  Widget _buildCommissionRow(
    String label,
    String amount,
    String rate,
    AppColorsExtension colors,
    ThemeData theme, {
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            ),
          ),
          Row(
            children: [
              if (rate.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colors.infoBg,
                    borderRadius: BorderRadius.circular(
                      AppTheme.radiusFull,
                    ),
                  ),
                  child: Text(
                    rate,
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.info,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Text(
                amount,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                  color: colors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection(
    BuildContext context,
    AdminFinancialDashboardController controller,
    AppColorsExtension colors,
    ThemeData theme,
    NumberFormat numberFormat,
  ) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'admin.finance.recent_transactions'.tr,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Obx(() {
            if (controller.recentTransactions.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'admin.finance.no_transactions'.tr,
                    style: TextStyle(color: colors.textMuted),
                  ),
                ),
              );
            }

            return Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainer,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppTheme.radiusDefault),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          'admin.financial.type'.tr,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colors.textMuted,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'admin.financial.amount'.tr,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colors.textMuted,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'admin.financial.status'.tr,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Rows
                ...controller.recentTransactions.take(10).map(
                  (txn) {
                    final type = txn['type'] as String? ?? '';
                    final amount = (txn['amount'] as num?)?.toDouble() ?? 0;
                    final status = txn['status'] as String? ?? '';

                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: colors.borderSubtle,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              'admin.financial.$type'.tr,
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              numberFormat.format(amount),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: (type == 'credit' || type == 'top_up')
                                    ? colors.success
                                    : theme.colorScheme.error,
                              ),
                            ),
                          ),
                          Expanded(
                            child: StatusBadge(
                              label: 'admin.financial.$status'.tr,
                              color: _getStatusColor(status),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    return AdminStatusColors.statusColor(status);
  }
}
