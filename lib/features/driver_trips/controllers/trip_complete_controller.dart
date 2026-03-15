import 'package:biko/core/models/rating_model.dart';
import 'package:biko/core/models/trip_model.dart';
import 'package:biko/core/routes/app_routes.dart';
import 'package:biko/core/services/auth_service.dart';
import 'package:biko/core/services/firestore_service.dart';
import 'package:biko/core/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Controller for the trip completion screen.
///
/// Shows fare breakdown, handles cash collection confirmation,
/// and allows rating the customer.
class TripCompleteController extends GetxController {
  final isLoading = true.obs;
  final trip = Rxn<TripModel>();
  final rating = 5.obs;
  final isSubmitting = false.obs;
  final hasRated = false.obs;

  // Fare breakdown (read from app_config — never hardcoded)
  final commissionRate = 0.0.obs;
  final totalFare = 0.0.obs;
  final commission = 0.0.obs;
  final netEarning = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    _loadTrip();
  }

  Future<void> _loadTrip() async {
    try {
      final args = Get.arguments as Map<String, dynamic>?;
      final tripId = args?['tripId'] as String?;
      if (tripId == null) {
        AppSnackbar.error('trip_complete.error_no_trip'.tr);
        Get.offAllNamed<void>(AppRoutes.driverHome);
        return;
      }

      final loadedTrip = await FirestoreService.getTrip(tripId);
      if (loadedTrip == null) {
        AppSnackbar.error('trip_complete.error_no_trip'.tr);
        Get.offAllNamed<void>(AppRoutes.driverHome);
        return;
      }

      trip.value = loadedTrip;

      // Load commission rate from app_config
      await _loadFareBreakdown(loadedTrip);

      isLoading.value = false;
    } catch (e) {
      debugPrint('TripCompleteController._loadTrip error: $e');
      isLoading.value = false;
    }
  }

  Future<void> _loadFareBreakdown(TripModel loadedTrip) async {
    try {
      final rate = await FirestoreService.getCommissionRate();
      if (rate != null) {
        commissionRate.value = rate;
      }
    } catch (e) {
      debugPrint('TripCompleteController._loadFareBreakdown error: $e');
    }

    final fare = loadedTrip.finalPrice;
    totalFare.value = fare;
    commission.value = fare * commissionRate.value;
    netEarning.value = fare - commission.value;
  }

  /// Confirm cash collection (calls Cloud Function to process commission).
  Future<void> confirmCashCollected() async {
    final currentTrip = trip.value;
    if (currentTrip == null) return;

    isSubmitting.value = true;
    try {
      await FirestoreService.callProcessCommission(currentTrip.id);
      AppSnackbar.success('trip_complete.cash_confirmed'.tr);
    } catch (e) {
      debugPrint('TripCompleteController.confirmCashCollected error: $e');
      AppSnackbar.error('trip_complete.cash_failed'.tr);
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Submit rating for the customer.
  Future<void> submitRating() async {
    final currentTrip = trip.value;
    if (currentTrip == null) return;

    final uid = AuthService.currentUser?.uid;
    if (uid == null) return;

    isSubmitting.value = true;
    try {
      final ratingModel = RatingModel(
        ratingId: '',
        tripId: currentTrip.id,
        raterUid: uid,
        rateeUid: currentTrip.customerUid,
        score: rating.value,
        createdAt: DateTime.now(),
      );

      await FirestoreService.submitRating(ratingModel);
      hasRated.value = true;
      AppSnackbar.success('trip_complete.rating_submitted'.tr);
    } catch (e) {
      debugPrint('TripCompleteController.submitRating error: $e');
      AppSnackbar.error('trip_complete.rating_failed'.tr);
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Go back to home screen.
  void goHome() {
    Get.offAllNamed<void>(AppRoutes.driverHome);
  }
}
