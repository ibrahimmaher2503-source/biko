import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// Form with date range picker and generate button for report parameters.
class ReportParameterForm extends StatefulWidget {
  const ReportParameterForm({
    required this.reportType,
    required this.onGenerate,
    super.key,
  });

  final String reportType;
  final Function(DateTimeRange, Map<String, dynamic>) onGenerate;

  @override
  State<ReportParameterForm> createState() => _ReportParameterFormState();
}

class _ReportParameterFormState extends State<ReportParameterForm> {
  DateTimeRange? _dateRange;

  Future<void> _pickDateRange() async {
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: _dateRange,
    );
    if (result != null) {
      setState(() => _dateRange = result);
    }
  }

  void _generate() {
    if (_dateRange == null) return;
    widget.onGenerate(
      _dateRange!,
      {'report_type': widget.reportType},
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'admin.finance.report_parameters'.tr,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickDateRange,
                icon: const Icon(Icons.date_range, size: 18),
                label: Text(
                  _dateRange != null
                      ? '${DateFormat('dd/MM/yyyy').format(_dateRange!.start)}'
                          ' - '
                          '${DateFormat('dd/MM/yyyy').format(_dateRange!.end)}'
                      : 'admin.finance.select_date_range'.tr,
                  style: const TextStyle(fontSize: 13),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  side: BorderSide(color: colors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppTheme.radiusDefault,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 160,
              child: AppButton(
                text: 'admin.finance.generate_report'.tr,
                leadingIcon: Icons.download_rounded,
                onPressed: _dateRange != null ? _generate : null,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
