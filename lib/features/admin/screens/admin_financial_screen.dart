import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_button.dart';
import 'package:biko/core/widgets/app_card.dart';
import 'package:biko/core/widgets/app_loading.dart';
import 'package:biko/features/admin/controllers/admin_financial_controller.dart';
import 'package:biko/features/admin/utils/admin_status_colors.dart';
import 'package:biko/features/admin/widgets/admin_data_table.dart';
import 'package:biko/features/admin/widgets/date_range_picker.dart';
import 'package:biko/features/admin/widgets/stat_card.dart';
import 'package:biko/features/admin/widgets/status_badge.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class AdminFinancialScreen extends GetView<AdminFinancialController> {
  const AdminFinancialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;
    final numberFormat = NumberFormat.currency(
      symbol: 'EGP ',
      decimalDigits: 2,
    );
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'admin.financial.title'.tr,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    Obx(
                      () => AdminDateRangePicker(
                        selectedRange: controller.dateRange.value,
                        onRangeSelected: controller.updateDateRange,
                      ),
                    ),
                    const SizedBox(width: 16),
                    AppButton(
                      text: 'admin.financial.export_csv'.tr,
                      onPressed: controller.exportCsv,
                      variant: ButtonVariant.outline,
                      leadingIcon: Icons.download,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Summary Cards
            Obx(() {
              final summaryData = controller.summary.value;
              if (summaryData == null) {
                return const Center(child: AppLoading());
              }

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
                      StatCard(
                        titleKey: 'admin.financial.total_revenue',
                        value: numberFormat.format(summaryData.totalRevenue),
                        icon: Icons.attach_money,
                        iconColor: colors.success,
                      ),
                      StatCard(
                        titleKey: 'admin.financial.total_commission',
                        value: numberFormat.format(summaryData.totalCommission),
                        icon: Icons.percent,
                        iconColor: theme.colorScheme.primary,
                      ),
                      StatCard(
                        titleKey: 'admin.financial.total_top_ups',
                        value: numberFormat.format(summaryData.totalTopUps),
                        icon: Icons.arrow_upward,
                        iconColor: colors.info,
                      ),
                      StatCard(
                        titleKey: 'admin.financial.total_refunds',
                        value: numberFormat.format(summaryData.totalRefunds),
                        icon: Icons.arrow_downward,
                        iconColor: colors.warning,
                      ),
                    ],
                  );
                },
              );
            }),
            const SizedBox(height: 32),

            // Commission Breakdown
            Obx(() {
              if (controller.commissionBreakdown.isEmpty) {
                return const SizedBox.shrink();
              }

              return AppCard(
                padding: 24,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'admin.financial.commission_breakdown'.tr,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Table(
                      border: TableBorder.all(color: colors.border),
                      columnWidths: const {
                        0: FlexColumnWidth(2),
                        1: FlexColumnWidth(),
                        2: FlexColumnWidth(2),
                        3: FlexColumnWidth(),
                        4: FlexColumnWidth(2),
                      },
                      children: [
                        TableRow(
                          decoration: BoxDecoration(
                            color: colors.surfaceContainer,
                          ),
                          children: [
                            _buildTableHeader('admin.financial.trip_type'.tr),
                            _buildTableHeader('admin.financial.trip_count'.tr),
                            _buildTableHeader('admin.financial.total_fare'.tr),
                            _buildTableHeader(
                              'admin.financial.commission_rate'.tr,
                            ),
                            _buildTableHeader(
                              'admin.financial.commission_earned'.tr,
                            ),
                          ],
                        ),
                        ...controller.commissionBreakdown.map((item) {
                          return TableRow(
                            children: [
                              _buildTableCell(
                                StatusBadge(
                                  label: 'trip_type.${item['type']}'.tr,
                                  color: colors.info,
                                ),
                              ),
                              _buildTableCell(Text('${item['tripCount']}')),
                              _buildTableCell(
                                Text(numberFormat.format(item['totalFare'])),
                              ),
                              _buildTableCell(
                                Text(
                                  '${(item['commissionRate'] as double).toStringAsFixed(1)}%',
                                ),
                              ),
                              _buildTableCell(
                                Text(
                                  numberFormat.format(item['commissionEarned']),
                                  style: TextStyle(
                                    color: colors.success,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 32),

            // Filters
            AppCard(
              child: Row(
                children: [
                  Expanded(
                    child: Obx(
                      () => DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: controller.transactionTypeFilter.value,
                        decoration: InputDecoration(
                          labelText: 'admin.financial.transaction_type'.tr,
                          border: const OutlineInputBorder(),
                        ),
                        items: [
                          DropdownMenuItem(
                            child: Text('admin.financial.all_types'.tr),
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
                          controller.transactionTypeFilter.value = value;
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Obx(
                      () => DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: controller.paymentMethodFilter.value,
                        decoration: InputDecoration(
                          labelText: 'admin.financial.payment_method'.tr,
                          border: const OutlineInputBorder(),
                        ),
                        items: [
                          DropdownMenuItem(
                            child: Text('admin.financial.all_methods'.tr),
                          ),
                          DropdownMenuItem(
                            value: 'cash',
                            child: Text('admin.financial.cash'.tr),
                          ),
                          DropdownMenuItem(
                            value: 'wallet',
                            child: Text('admin.financial.wallet'.tr),
                          ),
                          DropdownMenuItem(
                            value: 'card',
                            child: Text('admin.financial.card'.tr),
                          ),
                          DropdownMenuItem(
                            value: 'vodafone_cash',
                            child: Text('admin.financial.vodafone_cash'.tr),
                          ),
                          DropdownMenuItem(
                            value: 'fawry',
                            child: Text('admin.financial.fawry'.tr),
                          ),
                        ],
                        onChanged: (value) {
                          controller.paymentMethodFilter.value = value;
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  AppButton(
                    text: 'admin.financial.apply_filters'.tr,
                    onPressed: controller.applyFilters,
                  ),
                  const SizedBox(width: 8),
                  AppButton(
                    text: 'admin.financial.clear_filters'.tr,
                    onPressed: controller.clearFilters,
                    variant: ButtonVariant.text,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Transactions Table
            Obx(() {
              return SizedBox(
                height: 500,
                child: AdminDataTable<Map<String, dynamic>>(
                  columns: [
                    AdminColumn(
                      label: 'admin.financial.transaction_id'.tr,
                      flex: 2,
                    ),
                    AdminColumn(label: 'admin.financial.type'.tr),
                    AdminColumn(label: 'admin.financial.user_id'.tr, flex: 2),
                    AdminColumn(label: 'admin.financial.amount'.tr),
                    AdminColumn(label: 'admin.financial.method'.tr),
                    AdminColumn(label: 'admin.financial.status'.tr),
                    AdminColumn(
                      label: 'admin.financial.created_at'.tr,
                      flex: 2,
                    ),
                  ],
                  rows: controller.transactions,
                  cellBuilder: (transaction, colIndex) {
                    switch (colIndex) {
                      case 0:
                        return Text(
                          transaction['txn_id'] ?? '',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: colors.textMuted,
                          ),
                        );
                      case 1:
                        return StatusBadge(
                          label: 'admin.financial.${transaction['type']}'.tr,
                          color: _getTypeStatusColor(transaction['type']),
                        );
                      case 2:
                        return Text(
                          transaction['uid'] ?? '',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: colors.textMuted,
                          ),
                        );
                      case 3:
                        return Text(
                          numberFormat.format(transaction['amount'] ?? 0.0),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color:
                                (transaction['type'] == 'credit' ||
                                    transaction['type'] == 'top_up')
                                ? colors.success
                                : theme.colorScheme.error,
                          ),
                        );
                      case 4:
                        return Text(
                          'admin.financial.${transaction['method']}'.tr,
                        );
                      case 5:
                        return StatusBadge(
                          label: 'admin.financial.${transaction['status']}'.tr,
                          color: _getStatusColor(transaction['status']),
                        );
                      case 6:
                        return Text(
                          transaction['created_at'] != null
                              ? dateFormat.format(
                                  (transaction['created_at'] as Timestamp)
                                      .toDate(),
                                )
                              : '',
                          style: TextStyle(color: colors.textMuted),
                        );
                      default:
                        return const SizedBox.shrink();
                    }
                  },
                  isLoading: controller.isLoading.value,
                  emptyMessage: 'admin.financial.no_transactions'.tr,
                  hasNextPage: controller.hasMore.value,
                  onNextPage: () => controller.loadTransactions(loadMore: true),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildTableCell(Widget child) {
    return Padding(padding: const EdgeInsets.all(8.0), child: child);
  }

  Color _getTypeStatusColor(String? type) {
    return AdminStatusColors.statusColor(type ?? '');
  }

  Color _getStatusColor(String? status) {
    return AdminStatusColors.statusColor(status ?? '');
  }
}
