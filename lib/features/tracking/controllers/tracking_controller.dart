import 'dart:async';

import 'package:biko/core/models/enums.dart';
import 'package:biko/core/routes/app_routes.dart';
import 'package:biko/core/services/firestore_service.dart';
import 'package:biko/core/widgets/app_snackbar.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Controller for the trip tracking screen.
///
/// Listens to Realtime DB for driver location and trip status updates.
/// Handles status transitions, cancellation, and navigation.
class TrackingController extends GetxController {
  // ==================== Observables ====================

  /// Current tracking status
  final trackingStatus = TrackingStatus.driverEnRoute.obs;

  /// Driver's current location
  final driverLocation = Rxn<LatLng>();

  /// Driver's heading (for marker rotation)
  final driverHeading = 0.0.obs;

  /// Estimated time of arrival string
  final eta = ''.obs;

  /// Trip ID from route arguments
  final tripId = ''.obs;

  /// Driver name (from trip data)
  final driverName = ''.obs;

  /// Driver photo URL
  final driverPhotoUrl = Rxn<String>();

  /// Vehicle type
  final vehicleType = ''.obs;

  /// Plate number
  final plateNumber = ''.obs;

  /// Driver rating
  final driverRating = 0.0.obs;

  /// Driver phone number (for call button)
  final driverPhone = ''.obs;

  /// Driver UID (for trip completion / chat)
  final driverUid = ''.obs;

  /// Customer UID (for trip completion / chat)
  final customerUid = ''.obs;

  /// Pickup location
  final pickupLocation = Rxn<LatLng>();

  /// Dropoff location
  final dropoffLocation = Rxn<LatLng>();

  /// Whether cancellation is in progress
  final isCancelling = false.obs;

  /// Whether initial data has loaded
  final isLoading = true.obs;

  // ==================== Internal ====================

  StreamSubscription<Map<String, dynamic>>? _tripSub;
  StreamSubscription<Map<String, dynamic>>? _driverLocationSub;

  // ==================== Lifecycle ====================

  @override
  void onInit() {
    super.onInit();
    _extractArguments();
    _listenToTrip();
    _listenToDriverLocation();
  }

  @override
  void onClose() {
    _tripSub?.cancel();
    _driverLocationSub?.cancel();
    super.onClose();
  }

  // ==================== Initialization ====================

  void _extractArguments() {
    final args = Get.arguments;
    if (args is Map<String, dynamic>) {
      tripId.value = (args['trip_id'] as String?) ?? '';
    }
  }

  void _listenToTrip() {
    if (tripId.value.isEmpty) {
      isLoading.value = false;
      return;
    }

    _tripSub = FirestoreService.listenToActiveTrip(tripId.value).listen(
      (data) {
        if (data.isEmpty) return;
        _handleTripUpdate(data);
        isLoading.value = false;
      },
      onError: (_) {
        isLoading.value = false;
      },
    );
  }

  /// Listen to driver location from Realtime Database (sub-second updates).
  void _listenToDriverLocation() {
    if (tripId.value.isEmpty) return;

    _driverLocationSub =
        FirestoreService.listenToDriverLocation(tripId.value).listen(
      (data) {
        if (data.isEmpty) return;
        _handleDriverLocationUpdate(data);
      },
    );
  }

  // ==================== Status Updates ====================

  /// Handle driver location update from RTDB.
  void _handleDriverLocationUpdate(Map<String, dynamic> data) {
    final lat = (data['driver_lat'] as num?)?.toDouble();
    final lng = (data['driver_lng'] as num?)?.toDouble();
    if (lat != null && lng != null) {
      driverLocation.value = LatLng(lat, lng);
    }

    driverHeading.value = (data['driver_heading'] as num?)?.toDouble() ?? 0;

    final etaMinutes = (data['eta_minutes'] as num?)?.toInt();
    if (etaMinutes != null) {
      eta.value = 'tracking.eta_minutes'.trParams({
        'minutes': etaMinutes.toString(),
      });
    }
  }

  /// Handle trip data update from Firestore (status, driver info, locations).
  void _handleTripUpdate(Map<String, dynamic> data) {
    // Update driver info from Firestore
    driverName.value = (data['driver_name'] as String?) ?? '';
    driverPhotoUrl.value = data['driver_photo_url'] as String?;
    vehicleType.value = (data['vehicle_type'] as String?) ?? '';
    plateNumber.value = (data['plate_number'] as String?) ?? '';
    driverRating.value = (data['driver_rating'] as num?)?.toDouble() ?? 0;
    driverPhone.value = (data['driver_phone'] as String?) ?? '';
    driverUid.value = (data['driver_uid'] as String?) ?? '';
    customerUid.value = (data['customer_uid'] as String?) ?? '';

    // Update pickup/dropoff
    final pickupLat = (data['pickup_lat'] as num?)?.toDouble();
    final pickupLng = (data['pickup_lng'] as num?)?.toDouble();
    if (pickupLat != null && pickupLng != null) {
      pickupLocation.value = LatLng(pickupLat, pickupLng);
    }

    final dropoffLat = (data['dropoff_lat'] as num?)?.toDouble();
    final dropoffLng = (data['dropoff_lng'] as num?)?.toDouble();
    if (dropoffLat != null && dropoffLng != null) {
      dropoffLocation.value = LatLng(dropoffLat, dropoffLng);
    }

    // Handle status transition
    final status = data['status'] as String?;
    if (status != null) {
      _handleStatusChange(TrackingStatus.fromJson(status));
    }
  }

  void _handleStatusChange(TrackingStatus newStatus) {
    final oldStatus = trackingStatus.value;
    trackingStatus.value = newStatus;

    // Show snackbar for key transitions
    if (newStatus == TrackingStatus.driverArrived &&
        oldStatus != TrackingStatus.driverArrived) {
      AppSnackbar.success('tracking.driver_arrived'.tr);
    }

    // Navigate to completion screen
    if (newStatus == TrackingStatus.completed) {
      Get.offNamed(
        AppRoutes.tripCompleted,
        arguments: {
          'tripId': tripId.value,
          'driverUid': driverUid.value,
          'customerUid': customerUid.value,
        },
      );
    }
  }

  // ==================== Actions ====================

  /// Cancel the trip (only allowed before trip_in_progress).
  Future<void> cancelTrip() async {
    if (trackingStatus.value == TrackingStatus.tripInProgress) {
      AppSnackbar.error('tracking.cannot_cancel_in_progress'.tr);
      return;
    }

    isCancelling.value = true;
    try {
      await FirestoreService.cancelTrip(tripId.value, 'Customer cancelled');
      Get.offAllNamed(AppRoutes.customerHome);
    } catch (_) {
      AppSnackbar.error('tracking.cancel_error'.tr);
    } finally {
      isCancelling.value = false;
    }
  }

  /// Whether the cancel button should be visible.
  bool get canCancel =>
      trackingStatus.value == TrackingStatus.driverEnRoute ||
      trackingStatus.value == TrackingStatus.driverArrived;
}
