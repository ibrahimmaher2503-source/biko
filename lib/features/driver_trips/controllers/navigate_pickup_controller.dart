import 'dart:async';

import 'package:biko/core/models/directions_result.dart';
import 'package:biko/core/models/trip_model.dart';
import 'package:biko/core/routes/app_routes.dart';
import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/services/auth_service.dart';
import 'package:biko/core/services/firestore_service.dart';
import 'package:biko/core/services/location_service.dart';
import 'package:biko/core/services/map_service.dart';
import 'package:biko/core/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Controller for the navigate-to-pickup screen.
///
/// Shows map with route from driver to pickup, customer info,
/// and "I Have Arrived" button.
class NavigatePickupController extends GetxController {
  final isLoading = true.obs;
  final trip = Rxn<TripModel>();
  final directions = Rxn<DirectionsResult>();
  final driverPosition = Rxn<Position>();
  final markers = <Marker>{}.obs;
  final polylines = <Polyline>{}.obs;

  late final LocationService _locationService;
  StreamSubscription<Position>? _locationSubscription;

  String get customerName => trip.value?.customerUid ?? '';

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
        AppSnackbar.error('navigate.error_no_trip'.tr);
        Get.back<void>();
        return;
      }

      final loadedTrip = await FirestoreService.getTrip(tripId);
      if (loadedTrip == null) {
        AppSnackbar.error('navigate.error_no_trip'.tr);
        Get.back<void>();
        return;
      }

      trip.value = loadedTrip;

      // Get current position
      final position = await _locationService.getCurrentPosition();
      if (position != null) {
        driverPosition.value = position;
        await _fetchRoute(position);
      }

      // Start tracking driver location
      _startLocationTracking();

      isLoading.value = false;
    } catch (e) {
      debugPrint('NavigatePickupController._loadTrip error: $e');
      isLoading.value = false;
    }
  }

  Future<void> _fetchRoute(Position position) async {
    final currentTrip = trip.value;
    if (currentTrip == null) return;

    final origin = LatLng(position.latitude, position.longitude);
    final destination = LatLng(currentTrip.pickup.lat, currentTrip.pickup.lng);

    final result = await MapService.getDirections(origin, destination);
    directions.value = result;

    _updateMapOverlays(origin, destination);
  }

  void _updateMapOverlays(LatLng origin, LatLng destination) {
    final currentDirections = directions.value;
    if (currentDirections == null) return;

    markers.assignAll({
      Marker(
        markerId: const MarkerId('driver'),
        position: origin,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
      Marker(
        markerId: const MarkerId('pickup'),
        position: destination,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
    });

    polylines.assignAll({
      Polyline(
        polylineId: const PolylineId('route'),
        points: currentDirections.polylinePoints,
        color: AppTheme.primary,
        width: 4,
      ),
    });
  }

  void _startLocationTracking() {
    final stream = _locationService.getLocationStream();
    _locationSubscription = stream.listen((position) {
      driverPosition.value = position;

      // Update driver marker
      final currentTrip = trip.value;
      if (currentTrip == null) return;

      final driverLatLng = LatLng(position.latitude, position.longitude);
      final pickupLatLng = LatLng(
        currentTrip.pickup.lat,
        currentTrip.pickup.lng,
      );

      markers.assignAll({
        Marker(
          markerId: const MarkerId('driver'),
          position: driverLatLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
        Marker(
          markerId: const MarkerId('pickup'),
          position: pickupLatLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
        ),
      });

      // Update driver location in RTDB for customer tracking
      final uid = AuthService.currentUid;
      if (uid != null) {
        FirestoreService.updateActiveTripDriverLocation(currentTrip.id, {
          'driver_lat': position.latitude,
          'driver_lng': position.longitude,
          'driver_heading': position.heading,
        });
      }
    });
  }

  /// Mark as arrived at pickup location.
  Future<void> markArrived() async {
    final currentTrip = trip.value;
    if (currentTrip == null) return;

    try {
      await FirestoreService.updateTripStatus(currentTrip.id, 'arrived');
      Get.offNamed<void>(
        AppRoutes.activeTrip,
        arguments: {'tripId': currentTrip.id},
      );
    } catch (e) {
      debugPrint('NavigatePickupController.markArrived error: $e');
      AppSnackbar.error('navigate.arrived_failed'.tr);
    }
  }

  @override
  void onClose() {
    _locationSubscription?.cancel();
    super.onClose();
  }
}
