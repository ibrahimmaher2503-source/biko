import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_button.dart';
import 'package:biko/core/widgets/app_card.dart';
import 'package:biko/core/widgets/app_empty_state.dart';
import 'package:biko/core/widgets/app_loading.dart';
import 'package:biko/features/admin/controllers/admin_settlement_controller.dart';
import 'package:biko/features/admin/utils/admin_status_colors.dart';
import 'package:biko/features/admin/widgets/confirm_dialog.dart';
import 'package:biko/features/admin/widgets/finance/financial_stat_card.dart';
import 'package:biko/features/admin/widgets/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// Admin settlement screen for processing driver payouts with
/// summary cards, driver selection table, settlement history,
/// and a process settlement action button.
class AdminSettlementScreen extends StatelessWidget {
  const AdminSettlementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AdminSettlementController>();
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
            controller.summary.value == null) {
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
                      'admin.finance.settlements_title'.tr,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        Obx(
                          () => AppButton(
                            text: 'admin.finance.process_settlement'.tr,
                            leadingIcon: Icons.send,
                            onPressed:
                                controller.selectedDriverUids.isEmpty
                                    ? null
                                    : () => _confirmProcessSettlement(
                                          context,
                                          controller,
                                        ),
                          ),
                        ),
                      ],
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

                // Driver settlement table
                _buildDriverTable(
                  context,
                  controller,
                  colors,
                  theme,
                  numberFormat,
                ),
                const SizedBox(height: 24),

                // Settlement history
                _buildHistory(
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
    AdminSettlementController controller,
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
          if (constraints.maxWidth > 800) {
            crossAxisCount = 3;
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
                title: 'admin.finance.drivers_to_pay',
                value: summary.driversToPayCount.toString(),
                icon: Icons.people,
                color: theme.colorScheme.primary,
              ),
              FinancialStatCard(
                title: 'admin.finance.total_settlement_amount',
                value: numberFormat.format(summary.totalAmount),
                icon: Icons.account_balance,
                color: colors.warning,
              ),
              FinancialStatCard(
                title: 'admin.finance.pending_settlements',
                value: summary.pendingSettlements.toString(),
                icon: Icons.schedule,
                color: colors.info,
              ),
            ],
          );
        },
      );
    });
  }

  Widget _buildDriverTable(
    BuildContext context,
    AdminSettlementController controller,
    AppColorsExtension colors,
    ThemeData theme,
    NumberFormat numberFormat,
  ) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'admin.finance.drivers_pending_settlement'.tr,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  Obx(
                    () => Text(
                      '${controller.selectedDriverUids.length} ${'admin.finance.selected'.tr}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AppButton(
                    text: 'admin.finance.select_all'.tr,
                    variant: ButtonVariant.text,
                    onPressed: controller.selectAll,
                  ),
                  AppButton(
                    text: 'admin.finance.deselect_all'.tr,
                    variant: ButtonVariant.text,
                    onPressed: controller.deselectAll,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Obx(() {
            if (controller.drivers.isEmpty) {
              return AppEmptyState(
                icon: Icons.check_circle_outline,
                title: 'admin.finance.no_pending_settlements'.tr,
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
                      const SizedBox(width: 48),
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
                          'admin.finance.pending_amount'.tr,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colors.textMuted,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'admin.finance.bank_details'.tr,
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
                // Data rows
                ...controller.drivers.map((driver) {
                  return Obx(() {
                    final isSelected = controller.selectedDriverUids
                        .contains(driver.driverUid);

                    return InkWell(
                      onTap: () => controller.toggleDriverSelection(
                        driver.driverUid,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colors.infoBg
                              : null,
                          border: Border(
                            bottom: BorderSide(
                              color: colors.borderSubtle,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 48,
                              child: Checkbox(
                                value: isSelected,
                                onChanged: (_) =>
                                    controller.toggleDriverSelection(
                                  driver.driverUid,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                driver.driverName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                numberFormat.format(
                                  driver.pendingAmount,
                                ),
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: colors.success,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                driver.bankDetails ?? '-',
                                style: TextStyle(
                                  color: colors.textMuted,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Expanded(
                              child: StatusBadge(
                                label: 'admin.finance.${driver.status}'.tr,
                                color: _getStatusColor(driver.status),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  });
                }),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildHistory(
    BuildContext context,
    AdminSettlementController controller,
    AppColorsExtension colors,
    ThemeData theme,
    NumberFormat numberFormat,
  ) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'admin.finance.settlement_history'.tr,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Obx(() {
            if (controller.history.isEmpty) {
              return AppEmptyState(
                icon: Icons.history,
                title: 'admin.finance.no_history'.tr,
              );
            }

            return Column(
              children: controller.history.map((record) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: colors.borderSubtle),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusDefault,
                          ),
                        ),
                        child: Icon(
                          Icons.check_circle,
                          size: 20,
                          color: colors.success,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              numberFormat.format(record.totalAmount),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${record.driverCount} ${'admin.finance.drivers'.tr} - '
                              '${dateFormat.format(record.processedAt)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${'admin.finance.by'.tr}: ${record.processedBy}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.textMuted,
                        ),
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

  Future<void> _confirmProcessSettlement(
    BuildContext context,
    AdminSettlementController controller,
  ) async {
    final numberFormat = NumberFormat.currency(
      symbol: 'EGP ',
      decimalDigits: 2,
    );

    final selectedDrivers = controller.drivers.where(
      (d) => controller.selectedDriverUids.contains(d.driverUid),
    );
    final totalAmount = selectedDrivers.fold<double>(
      0,
      (sum, d) => sum + d.pendingAmount,
    );

    final confirmed = await ConfirmDialog.show(
      title: 'admin.finance.confirm_settlement'.tr,
      message: 'admin.finance.settlement_confirm_message'.trParams({
        'count': controller.selectedDriverUids.length.toString(),
        'amount': numberFormat.format(totalAmount),
      }),
      confirmLabel: 'admin.finance.process_settlement'.tr,
    );

    if (confirmed) {
      await controller.processSettlement();
    }
  }

  Color _getStatusColor(String status) {
    return AdminStatusColors.statusColor(status);
  }
}
