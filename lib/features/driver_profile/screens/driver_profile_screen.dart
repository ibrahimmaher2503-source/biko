import 'package:biko/core/routes/app_routes.dart';
import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_button.dart';
import 'package:biko/core/widgets/app_card.dart';
import 'package:biko/core/widgets/app_dialog.dart';
import 'package:biko/core/widgets/app_loading.dart';
import 'package:biko/core/widgets/app_text_field.dart';
import 'package:biko/features/driver_profile/controllers/driver_profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Driver profile screen matching stitch profile setup design.
///
/// Large avatar with camera overlay, name edit, vehicle info card,
/// quick navigation links, and logout button.
class DriverProfileScreen extends GetView<DriverProfileController> {
  const DriverProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = theme.extension<AppColorsExtension>()!;

    return Scaffold(
      appBar: AppBar(title: Text('profile.title'.tr), centerTitle: true),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: AppLoading());
        }

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 8),

            // Avatar section (matches stitch: large circle + camera badge)
            Center(
              child: GestureDetector(
                onTap: controller.changeAvatar,
                child: Obx(() {
                  final avatarUrl = controller.user.value?.avatarUrl;
                  return Column(
                    children: [
                      Stack(
                        children: [
                          // Outer ring
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: ext.borderSubtle,
                                width: 3,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 56,
                              backgroundColor: AppTheme.neutralTint,
                              backgroundImage: avatarUrl != null &&
                                      avatarUrl.isNotEmpty
                                  ? NetworkImage(avatarUrl)
                                  : null,
                              child: avatarUrl == null ||
                                      avatarUrl.isEmpty
                                  ? Icon(
                                      Icons.person,
                                      size: 48,
                                      color: ext.textMuted,
                                    )
                                  : null,
                            ),
                          ),
                          // Loading overlay
                          if (controller.isUploadingAvatar.value)
                            Positioned.fill(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Colors.black
                                      .withValues(alpha: 0.3),
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: AppLoading(size: 28),
                                ),
                              ),
                            ),
                          // Camera badge
                          Positioned(
                            bottom: 4,
                            right: 4,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppTheme.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: ext.surfaceElevated,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primary.withValues(
                                      alpha: 0.3,
                                    ),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'profile.upload_photo'.tr,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
            const SizedBox(height: 28),

            // Name field
            Text(
              'profile.name'.tr,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            AppTextField(
              controller: controller.nameController,
              hint: 'profile.name_hint'.tr,
              suffixIcon: Icons.person_outline,
            ),
            const SizedBox(height: 12),
            AppButton(
              text: 'profile.save_name'.tr,
              onPressed: controller.updateName,
              variant: ButtonVariant.secondary,
            ),
            const SizedBox(height: 28),

            // Vehicle info (read-only card)
            Obx(() {
              final profile = controller.driverProfile.value;
              if (profile == null) return const SizedBox.shrink();

              return AppCard(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusLarge,
                              ),
                            ),
                            child: const Icon(
                              Icons.two_wheeler,
                              color: AppTheme.primary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'profile.vehicle_info'.tr,
                            style:
                                theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _InfoRow(
                        label: 'profile.vehicle_type'.tr,
                        value: profile.vehicleType.toJson(),
                      ),
                      Divider(color: ext.borderSubtle, height: 20),
                      _InfoRow(
                        label: 'profile.plate_number'.tr,
                        value: profile.plateNumber,
                      ),
                      Divider(color: ext.borderSubtle, height: 20),
                      _InfoRow(
                        label: 'profile.vehicle_model'.tr,
                        value: profile.vehicleModel,
                      ),
                      Divider(color: ext.borderSubtle, height: 20),
                      _InfoRow(
                        label: 'profile.license'.tr,
                        value: profile.licenseNumber,
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 20),

            // Quick links
            AppCard(
              child: Column(
                children: [
                  _QuickLinkTile(
                    icon: Icons.star_rounded,
                    iconColor: ext.warning,
                    title: 'profile.my_ratings'.tr,
                    onTap: () => Get.toNamed(AppRoutes.driverRatings),
                  ),
                  Divider(color: ext.borderSubtle, height: 1),
                  _QuickLinkTile(
                    icon: Icons.account_balance_wallet_rounded,
                    iconColor: ext.success,
                    title: 'profile.my_wallet'.tr,
                    onTap: () => Get.toNamed(AppRoutes.driverWallet),
                  ),
                  Divider(color: ext.borderSubtle, height: 1),
                  _QuickLinkTile(
                    icon: Icons.settings_rounded,
                    iconColor: ext.textMuted,
                    title: 'profile.settings'.tr,
                    onTap: () => Get.toNamed(AppRoutes.driverSettings),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Logout
            AppButton(
              text: 'profile.logout'.tr,
              onPressed: () async {
                final confirmed = await AppDialog.confirm(
                  title: 'profile.logout_confirm_title'.tr,
                  content: 'profile.logout_confirm_message'.tr,
                  confirmText: 'profile.logout'.tr,
                  isDestructive: true,
                );
                if (confirmed) {
                  await controller.logout();
                }
              },
              variant: ButtonVariant.outline,
            ),
            const SizedBox(height: 32),
          ],
        );
      }),
    );
  }
}

/// Quick link tile with colored icon.
class _QuickLinkTile extends StatelessWidget {
  const _QuickLinkTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: Theme.of(context).extension<AppColorsExtension>()!.textMuted,
      ),
      onTap: onTap,
    );
  }
}

/// Vehicle info row: label on left, value on right.
class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = theme.extension<AppColorsExtension>()!;

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: ext.textMuted,
            ),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
