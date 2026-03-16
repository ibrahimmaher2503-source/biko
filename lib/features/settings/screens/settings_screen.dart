import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_menu_item.dart';
import 'package:biko/core/widgets/language_selector.dart';
import 'package:biko/features/profile/controllers/profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

/// Settings screen with language, theme, and notification preferences
class SettingsScreen extends GetView<ProfileController> {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = theme.extension<AppColorsExtension>()!;

    return Scaffold(
      appBar: AppBar(title: Text('profile.settings'.tr), centerTitle: false),
      body: Obx(() {
        final userData = controller.user.value;
        final currentLang = userData?.lang ?? 'ar';
        final currentTheme = userData?.theme ?? 'light';

        return SingleChildScrollView(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section: Appearance
              _SectionHeader(
                title: 'settings.appearance'.tr,
                icon: Icons.palette_outlined,
                color: AppTheme.primary,
              ),
              AppMenuItem(
                icon: Icons.language_rounded,
                title: 'settings.language'.tr,
                subtitle: currentLang == 'ar'
                    ? 'settings.arabic'.tr
                    : 'settings.english'.tr,
                onTap: () => _showLanguageSelector(context, currentLang),
              ),
              AppMenuItem(
                icon: Icons.dark_mode_outlined,
                title: 'settings.theme'.tr,
                subtitle: currentTheme == 'dark'
                    ? 'settings.dark_mode'.tr
                    : 'settings.light_mode'.tr,
                trailing: Switch(
                  value: currentTheme == 'dark',
                  onChanged: (isDark) {
                    controller.changeTheme(isDark ? 'dark' : 'light');
                  },
                  activeThumbColor: AppTheme.primary,
                ),
                onTap: () {
                  controller.changeTheme(
                    currentTheme == 'dark' ? 'light' : 'dark',
                  );
                },
              ),

              // Section: Notifications
              _SectionHeader(
                title: 'settings.notifications'.tr,
                icon: Icons.notifications_outlined,
                color: ext.warning,
              ),
              AppMenuItem(
                icon: Icons.notifications_active_outlined,
                title: 'settings.push_notifications'.tr,
                trailing: Switch(
                  value: controller.notificationsEnabled.value,
                  onChanged: (_) => controller.toggleNotifications(),
                  activeThumbColor: AppTheme.primary,
                ),
                onTap: controller.toggleNotifications,
              ),

              // Section: About
              _SectionHeader(
                title: 'settings.about'.tr,
                icon: Icons.info_outline_rounded,
                color: ext.info,
              ),
              AppMenuItem(
                icon: Icons.info_outline_rounded,
                title: 'settings.app_version'.tr,
                subtitle: '1.0.0',
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: ext.surfaceContainer,
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  ),
                  child: Text(
                    'v1.0.0',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: ext.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                onTap: () {},
              ),
              AppMenuItem(
                icon: Icons.description_outlined,
                title: 'settings.terms'.tr,
                onTap: () => launchUrl(
                  Uri.parse('https://biko.app/terms'),
                  mode: LaunchMode.externalApplication,
                ),
              ),
              AppMenuItem(
                icon: Icons.privacy_tip_outlined,
                title: 'settings.privacy'.tr,
                showDivider: false,
                onTap: () => launchUrl(
                  Uri.parse('https://biko.app/privacy'),
                  mode: LaunchMode.externalApplication,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      }),
    );
  }

  void _showLanguageSelector(BuildContext context, String currentLang) {
    Get.bottomSheet<void>(
      LanguageSelector(
        currentLang: currentLang,
        onLanguageChanged: controller.changeLanguage,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.color,
  });

  final String title;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppColorsExtension>()!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusDefault),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: ext.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
