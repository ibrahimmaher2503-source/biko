import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// Data model for a single promo usage record.
class PromoUsageRecord {
  const PromoUsageRecord({
    required this.userId,
    required this.userName,
    required this.tripId,
    required this.discountAmount,
    required this.usedAt,
  });

  final String userId;
  final String userName;
  final String tripId;
  final double discountAmount;
  final DateTime usedAt;
}

class PromoUsageHistory extends StatelessWidget {
  const PromoUsageHistory({
    required this.records,
    super.key,
  });

  final List<PromoUsageRecord> records;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    final theme = Theme.of(context);
    final fmt = DateFormat('dd/MM/yyyy HH:mm');

    if (records.isEmpty) {
      return AppCard(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'admin.promos.no_usage_history'.tr,
              style: TextStyle(color: colors.textMuted),
            ),
          ),
        ),
      );
    }

    return AppCard(
      padding: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'admin.promos.usage_history'.tr,
              style: theme.textTheme.titleMedium,
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                colors.surfaceContainer,
              ),
              columns: [
                DataColumn(
                  label: Text(
                    'admin.promos.user'.tr,
                    style: TextStyle(color: colors.textMuted),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'admin.promos.trip_id'.tr,
                    style: TextStyle(color: colors.textMuted),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'admin.promos.discount_applied'.tr,
                    style: TextStyle(color: colors.textMuted),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'admin.promos.used_at'.tr,
                    style: TextStyle(color: colors.textMuted),
                  ),
                ),
              ],
              rows: records
                  .map(
                    (r) => DataRow(
                      cells: [
                        DataCell(Text(r.userName)),
                        DataCell(
                          Text(
                            r.tripId.length > 8
                                ? '${r.tripId.substring(0, 8)}...'
                                : r.tripId,
                          ),
                        ),
                        DataCell(
                          Text(
                            '${r.discountAmount.toStringAsFixed(0)} '
                            '${'common.egp'.tr}',
                          ),
                        ),
                        DataCell(Text(fmt.format(r.usedAt))),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
