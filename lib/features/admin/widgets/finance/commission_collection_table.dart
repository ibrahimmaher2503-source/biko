import 'package:biko/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// DataTable showing commission collection per driver:
/// driver name, trips, gross revenue, commission, and pending amount.
class CommissionCollectionTable extends StatelessWidget {
  const CommissionCollectionTable({
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
            'finance.no_commission_data'.tr,
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
          DataColumn(label: Text('finance.driver'.tr)),
          DataColumn(label: Text('finance.trips'.tr), numeric: true),
          DataColumn(label: Text('finance.gross'.tr), numeric: true),
          DataColumn(label: Text('finance.commission'.tr), numeric: true),
          DataColumn(label: Text('finance.pending'.tr), numeric: true),
        ],
        rows: data.map((row) {
          final driver = row['driver'] as String? ?? '';
          final trips = row['trips'] as num? ?? 0;
          final gross = row['gross'] as num? ?? 0;
          final commission = row['commission'] as num? ?? 0;
          final pending = row['pending'] as num? ?? 0;

          return DataRow(
            cells: [
              DataCell(
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 160),
                  child: Text(
                    driver,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              DataCell(Text(trips.toString())),
              DataCell(
                Text('${gross.toStringAsFixed(0)} ${'common.egp'.tr}'),
              ),
              DataCell(
                Text(
                  '${commission.toStringAsFixed(0)} ${'common.egp'.tr}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              DataCell(
                Text(
                  '${pending.toStringAsFixed(0)} ${'common.egp'.tr}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: pending > 0 ? colors.warning : colors.success,
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
