import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_environment.dart';
import 'operation_recovery.dart';

const _channel = AndroidNotificationChannel(
  'biko_operational',
  'تحديثات الطلبات',
  description: 'تنبيهات العروض وحالة الطلبات النشطة.',
  importance: Importance.high,
);

@pragma('vm:entry-point')
Future<void> bikoMessagingBackgroundHandler(RemoteMessage _) async {
  if (!AppEnvironment.hasFirebase || Firebase.apps.isNotEmpty) return;
  await Firebase.initializeApp(options: bikoFirebaseOptions);
}

FirebaseOptions get bikoFirebaseOptions => FirebaseOptions(
  apiKey: AppEnvironment.firebaseApiKey,
  appId: AppEnvironment.firebaseAppId,
  messagingSenderId: AppEnvironment.firebaseMessagingSenderId,
  projectId: AppEnvironment.firebaseProjectId,
  iosBundleId: AppEnvironment.firebaseIosBundleId.isEmpty
      ? null
      : AppEnvironment.firebaseIosBundleId,
);

Future<bool> initializeBikoFirebase() async {
  if (!AppEnvironment.hasFirebase) return false;
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(options: bikoFirebaseOptions);
  }
  FirebaseMessaging.onBackgroundMessage(bikoMessagingBackgroundHandler);
  return true;
}

enum BikoNotificationPermission { notDetermined, granted, provisional, denied }

class OperationalNotification {
  const OperationalNotification({
    required this.id,
    required this.type,
    required this.targetType,
    required this.title,
    required this.body,
    this.orderId,
    this.offerId,
  });

  static final _uuid = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    caseSensitive: false,
  );
  static const _types = {
    'NEW_WORK',
    'NEW_OFFER',
    'OFFER_SELECTED',
    'OFFER_CLOSED',
    'DRIVER_ASSIGNED',
    'DRIVER_ON_WAY',
    'DRIVER_ARRIVED',
    'IN_PROGRESS',
    'COMPLETED',
    'CANCELLED',
    'EXPIRED',
    'DOCUMENT_EXPIRING',
    'DOCUMENT_EXPIRED',
  };
  static const _targets = {
    'ORDER',
    'ACTIVE_ORDER',
    'WAITING_OFFER',
    'REQUESTS',
    'PROFILE',
  };

  factory OperationalNotification.fromRealtime(Map<String, dynamic> row) =>
      OperationalNotification._parse(row);

  factory OperationalNotification.fromPush(Map<String, dynamic> data) =>
      OperationalNotification._parse({'id': data['notification_id'], ...data});

  factory OperationalNotification._parse(Map<String, dynamic> data) {
    final id = data['id']?.toString() ?? '';
    final type = data['event_type']?.toString().toUpperCase() ?? '';
    final target = data['target_type']?.toString().toUpperCase() ?? '';
    final orderId = _validUuid(data['order_id']);
    final offerId = _validUuid(data['offer_id']);
    if (!_uuid.hasMatch(id) ||
        !_types.contains(type) ||
        !_targets.contains(target) ||
        (!const {'REQUESTS', 'PROFILE'}.contains(target) && orderId == null)) {
      throw const FormatException('Invalid operational notification');
    }
    return OperationalNotification(
      id: id,
      type: type,
      targetType: target,
      orderId: orderId,
      offerId: offerId,
      title: data['title']?.toString() ?? 'تحديث جديد',
      body: data['body']?.toString() ?? 'افتح التطبيق لعرض الحالة الحالية.',
    );
  }

  static String? _validUuid(Object? value) {
    final text = value?.toString();
    return text != null && _uuid.hasMatch(text) ? text : null;
  }

  final String id;
  final String type;
  final String targetType;
  final String? orderId;
  final String? offerId;
  final String title;
  final String body;

  String get payload => jsonEncode({
    'notification_id': id,
    'event_type': type,
    'target_type': targetType,
    'order_id': orderId,
    'offer_id': offerId,
    'title': title,
    'body': body,
  });

  static OperationalNotification? tryPush(Map<String, dynamic> data) {
    try {
      return OperationalNotification.fromPush(data);
    } on FormatException {
      return null;
    }
  }

  static OperationalNotification? tryPayload(String? payload) {
    if (payload == null) return null;
    try {
      return OperationalNotification.fromPush(
        Map<String, dynamic>.from(jsonDecode(payload) as Map),
      );
    } on Object {
      return null;
    }
  }
}

class OperationalEventDedupe {
  OperationalEventDedupe({this.capacity = 100});

  final int capacity;
  final LinkedHashSet<String> _ids = LinkedHashSet();

  bool take(String id) {
    if (!_ids.add(id)) return false;
    while (_ids.length > capacity) {
      _ids.remove(_ids.first);
    }
    return true;
  }

