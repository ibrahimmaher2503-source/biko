import 'package:biko/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// DataTable showing failed payments with trip, user, amount,
/// method, error, and timestamp columns.
class FailedPaymentsTable extends StatelessWidget {
  const FailedPaymentsTable({
    required this.data,
    super.key,
  });

  final List<Map<String, dynamic>> data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;

    if (data.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'finance.no_failed_payments'.tr,
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
          DataColumn(label: Text('finance.trip'.tr)),
          DataColumn(label: Text('finance.user'.tr)),
          DataColumn(label: Text('finance.amount'.tr), numeric: true),
          DataColumn(label: Text('finance.method'.tr)),
          DataColumn(label: Text('finance.error'.tr)),
          DataColumn(label: Text('finance.timestamp'.tr)),
        ],
        rows: data.map((row) {
          final trip = row['trip'] as String? ?? '';
          final user = row['user'] as String? ?? '';
          final amount = row['amount'] as num? ?? 0;
          final method = row['method'] as String? ?? '';
          final error = row['error'] as String? ?? '';
          final timestamp = row['timestamp'];
          final timeStr = timestamp is DateTime
              ? DateFormat('dd/MM HH:mm').format(timestamp)
              : (timestamp?.toString() ?? '');

          return DataRow(
            cells: [
              DataCell(
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 100),
                  child: Text(
                    trip,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.info,
                    ),
                  ),
                ),
              ),
              DataCell(
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 120),
                  child: Text(user, overflow: TextOverflow.ellipsis),
                ),
              ),
              DataCell(
                Text(
                  '${amount.toStringAsFixed(2)} ${'common.egp'.tr}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
              DataCell(Text(method)),
              DataCell(
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 180),
                  child: Text(
                    error,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              ),
              DataCell(
                Text(
                  timeStr,
                  style: TextStyle(fontSize: 12, color: colors.textMuted),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
