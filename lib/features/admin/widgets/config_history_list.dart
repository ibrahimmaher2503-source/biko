import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// Data model for a single configuration change record.
class ConfigChangeRecord {
  const ConfigChangeRecord({
    required this.key,
    required this.oldValue,
    required this.newValue,
    required this.changedBy,
    required this.changedAt,
  });

  final String key;
  final String oldValue;
  final String newValue;
  final String changedBy;
  final DateTime changedAt;
}

class ConfigHistoryList extends StatelessWidget {
  const ConfigHistoryList({
    required this.records,
    super.key,
  });

  final List<ConfigChangeRecord> records;

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
              'admin.config.no_history'.tr,
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
              'admin.config.change_history'.tr,
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
                    'admin.config.key'.tr,
                    style: TextStyle(color: colors.textMuted),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'admin.config.old_value'.tr,
                    style: TextStyle(color: colors.textMuted),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'admin.config.new_value'.tr,
                    style: TextStyle(color: colors.textMuted),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'admin.config.changed_by'.tr,
                    style: TextStyle(color: colors.textMuted),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'admin.config.changed_at'.tr,
                    style: TextStyle(color: colors.textMuted),
                  ),
                ),
              ],
              rows: records
                  .map(
                    (r) => DataRow(
                      cells: [
                        DataCell(
                          Text(
                            r.key,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            r.oldValue,
                            style: TextStyle(
                              color: theme.colorScheme.error,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            r.newValue,
                            style: TextStyle(color: colors.success),
                          ),
                        ),
                        DataCell(Text(r.changedBy)),
                        DataCell(Text(fmt.format(r.changedAt))),
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
