import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/features/admin/models/finance/generated_report_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// DataTable showing generated report history with name, type,
/// date, and download link.
class ReportHistoryList extends StatelessWidget {
  const ReportHistoryList({
    required this.data,
    super.key,
  });

  final List<GeneratedReportModel> data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;

    if (data.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'admin.finance.no_reports'.tr,
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
          DataColumn(label: Text('admin.finance.report_name'.tr)),
          DataColumn(label: Text('admin.finance.type'.tr)),
          DataColumn(label: Text('admin.finance.generated_at'.tr)),
          DataColumn(label: Text('admin.finance.download'.tr)),
        ],
        rows: data.map((report) {
          return DataRow(
            cells: [
              DataCell(
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 200),
                  child: Text(
                    report.name,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colors.infoBg,
                    borderRadius: BorderRadius.circular(
                      AppTheme.radiusFull,
                    ),
                  ),
                  child: Text(
                    report.type,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.info,
                    ),
                  ),
                ),
              ),
              DataCell(
                Text(
                  DateFormat('dd/MM/yyyy HH:mm').format(report.generatedAt),
                  style: TextStyle(fontSize: 12, color: colors.textMuted),
                ),
              ),
              DataCell(
                report.downloadUrl.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.download_rounded,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                        tooltip: 'admin.finance.download'.tr,
                        onPressed: () {
                          // Download handled by controller
                        },
                      )
                    : Text(
                        'admin.finance.unavailable'.tr,
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textMuted,
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
