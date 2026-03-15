import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_button.dart';
import 'package:biko/core/widgets/app_text_field.dart';
import 'package:biko/features/auth/controllers/profile_setup_controller.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfileSetupScreen extends GetView<ProfileSetupController> {
  const ProfileSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top bar — back button + title
            _buildTopBar(context),
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    _buildAvatarSection(context),
                    const SizedBox(height: 32),
                    _buildNameField(context),
                    const SizedBox(height: 32),
                    _buildLanguageSelector(context),
                    const SizedBox(height: 32),
                    _buildThemeSelector(context),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
            // Bottom button
            _buildCompleteButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
      child: Row(
        children: [
          IconButton(onPressed: Get.back, icon: const Icon(Icons.arrow_back)),
          Expanded(
            child: Text(
              'profile.title'.tr,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48), // Balance the back button
        ],
      ),
    );
  }

  Widget _buildAvatarSection(BuildContext context) {
    final ext = Theme.of(context).extension<AppColorsExtension>()!;

    return Column(
      children: [
        // Avatar with camera badge
        GestureDetector(
          onTap: controller.pickAvatar,
          child: Stack(
            children: [
              Obx(() {
                final url = controller.avatarUrl.value;
                return CircleAvatar(
                  radius: 64,
                  backgroundColor: ext.surfaceContainer,
                  backgroundImage: url != null
                      ? CachedNetworkImageProvider(url)
                      : null,
                  child: controller.isUploading.value
                      ? const CircularProgressIndicator(strokeWidth: 2.5)
                      : url == null
                      ? Icon(
                          Icons.person,
                          size: 48,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.4),
                        )
                      : null,
                );
              }),
              // Camera badge
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      width: 3,
                    ),
                  ),
                  child: const Icon(
                    Icons.photo_camera,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'profile.upload_photo'.tr,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'profile.upload_hint'.tr,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildNameField(BuildContext context) {
    return AppTextField(
      controller: controller.nameController,
      label: 'profile.full_name'.tr,
      hint: 'profile.name_hint'.tr,
      prefixIcon: Icons.person_outline,
    );
  }

  Widget _buildLanguageSelector(BuildContext context) {
    final ext = Theme.of(context).extension<AppColorsExtension>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'profile.select_language'.tr,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: ext.surfaceContainer,
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            border: Border.all(color: ext.border),
          ),
          child: Obx(
            () => Row(
              children: [
                _languageOption(
                  context,
                  label: 'profile.english'.tr,
                  value: 'en',
                  isSelected: controller.selectedLang.value == 'en',
                ),
                _languageOption(
                  context,
                  label: 'profile.arabic'.tr,
                  value: 'ar',
                  isSelected: controller.selectedLang.value == 'ar',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildThemeSelector(BuildContext context) {
    final ext = Theme.of(context).extension<AppColorsExtension>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'profile.select_theme'.tr,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: ext.surfaceContainer,
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            border: Border.all(color: ext.border),
          ),
          child: Obx(
            () => Row(
              children: [
                _themeOption(
                  context,
                  label: 'profile.light'.tr,
                  value: 'light',
                  icon: Icons.light_mode,
                  isSelected: controller.selectedTheme.value == 'light',
                ),
                _themeOption(
                  context,
                  label: 'profile.dark'.tr,
                  value: 'dark',
                  icon: Icons.dark_mode,
                  isSelected: controller.selectedTheme.value == 'dark',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _themeOption(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required bool isSelected,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () => controller.selectTheme(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 48,
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected
                      ? Colors.white
                      : Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: isSelected
                        ? Colors.white
                        : Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.5),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _languageOption(
    BuildContext context, {
    required String label,
    required String value,
    required bool isSelected,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () => controller.selectLanguage(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 48,
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: isSelected
                    ? Colors.white
                    : Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.5),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompleteButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Obx(
        () => AppButton(
          text: 'profile.complete'.tr,
          onPressed: controller.isSaving.value
              ? null
              : controller.completeProfile,
          trailingIcon: Icons.arrow_forward,
          isLoading: controller.isSaving.value,
        ),
      ),
    );
  }
}
