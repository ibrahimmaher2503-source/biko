import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_card.dart';
import 'package:biko/core/widgets/app_empty_state.dart';
import 'package:biko/core/widgets/app_loading.dart';
import 'package:biko/features/admin/controllers/admin_payment_analytics_controller.dart';
import 'package:biko/features/admin/widgets/date_range_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// Admin payment analytics screen showing success rates,
/// cash vs digital breakdown, and failed payments table.
/// Shows alert banner when failure rate exceeds threshold.
class AdminPaymentAnalyticsScreen extends StatelessWidget {
  const AdminPaymentAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AdminPaymentAnalyticsController>();
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Obx(() {
        if (controller.isLoading.value &&
            controller.successReport.isEmpty) {
          return const Center(child: AppLoading());
        }

        return RefreshIndicator(
          onRefresh: controller.loadData,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'admin.finance.payment_analytics'.tr,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Obx(
                      () => AdminDateRangePicker(
                        selectedRange: controller.dateRange,
                        onRangeSelected: controller.filterByDate,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // High failure rate alert
                Obx(() {
                  if (!controller.hasHighFailureRate) {
                    return const SizedBox.shrink();
                  }

                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: colors.warningBg,
                      borderRadius: BorderRadius.circular(
                        AppTheme.radiusDefault,
                      ),
                      border: Border.all(color: colors.warning),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: colors.warning,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'admin.finance.high_failure_rate'.tr,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colors.warning,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'admin.finance.high_failure_description'.tr,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                // Payment success chart
                _buildSuccessChart(context, controller, colors, theme),
                const SizedBox(height: 24),

                // Cash vs Digital breakdown
                _buildCashVsDigital(context, controller, colors, theme),
                const SizedBox(height: 24),

                // Failed payments table
                _buildFailedPayments(context, controller, colors, theme),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSuccessChart(
    BuildContext context,
    AdminPaymentAnalyticsController controller,
    AppColorsExtension colors,
    ThemeData theme,
  ) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'admin.finance.payment_success_rates'.tr,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Obx(() {
            if (controller.successReport.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'admin.finance.no_data'.tr,
                    style: TextStyle(color: colors.textMuted),
                  ),
                ),
              );
            }

            return Column(
              children: controller.successReport.map((report) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            report.method,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${report.successRate.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: report.successRate >= 90
                                  ? colors.success
                                  : report.successRate >= 70
                                      ? colors.warning
                                      : theme.colorScheme.error,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusFull,
                        ),
                        child: LinearProgressIndicator(
                          value: report.successRate / 100,
                          minHeight: 8,
                          backgroundColor: colors.surfaceContainer,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            report.successRate >= 90
                                ? colors.success
                                : report.successRate >= 70
                                    ? colors.warning
                                    : theme.colorScheme.error,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${'admin.finance.total_attempts'.tr}: ${report.totalAttempts}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.textMuted,
                            ),
                          ),
                          Text(
                            '${'admin.finance.failures'.tr}: ${report.failCount}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: report.failCount > 0
                                  ? theme.colorScheme.error
                                  : colors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCashVsDigital(
    BuildContext context,
    AdminPaymentAnalyticsController controller,
    AppColorsExtension colors,
    ThemeData theme,
  ) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'admin.finance.cash_vs_digital'.tr,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Obx(() {
            if (controller.cashVsDigital.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'admin.finance.no_data'.tr,
                    style: TextStyle(color: colors.textMuted),
                  ),
                ),
              );
            }

            final cashPercent =
                (controller.cashVsDigital['cash_percentage'] as num?)
                    ?.toDouble() ??
                0;
            final digitalPercent =
                (controller.cashVsDigital['digital_percentage'] as num?)
                    ?.toDouble() ??
                0;

            return LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 500;

                final cashWidget = _buildPaymentModeCard(
                  'admin.finance.cash_payments'.tr,
                  cashPercent,
                  Icons.money,
                  colors.success,
                  colors,
                  theme,
                );

                final digitalWidget = _buildPaymentModeCard(
                  'admin.finance.digital_payments'.tr,
                  digitalPercent,
                  Icons.phone_android,
                  colors.info,
                  colors,
                  theme,
                );

                if (isWide) {
                  return Row(
                    children: [
                      Expanded(child: cashWidget),
                      const SizedBox(width: 16),
                      Expanded(child: digitalWidget),
                    ],
                  );
                }

                return Column(
                  children: [
                    cashWidget,
                    const SizedBox(height: 16),
                    digitalWidget,
                  ],
                );
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPaymentModeCard(
    String label,
    double percentage,
    IconData icon,
    Color color,
    AppColorsExtension colors,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppTheme.radiusDefault),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 12),
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFailedPayments(
    BuildContext context,
    AdminPaymentAnalyticsController controller,
    AppColorsExtension colors,
    ThemeData theme,
  ) {
    final numberFormat = NumberFormat.currency(
      symbol: 'EGP ',
      decimalDigits: 2,
    );

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.error_outline,
                color: theme.colorScheme.error,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'admin.finance.failed_payments'.tr,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Obx(() {
            if (controller.failedPayments.isEmpty) {
              return AppEmptyState(
                icon: Icons.check_circle_outline,
                title: 'admin.finance.no_failed_payments'.tr,
              );
            }

            return Column(
              children: [
                // Table header
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
                          'admin.finance.transaction_id'.tr,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colors.textMuted,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'admin.financial.method'.tr,
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
                        flex: 2,
                        child: Text(
                          'admin.finance.error_reason'.tr,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                ...controller.failedPayments.map((payment) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: colors.borderSubtle),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            payment['txn_id'] as String? ?? '',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              color: colors.textMuted,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            payment['method'] as String? ?? '',
                          ),
                        ),
                        Expanded(
                          child: Text(
                            numberFormat.format(
                              (payment['amount'] as num?)?.toDouble() ?? 0,
                            ),
                            style: TextStyle(
                              color: theme.colorScheme.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            payment['error'] as String? ?? '',
                            style: TextStyle(
                              color: colors.textMuted,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            );
          }),
        ],
      ),
    );
  }
}
