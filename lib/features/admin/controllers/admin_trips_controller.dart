import 'package:biko/core/models/enums.dart';
import 'package:biko/core/models/trip_model.dart';
import 'package:biko/core/models/user_model.dart';
import 'package:biko/core/widgets/app_snackbar.dart';
import 'package:biko/features/admin/services/admin_firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show DocumentSnapshot;
import 'package:flutter/material.dart' show DateTimeRange;
import 'package:get/get.dart';

/// Controller for Admin Trips Management screen (US7).
///
/// Handles:
/// - Paginated trip list with type/status/date filters
/// - Trip detail view with customer, driver, and bids
/// - Issue credit via Cloud Function (adjustWalletBalance)
class AdminTripsController extends GetxController {
  // ==================== Observables ====================

  /// List of trips for current page
  final trips = <TripModel>[].obs;

  /// Loading state
  final isLoading = false.obs;

  /// Filter: trip type
  final typeFilter = Rx<TripType?>(null);

  /// Filter: trip status
  final statusFilter = Rx<TripStatus?>(null);

  /// Filter: date range
  final dateRange = Rx<DateTimeRange?>(null);

  /// Pagination: has more pages
  final hasMore = false.obs;

  /// Pagination: current page number (1-indexed)
  final currentPage = 1.obs;

  /// Pagination: last Firestore document for cursor
  DocumentSnapshot? lastDocument;

  /// Selected trip for detail view
  final selectedTrip = Rx<TripModel?>(null);

  /// Bids for selected trip
  final tripBids = <Map<String, dynamic>>[].obs;

  /// Customer user for selected trip
  final tripCustomer = Rx<UserModel?>(null);

  /// Driver user for selected trip
  final tripDriver = Rx<UserModel?>(null);

  // ==================== Lifecycle ====================

  @override
  void onInit() {
    super.onInit();
    loadTrips();
  }

  @override
  // ignore: unnecessary_overrides
  void onClose() {
    super.onClose();
  }

  // ==================== Trip List ====================

  /// Load trips with current filters and pagination
  Future<void> loadTrips() async {
    try {
      isLoading.value = true;

      final result = await AdminFirestoreService.getPaginatedTrips(
        typeFilter: typeFilter.value,
        statusFilter: statusFilter.value,
        dateRange: dateRange.value,
        startAfter: lastDocument,
      );

      trips.value = result.items;
      lastDocument = result.lastDocument;
      hasMore.value = result.hasMore;
    } catch (e) {
      AppSnackbar.error('admin.trips.load_error'.tr);
    } finally {
      isLoading.value = false;
    }
  }

  /// Reset filters and reload from page 1
  void resetFilters() {
    typeFilter.value = null;
    statusFilter.value = null;
    dateRange.value = null;
    currentPage.value = 1;
    lastDocument = null;
    loadTrips();
  }

  /// Apply filter change and reload
  void applyFilter() {
    currentPage.value = 1;
    lastDocument = null;
    loadTrips();
  }

  // ==================== Pagination ====================

  /// Load next page
  void nextPage() {
    if (!hasMore.value || isLoading.value) return;
    currentPage.value++;
    loadTrips();
  }

  /// Load previous page (reset to first page)
  void previousPage() {
    if (currentPage.value <= 1 || isLoading.value) return;
    currentPage.value = 1;
    lastDocument = null;
    loadTrips();
  }

  // ==================== Trip Detail ====================

  /// Load full trip details including bids, customer, and driver
  Future<void> loadTripDetail(String tripId) async {
    try {
      isLoading.value = true;

      // Load trip document via service
      final trip = await AdminFirestoreService.getTripById(tripId);

      if (trip == null) {
        AppSnackbar.error('admin.trips.trip_not_found_message'.tr);
        return;
      }

      selectedTrip.value = trip;

      // Load bids subcollection via service
      tripBids.value = await AdminFirestoreService.getTripBids(tripId);

      // Load customer user via service
      if (trip.customerUid.isNotEmpty) {
        tripCustomer.value =
            await AdminFirestoreService.getUserById(trip.customerUid);
      }

      // Load driver user (if assigned) via service
      if (trip.driverUid != null && trip.driverUid!.isNotEmpty) {
        tripDriver.value =
            await AdminFirestoreService.getUserById(trip.driverUid!);
      }
    } catch (e) {
      AppSnackbar.error('admin.trips.detail_error'.tr);
    } finally {
      isLoading.value = false;
    }
  }

  // ==================== Actions ====================

  /// Issue credit to customer via Cloud Function
  Future<void> issueCredit({
    required String tripId,
    required String customerUid,
    required double amount,
    required String reason,
  }) async {
    try {
      isLoading.value = true;

      await AdminFirestoreService.callCloudFunction(
        'adjustWalletBalance',
        {
          'uid': customerUid,
          'amount': amount,
          'type': 'credit',
          'reference': 'trip_credit_$tripId',
          'reason': reason,
        },
      );

      AppSnackbar.success('admin.trips.credit_issued_message'.tr);

      // Reload trip detail to reflect changes
      await loadTripDetail(tripId);
    } catch (e) {
      AppSnackbar.error('admin.trips.credit_error'.tr);
    } finally {
      isLoading.value = false;
    }
  }
}
