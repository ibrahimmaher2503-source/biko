import 'package:biko/core/routes/app_routes.dart';
import 'package:biko/demo_theme_screen.dart';
import 'package:biko/demo_widgets_screen.dart';
import 'package:biko/features/auth/bindings/otp_verification_binding.dart';
import 'package:biko/features/auth/bindings/phone_login_binding.dart';
import 'package:biko/features/auth/bindings/profile_setup_binding.dart';
import 'package:biko/features/auth/screens/otp_verification_screen.dart';
import 'package:biko/features/auth/screens/phone_login_screen.dart';
import 'package:biko/features/auth/screens/profile_setup_screen.dart';
import 'package:biko/features/driver_chat/bindings/chat_binding.dart';
import 'package:biko/features/driver_chat/screens/chat_screen.dart';
import 'package:biko/features/driver_earnings/bindings/earnings_binding.dart';
import 'package:biko/features/driver_earnings/screens/earnings_screen.dart';
import 'package:biko/features/driver_home/bindings/driver_home_binding.dart';
import 'package:biko/features/driver_home/screens/driver_home_screen.dart';
import 'package:biko/features/driver_profile/bindings/driver_profile_binding.dart';
import 'package:biko/features/driver_profile/screens/driver_profile_screen.dart';
import 'package:biko/features/driver_ratings/bindings/ratings_binding.dart';
import 'package:biko/features/driver_ratings/screens/ratings_screen.dart';
import 'package:biko/features/driver_registration/bindings/driver_registration_binding.dart';
import 'package:biko/features/driver_registration/screens/driver_registration_screen.dart';
import 'package:biko/features/driver_registration/screens/pending_approval_screen.dart';
import 'package:biko/features/driver_settings/bindings/driver_settings_binding.dart';
import 'package:biko/features/driver_settings/screens/driver_settings_screen.dart';
import 'package:biko/features/driver_trips/bindings/active_trip_binding.dart';
import 'package:biko/features/driver_trips/bindings/bid_binding.dart';
import 'package:biko/features/driver_trips/bindings/driver_trips_binding.dart';
import 'package:biko/features/driver_trips/bindings/navigate_pickup_binding.dart';
import 'package:biko/features/driver_trips/bindings/trip_complete_binding.dart';
import 'package:biko/features/driver_trips/screens/active_trip_screen.dart';
import 'package:biko/features/driver_trips/screens/bid_screen.dart';
import 'package:biko/features/driver_trips/screens/navigate_to_pickup_screen.dart';
import 'package:biko/features/driver_trips/screens/trip_complete_screen.dart';
import 'package:biko/features/driver_trips/screens/trip_requests_screen.dart';
import 'package:biko/features/driver_wallet/bindings/wallet_binding.dart';
import 'package:biko/features/driver_wallet/screens/wallet_screen.dart';
import 'package:biko/features/onboarding/bindings/onboarding_binding.dart';
import 'package:biko/features/onboarding/screens/onboarding_screen.dart';
import 'package:biko/features/splash/bindings/splash_binding.dart';
import 'package:biko/features/splash/screens/splash_screen.dart';
import 'package:get/get.dart';

/// Driver app page registry
///
/// Returns the list of [GetPage] entries for the driver app.
/// New pages are added here as features are implemented.
class DriverPages {
  DriverPages._();

  static List<GetPage> get pages => [
    // ==================== Demo Routes ====================
    GetPage(name: AppRoutes.demoTheme, page: () => const DemoThemeScreen()),
    GetPage(name: AppRoutes.demoWidgets, page: () => const DemoWidgetsScreen()),

    // ==================== Shared Routes ====================
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashScreen(),
      binding: SplashBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.onboarding,
      page: () => const OnboardingScreen(),
      binding: OnboardingBinding(),
      transition: Transition.rightToLeft,
    ),

    // ==================== Auth Routes ====================
    GetPage(
      name: AppRoutes.phoneLogin,
      page: () => const PhoneLoginScreen(),
      binding: PhoneLoginBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.otpVerification,
      page: OtpVerificationScreen.new,
      binding: OtpVerificationBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.profileSetup,
      page: () => const ProfileSetupScreen(),
      binding: ProfileSetupBinding(),
      transition: Transition.rightToLeft,
    ),

    // ==================== Driver Registration ====================
    GetPage(
      name: AppRoutes.driverRegistration,
      page: () => const DriverRegistrationScreen(),
      binding: DriverRegistrationBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.pendingApproval,
      page: () => const PendingApprovalScreen(),
      transition: Transition.fadeIn,
    ),

    // ==================== Driver Home ====================
    GetPage(
      name: AppRoutes.driverHome,
      page: () => const DriverHomeScreen(),
      binding: DriverHomeBinding(),
      transition: Transition.fadeIn,
    ),

    // ==================== Driver Trip Flow ====================
    GetPage(
      name: AppRoutes.incomingRequests,
      page: () => const TripRequestsScreen(),
      binding: DriverTripsBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.submitBid,
      page: () => const BidScreen(),
      binding: BidBinding(),
      transition: Transition.rightToLeft,
    ),

    GetPage(
      name: AppRoutes.navigateToPickup,
      page: () => const NavigateToPickupScreen(),
      binding: NavigatePickupBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.activeTrip,
      page: () => const ActiveTripScreen(),
      binding: ActiveTripBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.driverTripComplete,
      page: () => const TripCompleteScreen(),
      binding: TripCompleteBinding(),
      transition: Transition.fadeIn,
    ),

    // ==================== Driver Supporting Screens ====================
    GetPage(
      name: AppRoutes.earnings,
      page: () => const EarningsScreen(),
      binding: EarningsBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.driverWallet,
      page: () => const WalletScreen(),
      binding: WalletBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.driverRatings,
      page: () => const RatingsScreen(),
      binding: RatingsBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.driverChat,
      page: () => const ChatScreen(),
      binding: ChatBinding(),
      transition: Transition.rightToLeft,
    ),

    // ==================== Driver Profile & Settings ====================
    GetPage(
      name: AppRoutes.driverProfile,
      page: () => const DriverProfileScreen(),
      binding: DriverProfileBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.driverSettings,
      page: () => const DriverSettingsScreen(),
      binding: DriverSettingsBinding(),
      transition: Transition.rightToLeft,
    ),
  ];
}
