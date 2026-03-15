import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:biko/core/models/user_model.dart';
import 'package:biko/core/services/firestore_service.dart';
import 'package:biko/core/services/storage_service.dart';
import 'package:biko/core/widgets/app_snackbar.dart';
import 'package:biko/features/auth/controllers/auth_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

/// Controller for profile and settings screens
class ProfileController extends GetxController {
  // ==================== Observable State ====================

  final Rx<UserModel?> user = Rx<UserModel?>(null);
  final RxBool isLoading = true.obs;
  final RxBool isSaving = false.obs;
  final RxBool isUploadingAvatar = false.obs;
  final RxString errorMessage = ''.obs;
  final RxBool notificationsEnabled = true.obs;

  StreamSubscription<UserModel?>? _userSub;
  String _uid = '';

  // ==================== Lifecycle ====================

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>?;
    _uid = args?['uid'] as String? ?? '';
    _listenToUser();
  }

  @override
  void onClose() {
    _userSub?.cancel();
    super.onClose();
  }

  // ==================== Data Loading ====================

  void _listenToUser() {
    if (_uid.isEmpty) {
      isLoading.value = false;
      return;
    }
    _userSub = FirestoreService.listenToUser(_uid).listen(
      (userData) {
        user.value = userData;
        isLoading.value = false;
      },
      onError: (Object e) {
        debugPrint('❌ ProfileController._listenToUser: $e');
        isLoading.value = false;
        errorMessage.value = 'profile.load_error';
      },
    );
  }

  // ==================== Profile Actions ====================

  /// Save profile name
  Future<void> saveProfile(String newName) async {
    if (isSaving.value || newName.isEmpty) return;
    try {
      isSaving.value = true;
      await FirestoreService.updateUser(_uid, {'name': newName});
      AppSnackbar.success('profile.saved'.tr);
      Get.back<void>();
    } catch (e) {
      debugPrint('❌ ProfileController.saveProfile: $e');
      AppSnackbar.error('profile.save_error'.tr);
    } finally {
      isSaving.value = false;
    }
  }

  /// Change avatar from camera or gallery
  Future<void> changeAvatar(ImageSource source) async {
    try {
      isUploadingAvatar.value = true;
      final xFile = await StorageService.pickImage(source: source);
      if (xFile == null) {
        isUploadingAvatar.value = false;
        return;
      }
      final file = File(xFile.path);
      final url = await StorageService.uploadAvatar(_uid, file);
      await FirestoreService.updateUser(_uid, {'avatar_url': url});
      AppSnackbar.success('profile.avatar_updated'.tr);
    } catch (e) {
      debugPrint('❌ ProfileController.changeAvatar: $e');
      AppSnackbar.error('profile.avatar_error'.tr);
    } finally {
      isUploadingAvatar.value = false;
    }
  }

  /// Change app language
  Future<void> changeLanguage(String lang) async {
    try {
      await FirestoreService.updateUser(_uid, {'lang': lang});
      Get.updateLocale(Locale(lang));
    } catch (e) {
      debugPrint('❌ ProfileController.changeLanguage: $e');
    }
  }

  /// Change theme mode
  Future<void> changeTheme(String mode) async {
    try {
      await FirestoreService.updateUser(_uid, {'theme': mode});
    } catch (e) {
      debugPrint('❌ ProfileController.changeTheme: $e');
    }
  }

  /// Toggle push notifications on/off
  void toggleNotifications() {
    notificationsEnabled.value = !notificationsEnabled.value;
    // TODO: persist preference and update FCM token registration
  }

  /// Logout — delegates to AuthController for proper Firebase sign-out
  Future<void> logout() async {
    await Get.find<AuthController>().signOut();
  }
}
