import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Firebase initialization service for BikeRide multi-app architecture
///
/// Handles Firebase initialization with proper error handling.
/// Called once during app startup before any Firebase features are used.
///
/// Usage:
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await FirebaseService.initialize();
///   runApp(MyApp());
/// }
/// ```
class FirebaseService {
  // Prevent instantiation
  FirebaseService._();

  /// Initialize Firebase with error handling
  ///
  /// Returns true if initialization succeeds, false otherwise.
  /// Logs errors but doesn't throw to allow app to continue in offline mode.
  static Future<bool> initialize() async {
    try {
      await Firebase.initializeApp(
        // Firebase options will be auto-detected from:
        // - android/app/google-services.json (Android)
        // - ios/Runner/GoogleService-Info.plist (iOS)
        // - web/index.html (Web)
      );

      if (kDebugMode) {
        print('✅ Firebase initialized successfully');
      }

      return true;
    } on FirebaseException catch (e) {
      // Firebase-specific errors (already initialized, configuration issues, etc.)
      if (kDebugMode) {
        print('❌ Firebase initialization failed: ${e.code} - ${e.message}');
      }

      // If Firebase is already initialized, consider it a success
      if (e.code == 'duplicate-app') {
        if (kDebugMode) {
          print('ℹ️ Firebase already initialized');
        }
        return true;
      }

      return false;
    } catch (e) {
      // Generic errors (network issues, missing configuration files, etc.)
      if (kDebugMode) {
        print('❌ Firebase initialization error: $e');
      }
      return false;
    }
  }

  /// Check if Firebase is initialized
  static bool get isInitialized {
    try {
      // Attempt to access Firebase.apps - throws if not initialized
      return Firebase.apps.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
