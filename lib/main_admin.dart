import 'package:biko/core/app_initializer.dart';
import 'package:biko/core/routes/admin_pages.dart';
import 'package:biko/core/routes/app_routes.dart';
import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/translations/app_translations.dart';
import 'package:biko/features/admin/controllers/admin_auth_controller.dart';
import 'package:biko/features/admin/controllers/admin_layout_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// BikeRide Admin Panel Entry Point (Web-optimized)
///
/// Run this app:
/// ```bash
/// flutter run -d chrome -t lib/main_admin.dart
/// ```
void main() async {
  await AppInitializer.init(
    appName: 'Admin',
    appBuilder: () {
      // Register permanent admin controllers before building the widget tree.
      Get.put(AdminAuthController(), permanent: true);
      Get.put(AdminLayoutController(), permanent: true);
      return const AdminApp();
    },
  );
}

/// Admin App root widget (Web-optimized)
class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      // App metadata
      title: 'BikeRide Admin',
      debugShowCheckedModeBanner: false,

      // Theme configuration
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,

      // Localization configuration
      translations: AppTranslations(),
      locale: const Locale('en'), // Admin defaults to English
      fallbackLocale: const Locale('ar'),

      // RTL/LTR support
      builder: (context, child) {
        final locale = Get.locale ?? const Locale('en');
        final isRTL = locale.languageCode == 'ar';

        return Directionality(
          textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
          child: child ?? const SizedBox.shrink(),
        );
      },

      // Routing configuration
      initialRoute: AppRoutes.adminLogin,
      getPages: AdminPages.pages,
      unknownRoute: GetPage(
        name: AppRoutes.adminNotFound,
        page: () => Scaffold(
          body: Center(child: Text('admin.not_found'.tr)),
        ),
      ),
    );
  }
}
