import 'dart:async';
import 'dart:io';

import 'package:biko/core/models/driver_profile_model.dart';
import 'package:biko/core/models/user_model.dart';
import 'package:biko/core/routes/app_routes.dart';
import 'package:biko/core/services/auth_service.dart';
import 'package:biko/core/services/firestore_service.dart';
import 'package:biko/core/services/storage_service.dart';
import 'package:biko/core/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

/// Controller for the driver profile screen.
///
/// Manages user info display, avatar change, and logout.
class DriverProfileController extends GetxController {
  final isLoading = true.obs;
  final user = Rxn<UserModel>();
  final driverProfile = Rxn<DriverProfileModel>();
  final isUploadingAvatar = false.obs;

  final nameController = TextEditingController();

  StreamSubscription<UserModel?>? _userSub;

  @override
  void onInit() {
    super.onInit();
    _init();
  }

  Future<void> _init() async {
    final uid = AuthService.currentUid;
    if (uid == null) {
      isLoading.value = false;
      return;
    }

    // Listen to user document
    _userSub = FirestoreService.listenToUser(uid).listen(
      (u) {
        user.value = u;
        if (u != null) {
          nameController.text = u.name;
        }
      },
      onError: (Object e) =>
          debugPrint('DriverProfileController._init user error: $e'),
    );

    // Load driver profile
    try {
      final profile = await FirestoreService.getDriverProfile(uid);
      driverProfile.value = profile;
    } catch (e) {
      debugPrint('DriverProfileController._init profile error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Pick and upload a new avatar.
  Future<void> changeAvatar() async {
    final uid = AuthService.currentUid;
    if (uid == null) return;

    final file = await StorageService.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    isUploadingAvatar.value = true;
    try {
      final url = await StorageService.uploadAvatar(uid, File(file.path));
      await FirestoreService.updateUser(uid, {'avatar_url': url});
      AppSnackbar.success('profile.avatar_updated'.tr);
    } catch (e) {
      debugPrint('DriverProfileController.changeAvatar error: $e');
      AppSnackbar.error('profile.avatar_failed'.tr);
    } finally {
      isUploadingAvatar.value = false;
    }
  }

  /// Update display name.
  Future<void> updateName() async {
    final uid = AuthService.currentUid;
    if (uid == null) return;

    final name = nameController.text.trim();
    if (name.isEmpty) return;

    try {
      await FirestoreService.updateUser(uid, {'name': name});
      AppSnackbar.success('profile.name_updated'.tr);
    } catch (e) {
      debugPrint('DriverProfileController.updateName error: $e');
      AppSnackbar.error('profile.update_failed'.tr);
    }
  }

  /// Sign out and navigate to splash.
  Future<void> logout() async {
    await AuthService.signOut();
    Get.offAllNamed(AppRoutes.splash);
  }

  @override
  void onClose() {
    _userSub?.cancel();
    nameController.dispose();
    super.onClose();
  }
}
