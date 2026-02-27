import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:biko/core/services/firebase_service.dart';
import 'package:biko/features/auth/controllers/auth_controller.dart';

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
    debugPrint('🚀 Initializing BikeRide $appName App...');

    // Step 2: Initialize Firebase
    try {
      final firebaseInitialized = await FirebaseService.initialize();

      if (!firebaseInitialized) {
        debugPrint('⚠️ Firebase initialization failed - continuing in offline mode');
        // App continues to run, but Firebase features will be unavailable
      }
    } catch (e) {
      debugPrint('❌ Critical error during Firebase initialization: $e');
      // App continues to run in offline mode
    }

    // Step 3: Register global controllers
    try {
      // Register AuthController as permanent (survives route changes)
      Get.put(AuthController(), permanent: true);
      debugPrint('✅ Global controllers registered');
    } catch (e) {
      debugPrint('❌ Error registering global controllers: $e');
      // Critical error - but we'll let GetX handle it
    }

    // Step 4: Run the app
    try {
      runApp(appBuilder());
      debugPrint('✅ $appName App launched successfully');
    } catch (e) {
      debugPrint('❌ Critical error launching app: $e');
      rethrow; // Fatal error - cannot continue
    }
  }
}
