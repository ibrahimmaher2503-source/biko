import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_button.dart';
import 'package:biko/core/widgets/app_card.dart';
import 'package:biko/core/widgets/app_empty_state.dart';
import 'package:biko/core/widgets/app_loading.dart';
import 'package:biko/core/widgets/app_text_field.dart';
import 'package:biko/features/admin/controllers/admin_transaction_monitor_controller.dart';
import 'package:biko/features/admin/utils/admin_status_colors.dart';
import 'package:biko/features/admin/widgets/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// Admin transaction monitor screen with live transaction feed,
/// search/filter panel, and suspicious transactions list.
class AdminTransactionMonitorScreen extends StatelessWidget {
  const AdminTransactionMonitorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AdminTransactionMonitorController>();
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    final theme = Theme.of(context);
    final numberFormat = NumberFormat.currency(
      symbol: 'EGP ',
      decimalDigits: 2,
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Obx(() {
        if (controller.isLoading.value && controller.transactions.isEmpty) {
          return const Center(child: AppLoading());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with live indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'admin.finance.transaction_monitor'.tr,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Live indicator
                      Obx(
                        () => GestureDetector(
                          onTap: controller.toggleLive,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: controller.isLive.value
                                  ? colors.successBg
                                  : colors.surfaceContainer,
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusFull,
                              ),
                              border: Border.all(
                                color: controller.isLive.value
                                    ? colors.success
                                    : colors.border,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: controller.isLive.value
                                        ? colors.success
                                        : colors.textMuted,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  controller.isLive.value
                                      ? 'admin.finance.live'.tr
                                      : 'admin.finance.paused'.tr,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: controller.isLive.value
                                        ? colors.success
                                        : colors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: controller.search,
                    tooltip: 'admin.common.refresh'.tr,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Filter panel
              _buildFilterPanel(context, controller, colors, theme),
              const SizedBox(height: 24),

              // Transaction table
              _buildTransactionTable(
                context,
                controller,
                colors,
                theme,
                numberFormat,
              ),
              const SizedBox(height: 24),

              // Suspicious transactions
              _buildSuspiciousTransactions(
                context,
                controller,
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

  Widget _buildFilterPanel(
    BuildContext context,
    AdminTransactionMonitorController controller,
    AppColorsExtension colors,
    ThemeData theme,
  ) {
    return AppCard(
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'admin.finance.search_transactions'.tr,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    AppTheme.radiusDefault,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              onChanged: (value) => controller.searchQuery.value = value,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonFormField<String>(
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'admin.financial.type'.tr,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    AppTheme.radiusDefault,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items: [
                DropdownMenuItem(
                  value: 'all',
                  child: Text('admin.common.all'.tr),
                ),
                DropdownMenuItem(
                  value: 'credit',
                  child: Text('admin.financial.credit'.tr),
                ),
                DropdownMenuItem(
                  value: 'debit',
                  child: Text('admin.financial.debit'.tr),
                ),
                DropdownMenuItem(
                  value: 'top_up',
                  child: Text('admin.financial.top_up'.tr),
                ),
                DropdownMenuItem(
                  value: 'refund',
                  child: Text('admin.financial.refund'.tr),
                ),
              ],
              onChanged: (value) {
                if (value != null && value != 'all') {
                  controller.search(type: value);
                } else {
                  controller.search();
                }
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonFormField<String>(
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'admin.financial.status'.tr,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    AppTheme.radiusDefault,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items: [
                DropdownMenuItem(
                  value: 'all',
                  child: Text('admin.common.all'.tr),
                ),
                DropdownMenuItem(
                  value: 'completed',
                  child: Text('admin.financial.completed'.tr),
                ),
                DropdownMenuItem(
                  value: 'pending',
                  child: Text('admin.financial.pending'.tr),
                ),
                DropdownMenuItem(
                  value: 'failed',
                  child: Text('admin.financial.failed'.tr),
                ),
              ],
              onChanged: (value) {
                if (value != null && value != 'all') {
                  controller.search(status: value);
                } else {
                  controller.search();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTable(
    BuildContext context,
    AdminTransactionMonitorController controller,
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
            'admin.finance.transactions'.tr,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Obx(() {
            if (controller.transactions.isEmpty) {
              return AppEmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'admin.finance.no_transactions'.tr,
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
                          'admin.financial.transaction_id'.tr,
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
                          'admin.financial.status'.tr,
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
                      const SizedBox(width: 50),
                    ],
                  ),
                ),
                // Rows
                ...controller.transactions.map((txn) {
                  final type = txn['type'] as String? ?? '';
                  final amount =
                      (txn['amount'] as num?)?.toDouble() ?? 0;
                  final status = txn['status'] as String? ?? '';
                  final isCredit =
                      type == 'credit' || type == 'top_up';

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
                            txn['txn_id'] as String? ?? '',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              color: colors.textMuted,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Expanded(
                          child: StatusBadge(
                            label: 'admin.financial.$type'.tr,
                            color: _getTypeColor(type),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            numberFormat.format(amount),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isCredit
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
                        Expanded(
                          flex: 2,
                          child: Text(
                            txn['created_at'] != null
                                ? dateFormat.format(
                                    DateTime.now(),
                                  )
                                : '',
                            style: TextStyle(
                              color: colors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 50,
                          child: IconButton(
                            icon: Icon(
                              Icons.flag_outlined,
                              size: 18,
                              color: colors.textMuted,
                            ),
                            tooltip: 'admin.finance.flag_suspicious'.tr,
                            onPressed: () => _showFlagDialog(
                              context,
                              controller,
                              txn['txn_id'] as String? ?? '',
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

  Widget _buildSuspiciousTransactions(
    BuildContext context,
    AdminTransactionMonitorController controller,
    AppColorsExtension colors,
    ThemeData theme,
    NumberFormat numberFormat,
  ) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber,
                color: colors.warning,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'admin.finance.suspicious_transactions'.tr,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Obx(() {
            if (controller.suspiciousTransactions.isEmpty) {
              return AppEmptyState(
                icon: Icons.shield_outlined,
                title: 'admin.finance.no_suspicious'.tr,
              );
            }

            final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

            return Column(
              children: controller.suspiciousTransactions.map((item) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.warningBg,
                    borderRadius: BorderRadius.circular(
                      AppTheme.radiusDefault,
                    ),
                    border: Border.all(
                      color: colors.warning.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  item.userName,
                                  style: theme.textTheme.titleSmall
                                      ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  numberFormat.format(item.amount),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.error,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.reason,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              dateFormat.format(item.flaggedAt),
                              style: TextStyle(
                                fontSize: 11,
                                color: colors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!item.isReviewed)
                        IconButton(
                          icon: Icon(
                            Icons.check_circle_outline,
                            color: colors.success,
                          ),
                          tooltip: 'admin.finance.clear_flag'.tr,
                          onPressed: () =>
                              controller.clearFlag(item.id),
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

  void _showFlagDialog(
    BuildContext context,
    AdminTransactionMonitorController controller,
    String transactionId,
  ) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'admin.finance.flag_suspicious'.tr,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'admin.finance.reason'.tr,
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
                      width: 100,
                      child: AppButton(
                        text: 'admin.finance.flag'.tr,
                        onPressed: () {
                          if (reasonController.text.isNotEmpty) {
                            controller.flagSuspicious(
                              transactionId,
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

  Color _getTypeColor(String type) {
    return AdminStatusColors.statusColor(type);
  }

  Color _getStatusColor(String status) {
    return AdminStatusColors.statusColor(status);
  }
}
