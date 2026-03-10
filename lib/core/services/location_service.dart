import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

/// Global location service — registered permanently in AppInitializer
///
/// Handles location permissions, current position, and real-time location streams.
/// Uses the `geolocator` package for GPS access.
class LocationService extends GetxService {
  StreamSubscription<Position>? _positionSubscription;
  final _currentPosition = Rxn<Position>();

  /// Current device position (null until first fix)
  Position? get currentPosition => _currentPosition.value;

  /// Reactive current position
  Rxn<Position> get currentPositionRx => _currentPosition;

  @override
  void onInit() {
    super.onInit();
    _initLocation();
  }

  @override
  void onClose() {
    _positionSubscription?.cancel();
    super.onClose();
  }

  Future<void> _initLocation() async {
    final hasPermission = await checkAndRequestPermission();
    if (hasPermission) {
      await getCurrentPosition();
    }
  }

  /// Check if location services are enabled and permissions granted.
  /// Requests permission if not yet granted.
  /// Returns `true` if location is available.
  Future<bool> checkAndRequestPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('⚠️ Location services are disabled');
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('⚠️ Location permission denied');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('⚠️ Location permission permanently denied');
      return false;
    }

    return true;
  }

  /// Get the current position once
  Future<Position?> getCurrentPosition() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      _currentPosition.value = position;
      return position;
    } catch (e) {
      debugPrint('⚠️ Failed to get current position: $e');
      return null;
    }
  }

  /// Start a continuous location stream
  ///
  /// Filters out inaccurate readings (>50m accuracy) and
  /// jumps (>100m in <2s) per project requirements.
  Stream<Position> getLocationStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).where((position) {
      // Filter: ignore GPS events where accuracy > 50m
      if (position.accuracy > 50) return false;

      // Filter: ignore distance > 100m within < 2 seconds
      final prev = _currentPosition.value;
      if (prev != null) {
        final distance = Geolocator.distanceBetween(
          prev.latitude,
          prev.longitude,
          position.latitude,
          position.longitude,
        );
        final timeDiff =
            position.timestamp.difference(prev.timestamp).inSeconds;
        if (distance > 100 && timeDiff < 2) return false;
      }

      _currentPosition.value = position;
      return true;
    });
  }

  /// Calculate distance between two points in meters
  static double distanceBetween(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }
}
