import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:biko/core/app_initializer.dart';
import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/translations/app_translations.dart';
import 'package:biko/core/routes/app_routes.dart';
import 'package:biko/demo_theme_screen.dart';
import 'package:biko/demo_widgets_screen.dart';

/// BikeRide Driver App Entry Point
///
/// Run this app:
/// ```bash
/// flutter run -t lib/main_driver.dart
/// ```
void main() async {
  await AppInitializer.init(
    appName: 'Driver',
    appBuilder: () => const DriverApp(),
  );
}

/// Driver App root widget
class DriverApp extends StatelessWidget {
  const DriverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      // App metadata
      title: 'BikeRide Driver',
      debugShowCheckedModeBanner: false,

      // Theme configuration
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Follows system preference

      // Localization configuration
      translations: AppTranslations(),
      locale: const Locale('ar'), // Default to Arabic for Egypt market
      fallbackLocale: const Locale('en'),

      // RTL/LTR support
      builder: (context, child) {
        // Determine text direction based on current locale
        final locale = Get.locale ?? const Locale('ar');
        final isRTL = locale.languageCode == 'ar';

        return Directionality(
          textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
          child: child ?? const SizedBox.shrink(),
        );
      },

      // Routing configuration
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
        // Driver-specific routes will be added here
        // GetPage(
        //   name: AppRoutes.driverHome,
        //   page: () => DriverHomeScreen(),
        // ),
      ],
    );
  }
}
