import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_button.dart';
import 'package:biko/core/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ForceOfflineDialog extends StatefulWidget {
  const ForceOfflineDialog({
    required this.driverName,
    super.key,
  });

  final String driverName;

  static Future<String?> show(
    BuildContext context, {
    required String driverName,
  }) {
    return showDialog<String>(
      context: context,
      builder: (_) => ForceOfflineDialog(driverName: driverName),
    );
  }

  @override
  State<ForceOfflineDialog> createState() => _ForceOfflineDialogState();
}

class _ForceOfflineDialogState extends State<ForceOfflineDialog> {
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 450),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'admin.drivers.force_offline_title'.tr,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Text(
                '${'admin.drivers.force_offline_confirm'.tr} '
                '${widget.driverName}?',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.warningBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: colors.warning,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'admin.drivers.force_offline_warning'.tr,
                        style: TextStyle(color: colors.warning),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'admin.drivers.offline_reason'.tr,
                controller: _reasonController,
                maxLines: 3,
                hint: 'admin.drivers.offline_reason_hint'.tr,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 120,
                    child: AppButton(
                      text: 'common.cancel'.tr,
                      variant: ButtonVariant.outline,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 160,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.warning,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusDefault,
                          ),
                        ),
                        minimumSize: const Size(160, 44),
                      ),
                      onPressed: () {
                        final reason = _reasonController.text.trim();
                        Navigator.pop(
                          context,
                          reason.isEmpty
                              ? 'admin.drivers.no_reason'.tr
                              : reason,
                        );
                      },
                      child: Text('admin.drivers.force_offline'.tr),
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
