import 'package:biko/core/routes/app_routes.dart';
import 'package:biko/core/services/auth_service.dart';
import 'package:biko/features/admin/models/admin_user_model.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

/// Admin authentication controller
///
/// Manages admin panel auth state. Verifies `role: admin` custom claims.
/// Registered permanently in the Admin app entry point.
///
/// All Firebase Auth access goes through [AuthService] (RULE-06 compliance).
class AdminAuthController extends GetxController {
  /// Route to navigate to after a successful login.
  /// Dispatcher app overrides this to [AppRoutes.dispatchHome].
  static String postLoginRoute = AppRoutes.adminDashboard;

  final isAuthenticated = false.obs;
  final isCheckingAuth = true.obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final adminUser = Rxn<AdminUserModel>();
  final _isSuperAdmin = false.obs;

  /// Whether the current admin has super admin privileges
  bool get isSuperAdmin => _isSuperAdmin.value;

  /// Current user info (convenience accessor via AuthService)
  AuthUserInfo? get currentUser => AuthService.currentUserInfo;

  @override
  void onInit() {
    super.onInit();
    checkAdminAccess();
  }

  /// Check if the current user has admin claims
  Future<void> checkAdminAccess() async {
    try {
      final userInfo = AuthService.currentUserInfo;
      if (userInfo == null) {
        isAuthenticated.value = false;
        return;
      }

      final token = await AuthService.getIdTokenResult();
      final role = token?.claims?['role'] as String?;

      if (role == 'admin' || role == 'super_admin') {
        _isSuperAdmin.value = role == 'super_admin';
        adminUser.value = AdminUserModel.fromAuthUserInfo(
          userInfo,
          token?.claims ?? {},
        );
        isAuthenticated.value = true;
      } else {
        isAuthenticated.value = false;
      }
    } catch (e) {
      debugPrint('checkAdminAccess error: $e');
      isAuthenticated.value = false;
    } finally {
      isCheckingAuth.value = false;
    }
  }

  /// Sign in as admin (accepts positional args from login screen)
  Future<void> signIn(String email, String password) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final userInfo = await AuthService.signInWithEmail(
        email: email,
        password: password,
      );

      if (userInfo == null) {
        errorMessage.value = 'admin.login.error'.tr;
        isAuthenticated.value = false;
        return;
      }

      // Check custom claims for admin role
      final token = await AuthService.getIdTokenResult();
      final role = token?.claims?['role'] as String?;

      if (role != 'admin' && role != 'super_admin') {
        errorMessage.value = 'admin.login.not_admin'.tr;
        await AuthService.signOutFirebaseOnly();
        isAuthenticated.value = false;
        return;
      }

      _isSuperAdmin.value = role == 'super_admin';

      adminUser.value = AdminUserModel.fromAuthUserInfo(
        userInfo,
        token?.claims ?? {},
      );

      isAuthenticated.value = true;
      Get.offAllNamed(postLoginRoute);
    } catch (e) {
      debugPrint('AdminAuthController.signIn failed: $e');
      if (e is AuthException) {
        switch (e.code) {
          case 'user-not-found':
          case 'wrong-password':
          case 'invalid-credential':
          case 'invalid-email':
            errorMessage.value = 'admin.login.error_invalid'.tr;
          case 'network-request-failed':
            errorMessage.value = 'admin.login.error_network'.tr;
          default:
            errorMessage.value = 'admin.login.error'.tr;
        }
      } else {
        errorMessage.value = 'admin.login.error'.tr;
      }
      isAuthenticated.value = false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await AuthService.signOutFirebaseOnly();
    isAuthenticated.value = false;
    adminUser.value = null;
    _isSuperAdmin.value = false;
    Get.offAllNamed(AppRoutes.adminLogin);
  }
}
