import 'dart:async';

import 'package:biko/core/models/bid_model.dart';
import 'package:biko/core/models/enums.dart';
import 'package:biko/core/routes/app_routes.dart';
import 'package:biko/core/services/firestore_service.dart';
import 'package:biko/core/widgets/app_snackbar.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

/// Controller for the incoming bids screen.
///
/// Listens to live bids from Realtime DB, handles accept/reject,
/// search timeout, and cancellation.
class BidsController extends GetxController {
  // ==================== Observables ====================

  /// Live list of incoming bids
  final bids = <BidModel>[].obs;

  /// Loading state for initial data
  final isLoading = true.obs;

  /// Whether a bid acceptance is in progress
  final isAcceptingBid = false.obs;

  /// Trip ID from route arguments
  final tripId = ''.obs;

  /// Whether the search has timed out (60s with no bids)
  final hasTimedOut = false.obs;

  /// Customer's offered price (for display)
  final offeredPrice = 0.0.obs;

  /// Pickup address (for display)
  final pickupAddress = ''.obs;

  /// Dropoff address (for display)
  final dropoffAddress = ''.obs;

  // ==================== Internal ====================

  StreamSubscription<List<BidModel>>? _bidsSub;
  Timer? _timeoutTimer;

  /// Whether the trip was intentionally accepted/cancelled by user action.
  ///
  /// Set to `true` before any explicit navigation away from the screen so
  /// that [onClose] does not redundantly cancel a trip that is already done.
  bool _tripResolved = false;

  // ==================== Lifecycle ====================

  @override
  void onInit() {
    super.onInit();
    _extractArguments();
    _listenToBids();
    if (tripId.value.isNotEmpty) {
      _startTimeoutTimer();
    }
  }

  @override
  void onClose() {
    _bidsSub?.cancel();
    _timeoutTimer?.cancel();
    // If the user backed out without resolving the trip, cancel it silently
    // so drivers are not left bidding on an abandoned trip.
    if (!_tripResolved && tripId.value.isNotEmpty) {
      FirestoreService.cancelTripSearch(tripId.value).catchError((Object e) {
        debugPrint('⚠️ BidsController.onClose: silent cancel failed: $e');
        return null;
      });
    }
    super.onClose();
  }

  // ==================== Initialization ====================

  void _extractArguments() {
    final args = Get.arguments;
    if (args is Map<String, dynamic>) {
      tripId.value = (args['trip_id'] as String?) ?? '';
      offeredPrice.value = (args['offered_price'] as num?)?.toDouble() ?? 0;
      pickupAddress.value = (args['pickup_address'] as String?) ?? '';
      dropoffAddress.value = (args['dropoff_address'] as String?) ?? '';
    }
  }

  void _listenToBids() {
    if (tripId.value.isEmpty) {
      isLoading.value = false;
      return;
    }

    _bidsSub = FirestoreService.listenToLiveBids(tripId.value).listen(
      (bidList) {
        bids.assignAll(
          bidList.where((b) => b.status == BidStatus.pending).toList(),
        );
        isLoading.value = false;

        // Reset timeout when pending bids exist
        if (bids.isNotEmpty) {
          hasTimedOut.value = false;
          _timeoutTimer?.cancel();
        } else if (bids.isEmpty && bidList.isNotEmpty) {
          // All bids were rejected/expired — restart timeout
          _restartTimeoutTimer();
        }
      },
      onError: (_) {
        isLoading.value = false;
      },
    );
  }

  void _startTimeoutTimer() {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(const Duration(seconds: 60), () {
      if (bids.isEmpty) {
        hasTimedOut.value = true;
      }
    });
  }

  /// Restart the timeout timer (e.g. after all bids are rejected).
  void _restartTimeoutTimer() {
    _startTimeoutTimer();
  }

  // ==================== Actions ====================

  /// Accept a bid and navigate to trip tracking.
  Future<void> acceptBid(BidModel bid) async {
    isAcceptingBid.value = true;
    try {
      await FirestoreService.acceptBid(
        tripId: tripId.value,
        bidId: bid.bidId,
        finalPrice: bid.amount,
        driverUid: bid.driverUid,
      );

      _tripResolved = true;
      Get.offNamed(AppRoutes.trackTrip, arguments: {'trip_id': tripId.value});
    } catch (_) {
      AppSnackbar.error('bids.accept_error'.tr);
    } finally {
      isAcceptingBid.value = false;
    }
  }

  /// Reject a specific bid.
  Future<void> rejectBid(BidModel bid) async {
    try {
      await FirestoreService.rejectBid(tripId.value, bid.bidId);
    } catch (_) {
      AppSnackbar.error('common.error'.tr);
    }
  }

  /// Cancel the driver search and go home.
  Future<void> cancelSearch() async {
    try {
      _tripResolved = true;
      await FirestoreService.cancelTripSearch(tripId.value);
      Get.offAllNamed(AppRoutes.customerHome);
    } catch (_) {
      AppSnackbar.error('common.error'.tr);
    }
  }

  /// Cancel the trip and allow the screen to be popped.
  ///
  /// Called by the [PopScope] confirmation dialog in [BidsScreen].
  Future<bool> cancelTrip() async {
    if (tripId.value.isEmpty) return true;
    try {
      _tripResolved = true;
      await FirestoreService.cancelTripSearch(tripId.value);
      return true;
    } catch (e) {
      _tripResolved = false;
      debugPrint('❌ BidsController.cancelTrip: $e');
      return false;
    }
  }
}
