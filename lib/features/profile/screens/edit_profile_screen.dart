import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_button.dart';
import 'package:biko/core/widgets/app_loading.dart';
import 'package:biko/core/widgets/app_text_field.dart';
import 'package:biko/features/profile/controllers/profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Screen for editing user profile name
///
/// Uses StatefulWidget to properly manage TextEditingController lifecycle.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final ProfileController controller;
  late final TextEditingController nameController;

  @override
  void initState() {
    super.initState();
    controller = Get.find<ProfileController>();
    nameController = TextEditingController(
      text: controller.user.value?.name ?? '',
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppColorsExtension>()!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('profile.edit_profile'.tr)),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: AppLoading());
        }

        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Section header with icon
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                        AppTheme.radiusLarge,
                      ),
                    ),
                    child: const Icon(
                      Icons.person_outline_rounded,
                      color: AppTheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'profile.edit_profile'.tr,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              AppTextField(
                controller: nameController,
                label: 'profile.name'.tr,
                hint: 'profile.name_hint'.tr,
                prefixIcon: Icons.person_outline,
                textInputAction: TextInputAction.done,
                onEditingComplete: () =>
                    controller.saveProfile(nameController.text.trim()),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: ext.infoBg,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  border: Border.all(
                    color: ext.info.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 18, color: ext.info),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'profile.phone_readonly'.tr,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: ext.info,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Obx(
                () => AppButton(
                  text: 'common.save'.tr,
                  onPressed: () =>
                      controller.saveProfile(nameController.text.trim()),
                  isLoading: controller.isSaving.value,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      }),
    );
  }
}
