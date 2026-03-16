import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_card.dart';
import 'package:biko/features/driver_settings/controllers/driver_settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Driver settings screen with language, theme, and notification toggles.
///
/// Matches stitch design: grouped settings in cards with tinted icon
/// containers, clean toggle layout, and version badge.
class DriverSettingsScreen extends GetView<DriverSettingsController> {
  const DriverSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = theme.extension<AppColorsExtension>()!;

    return Scaffold(
      appBar: AppBar(title: Text('settings.title'.tr), centerTitle: false),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Language setting
          _SettingCard(
            icon: Icons.language_rounded,
            iconColor: ext.info,
            title: 'settings.language'.tr,
            subtitle: Obx(
              () => Text(
                controller.isArabic.value
                    ? 'settings.arabic'.tr
                    : 'settings.english'.tr,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: ext.textMuted,
                ),
              ),
            ),
            trailing: Obx(
              () => Switch(
                value: controller.isArabic.value,
                onChanged: controller.toggleLanguage,
                activeThumbColor: AppTheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Theme setting
          _SettingCard(
            icon: Icons.brightness_6_rounded,
            iconColor: ext.warning,
            title: 'settings.theme'.tr,
            subtitle: Obx(
              () => Text(
                controller.isDarkMode.value
                    ? 'settings.dark'.tr
                    : 'settings.light'.tr,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: ext.textMuted,
                ),
              ),
            ),
            trailing: Obx(
              () => Switch(
                value: controller.isDarkMode.value,
                onChanged: controller.toggleTheme,
                activeThumbColor: AppTheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Notifications setting
          _SettingCard(
            icon: Icons.notifications_rounded,
            iconColor: ext.success,
            title: 'settings.notifications'.tr,
            subtitle: Obx(
              () => Text(
                controller.notificationsEnabled.value
                    ? 'settings.notifications_on'.tr
                    : 'settings.notifications_off'.tr,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: ext.textMuted,
                ),
              ),
            ),
            trailing: Obx(
              () => Switch(
                value: controller.notificationsEnabled.value,
                onChanged: controller.toggleNotifications,
                activeThumbColor: AppTheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 32),

          // App version badge
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: ext.surfaceContainer,
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              ),
              child: Text(
                'settings.version'.tr,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: ext.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Single settings item with tinted icon, title, subtitle, and trailing widget.
class _SettingCard extends StatelessWidget {
  const _SettingCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Tinted icon container
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            // Title + subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  subtitle,
                ],
              ),
            ),
            // Trailing (switch)
            trailing,
          ],
        ),
      ),
    );
  }
}
