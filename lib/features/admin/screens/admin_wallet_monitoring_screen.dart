import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_button.dart';
import 'package:biko/core/widgets/app_card.dart';
import 'package:biko/core/widgets/app_empty_state.dart';
import 'package:biko/core/widgets/app_loading.dart';
import 'package:biko/core/widgets/app_text_field.dart';
import 'package:biko/features/admin/controllers/admin_wallet_controller.dart';
import 'package:biko/features/admin/utils/admin_status_colors.dart';
import 'package:biko/features/admin/widgets/finance/financial_stat_card.dart';
import 'package:biko/features/admin/widgets/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// Admin wallet monitoring screen with summary cards,
/// activity table, and wallet adjustment controls.
class AdminWalletMonitoringScreen extends StatelessWidget {
  const AdminWalletMonitoringScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AdminWalletController>();
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
          onRefresh: controller.loadWalletData,
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
                      'admin.finance.wallet_monitoring'.tr,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: controller.loadWalletData,
                      tooltip: 'admin.common.refresh'.tr,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Summary cards
                _buildSummaryCards(
                  context,
                  controller,
                  colors,
                  theme,
                  numberFormat,
                ),
                const SizedBox(height: 24),

                // Activity table
                _buildActivityTable(
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

  Widget _buildSummaryCards(
    BuildContext context,
    AdminWalletController controller,
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
                title: 'admin.finance.customer_balance',
                value: numberFormat.format(summary.totalCustomerBalance),
                icon: Icons.person,
                color: theme.colorScheme.primary,
              ),
              FinancialStatCard(
                title: 'admin.finance.driver_balance',
                value: numberFormat.format(summary.totalDriverBalance),
                icon: Icons.directions_bike,
                color: colors.success,
              ),
              FinancialStatCard(
                title: 'admin.finance.recent_top_ups',
                value: numberFormat.format(summary.recentTopUps),
                icon: Icons.arrow_upward,
                color: colors.info,
              ),
              FinancialStatCard(
                title: 'admin.finance.recent_spending',
                value: numberFormat.format(summary.recentSpending),
                icon: Icons.arrow_downward,
                color: colors.warning,
              ),
            ],
          );
        },
      );
    });
  }

  Widget _buildActivityTable(
    BuildContext context,
    AdminWalletController controller,
    AppColorsExtension colors,
    ThemeData theme,
    NumberFormat numberFormat,
  ) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'admin.finance.wallet_activity'.tr,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              AppButton(
                text: 'admin.finance.adjust_wallet'.tr,
                leadingIcon: Icons.tune,
                variant: ButtonVariant.outline,
                onPressed: () => _showAdjustmentDialog(
                  context,
                  controller,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Obx(() {
            if (controller.activity.isEmpty) {
              return AppEmptyState(
                icon: Icons.account_balance_wallet_outlined,
                title: 'admin.finance.no_activity'.tr,
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
                          'admin.finance.user'.tr,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colors.textMuted,
                          ),
                        ),
                      ),
                      Expanded(
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
                          'admin.finance.balance_after'.tr,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colors.textMuted,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'admin.financial.created_at'.tr,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Data rows
                ...controller.activity.map((item) {
                  final isCredit = item.type == 'credit' ||
                      item.type == 'top_up' ||
                      item.type == 'bonus';

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
                            item.userName,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Expanded(
                          child: StatusBadge(
                            label: 'admin.financial.${item.type}'.tr,
                            color: AdminStatusColors.transactionColor(
                              isCredit: isCredit,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '${isCredit ? '+' : '-'}${numberFormat.format(item.amount.abs())}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isCredit
                                  ? colors.success
                                  : theme.colorScheme.error,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            numberFormat.format(item.balanceAfter),
                            style: TextStyle(color: colors.textMuted),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            dateFormat.format(item.timestamp),
                            style: TextStyle(
                              color: colors.textMuted,
                              fontSize: 12,
                            ),
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

  void _showAdjustmentDialog(
    BuildContext context,
    AdminWalletController controller,
  ) {
    final uidController = TextEditingController();
    final amountController = TextEditingController();
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'admin.finance.adjust_wallet'.tr,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'admin.finance.adjust_description'.tr,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .extension<AppColorsExtension>()!
                        .textMuted,
                  ),
                ),
                const SizedBox(height: 24),
                AppTextField(
                  label: 'admin.finance.user_uid'.tr,
                  controller: uidController,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'admin.finance.amount_positive_or_negative'.tr,
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    signed: true,
                    decimal: true,
                  ),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'admin.finance.reason'.tr,
                  controller: reasonController,
                  maxLines: 2,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(
                      width: 100,
                      child: AppButton(
                        text: 'common.cancel'.tr,
                        variant: ButtonVariant.text,
                        onPressed: () => Get.back<void>(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 120,
                      child: AppButton(
                        text: 'admin.finance.apply'.tr,
                        onPressed: () {
                          final amount =
                              double.tryParse(amountController.text);
                          if (uidController.text.isNotEmpty &&
                              amount != null &&
                              reasonController.text.isNotEmpty) {
                            controller.adjustWallet(
                              uidController.text,
                              amount,
                              reasonController.text,
                            );
                            Get.back<void>();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).then((_) {
      uidController.dispose();
      amountController.dispose();
      reasonController.dispose();
    });
  }
}
