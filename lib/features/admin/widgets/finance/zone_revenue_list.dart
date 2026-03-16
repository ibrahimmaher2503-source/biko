import 'package:biko/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// DataTable showing revenue breakdown by zone.
class ZoneRevenueList extends StatelessWidget {
  const ZoneRevenueList({
    required this.zones,
    super.key,
  });

  final List<Map<String, dynamic>> zones;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;

    if (zones.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'admin.finance.no_zone_data'.tr,
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
          DataColumn(label: Text('admin.finance.zone_name'.tr)),
          DataColumn(label: Text('admin.finance.trips'.tr), numeric: true),
          DataColumn(label: Text('admin.finance.revenue'.tr), numeric: true),
          DataColumn(label: Text('admin.finance.avg_per_trip'.tr), numeric: true),
        ],
        rows: zones.map((zone) {
          final name = zone['name'] as String? ?? '';
          final trips = zone['trips'] as num? ?? 0;
          final revenue = zone['revenue'] as num? ?? 0;
          final avg = zone['avg_per_trip'] as num? ?? 0;

          return DataRow(
            cells: [
              DataCell(Text(name)),
              DataCell(Text(trips.toString())),
              DataCell(
                Text(
                  '${revenue.toStringAsFixed(0)} ${'common.egp'.tr}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              DataCell(
                Text('${avg.toStringAsFixed(0)} ${'common.egp'.tr}'),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
