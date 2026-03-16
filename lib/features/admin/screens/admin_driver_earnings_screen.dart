import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_button.dart';
import 'package:biko/core/widgets/app_card.dart';
import 'package:biko/core/widgets/app_empty_state.dart';
import 'package:biko/core/widgets/app_loading.dart';
import 'package:biko/core/widgets/app_text_field.dart';
import 'package:biko/features/admin/controllers/admin_driver_earnings_controller.dart';
import 'package:biko/features/admin/widgets/date_range_picker.dart';
import 'package:biko/features/admin/widgets/finance/financial_stat_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// Admin driver earnings screen showing summary cards,
/// earnings table with search, and action buttons for payouts/bonuses.
class AdminDriverEarningsScreen extends StatelessWidget {
  const AdminDriverEarningsScreen({super.key});

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
            controller.earningsSummary.isEmpty) {
          return const Center(child: AppLoading());
        }

        return RefreshIndicator(
          onRefresh: controller.loadEarnings,
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
                      'admin.finance.driver_earnings_title'.tr,
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

                // Summary cards
                _buildSummaryCards(
                  context,
                  controller,
                  colors,
                  theme,
                  numberFormat,
                ),
                const SizedBox(height: 24),

                // Earnings table
                _buildEarningsTable(
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
    AdminDriverEarningsController controller,
    AppColorsExtension colors,
    ThemeData theme,
    NumberFormat numberFormat,
  ) {
    return Obx(() {
      if (controller.earningsSummary.isEmpty) {
        return const SizedBox.shrink();
      }

      final totalGross = controller.earningsSummary
          .fold<double>(0, (sum, e) => sum + e.grossEarnings);
      final totalNet = controller.earningsSummary
          .fold<double>(0, (sum, e) => sum + e.netEarnings);
      final totalCommission = controller.earningsSummary
          .fold<double>(0, (sum, e) => sum + e.commission);
      final totalTrips = controller.earningsSummary
          .fold<int>(0, (sum, e) => sum + e.totalTrips);

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
                title: 'admin.finance.total_gross_earnings',
                value: numberFormat.format(totalGross),
                icon: Icons.payments,
                color: theme.colorScheme.primary,
              ),
              FinancialStatCard(
                title: 'admin.finance.total_net_earnings',
                value: numberFormat.format(totalNet),
                icon: Icons.account_balance_wallet,
                color: colors.success,
              ),
              FinancialStatCard(
                title: 'admin.finance.total_commission',
                value: numberFormat.format(totalCommission),
                icon: Icons.percent,
                color: colors.warning,
              ),
              FinancialStatCard(
                title: 'admin.finance.total_trips',
                value: totalTrips.toString(),
                icon: Icons.directions_bike,
                color: colors.info,
              ),
            ],
          );
        },
      );
    });
  }

  Widget _buildEarningsTable(
    BuildContext context,
    AdminDriverEarningsController controller,
    AppColorsExtension colors,
    ThemeData theme,
    NumberFormat numberFormat,
  ) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'admin.finance.driver_earnings_table'.tr,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Obx(() {
            if (controller.earningsSummary.isEmpty) {
              return AppEmptyState(
                icon: Icons.payments_outlined,
                title: 'admin.finance.no_earnings'.tr,
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
                          'admin.finance.driver_name'.tr,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colors.textMuted,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'admin.finance.gross'.tr,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colors.textMuted,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'admin.finance.commission_label'.tr,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colors.textMuted,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'admin.finance.net'.tr,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colors.textMuted,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'admin.finance.trips_label'.tr,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colors.textMuted,
                          ),
                        ),
                      ),
                      const SizedBox(width: 100),
                    ],
                  ),
                ),
                // Data rows
                ...controller.earningsSummary.map((earnings) {
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
                            earnings.driverName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            numberFormat.format(earnings.grossEarnings),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            numberFormat.format(earnings.commission),
                            style: TextStyle(color: colors.warning),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            numberFormat.format(earnings.netEarnings),
                            style: TextStyle(
                              color: colors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(earnings.totalTrips.toString()),
                        ),
                        SizedBox(
                          width: 100,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.send, size: 18),
                                tooltip: 'admin.finance.process_payout'.tr,
                                onPressed: () => _showPayoutDialog(
                                  context,
                                  controller,
                                  earnings.driverUid,
                                  earnings.driverName,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.card_giftcard,
                                  size: 18,
                                ),
                                tooltip: 'admin.finance.add_bonus'.tr,
                                onPressed: () => _showBonusDialog(
                                  context,
                                  controller,
                                  earnings.driverUid,
                                  earnings.driverName,
                                ),
                              ),
                            ],
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

  void _showPayoutDialog(
    BuildContext context,
    AdminDriverEarningsController controller,
    String driverUid,
    String driverName,
  ) {
    final amountController = TextEditingController();
    final methodNotifier = ValueNotifier<String>('bank_transfer');

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
                  '${'admin.finance.process_payout'.tr} - $driverName',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 24),
                AppTextField(
                  label: 'admin.finance.amount'.tr,
                  controller: amountController,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                ValueListenableBuilder<String>(
                  valueListenable: methodNotifier,
                  builder: (context, method, _) =>
                      DropdownButtonFormField<String>(
                    initialValue: method,
                    decoration: InputDecoration(
                      labelText: 'admin.finance.payout_method'.tr,
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'bank_transfer',
                        child: Text('admin.finance.bank_transfer'.tr),
                      ),
                      DropdownMenuItem(
                        value: 'vodafone_cash',
                        child: Text('admin.financial.vodafone_cash'.tr),
                      ),
                      DropdownMenuItem(
                        value: 'wallet',
                        child: Text('admin.financial.wallet'.tr),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) methodNotifier.value = v;
                    },
                  ),
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
                      width: 140,
                      child: AppButton(
                        text: 'admin.finance.process_payout'.tr,
                        onPressed: () {
                          final amount =
                              double.tryParse(amountController.text);
                          if (amount != null && amount > 0) {
                            controller.processPayout(
                              driverUid,
                              amount,
                              methodNotifier.value,
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
    );
  }

  void _showBonusDialog(
    BuildContext context,
    AdminDriverEarningsController controller,
    String driverUid,
    String driverName,
  ) {
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
                  '${'admin.finance.add_bonus'.tr} - $driverName',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 24),
                AppTextField(
                  label: 'admin.finance.amount'.tr,
                  controller: amountController,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'admin.finance.bonus_reason'.tr,
                  controller: reasonController,
                  maxLines: 3,
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
                        text: 'admin.finance.add_bonus'.tr,
                        onPressed: () {
                          final amount =
                              double.tryParse(amountController.text);
                          if (amount != null &&
                              amount > 0 &&
                              reasonController.text.isNotEmpty) {
                            controller.addBonus(
                              driverUid,
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
    );
  }
}
