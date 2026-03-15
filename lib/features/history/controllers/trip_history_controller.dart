import 'package:biko/core/models/trip_model.dart';
import 'package:biko/core/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  DocumentSnapshot? _lastDoc;

  // ==================== Lifecycle ====================

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>?;
    _uid = args?['uid'] as String? ?? '';
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
      _lastDoc = null;

      final results = await FirestoreService.getTripHistory(_uid);
      trips.assignAll(results);
      _lastDoc = await FirestoreService.getTripHistoryLastDoc(_uid);
      hasMore.value = results.length >= 20;
    } catch (e) {
      debugPrint('❌ TripHistoryController._loadTrips: $e');
      errorMessage.value = 'history.load_error';
    } finally {
      isLoading.value = false;
    }
  }

  /// Load more trips for pagination
  Future<void> loadMore() async {
    if (isLoadingMore.value || !hasMore.value || _lastDoc == null) return;
    try {
      isLoadingMore.value = true;
      final results = await FirestoreService.getTripHistory(
        _uid,
        lastDoc: _lastDoc,
      );
      trips.addAll(results);
      _lastDoc = await FirestoreService.getTripHistoryLastDoc(
        _uid,
        lastDoc: _lastDoc,
      );
      hasMore.value = results.length >= 20;
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
