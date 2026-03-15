import 'package:biko/core/routes/app_routes.dart';
import 'package:biko/demo_theme_screen.dart';
import 'package:biko/demo_widgets_screen.dart';
import 'package:biko/features/auth/bindings/otp_verification_binding.dart';
import 'package:biko/features/auth/bindings/phone_login_binding.dart';
import 'package:biko/features/auth/bindings/profile_setup_binding.dart';
import 'package:biko/features/auth/screens/otp_verification_screen.dart';
import 'package:biko/features/auth/screens/phone_login_screen.dart';
import 'package:biko/features/auth/screens/profile_setup_screen.dart';
import 'package:biko/features/bidding/bindings/bidding_binding.dart';
import 'package:biko/features/bidding/bindings/bids_binding.dart';
import 'package:biko/features/bidding/screens/bids_screen.dart';
import 'package:biko/features/bidding/screens/price_negotiation_screen.dart';
import 'package:biko/features/chat/bindings/chat_binding.dart';
import 'package:biko/features/chat/screens/chat_screen.dart';
import 'package:biko/features/dropoff/bindings/dropoff_binding.dart';
import 'package:biko/features/dropoff/screens/set_dropoff_screen.dart';
import 'package:biko/features/history/bindings/trip_history_binding.dart';
import 'package:biko/features/history/screens/trip_history_screen.dart';
import 'package:biko/features/home/bindings/home_binding.dart';
import 'package:biko/features/home/screens/customer_main_shell.dart';
import 'package:biko/features/notifications/bindings/notifications_binding.dart';
import 'package:biko/features/notifications/screens/notifications_screen.dart';
import 'package:biko/features/onboarding/bindings/onboarding_binding.dart';
import 'package:biko/features/onboarding/screens/onboarding_screen.dart';
import 'package:biko/features/pickup/bindings/pickup_binding.dart';
import 'package:biko/features/pickup/screens/set_pickup_screen.dart';
import 'package:biko/features/profile/bindings/profile_binding.dart';
import 'package:biko/features/profile/screens/edit_profile_screen.dart';
import 'package:biko/features/profile/screens/profile_screen.dart';
import 'package:biko/features/promo/bindings/promo_binding.dart';
import 'package:biko/features/promo/screens/promo_screen.dart';
import 'package:biko/features/referral/bindings/referral_binding.dart';
import 'package:biko/features/referral/screens/referral_screen.dart';
import 'package:biko/features/settings/bindings/settings_binding.dart';
import 'package:biko/features/settings/screens/settings_screen.dart';
import 'package:biko/features/splash/bindings/splash_binding.dart';
import 'package:biko/features/splash/screens/splash_screen.dart';
import 'package:biko/features/tracking/bindings/tracking_binding.dart';
import 'package:biko/features/tracking/screens/tracking_screen.dart';
import 'package:biko/features/trip/bindings/trip_completion_binding.dart';
import 'package:biko/features/trip/screens/rate_driver_screen.dart';
import 'package:biko/features/trip/screens/trip_completed_screen.dart';
import 'package:biko/features/wallet/bindings/wallet_binding.dart';
import 'package:biko/features/wallet/screens/top_up_screen.dart';
import 'package:biko/features/wallet/screens/wallet_screen.dart';
import 'package:get/get.dart';

/// Customer app page registry
///
/// Returns the list of [GetPage] entries for the customer app.
/// New pages are added here as features are implemented.
class CustomerPages {
  CustomerPages._();

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

    // ==================== Customer Home ====================
    GetPage(
      name: AppRoutes.customerHome,
      page: () => const CustomerMainShell(),
      binding: HomeBinding(),
      transition: Transition.fadeIn,
    ),

    // ==================== Trip Booking Flow ====================
    GetPage(
      name: AppRoutes.setPickup,
      page: () => const SetPickupScreen(),
      binding: PickupBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.setDropoff,
      page: () => const SetDropoffScreen(),
      binding: DropoffBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.createTrip,
      page: () => const PriceNegotiationScreen(),
      binding: BiddingBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.viewBids,
      page: () => const BidsScreen(),
      binding: BidsBinding(),
      transition: Transition.rightToLeft,
    ),

    // ==================== Trip Tracking ====================
    GetPage(
      name: AppRoutes.trackTrip,
      page: () => const TrackingScreen(),
      binding: TrackingBinding(),
      transition: Transition.fadeIn,
    ),

    // ==================== Trip Completion & Rating ====================
    GetPage(
      name: AppRoutes.tripCompleted,
      page: () => const TripCompletedScreen(),
      binding: TripCompletionBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.rateDriver,
      page: () => const RateDriverScreen(),
      binding: TripCompletionBinding(),
      transition: Transition.rightToLeft,
    ),

    // ==================== Wallet ====================
    GetPage(
      name: AppRoutes.customerWallet,
      page: () => const WalletScreen(),
      binding: WalletBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.topUpWallet,
      page: () => const TopUpScreen(),
      binding: WalletBinding(),
      transition: Transition.rightToLeft,
    ),

    // ==================== Profile & Settings ====================
    GetPage(
      name: AppRoutes.customerProfile,
      page: () => const ProfileScreen(),
      binding: ProfileBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: '${AppRoutes.customerProfile}/edit',
      page: () => const EditProfileScreen(),
      binding: ProfileBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.customerSettings,
      page: () => const SettingsScreen(),
      binding: SettingsBinding(),
      transition: Transition.rightToLeft,
    ),

    // ==================== Trip History ====================
    GetPage(
      name: AppRoutes.tripHistory,
      page: () => const TripHistoryScreen(),
      binding: TripHistoryBinding(),
      transition: Transition.rightToLeft,
    ),

    // ==================== Promo Codes ====================
    GetPage(
      name: AppRoutes.promoCodes,
      page: () => const PromoScreen(),
      binding: PromoBinding(),
      transition: Transition.rightToLeft,
    ),

    // ==================== Referral ====================
    GetPage(
      name: AppRoutes.referral,
      page: () => const ReferralScreen(),
      binding: ReferralBinding(),
      transition: Transition.rightToLeft,
    ),

    // ==================== Chat ====================
    GetPage(
      name: AppRoutes.customerChat,
      page: () => const ChatScreen(),
      binding: ChatBinding(),
      transition: Transition.rightToLeft,
    ),

    // ==================== Notifications ====================
    GetPage(
      name: AppRoutes.notifications,
      page: () => const NotificationsScreen(),
      binding: NotificationsBinding(),
      transition: Transition.rightToLeft,
    ),
  ];
}
