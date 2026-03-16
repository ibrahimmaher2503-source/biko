import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_button.dart';
import 'package:biko/core/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Dialog for scheduling a recurring report.
/// Returns a Map with frequency, email, and reportType, or null.
class ScheduleReportDialog extends StatefulWidget {
  const ScheduleReportDialog({super.key});

  /// Show the dialog and return schedule details or null if cancelled.
  static Future<Map<String, dynamic>?> show() {
    return Get.dialog<Map<String, dynamic>?>(
      const ScheduleReportDialog(),
    );
  }

  @override
  State<ScheduleReportDialog> createState() => _ScheduleReportDialogState();
}

class _ScheduleReportDialogState extends State<ScheduleReportDialog> {
  String _frequency = 'weekly';
  String _reportType = 'revenue';
  late final TextEditingController _emailController;

  static const List<String> _frequencies = [
    'daily',
    'weekly',
    'monthly',
  ];

  static const List<String> _reportTypes = [
    'revenue',
    'driver_payout',
    'transaction',
    'custom',
  ];

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _confirm() {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    Get.back<Map<String, dynamic>>(
      result: {
        'frequency': _frequency,
        'email': email,
        'report_type': _reportType,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'admin.finance.schedule_report'.tr,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              // Frequency dropdown
              Text(
                'admin.finance.frequency'.tr,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _frequency,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                items: _frequencies.map((freq) {
                  return DropdownMenuItem(
                    value: freq,
                    child: Text('admin.finance.freq_$freq'.tr),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _frequency = value);
                },
              ),
              const SizedBox(height: 16),
              // Report type dropdown
              Text(
                'admin.finance.report_type'.tr,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _reportType,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                items: _reportTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text('admin.finance.report_$type'.tr),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _reportType = value);
                },
              ),
              const SizedBox(height: 16),
              // Email field
              AppTextField(
                controller: _emailController,
                label: 'admin.finance.email'.tr,
                hint: 'admin.finance.enter_email'.tr,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 100,
                    child: AppButton(
                      text: 'common.cancel'.tr,
                      variant: ButtonVariant.text,
                      onPressed: () => Get.back<Map<String, dynamic>?>(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 140,
                    child: AppButton(
                      text: 'admin.finance.schedule'.tr,
                      onPressed: _confirm,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
