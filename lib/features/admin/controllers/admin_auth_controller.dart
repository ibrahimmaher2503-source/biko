import 'package:biko/core/routes/app_routes.dart';
import 'package:biko/features/admin/models/admin_user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

/// Admin authentication controller
///
/// Manages admin panel auth state. Verifies `role: admin` custom claims.
/// Registered permanently in the Admin app entry point.
class AdminAuthController extends GetxController {
  final isAuthenticated = false.obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final adminUser = Rxn<AdminUserModel>();
  final _isSuperAdmin = false.obs;

  /// Whether the current admin has super admin privileges
  bool get isSuperAdmin => _isSuperAdmin.value;

  /// Current Firebase Auth user (convenience accessor)
  User? get currentUser => FirebaseAuth.instance.currentUser;

  @override
  void onInit() {
    super.onInit();
    checkAdminAccess();
  }

  /// Check if the current user has admin claims
  Future<void> checkAdminAccess() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      isAuthenticated.value = false;
      return;
    }

    try {
      final token = await user.getIdTokenResult();
      final role = token.claims?['role'] as String?;

      if (role == 'admin' || role == 'super_admin') {
        _isSuperAdmin.value = role == 'super_admin';
        adminUser.value = AdminUserModel.fromFirebaseUser(
          user,
          token.claims ?? {},
        );
        isAuthenticated.value = true;
      } else {
        isAuthenticated.value = false;
      }
    } catch (e) {
      debugPrint('checkAdminAccess error: $e');
      isAuthenticated.value = false;
    }
  }

  /// Sign in as admin (accepts positional args from login screen)
  Future<void> signIn(String email, String password) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final credential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        errorMessage.value = 'admin.login.error'.tr;
        isAuthenticated.value = false;
        return;
      }

      // Check custom claims for admin role
      final token = await user.getIdTokenResult();
      final role = token.claims?['role'] as String?;

      if (role != 'admin' && role != 'super_admin') {
        errorMessage.value = 'admin.login.not_admin'.tr;
        await FirebaseAuth.instance.signOut();
        isAuthenticated.value = false;
        return;
      }

      _isSuperAdmin.value = role == 'super_admin';

      adminUser.value = AdminUserModel.fromFirebaseUser(
        user,
        token.claims ?? {},
      );

      isAuthenticated.value = true;
      Get.offAllNamed(AppRoutes.adminDashboard);
    } on FirebaseAuthException catch (e) {
      errorMessage.value = e.message ?? 'admin.login.error'.tr;
      isAuthenticated.value = false;
    } catch (e) {
      debugPrint('AdminAuthController.signIn failed: $e');
      errorMessage.value = 'admin.login.error'.tr;
      isAuthenticated.value = false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    isAuthenticated.value = false;
    adminUser.value = null;
    _isSuperAdmin.value = false;
    Get.offAllNamed(AppRoutes.adminLogin);
  }
}
