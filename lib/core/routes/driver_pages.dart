import 'package:biko/core/routes/app_routes.dart';
import 'package:biko/demo_theme_screen.dart';
import 'package:biko/demo_widgets_screen.dart';
import 'package:get/get.dart';

/// Driver app page registry
///
/// Returns the list of [GetPage] entries for the driver app.
/// New pages are added here as features are implemented.
class DriverPages {
  DriverPages._();

  static List<GetPage> get pages => [
    // ==================== Demo Routes ====================
    GetPage(
      name: AppRoutes.demoTheme,
      page: () => const DemoThemeScreen(),
    ),
    GetPage(
      name: AppRoutes.demoWidgets,
      page: () => const DemoWidgetsScreen(),
    ),

    // ==================== Shared Routes ====================
    // TODO: Add splash screen when created
    // TODO: Add onboarding screen when created

    // ==================== Auth Routes ====================
    // TODO: Add phone login screen when created
    // TODO: Add OTP verification screen when created
    // TODO: Add profile setup screen when created

    // ==================== Driver Routes ====================
    // Routes are added incrementally as features are built
  ];
}
