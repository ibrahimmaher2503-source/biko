import 'package:biko/core/services/fcm_service.dart';
import 'package:biko/core/services/firebase_service.dart';
import 'package:biko/core/services/location_service.dart';
import 'package:biko/features/auth/controllers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Centralized app initialization for BikeRide multi-app architecture
///
/// Handles the complete initialization sequence:
/// 1. Flutter bindings initialization
/// 2. Firebase initialization
/// 3. Global controller registration (AuthController)
/// 4. App launch
///
/// Usage:
/// ```dart
/// void main() async {
///   await AppInitializer.init(
///     appName: 'Customer',
///     appBuilder: () => CustomerApp(),
///   );
/// }
/// ```
class AppInitializer {
  // Prevent instantiation
  AppInitializer._();

  /// Restored theme mode from SharedPreferences (available after init)
  static ThemeMode restoredThemeMode = ThemeMode.light;

  /// App type identifier — 'driver' or 'customer' (lowercase, available after init)
  static String appType = 'customer';

  /// Local notifications plugin instance (shared with FcmService)
  static final localNotifications = FlutterLocalNotificationsPlugin();

  /// Initialize the app and run it
  ///
  /// Parameters:
  /// - [appName]: Name of the app (for logging purposes)
  /// - [appBuilder]: Callback that returns the root app widget
  static Future<void> init({
    required String appName,
    required Widget Function() appBuilder,
  }) async {
    // Step 1: Ensure Flutter bindings are initialized
    WidgetsFlutterBinding.ensureInitialized();
    appType = appName.toLowerCase();
    debugPrint('🚀 Initializing BikeRide $appName App...');

    // Step 2: Initialize Firebase
    try {
      final firebaseInitialized = await FirebaseService.initialize();

      if (!firebaseInitialized) {
        debugPrint(
          '⚠️ Firebase initialization failed - continuing in offline mode',
        );
        // App continues to run, but Firebase features will be unavailable
      }
    } catch (e) {
      debugPrint('❌ Critical error during Firebase initialization: $e');
      // App continues to run in offline mode
    }

    // Step 3: Initialize local notifications plugin + notification channels
    try {
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const initSettings = InitializationSettings(android: androidSettings);
      await localNotifications.initialize(initSettings);
      await FcmService.setupNotificationChannels();
      debugPrint('✅ Local notifications initialized');
    } catch (e) {
      debugPrint('⚠️ Local notifications initialization failed: $e');
    }

    // Step 4: Restore theme preference from local storage
    try {
      final prefs = await SharedPreferences.getInstance();
      final themePref = prefs.getString('theme_mode') ?? 'light';
      restoredThemeMode = themePref == 'dark'
          ? ThemeMode.dark
          : ThemeMode.light;
      debugPrint('🎨 Theme restored: $themePref');
    } catch (e) {
      debugPrint('⚠️ Failed to restore theme preference: $e');
    }

    // Step 5: Register global controllers
    try {
      // Register AuthController as permanent (survives route changes)
      Get.put(AuthController(), permanent: true);
      Get.put(LocationService(), permanent: true);
      debugPrint('✅ Global controllers registered');
    } catch (e) {
      debugPrint('❌ Error registering global controllers: $e');
      // Critical error - but we'll let GetX handle it
    }

    // Step 6: Run the app
    try {
      runApp(appBuilder());
      debugPrint('✅ $appName App launched successfully');
    } catch (e) {
      debugPrint('❌ Critical error launching app: $e');
      rethrow; // Fatal error - cannot continue
    }
  }
}
