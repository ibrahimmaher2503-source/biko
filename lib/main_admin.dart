import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:biko/core/app_initializer.dart';
import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/translations/app_translations.dart';
import 'package:biko/core/routes/app_routes.dart';
import 'package:biko/demo_theme_screen.dart';
import 'package:biko/demo_widgets_screen.dart';

/// BikeRide Admin Panel Entry Point (Web-optimized)
///
/// Run this app:
/// ```bash
/// flutter run -d chrome -t lib/main_admin.dart
/// ```
void main() async {
  await AppInitializer.init(
    appName: 'Admin',
    appBuilder: () => const AdminApp(),
  );
}

/// Admin App root widget (Web-optimized)
class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      // App metadata
      title: 'BikeRide Admin Panel',
      debugShowCheckedModeBanner: false,

      // Theme configuration
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Follows system preference

      // Localization configuration
      translations: AppTranslations(),
      locale: const Locale('en'), // Admin defaults to English
      fallbackLocale: const Locale('ar'),

      // RTL/LTR support
      builder: (context, child) {
        // Determine text direction based on current locale
        final locale = Get.locale ?? const Locale('en');
        final isRTL = locale.languageCode == 'ar';

        return Directionality(
          textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
          child: child ?? const SizedBox.shrink(),
        );
      },

      // Routing configuration (web-optimized with URL strategy)
      initialRoute: AppRoutes.demoTheme,
      getPages: [
        GetPage(
          name: AppRoutes.demoTheme,
          page: () => const DemoThemeScreen(),
        ),
        GetPage(
          name: AppRoutes.demoWidgets,
          page: () => const DemoWidgetsScreen(),
        ),
        // Admin-specific routes will be added here
        // GetPage(
        //   name: AppRoutes.adminDashboard,
        //   page: () => AdminDashboardScreen(),
        // ),
      ],

      // Web-specific configuration
      // useInheritedMediaQuery: true, // Better performance on web
    );
  }
}
