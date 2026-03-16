import 'package:biko/core/models/driver_profile_model.dart';
import 'package:biko/core/models/rating_model.dart';
import 'package:biko/core/services/auth_service.dart';
import 'package:biko/core/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Controller for the driver ratings screen.
///
/// Shows rating overview (average + distribution) and review list.
class RatingsController extends GetxController {
  final isLoading = true.obs;
  final driverProfile = Rxn<DriverProfileModel>();
  final ratings = <RatingModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadData();
  }

  Future<void> _loadData() async {
    isLoading.value = true;
    final uid = AuthService.currentUid;
    if (uid == null) {
      isLoading.value = false;
      return;
    }

    try {
      // Load profile for average rating + total trips
      final profile = await FirestoreService.getDriverProfile(uid);
      driverProfile.value = profile;

      // Load ratings
      final result = await FirestoreService.getDriverRatingsPaginated(uid);
      ratings.assignAll(result.items);
    } catch (e) {
      debugPrint('RatingsController._loadData error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Get star distribution (1-5) from current ratings list.
  Map<int, int> get starDistribution {
    final dist = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    for (final rating in ratings) {
      final star = rating.score.clamp(1, 5);
      dist[star] = (dist[star] ?? 0) + 1;
    }
    return dist;
  }

  @override
  Future<void> refresh() async {
    await _loadData();
  }
}
