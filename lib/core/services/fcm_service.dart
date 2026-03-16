import 'package:biko/core/services/auth_service.dart';
import 'package:biko/core/services/firestore_service.dart';
import 'package:biko/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Top-level background message handler (required by Firebase Messaging)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('Background FCM: ${message.messageId}');
  if (message.notification != null) {
    // Background isolates cannot reliably show local notifications without a
    // foreground service. The Firebase SDK handles displaying the system
    // notification automatically when the app is in the background.
    debugPrint('Notification: ${message.notification!.title}');
  }
}

/// Firebase Cloud Messaging service
///
/// Handles push notification setup, token management, and notification channels.
/// Static class following the same pattern as [AuthService].
class FcmService {
  FcmService._();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'bikeride_default';
  static const String _channelName = 'BikeRide Notifications';

  /// Initialize FCM: request permissions, get token, set up listeners
  static Future<void> initialize() async {
    try {
      // Request notification permissions
      await _messaging.requestPermission();

      // Set up local notifications for foreground display
      await _initLocalNotifications();

      // Get FCM token and persist to Firestore
      final token = await _messaging.getToken();
      debugPrint('📱 FCM Token: ${token?.substring(0, 20)}...');

      if (token != null) {
        await _persistToken(token);
      }

      // Listen for foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        debugPrint('🔄 FCM Token refreshed');
        _persistToken(newToken);
      });
    } catch (e) {
      debugPrint('⚠️ FCM initialization failed: $e');
    }
  }

  /// Initialize local notifications plugin for foreground display
  static Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const darwinSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );
    await _localNotifications.initialize(initSettings);
  }

  /// Persist FCM token to Firestore for the current user
  static Future<void> _persistToken(String token) async {
    final uid = AuthService.currentUid;
    if (uid == null) return;
    await FirestoreService.updateFcmToken(uid, token);
  }

  /// Set up Android notification channels
  static Future<void> setupNotificationChannels() async {
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  /// Clear FCM token (called on sign out)
  static Future<void> clearToken() async {
    try {
      // Clear from Firestore first
      final uid = AuthService.currentUid;
      if (uid != null) {
        await FirestoreService.clearFcmToken(uid);
      }
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

  /// Show a local notification when a foreground message is received
  static void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('📩 Foreground message: ${message.notification?.title}');

    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }
}
