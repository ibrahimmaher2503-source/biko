import 'dart:ui';

import 'package:biko/core/services/auth_service.dart';
import 'package:biko/core/services/fcm_service.dart';
import 'package:biko/core/services/firestore_service.dart';
import 'package:biko/core/widgets/app_snackbar.dart';
import 'package:biko/features/home/controllers/home_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsController extends GetxController {
  static const _keyLanguage = 'selected_language';
  static const _keyTheme = 'theme_mode';
  static const _keyNotifications = 'notifications_enabled';

  static const _allowedLanguages = {'ar', 'en'};
  static const _allowedThemes = {'light', 'dark'};

  final RxString selectedLanguage = 'ar'.obs;
  final RxBool isDarkMode = false.obs;
  final RxBool notificationsEnabled = true.obs;

  @override
  void onInit() {
    super.onInit();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final lang = prefs.getString(_keyLanguage) ?? 'ar';
      if (_allowedLanguages.contains(lang)) {
        selectedLanguage.value = lang;
      } else {
        selectedLanguage.value = 'ar';
        await prefs.setString(_keyLanguage, 'ar');
      }

      final theme = prefs.getString(_keyTheme) ?? 'light';
      if (_allowedThemes.contains(theme)) {
        isDarkMode.value = theme == 'dark';
      } else {
        isDarkMode.value = false;
        await prefs.setString(_keyTheme, 'light');
      }

      notificationsEnabled.value = prefs.getBool(_keyNotifications) ?? true;
    } catch (e) {
      debugPrint('❌ SettingsController._loadPreferences: $e');
    }
  }

  Future<void> changeLanguage(String langCode) async {
    if (!_allowedLanguages.contains(langCode)) return;
    if (langCode == selectedLanguage.value) return;

    final previous = selectedLanguage.value;
    selectedLanguage.value = langCode;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyLanguage, langCode);
    } catch (e) {
      selectedLanguage.value = previous;
      AppSnackbar.error('settings.save_failed'.tr);
      debugPrint('❌ SettingsController.changeLanguage persist: $e');
      return;
    }

    Get.updateLocale(Locale(langCode));

    if (Get.isRegistered<HomeController>()) {
      Get.find<HomeController>().resetBalance();
    }

    final uid = AuthService.currentUid;
    if (uid != null) {
      try {
        await FirestoreService.updateUser(uid, {'lang': langCode});
      } catch (e) {
        debugPrint('❌ SettingsController.changeLanguage remote sync: $e');
      }
    }
  }

  Future<void> toggleTheme() async {
    final newValue = !isDarkMode.value;
    isDarkMode.value = newValue;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyTheme, newValue ? 'dark' : 'light');
    } catch (e) {
      isDarkMode.value = !newValue;
      AppSnackbar.error('settings.save_failed'.tr);
      debugPrint('❌ SettingsController.toggleTheme persist: $e');
      return;
    }

    Get.changeThemeMode(newValue ? ThemeMode.dark : ThemeMode.light);
  }

  Future<void> toggleNotifications() async {
    final newValue = !notificationsEnabled.value;
    final previous = notificationsEnabled.value;
    notificationsEnabled.value = newValue;

    try {
      if (newValue) {
        await FcmService.initialize();
      } else {
        await FcmService.clearToken();
      }
    } catch (e) {
      notificationsEnabled.value = previous;
      AppSnackbar.error('profile.notification_error'.tr);
      debugPrint('❌ SettingsController.toggleNotifications FCM: $e');
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyNotifications, newValue);
    } catch (e) {
      notificationsEnabled.value = previous;
      try {
        if (previous) {
          await FcmService.initialize();
        } else {
          await FcmService.clearToken();
        }
      } catch (_) {}
      AppSnackbar.error('profile.notification_error'.tr);
      debugPrint('❌ SettingsController.toggleNotifications persist: $e');
    }
  }
}
