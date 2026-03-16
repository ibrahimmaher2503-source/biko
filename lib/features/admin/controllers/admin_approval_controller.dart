import 'package:biko/core/widgets/app_snackbar.dart';
import 'package:biko/features/admin/models/approval_stats_model.dart';
import 'package:biko/features/admin/models/driver_review_data.dart';
import 'package:biko/features/admin/services/admin_firestore_service.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class AdminApprovalController extends GetxController {
  final pendingDrivers = <DriverReviewData>[].obs;
  final Rx<DriverReviewData?> selectedDriver = Rx<DriverReviewData?>(null);
  final isLoading = false.obs;
  final Rx<ApprovalStatsModel?> approvalStats =
      Rx<ApprovalStatsModel?>(null);

  /// Filter by vehicle type: 'all', 'motorcycle', 'scooter', 'ebike'.
  final vehicleTypeFilter = 'all'.obs;

  /// Sort order: 'oldest' (default) or 'newest'.
  final sortBy = 'oldest'.obs;

  /// Returns the pending drivers list filtered by vehicle type
  /// and sorted according to the current sort order.
  List<DriverReviewData> get filteredDrivers {
    var result = pendingDrivers.toList();

    // Apply vehicle type filter.
    if (vehicleTypeFilter.value != 'all') {
      result = result
          .where(
            (d) =>
                d.driverProfile.vehicleType.name ==
                vehicleTypeFilter.value,
          )
          .toList();
    }

    // Apply sort order.
    if (sortBy.value == 'newest') {
      result.sort((a, b) => b.user.createdAt.compareTo(a.user.createdAt));
    } else {
      result.sort((a, b) => a.user.createdAt.compareTo(b.user.createdAt));
    }

    return result;
  }

  @override
  void onInit() {
    super.onInit();
    loadPendingDrivers();
    loadApprovalStats();
  }

  Future<void> loadPendingDrivers() async {
    try {
      isLoading.value = true;
      pendingDrivers.value =
          await AdminFirestoreService.getPendingDriversWithProfiles();
    } catch (e, stack) {
      debugPrint('loadPendingDrivers error: $e\n$stack');
      AppSnackbar.error(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> selectDriver(String uid) async {
    try {
      isLoading.value = true;

      final reviewData = await AdminFirestoreService.getDriverReviewData(uid);
      if (reviewData == null) {
        AppSnackbar.error('admin.drivers.driver_not_found'.tr);
        return;
      }
      selectedDriver.value = reviewData;
    } catch (e, stack) {
      debugPrint('selectDriver error: $e\n$stack');
      AppSnackbar.error(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> approveDriver(String uid) async {
    try {
      isLoading.value = true;

      await AdminFirestoreService.callCloudFunction(
        'approveDriver',
        {'uid': uid},
      );

      AppSnackbar.success('admin.approvals.driver_approved_success'.tr);

      await loadPendingDrivers();
      await loadApprovalStats();
      selectedDriver.value = null;
    } catch (e, stack) {
      debugPrint('approveDriver error: $e\n$stack');
      AppSnackbar.error(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> rejectDocuments(
    String uid,
    List<String> docIds,
    String reason,
  ) async {
    try {
      isLoading.value = true;

      await AdminFirestoreService.batchRejectDocumentsByIds(docIds, reason);

      AppSnackbar.success('admin.approvals.driver_rejected_success'.tr);

      if (selectedDriver.value != null) {
        await selectDriver(uid);
      }
      await loadPendingDrivers();
    } catch (e, stack) {
      debugPrint('rejectDocuments error: $e\n$stack');
      AppSnackbar.error(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> rejectCompletely(String uid, String reason) async {
    try {
      isLoading.value = true;

      await AdminFirestoreService.rejectDriverCompletely(uid, reason);

      AppSnackbar.success('admin.approvals.driver_rejected_success'.tr);

      selectedDriver.value = null;
      await loadPendingDrivers();
      await loadApprovalStats();
    } catch (e, stack) {
      debugPrint('rejectCompletely error: $e\n$stack');
      AppSnackbar.error(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadApprovalStats() async {
    try {
      approvalStats.value = await AdminFirestoreService.getApprovalStats();
    } catch (e, stack) {
      debugPrint('loadApprovalStats error: $e\n$stack');
    }
  }
}
