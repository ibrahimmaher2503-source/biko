import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Top-level background message handler (required by Firebase Messaging)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📩 Background message: ${message.messageId}');
}

/// Firebase Cloud Messaging service
///
/// Handles push notification setup, token management, and notification channels.
/// Static class following the same pattern as [AuthService].
class FcmService {
  FcmService._();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static const String _channelId = 'bikeride_default';
  static const String _channelName = 'BikeRide Notifications';

  /// Initialize FCM: request permissions, get token, set up listeners
  static Future<void> initialize() async {
    try {
      // Request notification permissions
      await _messaging.requestPermission();

      // Get FCM token
      final token = await _messaging.getToken();
      debugPrint('📱 FCM Token: ${token?.substring(0, 20)}...');

      // Listen for foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        debugPrint('🔄 FCM Token refreshed');
        // TODO: Update token in Firestore when FirestoreService is ready
      });
    } catch (e) {
      debugPrint('⚠️ FCM initialization failed: $e');
    }
  }

  /// Set up Android notification channels
  static Future<void> setupNotificationChannels() async {
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      importance: Importance.high,
    );

    final plugin = FlutterLocalNotificationsPlugin();
    await plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  /// Clear FCM token (called on sign out)
  static Future<void> clearToken() async {
    try {
      await _messaging.deleteToken();
      debugPrint('🗑️ FCM Token cleared');
    } catch (e) {
      debugPrint('⚠️ Failed to clear FCM token: $e');
    }
  }

  /// Get the current FCM token
  static Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      debugPrint('⚠️ Failed to get FCM token: $e');
      return null;
    }
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('📩 Foreground message: ${message.notification?.title}');
    // TODO: Show local notification via FlutterLocalNotificationsPlugin
  }
}
