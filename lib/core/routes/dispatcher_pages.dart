import 'package:biko/core/routes/app_routes.dart';
import 'package:biko/features/admin/screens/admin_login_screen.dart';
import 'package:biko/features/dispatch/bindings/dispatch_binding.dart';
import 'package:biko/features/dispatch/screens/dispatch_home_screen.dart';
import 'package:get/get.dart';

/// Page registry for the phone-based dispatcher app.
///
/// Uses the shared [AdminLoginScreen] for auth and routes to
/// [DispatchHomeScreen] after a successful login.
class DispatcherPages {
  DispatcherPages._();

  static List<GetPage> get pages => [
    GetPage(
      name: AppRoutes.adminLogin,
      page: () => const AdminLoginScreen(),
    ),
    GetPage(
      name: AppRoutes.dispatchHome,
      page: () => const DispatchHomeScreen(),
      binding: DispatchBinding(),
      middlewares: [DispatchAuthGuard()],
    ),
  ];
}
