import 'package:biko/core/routes/app_routes.dart';
import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_button.dart';
import 'package:biko/core/widgets/app_loading.dart';
import 'package:biko/core/widgets/app_menu_item.dart';
import 'package:biko/core/widgets/app_snackbar.dart';
import 'package:biko/features/profile/controllers/profile_controller.dart';
import 'package:biko/features/profile/widgets/profile_header.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

/// Main profile screen showing user info and menu options
class ProfileScreen extends GetView<ProfileController> {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('profile.my_profile'.tr), centerTitle: false),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: AppLoading());
        }

        final userData = controller.user.value;
        if (userData == null) {
          return Center(child: Text('profile.load_error'.tr));
        }

        return SingleChildScrollView(
          child: Column(
            children: [
              // Profile header with avatar
              ProfileHeader(
                name: userData.name,
                phone: userData.phone,
                avatarUrl: userData.avatarUrl,
                isUploading: controller.isUploadingAvatar.value,
                onAvatarTap: () => _showAvatarOptions(context),
              ),
              const SizedBox(height: 8),

              // Menu items
              AppMenuItem(
                icon: Icons.person_outline_rounded,
                title: 'profile.edit_profile'.tr,
                onTap: () => Get.toNamed(AppRoutes.customerProfileEdit),
              ),
              AppMenuItem(
                icon: Icons.account_balance_wallet_outlined,
                title: 'wallet.title'.tr,
                onTap: () => Get.toNamed(AppRoutes.customerWallet),
              ),
              AppMenuItem(
                icon: Icons.history_rounded,
                title: 'history.title'.tr,
                onTap: () => Get.toNamed(AppRoutes.tripHistory),
              ),
              AppMenuItem(
                icon: Icons.settings_outlined,
                title: 'profile.settings'.tr,
                onTap: () => Get.toNamed(AppRoutes.customerSettings),
              ),
              AppMenuItem(
                icon: Icons.help_outline_rounded,
                title: 'profile.help'.tr,
                onTap: () => AppSnackbar.info('home.coming_soon'.tr),
              ),
              AppMenuItem(
                icon: Icons.logout_rounded,
                title: 'profile.logout'.tr,
                iconColor: Theme.of(context).colorScheme.error,
                showDivider: false,
                onTap: () => _confirmLogout(context),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      }),
    );
  }

  void _showAvatarOptions(BuildContext context) {
    final ext = Theme.of(context).extension<AppColorsExtension>()!;

    Get.bottomSheet<void>(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppTheme.radiusXl),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: ext.borderSubtle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            _AvatarOption(
              icon: Icons.camera_alt_rounded,
              label: 'profile.take_photo'.tr,
              onTap: () {
                Get.back<void>();
                controller.changeAvatar(ImageSource.camera);
              },
            ),
            const SizedBox(height: 8),
            _AvatarOption(
              icon: Icons.photo_library_rounded,
              label: 'profile.choose_gallery'.tr,
              onTap: () {
                Get.back<void>();
                controller.changeAvatar(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    final ext = Theme.of(context).extension<AppColorsExtension>()!;
    final theme = Theme.of(context);

    Get.bottomSheet<void>(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppTheme.radiusXl),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: ext.borderSubtle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            // Warning icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.logout_rounded,
                color: theme.colorScheme.error,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'profile.logout'.tr,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'profile.logout_confirm'.tr,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: ext.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: 'common.cancel'.tr,
                    onPressed: () => Get.back<void>(),
                    variant: ButtonVariant.outline,
                    height: 48,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    text: 'common.yes'.tr,
                    onPressed: () {
                      Get.back<void>();
                      controller.logout();
                    },
                    height: 48,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarOption extends StatelessWidget {
  const _AvatarOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppColorsExtension>()!;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: ext.surfaceContainer,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(color: ext.borderSubtle),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusDefault),
              ),
              child: Icon(icon, color: AppTheme.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
