import 'package:biko/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// DataTable showing transactions with time, type, user, amount,
/// status, and a flag action button.
class TransactionTable extends StatelessWidget {
  const TransactionTable({
    required this.data,
    super.key,
    this.onRowTap,
    this.onFlag,
  });

  final List<Map<String, dynamic>> data;
  final Function(Map<String, dynamic>)? onRowTap;
  final Function(String)? onFlag;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;

    if (data.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'finance.no_transactions'.tr,
            style: TextStyle(color: colors.textMuted),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(colors.surfaceContainer),
        columnSpacing: 20,
        columns: [
          DataColumn(label: Text('finance.time'.tr)),
          DataColumn(label: Text('finance.type'.tr)),
          DataColumn(label: Text('finance.user'.tr)),
          DataColumn(label: Text('finance.amount'.tr), numeric: true),
          DataColumn(label: Text('finance.status'.tr)),
          DataColumn(label: Text('finance.actions'.tr)),
        ],
        rows: data.map((tx) {
          final timestamp = tx['timestamp'];
          final timeStr = timestamp is DateTime
              ? DateFormat('dd/MM HH:mm').format(timestamp)
              : (tx['time'] as String? ?? '');
          final type = tx['type'] as String? ?? '';
          final user = tx['user'] as String? ?? '';
          final amount = tx['amount'] as num? ?? 0;
          final status = tx['status'] as String? ?? '';
          final id = tx['id'] as String? ?? '';

          return DataRow(
            onSelectChanged: onRowTap != null
                ? (_) => onRowTap!(tx)
                : null,
            cells: [
              DataCell(Text(timeStr, style: const TextStyle(fontSize: 12))),
              DataCell(Text(type)),
              DataCell(
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 130),
                  child: Text(user, overflow: TextOverflow.ellipsis),
                ),
              ),
              DataCell(
                Text(
                  '${amount.toStringAsFixed(2)} ${'common.egp'.tr}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: amount >= 0
                        ? colors.success
                        : theme.colorScheme.error,
                  ),
                ),
              ),
              DataCell(_buildStatusBadge(status, colors)),
              DataCell(
                onFlag != null
                    ? IconButton(
                        icon: Icon(
                          Icons.flag_outlined,
                          size: 18,
                          color: colors.warning,
                        ),
                        tooltip: 'finance.flag_transaction'.tr,
                        onPressed: () => onFlag!(id),
                      )
                    : const SizedBox.shrink(),
              ),
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
      case 'flagged':
        bg = colors.warningBg;
        fg = colors.warning;
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
        status,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}
