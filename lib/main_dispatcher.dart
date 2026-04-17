import 'package:biko/core/app_initializer.dart';
import 'package:biko/core/routes/app_routes.dart';
import 'package:biko/core/routes/dispatcher_pages.dart';
import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/translations/app_translations.dart';
import 'package:biko/features/admin/controllers/admin_auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// BikeRide Dispatcher App — phone-native dispatch control
///
/// Run on Android/iOS:
/// ```bash
/// flutter run -t lib/main_dispatcher.dart
/// ```
void main() async {
  // Redirect login success to the dispatch home instead of admin dashboard.
  AdminAuthController.postLoginRoute = AppRoutes.dispatchHome;

  await AppInitializer.init(
    appName: 'Dispatcher',
    appBuilder: () {
      Get.put(AdminAuthController(), permanent: true);
      return const DispatcherApp();
    },
  );
}

/// Dispatcher app root widget (phone-optimised).
class DispatcherApp extends StatelessWidget {
  const DispatcherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'BikeRide Dispatch',
      debugShowCheckedModeBanner: false,

      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,

      translations: AppTranslations(),
      locale: const Locale('ar'),
      fallbackLocale: const Locale('en'),

      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },

      initialRoute: AppRoutes.adminLogin,
      getPages: DispatcherPages.pages,
    );
  }
}
