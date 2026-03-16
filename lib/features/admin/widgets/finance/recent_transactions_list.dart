import 'package:biko/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// DataTable displaying recent transactions with time, type, user,
/// amount, and status columns.
class RecentTransactionsList extends StatelessWidget {
  const RecentTransactionsList({
    required this.transactions,
    super.key,
    this.onRowTap,
  });

  final List<Map<String, dynamic>> transactions;
  final Function(Map<String, dynamic>)? onRowTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;

    if (transactions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'admin.finance.no_transactions'.tr,
            style: TextStyle(color: colors.textMuted),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(colors.surfaceContainer),
        columnSpacing: 24,
        columns: [
          DataColumn(label: Text('admin.finance.time'.tr)),
          DataColumn(label: Text('admin.finance.type'.tr)),
          DataColumn(label: Text('admin.finance.user'.tr)),
          DataColumn(label: Text('admin.finance.amount'.tr), numeric: true),
          DataColumn(label: Text('admin.finance.status'.tr)),
        ],
        rows: transactions.map((tx) {
          final timestamp = tx['timestamp'];
          final timeStr = timestamp is DateTime
              ? DateFormat('HH:mm').format(timestamp)
              : (tx['time'] as String? ?? '');
          final type = tx['type'] as String? ?? '';
          final user = tx['user'] as String? ?? '';
          final amount = tx['amount'] as num? ?? 0;
          final status = tx['status'] as String? ?? '';

          return DataRow(
            onSelectChanged: onRowTap != null
                ? (_) => onRowTap!(tx)
                : null,
            cells: [
              DataCell(Text(timeStr)),
              DataCell(Text(type)),
              DataCell(
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 140),
                  child: Text(
                    user,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              DataCell(
                Text(
                  '${amount.toStringAsFixed(2)} ${'common.egp'.tr}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: amount >= 0 ? colors.success : theme.colorScheme.error,
                  ),
                ),
              ),
              DataCell(_buildStatusBadge(status, colors)),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatusBadge(String status, AppColorsExtension colors) {
    Color bg;
    Color fg;
    switch (status.toLowerCase()) {
      case 'completed':
      case 'success':
        bg = colors.successBg;
        fg = colors.success;
      case 'pending':
        bg = colors.warningBg;
        fg = colors.warning;
      case 'failed':
        bg = Get.theme.colorScheme.error.withValues(alpha: 0.1);
        fg = Get.theme.colorScheme.error;
      default:
        bg = colors.surfaceContainer;
        fg = colors.textMuted;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Text(
        'admin.finance.status_${status.toLowerCase()}'.tr,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}
