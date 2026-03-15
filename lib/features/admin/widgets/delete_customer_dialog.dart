import 'package:biko/core/models/user_model.dart';
import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DeleteCustomerDialog extends StatelessWidget {
  const DeleteCustomerDialog({
    required this.user,
    required this.hasActiveTrips,
    super.key,
  });

  final UserModel user;
  final bool hasActiveTrips;

  static Future<bool?> show(
    BuildContext context, {
    required UserModel user,
    required bool hasActiveTrips,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => DeleteCustomerDialog(
        user: user,
        hasActiveTrips: hasActiveTrips,
      ),
    );
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
                'admin.customers.delete_title'.tr,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Text(
                '${'admin.customers.delete_confirm'.tr} ${user.name}?',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                user.phone,
                style: TextStyle(color: colors.textMuted),
              ),
              if (hasActiveTrips) ...[
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
                          'admin.customers.has_active_trips'.tr,
                          style: TextStyle(color: colors.warning),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
                    width: 120,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.error,
                        foregroundColor: theme.colorScheme.onError,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusDefault,
                          ),
                        ),
                        minimumSize: const Size(120, 44),
                      ),
                      onPressed: hasActiveTrips
                          ? null
                          : () => Navigator.pop(context, true),
                      child: Text('common.delete'.tr),
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
