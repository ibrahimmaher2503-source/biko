import 'package:biko/core/models/rating_model.dart';
import 'package:biko/core/models/trip_summary_model.dart';
import 'package:biko/core/routes/app_routes.dart';
import 'package:biko/core/services/firestore_service.dart';
import 'package:biko/core/widgets/app_snackbar.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

/// Controller for the trip completion and rating flow
class TripCompletionController extends GetxController {
  // ==================== Observable State ====================

  final Rx<TripSummaryModel?> summary = Rx<TripSummaryModel?>(null);
  final RxBool isLoading = true.obs;
  final RxBool isSubmitting = false.obs;
  final RxInt rating = 3.obs;
  final RxString comment = ''.obs;
  final RxList<String> selectedChips = <String>[].obs;
  final Rx<double?> tipAmount = Rx<double?>(null);
  final RxString errorMessage = ''.obs;

  String _tripId = '';
  String _driverUid = '';
  String _customerUid = '';

  // ==================== Lifecycle ====================

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>?;
    _tripId = args?['tripId'] as String? ?? '';
    _driverUid = args?['driverUid'] as String? ?? '';
    _customerUid = args?['customerUid'] as String? ?? '';
    _loadTripSummary();
  }

  // ==================== Data Loading ====================

  Future<void> _loadTripSummary() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      final result = await FirestoreService.getTripSummary(_tripId);
      summary.value = result;
      if (result == null) {
        errorMessage.value = 'trip_summary_not_found';
      }
    } catch (e) {
      debugPrint('❌ TripCompletionController._loadTripSummary: $e');
      errorMessage.value = 'trip_summary_error';
    } finally {
      isLoading.value = false;
    }
  }

  // ==================== Rating Actions ====================

  /// Update star rating (1-5)
  void setRating(int value) {
    rating.value = value.clamp(1, 5);
  }

  /// Toggle a comment chip
  void toggleChip(String chip) {
    if (selectedChips.contains(chip)) {
      selectedChips.remove(chip);
    } else {
      selectedChips.add(chip);
    }
  }

  /// Set the tip amount (null = no tip)
  void setTip(double? amount) {
    tipAmount.value = amount;
  }

  /// Submit the rating and optionally tip the driver
  Future<void> submitRating() async {
    if (isSubmitting.value) return;

    try {
      isSubmitting.value = true;

      // Build comment from chips + custom comment
      final fullComment = [
        ...selectedChips,
        if (comment.value.isNotEmpty) comment.value,
      ].join(', ');

      final ratingModel = RatingModel(
        ratingId: '',
        tripId: _tripId,
        raterUid: _customerUid,
        rateeUid: _driverUid,
        score: rating.value,
        comment: fullComment.isNotEmpty ? fullComment : null,
        chips: selectedChips.toList(),
        createdAt: DateTime.now(),
      );

      await FirestoreService.submitRating(ratingModel);

      // Tip driver if amount selected
      if (tipAmount.value != null && tipAmount.value! > 0) {
        await FirestoreService.tipDriver(_tripId, tipAmount.value!);
      }

      AppSnackbar.success('rating_submitted'.tr);
      Get.offAllNamed(AppRoutes.customerHome);
    } catch (e) {
      debugPrint('❌ TripCompletionController.submitRating: $e');
      AppSnackbar.error('rating_submit_error'.tr);
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Skip rating and go home
  void skipRating() {
    Get.offAllNamed(AppRoutes.customerHome);
  }
}
