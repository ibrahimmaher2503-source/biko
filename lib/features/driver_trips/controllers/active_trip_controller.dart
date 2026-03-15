import 'dart:async';

import 'package:biko/core/models/enums.dart';
import 'package:biko/core/models/trip_model.dart';
import 'package:biko/core/routes/app_routes.dart';
import 'package:biko/core/services/auth_service.dart';
import 'package:biko/core/services/firestore_service.dart';
import 'package:biko/core/services/location_service.dart';
import 'package:biko/core/services/map_service.dart';
import 'package:biko/core/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Controller for the active trip screen.
///
/// Manages trip in progress: map with route to dropoff, status
/// transitions (arrived → in_progress → completed), live location.
class ActiveTripController extends GetxController {
  final isLoading = true.obs;
  final trip = Rxn<TripModel>();
  final driverPosition = Rxn<Position>();
  final markers = <Marker>{}.obs;
  final polylines = <Polyline>{}.obs;
  final isTripStarted = false.obs;
  final isCompleting = false.obs;

  late final LocationService _locationService;
  StreamSubscription<Position>? _locationSubscription;

  @override
  void onInit() {
    super.onInit();
    _locationService = Get.find<LocationService>();
    _loadTrip();
  }

  Future<void> _loadTrip() async {
    try {
      final args = Get.arguments as Map<String, dynamic>?;
      final tripId = args?['tripId'] as String?;
      if (tripId == null) {
        AppSnackbar.error('active_trip.error_no_trip'.tr);
        Get.back<void>();
        return;
      }

      final loadedTrip = await FirestoreService.getTrip(tripId);
      if (loadedTrip == null) {
        AppSnackbar.error('active_trip.error_no_trip'.tr);
        Get.back<void>();
        return;
      }

      trip.value = loadedTrip;
      isTripStarted.value = loadedTrip.status == TripStatus.inProgress;

      // Get current position and fetch route to dropoff
      final position = await _locationService.getCurrentPosition();
      if (position != null) {
        driverPosition.value = position;
        await _fetchRoute(position);
      }

      _startLocationTracking();
      isLoading.value = false;
    } catch (e) {
      debugPrint('ActiveTripController._loadTrip error: $e');
      isLoading.value = false;
    }
  }

  Future<void> _fetchRoute(Position position) async {
    final currentTrip = trip.value;
    if (currentTrip == null) return;

    final origin = LatLng(position.latitude, position.longitude);
    final destination = LatLng(
      currentTrip.dropoff.lat,
      currentTrip.dropoff.lng,
    );

    final result = await MapService.getDirections(origin, destination);
    _updateMapOverlays(origin, destination, result);
  }

  void _updateMapOverlays(LatLng origin, LatLng destination, dynamic result) {
    markers.assignAll({
      Marker(
        markerId: const MarkerId('driver'),
        position: origin,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
      Marker(
        markerId: const MarkerId('dropoff'),
        position: destination,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    });

    if (result != null) {
      polylines.assignAll({
        Polyline(
          polylineId: const PolylineId('route'),
          points: result.polylinePoints as List<LatLng>,
          color: const Color(0xFFE0062E),
          width: 4,
        ),
      });
    }
  }

  void _startLocationTracking() {
    final stream = _locationService.getLocationStream();
    _locationSubscription = stream.listen((position) {
      driverPosition.value = position;

      final currentTrip = trip.value;
      if (currentTrip == null) return;

      final driverLatLng = LatLng(position.latitude, position.longitude);
      final dropoffLatLng = LatLng(
        currentTrip.dropoff.lat,
        currentTrip.dropoff.lng,
      );

      markers.assignAll({
        Marker(
          markerId: const MarkerId('driver'),
          position: driverLatLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
        Marker(
          markerId: const MarkerId('dropoff'),
          position: dropoffLatLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      });

      // Update driver location in RTDB
      final uid = AuthService.currentUser?.uid;
      if (uid != null) {
        FirestoreService.updateActiveTripDriverLocation(currentTrip.id, {
          'driver_lat': position.latitude,
          'driver_lng': position.longitude,
          'driver_heading': position.heading,
        });
      }
    });
  }

  /// Start the trip (transition from arrived → in_progress).
  Future<void> startTrip() async {
    final currentTrip = trip.value;
    if (currentTrip == null) return;

    try {
      await FirestoreService.updateTripStatus(currentTrip.id, 'in_progress');
      isTripStarted.value = true;
      trip.value = currentTrip.copyWith(status: TripStatus.inProgress);
    } catch (e) {
      debugPrint('ActiveTripController.startTrip error: $e');
      AppSnackbar.error('active_trip.start_failed'.tr);
    }
  }

  /// Complete the trip.
  Future<void> completeTrip() async {
    final currentTrip = trip.value;
    if (currentTrip == null) return;

    isCompleting.value = true;
    try {
      await FirestoreService.updateTripStatus(currentTrip.id, 'completed');
      Get.offNamed<void>(
        AppRoutes.driverTripComplete,
        arguments: {'tripId': currentTrip.id},
      );
    } catch (e) {
      debugPrint('ActiveTripController.completeTrip error: $e');
      AppSnackbar.error('active_trip.complete_failed'.tr);
    } finally {
      isCompleting.value = false;
    }
  }

  /// Navigate to chat screen.
  void openChat() {
    final currentTrip = trip.value;
    if (currentTrip == null) return;

    Get.toNamed<void>(
      AppRoutes.driverChat,
      arguments: {'tripId': currentTrip.id},
    );
  }

  @override
  void onClose() {
    _locationSubscription?.cancel();
    super.onClose();
  }
}
