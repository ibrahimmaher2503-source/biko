import 'dart:async';

import 'package:biko/core/services/auth_service.dart';
import 'package:biko/core/services/location_service.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

/// Background location service for driver GPS tracking.
///
/// Publishes driver location to Realtime Database every 3 seconds
/// while the driver is online. Wraps [LocationService.getLocationStream()]
/// to reuse existing accuracy/jump filtering.
///
/// Usage:
/// ```dart
/// final bgService = Get.find<BackgroundLocationService>();
/// await bgService.start(); // Go online
/// bgService.stop();        // Go offline
/// ```
class BackgroundLocationService extends GetxService {
  static final _realtimeDb = FirebaseDatabase.instance.ref();

  StreamSubscription<Position>? _locationSubscription;
  Timer? _publishTimer;
  Position? _lastPosition;
  DatabaseReference? _disconnectRef;

  /// Whether the driver is currently online and publishing location
  final isOnline = false.obs;

  /// Start publishing driver location to Realtime DB.
  ///
  /// Subscribes to [LocationService] GPS stream and writes
  /// lat/lng/heading/updatedAt every 3 seconds.
  Future<void> start() async {
    if (isOnline.value) {
      debugPrint('⚠️ BackgroundLocationService: Already started');
      return;
    }
    // Set immediately to prevent concurrent starts
    isOnline.value = true;

    final uid = AuthService.currentUid;
    if (uid == null) {
      debugPrint('⚠️ BackgroundLocationService: No authenticated user');
      isOnline.value = false;
      return;
    }

    final locationService = Get.find<LocationService>();
    final hasPermission = await locationService.checkAndRequestPermission();
    if (!hasPermission) {
      debugPrint('⚠️ BackgroundLocationService: No location permission');
      isOnline.value = false;
      return;
    }

    // Subscribe to filtered GPS stream from LocationService
    _locationSubscription = locationService.getLocationStream().listen(
      (position) {
        _lastPosition = position;
      },
      onError: (e) {
        debugPrint('⚠️ BackgroundLocationService stream error: $e');
      },
    );

    // Publish location every 3 seconds
    _publishTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _publishLocation(uid),
    );

    // Set online status
    await _setOnlineStatus(uid, true);

    // Register onDisconnect handler so RTDB marks driver offline if the
    // connection is lost unexpectedly (network drop, app killed, etc.)
    _disconnectRef = _realtimeDb.child('driver_locations/$uid');
    await _disconnectRef!.onDisconnect().update({
      'is_online': false,
      'updated_at': ServerValue.timestamp,
    });

    debugPrint('✅ BackgroundLocationService started for $uid');
  }

  /// Stop publishing driver location.
  Future<void> stop() async {
    final uid = AuthService.currentUid;

    _publishTimer?.cancel();
    _publishTimer = null;
    await _locationSubscription?.cancel();
    _locationSubscription = null;
    _lastPosition = null;

    // Cancel onDisconnect handler since we're going offline intentionally
    await _disconnectRef?.onDisconnect().cancel();
    _disconnectRef = null;

    if (uid != null) {
      await _setOnlineStatus(uid, false);
    }

    isOnline.value = false;
    debugPrint('🛑 BackgroundLocationService stopped');
  }

  /// Publish current position to RTDB `/driver_locations/{uid}/`
  Future<void> _publishLocation(String uid) async {
    final position = _lastPosition;
    if (position == null) return;

    try {
      await _realtimeDb.child('driver_locations/$uid').update({
        'lat': position.latitude,
        'lng': position.longitude,
        'heading': position.heading,
        'updated_at': ServerValue.timestamp,
        'is_online': true,
      });
    } catch (e) {
      debugPrint('⚠️ BackgroundLocationService publish error: $e');
    }
  }

  /// Set driver online/offline status in RTDB
  Future<void> _setOnlineStatus(String uid, bool online) async {
    try {
      await _realtimeDb.child('driver_locations/$uid').update({
        'is_online': online,
        'updated_at': ServerValue.timestamp,
      });
    } catch (e) {
      debugPrint('⚠️ BackgroundLocationService setOnlineStatus error: $e');
    }
  }

  @override
  void onClose() {
    unawaited(stop());
    super.onClose();
  }
}
