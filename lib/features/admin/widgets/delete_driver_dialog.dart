import 'package:biko/core/models/driver_profile_model.dart';
import 'package:biko/core/models/user_model.dart';
import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DeleteDriverDialog extends StatelessWidget {
  const DeleteDriverDialog({
    required this.user,
    required this.profile,
    super.key,
  });

  final UserModel user;
  final DriverProfileModel profile;

  static Future<bool?> show(
    BuildContext context, {
    required UserModel user,
    required DriverProfileModel profile,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => DeleteDriverDialog(user: user, profile: profile),
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
                'admin.drivers.delete_title'.tr,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Text(
                '${'admin.drivers.delete_confirm'.tr} ${user.name}?',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.surfaceContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoRow(
                      label: 'common.phone'.tr,
                      value: user.phone,
                    ),
                    const SizedBox(height: 4),
                    _InfoRow(
                      label: 'admin.drivers.total_trips'.tr,
                      value: '${profile.totalTrips}',
                    ),
                    const SizedBox(height: 4),
                    _InfoRow(
                      label: 'admin.drivers.total_earnings'.tr,
                      value:
                          '${profile.totalEarnings.toStringAsFixed(0)} ${'common.egp'.tr}',
                    ),
                    const SizedBox(height: 4),
                    _InfoRow(
                      label: 'admin.drivers.rating'.tr,
                      value: profile.ratingAvg.toStringAsFixed(1),
                    ),
                  ],
                ),
              ),
              if (profile.isOnline) ...[
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
                          'admin.drivers.currently_online_warning'.tr,
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
                      onPressed: () => Navigator.pop(context, true),
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: colors.textMuted, fontSize: 13),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}