  void clear() => _ids.clear();
}

class OperationalSubscriptionGeneration {
  int _value = 0;

  int begin() => ++_value;
  void cancel() => _value++;
  bool isCurrent(int value) => value == _value;
}

class PushNotifications {
  PushNotifications(
    this._client, {
    required this.appKind,
    FirebaseMessaging? messaging,
    FlutterLocalNotificationsPlugin? local,
  }) : _messaging = messaging ?? FirebaseMessaging.instance,
       _local = local ?? FlutterLocalNotificationsPlugin();

  final SupabaseClient _client;
  final String appKind;
  final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _local;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openSubscription;
  StreamSubscription<String>? _tokenSubscription;
  OperationalNotification? _pendingLaunch;
  Future<bool> Function(OperationalNotification event)? _onForeground;
  Future<void> Function(OperationalNotification event)? _onOpen;

  Future<void> initialize({
    required Future<bool> Function(OperationalNotification event) onForeground,
    required Future<void> Function(OperationalNotification event) onOpen,
  }) async {
    _onForeground = onForeground;
    _onOpen = onOpen;
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _local.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (response) {
        final event = OperationalNotification.tryPayload(response.payload);
        if (event != null) unawaited(_onOpen?.call(event));
      },
    );
    if (Platform.isAndroid) {
      await _local
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(_channel);
    }
    _foregroundSubscription = FirebaseMessaging.onMessage.listen((message) {
      final event = OperationalNotification.tryPush(message.data);
      if (event != null) unawaited(_handleForeground(event));
    });
    _openSubscription = FirebaseMessaging.onMessageOpenedApp.listen((message) {
      final event = OperationalNotification.tryPush(message.data);
      if (event != null) unawaited(_onOpen?.call(event));
    });
    _tokenSubscription = _messaging.onTokenRefresh.listen((token) {
      if (_client.auth.currentUser != null) unawaited(_register(token));
    });
    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      _pendingLaunch = OperationalNotification.tryPush(initial.data);
    }
    await registerWhenAlreadyAllowed();
  }

  Future<void> _handleForeground(OperationalNotification event) async {
    if (await _onForeground!(event) != true) return;
    await _local.show(
      id: event.id.hashCode & 0x7fffffff,
      title: event.title,
      body: event.body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'biko_operational',
          'تحديثات الطلبات',
          channelDescription: 'تنبيهات العروض وحالة الطلبات النشطة.',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: event.payload,
    );
  }

  Future<BikoNotificationPermission> permission() async =>
      _mapPermission(await _messaging.getNotificationSettings());

  Future<BikoNotificationPermission> requestPermissionAndRegister() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    final result = _mapPermission(settings);
    if (result == BikoNotificationPermission.granted ||
        result == BikoNotificationPermission.provisional) {
      try {
        final token = await _messaging.getToken();
        if (token != null) await _register(token);
      } catch (_) {
        // Permission succeeds independently from optional token registration.
      }
    }
    return result;
  }

  Future<void> registerWhenAlreadyAllowed() async {
    try {
      final status = await permission();
      if (status != BikoNotificationPermission.granted &&
          status != BikoNotificationPermission.provisional) {
        return;
      }
      final token = await _messaging.getToken();
      if (token != null) await _register(token);
    } catch (_) {
      // Push remains optional; Realtime/manual refresh stay available.
    }
  }

  Future<void> _register(String token) => _client
      .rpc(
        'register_push_token',
        params: {
          'p_token': token,
          'p_platform': Platform.isIOS ? 'IOS' : 'ANDROID',
          'p_app_kind': appKind,
        },
      )
      .timeout(transportTimeout);

  Future<void> revokeCurrentToken() async {
    final token = await _messaging.getToken();
    if (token == null || _client.auth.currentUser == null) return;
    await _client
        .rpc(
          'revoke_push_token',
          params: {'p_token': token, 'p_app_kind': appKind},
        )
        .timeout(transportTimeout);
  }

  Future<void> processPendingLaunch() async {
    final event = _pendingLaunch;
    _pendingLaunch = null;
    if (event != null) await _onOpen?.call(event);
  }

  BikoNotificationPermission _mapPermission(NotificationSettings settings) =>
      switch (settings.authorizationStatus) {
        AuthorizationStatus.authorized => BikoNotificationPermission.granted,
        AuthorizationStatus.provisional =>
          BikoNotificationPermission.provisional,
        AuthorizationStatus.notDetermined =>
          BikoNotificationPermission.notDetermined,
        _ => BikoNotificationPermission.denied,
      };

  Future<void> dispose() async {
    await Future.wait([
      _foregroundSubscription?.cancel() ?? Future.value(),
      _openSubscription?.cancel() ?? Future.value(),
      _tokenSubscription?.cancel() ?? Future.value(),
    ]);
  }
}
