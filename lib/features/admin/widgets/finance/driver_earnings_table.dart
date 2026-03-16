import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/features/admin/models/finance/driver_earnings_report_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// DataTable displaying driver earnings with gross, commission,
/// tips, bonuses, and net columns.
class DriverEarningsTable extends StatelessWidget {
  const DriverEarningsTable({
    required this.data,
    super.key,
    this.onRowTap,
  });

  final List<DriverEarningsReportModel> data;
  final Function(String)? onRowTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;

    if (data.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'admin.finance.no_earnings_data'.tr,
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
          DataColumn(label: Text('admin.finance.driver'.tr)),
          DataColumn(label: Text('admin.finance.trips'.tr), numeric: true),
          DataColumn(label: Text('admin.finance.gross'.tr), numeric: true),
          DataColumn(label: Text('admin.finance.commission'.tr), numeric: true),
          DataColumn(label: Text('admin.finance.tips'.tr), numeric: true),
          DataColumn(label: Text('admin.finance.bonuses'.tr), numeric: true),
          DataColumn(label: Text('admin.finance.net'.tr), numeric: true),
        ],
        rows: data.map((driver) {
          return DataRow(
            onSelectChanged: onRowTap != null
                ? (_) => onRowTap!(driver.driverUid)
                : null,
            cells: [
              DataCell(
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 140),
                  child: Text(
                    driver.driverName,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              DataCell(Text(driver.totalTrips.toString())),
              DataCell(
                Text(
                  '${driver.grossEarnings.toStringAsFixed(0)} '
                  '${'common.egp'.tr}',
                ),
              ),
              DataCell(
                Text(
                  '${driver.commission.toStringAsFixed(0)} '
                  '${'common.egp'.tr}',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
              DataCell(
                Text(
                  '${driver.tips.toStringAsFixed(0)} ${'common.egp'.tr}',
                ),
              ),
              DataCell(
                Text(
                  '${driver.bonuses.toStringAsFixed(0)} ${'common.egp'.tr}',
                ),
              ),
              DataCell(
                Text(
                  '${driver.netEarnings.toStringAsFixed(0)} '
                  '${'common.egp'.tr}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
