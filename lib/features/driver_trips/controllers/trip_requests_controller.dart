import 'dart:async';

import 'package:biko/core/routes/app_routes.dart';
import 'package:biko/core/services/auth_service.dart';
import 'package:biko/core/services/background_location_service.dart';
import 'package:biko/core/services/firestore_service.dart';
import 'package:biko/core/widgets/app_snackbar.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

/// Controller for incoming trip requests screen.
///
/// Listens to Realtime DB for live trip requests,
/// manages countdown timers, and handles accept/bid actions.
class TripRequestsController extends GetxController {
  /// List of active trip requests
  final tripRequests = <TripRequest>[].obs;

  /// Loading state
  final isLoading = true.obs;

  /// Whether the driver is online
  bool get isOnline => Get.find<BackgroundLocationService>().isOnline.value;

  StreamSubscription<List<Map<String, dynamic>>>? _requestsSubscription;
  final _countdownTimers = <String, Timer>{};

  @override
  void onInit() {
    super.onInit();
    _listenToRequests();
  }

  @override
  void onClose() {
    _requestsSubscription?.cancel();
    for (final timer in _countdownTimers.values) {
      timer.cancel();
    }
    _countdownTimers.clear();
    super.onClose();
  }

  /// Accept trip at the customer's offered price.
  Future<void> acceptTrip(TripRequest request) async {
    try {
      final uid = AuthService.currentUid;
      if (uid == null) return;

      await FirestoreService.acceptBid(
        tripId: request.tripId,
        bidId: '', // Direct acceptance — no bid involved
        finalPrice: request.customerPrice,
        driverUid: uid,
      );

      // Remove from list and navigate to pickup
      tripRequests.removeWhere((r) => r.tripId == request.tripId);
      _cancelCountdown(request.tripId);
      Get.toNamed(
        AppRoutes.navigateToPickup,
        arguments: {'tripId': request.tripId},
      );
    } catch (e) {
      debugPrint('❌ TripRequestsController.acceptTrip failed: $e');
      AppSnackbar.error('driver_trips.accept_failed'.tr);
    }
  }

  /// Navigate to bid screen for counter-bid.
  void submitBid(TripRequest request) {
    Get.toNamed(
      AppRoutes.submitBid,
      arguments: {
        'tripId': request.tripId,
        'customerPrice': request.customerPrice,
        'pickupAddress': request.pickupAddress,
        'dropoffAddress': request.dropoffAddress,
        'distanceKm': request.distanceKm,
        'durationMinutes': request.durationMinutes,
      },
    );
  }

  /// Dismiss a request card manually.
  void dismissRequest(String tripId) {
    tripRequests.removeWhere((r) => r.tripId == tripId);
    _cancelCountdown(tripId);
  }

  // ==================== Private Methods ====================

  void _listenToRequests() {
    isLoading.value = true;

    _requestsSubscription = FirestoreService.listenToTripRequests().listen(
      (requests) {
        _processRequests(requests);
        isLoading.value = false;
      },
      onError: (e) {
        debugPrint('⚠️ TripRequestsController stream error: $e');
        isLoading.value = false;
      },
    );
  }

  void _processRequests(List<Map<String, dynamic>> rawRequests) {
    final newRequests = <TripRequest>[];

    for (final data in rawRequests) {
      final tripId = data['trip_id'] as String? ?? '';
      if (tripId.isEmpty) continue;

      // Skip already expired requests
      final createdAt = data['created_at'] as int? ?? 0;
      final elapsed = DateTime.now().millisecondsSinceEpoch - createdAt;
      final remainingSeconds = 30 - (elapsed ~/ 1000);
      if (remainingSeconds <= 0) continue;

      final request = TripRequest(
        tripId: tripId,
        pickupAddress: data['pickup_address'] as String? ?? '',
        dropoffAddress: data['dropoff_address'] as String? ?? '',
        customerPrice: (data['customer_price'] as num?)?.toDouble() ?? 0.0,
        distanceKm: (data['distance_km'] as num?)?.toDouble() ?? 0.0,
        durationMinutes: (data['duration_minutes'] as num?)?.toInt() ?? 0,
        vehicleType: data['vehicle_type'] as String? ?? 'motorcycle',
        countdown: remainingSeconds,
      );

      newRequests.add(request);
      _startCountdown(request);
    }

    tripRequests.value = newRequests;
  }

  void _startCountdown(TripRequest request) {
    _cancelCountdown(request.tripId);

    _countdownTimers[request
        .tripId] = Timer.periodic(const Duration(seconds: 1), (timer) {
      final index = tripRequests.indexWhere((r) => r.tripId == request.tripId);
      if (index == -1) {
        timer.cancel();
        return;
      }

      final current = tripRequests[index];
      if (current.countdown <= 1) {
        // Auto-dismiss at 0
        tripRequests.removeAt(index);
        timer.cancel();
        _countdownTimers.remove(request.tripId);
        return;
      }

      tripRequests[index] = current.copyWith(countdown: current.countdown - 1);
    });
  }

  void _cancelCountdown(String tripId) {
    _countdownTimers[tripId]?.cancel();
    _countdownTimers.remove(tripId);
  }
}

/// Data model for a trip request card.
class TripRequest {
  const TripRequest({
    required this.tripId,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.customerPrice,
    required this.distanceKm,
    required this.durationMinutes,
    required this.vehicleType,
    required this.countdown,
  });

  final String tripId;
  final String pickupAddress;
  final String dropoffAddress;
  final double customerPrice;
  final double distanceKm;
  final int durationMinutes;
  final String vehicleType;
  final int countdown;

  TripRequest copyWith({int? countdown}) {
    return TripRequest(
      tripId: tripId,
      pickupAddress: pickupAddress,
      dropoffAddress: dropoffAddress,
      customerPrice: customerPrice,
      distanceKm: distanceKm,
      durationMinutes: durationMinutes,
      vehicleType: vehicleType,
      countdown: countdown ?? this.countdown,
    );
  }
}
