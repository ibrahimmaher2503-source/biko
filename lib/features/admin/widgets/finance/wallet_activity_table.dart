import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/features/admin/models/finance/wallet_activity_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// DataTable showing wallet activity: user, type, amount,
/// balance after, and timestamp.
class WalletActivityTable extends StatelessWidget {
  const WalletActivityTable({
    required this.data,
    super.key,
  });

  final List<WalletActivityModel> data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;

    if (data.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'finance.no_wallet_activity'.tr,
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
          DataColumn(label: Text('finance.user'.tr)),
          DataColumn(label: Text('finance.type'.tr)),
          DataColumn(label: Text('finance.amount'.tr), numeric: true),
          DataColumn(label: Text('finance.balance_after'.tr), numeric: true),
          DataColumn(label: Text('finance.timestamp'.tr)),
        ],
        rows: data.map((activity) {
          final isCredit = activity.amount >= 0;

          return DataRow(
            cells: [
              DataCell(
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 140),
                  child: Text(
                    activity.userName,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              DataCell(Text(activity.type)),
              DataCell(
                Text(
                  '${isCredit ? '+' : ''}${activity.amount.toStringAsFixed(2)}'
                  ' ${'common.egp'.tr}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isCredit ? colors.success : theme.colorScheme.error,
                  ),
                ),
              ),
              DataCell(
                Text(
                  '${activity.balanceAfter.toStringAsFixed(2)} '
                  '${'common.egp'.tr}',
                ),
              ),
              DataCell(
                Text(
                  DateFormat('dd/MM/yyyy HH:mm').format(activity.timestamp),
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
