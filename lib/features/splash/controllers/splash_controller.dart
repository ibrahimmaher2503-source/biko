import 'package:biko/core/app_initializer.dart';
import 'package:biko/core/models/enums.dart';
import 'package:biko/core/routes/app_routes.dart';
import 'package:biko/core/services/auth_service.dart';
import 'package:biko/core/services/firestore_service.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Splash screen controller — initializes app and determines navigation
///
/// Decision tree (per research R-003):
/// 1. Onboarding not completed → /onboarding
/// 2. Not authenticated → /auth/phone
/// 3. Profile incomplete → /auth/profile-setup
/// 4. [Driver] Not approved → /driver/pending
/// 5. Otherwise → home screen
class SplashController extends GetxController {
  final _isError = false.obs;
  bool get isError => _isError.value;

  @override
  void onReady() {
    super.onReady();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Run minimum display time and initialization checks in parallel
      final results = await Future.wait([
        Future.delayed(const Duration(seconds: 2)),
        _determineDestination(),
      ]);

      final destination = results[1] as String;
      Get.offAllNamed(
        destination,
        arguments: destination == AppRoutes.onboarding
            ? AppInitializer.appType
            : null,
      );
    } catch (e) {
      _isError.value = true;
    }
  }

  Future<String> _determineDestination() async {
    // 1. Check if onboarding has been completed (app-type-specific)
    final prefs = await SharedPreferences.getInstance();
    final appType = AppInitializer.appType;
    final onboardingCompleted =
        prefs.getBool('onboarding_completed_$appType') ?? false;

    if (!onboardingCompleted) {
      return AppRoutes.onboarding;
    }

    // 2. Check if user is authenticated (via AuthService, not direct Firebase)
    final currentUser = AuthService.currentUser;
    if (currentUser == null) {
      return AppRoutes.phoneLogin;
    }

    // 3. Fetch user profile and check completeness
    final userModel = await FirestoreService.getUser(currentUser.uid);
    if (userModel == null || !userModel.isProfileComplete) {
      return AppRoutes.profileSetup;
    }

    // 4. Driver-specific: check approval status
    if (userModel.type == UserType.driver) {
      if (userModel.status == UserStatus.pendingApproval) {
        return AppRoutes.pendingApproval;
      }
      return AppRoutes.driverHome;
    }

    // 5. Customer → home
    return AppRoutes.customerHome;
  }

  /// Retry initialization after error
  void retry() {
    _isError.value = false;
    _initialize();
  }
}
