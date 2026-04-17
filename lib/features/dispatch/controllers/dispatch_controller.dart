import 'dart:async';

import 'package:biko/core/models/driver_location_model.dart';
import 'package:biko/core/models/trip_model.dart';
import 'package:biko/core/services/firestore_service.dart';
import 'package:biko/core/widgets/app_snackbar.dart';
import 'package:get/get.dart';

/// Controller for the phone-based dispatcher interface.
///
/// Streams live data from Firestore + Realtime DB and exposes
/// dispatcher actions: assign driver, cancel trip.
class DispatchController extends GetxController {
  // ==================== Observables ====================

  final searchingTrips = <TripModel>[].obs;
  final activeTrips = <TripModel>[].obs;
  final onlineDrivers = <DriverLocationModel>[].obs;
  final isLoading = true.obs;
  final isAssigning = false.obs;

  // ==================== Streams ====================

  StreamSubscription<List<TripModel>>? _searchingSub;
  StreamSubscription<List<TripModel>>? _activeSub;
  StreamSubscription<List<DriverLocationModel>>? _driversSub;

  // ==================== Lifecycle ====================

  @override
  void onInit() {
    super.onInit();
    _startStreams();
  }

  void _startStreams() {
    _searchingSub = FirestoreService.listenToSearchingTrips().listen(
      (trips) {
        searchingTrips.value = trips;
        isLoading.value = false;
      },
      onError: (_) => isLoading.value = false,
    );

    _activeSub = FirestoreService.listenToActiveTrips().listen(
      (trips) => activeTrips.value = trips,
    );

    _driversSub = FirestoreService.listenToAllOnlineDrivers().listen(
      (drivers) => onlineDrivers.value = drivers,
    );
  }

  @override
  void onClose() {
    _searchingSub?.cancel();
    _activeSub?.cancel();
    _driversSub?.cancel();
    super.onClose();
  }

  // ==================== Actions ====================

  /// Manually assign [driverUid] to [tripId] at [price].
  Future<void> assignDriver({
    required String tripId,
    required String driverUid,
    required double price,
  }) async {
    try {
      isAssigning.value = true;
      await FirestoreService.assignDriverToTrip(
        tripId: tripId,
        driverUid: driverUid,
        price: price,
      );
      AppSnackbar.success('dispatch.driver_assigned'.tr);
    } catch (e) {
      AppSnackbar.error('dispatch.assign_error'.tr);
    } finally {
      isAssigning.value = false;
    }
  }

  /// Cancel a searching trip from the dispatcher panel.
  Future<void> cancelTrip(String tripId) async {
    try {
      await FirestoreService.cancelTrip(tripId, 'Cancelled by dispatcher');
      AppSnackbar.success('dispatch.trip_cancelled'.tr);
    } catch (e) {
      AppSnackbar.error('dispatch.cancel_error'.tr);
    }
  }
}
