import 'package:biko/core/models/trip_model.dart';
import 'package:biko/core/services/auth_service.dart';
import 'package:biko/core/services/firestore_service.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

/// Controller for trip history list with pagination
class TripHistoryController extends GetxController {
  // ==================== Observable State ====================

  final RxList<TripModel> trips = <TripModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool hasMore = true.obs;
  final RxString errorMessage = ''.obs;

  String _uid = '';

  /// Opaque pagination cursor — never inspect, just pass back to service.
  Object? _cursor;

  static const _pageSize = 20;

  // ==================== Lifecycle ====================

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>?;
    _uid = args?['uid'] as String? ?? '';
    // Fallback to current auth user if arguments are missing
    if (_uid.isEmpty) {
      _uid = AuthService.currentUid ?? '';
    }
    _loadTrips();
  }

  // ==================== Data Loading ====================

  Future<void> _loadTrips() async {
    if (_uid.isEmpty) {
      isLoading.value = false;
      return;
    }
    try {
      isLoading.value = true;
      errorMessage.value = '';
      _cursor = null;

      final result = await FirestoreService.getTripHistoryPaginated(_uid);
      trips.assignAll(result.items);
      _cursor = result.cursor;
      hasMore.value = result.hasMore(_pageSize);
    } catch (e) {
      debugPrint('❌ TripHistoryController._loadTrips: $e');
      errorMessage.value = 'history.load_error';
    } finally {
      isLoading.value = false;
    }
  }

  /// Load more trips for pagination
  Future<void> loadMore() async {
    if (isLoadingMore.value || !hasMore.value || _cursor == null) return;
    try {
      isLoadingMore.value = true;
      final result = await FirestoreService.getTripHistoryPaginated(
        _uid,
        cursor: _cursor,
      );
      if (result.items.isEmpty) {
        hasMore.value = false;
      } else {
        trips.addAll(result.items);
        _cursor = result.cursor;
        hasMore.value = result.hasMore(_pageSize);
      }
    } catch (e) {
      debugPrint('❌ TripHistoryController.loadMore: $e');
    } finally {
      isLoadingMore.value = false;
    }
  }

  /// Refresh the trip list
  Future<void> refreshTrips() async {
    await _loadTrips();
  }
}
