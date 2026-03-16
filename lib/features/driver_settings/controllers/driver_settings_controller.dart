import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Controller for the driver settings screen.
///
/// Manages language, theme, and notification preferences.
class DriverSettingsController extends GetxController {
  late final SharedPreferences _prefs;

  final isArabic = true.obs;
  final isDarkMode = false.obs;
  final notificationsEnabled = true.obs;

  @override
  void onInit() {
    super.onInit();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    isArabic.value = _prefs.getBool('is_arabic') ?? true;
    isDarkMode.value = _prefs.getBool('is_dark_mode') ?? false;
    notificationsEnabled.value =
        _prefs.getBool('notifications_enabled') ?? true;
  }

  /// Toggle language between Arabic and English.
  void toggleLanguage(bool arabic) {
    isArabic.value = arabic;
    _prefs.setBool('is_arabic', arabic);

    final locale = arabic ? const Locale('ar') : const Locale('en');
    Get.updateLocale(locale);
  }

  /// Toggle dark/light mode.
  void toggleTheme(bool dark) {
    isDarkMode.value = dark;
    _prefs.setBool('is_dark_mode', dark);

    Get.changeThemeMode(dark ? ThemeMode.dark : ThemeMode.light);
  }

  /// Toggle notifications.
  void toggleNotifications(bool enabled) {
    notificationsEnabled.value = enabled;
    _prefs.setBool('notifications_enabled', enabled);
  }
}
