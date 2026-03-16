import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_button.dart';
import 'package:biko/features/admin/models/finance/suspicious_transaction_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// DataTable showing suspicious/flagged transactions with
/// review and clear action buttons per row.
class SuspiciousTransactionsList extends StatelessWidget {
  const SuspiciousTransactionsList({
    required this.data,
    required this.onReview,
    required this.onClear,
    super.key,
  });

  final List<SuspiciousTransactionModel> data;
  final Function(String) onReview;
  final Function(String) onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;

    if (data.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'admin.finance.no_suspicious_transactions'.tr,
            style: TextStyle(color: colors.textMuted),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(colors.surfaceContainer),
        columnSpacing: 16,
        columns: [
          DataColumn(label: Text('admin.finance.user'.tr)),
          DataColumn(label: Text('admin.finance.amount'.tr), numeric: true),
          DataColumn(label: Text('admin.finance.reason'.tr)),
          DataColumn(label: Text('admin.finance.flagged_at'.tr)),
          DataColumn(label: Text('admin.finance.status'.tr)),
          DataColumn(label: Text('admin.finance.actions'.tr)),
        ],
        rows: data.map((item) {
          return DataRow(
            cells: [
              DataCell(
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 130),
                  child: Text(
                    item.userName,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              DataCell(
                Text(
                  '${item.amount.toStringAsFixed(2)} ${'common.egp'.tr}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
              DataCell(
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 180),
                  child: Text(
                    item.reason,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              DataCell(
                Text(
                  DateFormat('dd/MM HH:mm').format(item.flaggedAt),
                  style: TextStyle(fontSize: 12, color: colors.textMuted),
                ),
              ),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: item.isReviewed
                        ? colors.successBg
                        : colors.warningBg,
                    borderRadius: BorderRadius.circular(
                      AppTheme.radiusFull,
                    ),
                  ),
                  child: Text(
                    item.isReviewed
                        ? 'admin.finance.reviewed'.tr
                        : 'admin.finance.pending_review'.tr,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: item.isReviewed
                          ? colors.success
                          : colors.warning,
                    ),
                  ),
                ),
              ),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!item.isReviewed) ...[
                      SizedBox(
                        width: 80,
                        height: 32,
                        child: AppButton(
                          text: 'admin.finance.review'.tr,
                          variant: ButtonVariant.outline,
                          height: 32,
                          onPressed: () => onReview(item.id),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    SizedBox(
                      width: 70,
                      height: 32,
                      child: AppButton(
                        text: 'admin.finance.clear'.tr,
                        variant: ButtonVariant.text,
                        height: 32,
                        onPressed: () => onClear(item.id),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
