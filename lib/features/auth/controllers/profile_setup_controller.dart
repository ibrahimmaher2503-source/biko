import 'dart:io';

import 'package:biko/core/routes/app_routes.dart';
import 'package:biko/core/services/auth_service.dart';
import 'package:biko/core/services/firestore_service.dart';
import 'package:biko/core/services/storage_service.dart';
import 'package:biko/core/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileSetupController extends GetxController {
  final nameController = TextEditingController();
  final avatarUrl = Rxn<String>();
  final selectedLang = 'en'.obs;
  final selectedTheme = 'light'.obs;
  final isUploading = false.obs;
  final isSaving = false.obs;

  @override
  void onInit() {
    super.onInit();
    _prefillFromAuth();
  }

  @override
  void onClose() {
    nameController.dispose();
    super.onClose();
  }

  /// Pre-fill name and avatar from Firebase Auth user (Google sign-in)
  void _prefillFromAuth() {
    final user = AuthService.currentUser;
    if (user == null) return;

    final displayName = user.displayName;
    if (displayName != null && displayName.isNotEmpty) {
      nameController.text = displayName;
    }

    final photoURL = user.photoURL;
    if (photoURL != null) {
      avatarUrl.value = photoURL;
    }
  }

  /// Show bottom sheet to pick image from camera or gallery
  Future<void> pickAvatar() async {
    final source = await Get.bottomSheet<ImageSource>(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Get.theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text('profile.pick_camera'.tr),
              onTap: () => Get.back(result: ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text('profile.pick_gallery'.tr),
              onTap: () => Get.back(result: ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final file = await StorageService.pickImage(source: source);
    if (file == null) return;

    isUploading.value = true;
    try {
      final uid = AuthService.currentUser!.uid;
      final url = await StorageService.uploadAvatar(uid, File(file.path));
      avatarUrl.value = url;
    } catch (e) {
      AppSnackbar.error(e.toString());
    } finally {
      isUploading.value = false;
    }
  }

  /// Update app locale immediately when language is selected
  void selectLanguage(String lang) {
    selectedLang.value = lang;
    Get.updateLocale(Locale(lang));
  }

  /// Update theme immediately and persist to SharedPreferences
  Future<void> selectTheme(String theme) async {
    selectedTheme.value = theme;
    Get.changeThemeMode(theme == 'dark' ? ThemeMode.dark : ThemeMode.light);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', theme);
  }

  /// Validate and save profile to Firestore
  Future<void> completeProfile() async {
    final name = nameController.text.trim();
    if (name.isEmpty) {
      AppSnackbar.warning('profile.name_required'.tr);
      return;
    }

    isSaving.value = true;
    try {
      final uid = AuthService.currentUser!.uid;
      await FirestoreService.updateUser(uid, {
        'name': name,
        'lang': selectedLang.value,
        'theme': selectedTheme.value,
        if (avatarUrl.value != null) 'avatar_url': avatarUrl.value,
      });

      // Determine the app type for navigation
      final user = await FirestoreService.getUser(uid);
      if (user != null && user.type.name == 'driver') {
        Get.offAllNamed(AppRoutes.driverRegistration);
      } else {
        Get.offAllNamed(AppRoutes.customerHome);
      }
    } catch (e) {
      AppSnackbar.error(e.toString());
    } finally {
      isSaving.value = false;
    }
  }
}
