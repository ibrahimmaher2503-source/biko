import 'package:biko/core/models/document_model.dart';
import 'package:biko/core/models/driver_profile_model.dart';
import 'package:biko/core/models/enums.dart';
import 'package:biko/core/models/user_model.dart';
import 'package:biko/core/widgets/app_snackbar.dart';
import 'package:biko/features/admin/services/admin_firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AdminDriversController extends GetxController {
  // Driver list with combined user and profile data
  final RxList<Map<String, dynamic>> drivers = <Map<String, dynamic>>[].obs;

  // Filters
  final RxString approvalFilter = 'all'.obs;
  final RxString onlineFilter = 'all'.obs;
  final RxString searchQuery = ''.obs;

  // Pagination
  final RxBool isLoading = false.obs;
  final RxBool hasMore = true.obs;
  final RxInt currentPage = 1.obs;
  final int pageSize = 20;
  dynamic lastDocument;

  /// Text controller for the search field in the drivers screen.
  final TextEditingController searchTextController = TextEditingController();

  // Selected driver details
  final Rx<UserModel?> selectedDriver = Rx<UserModel?>(null);
  final Rx<DriverProfileModel?> selectedDriverProfile = Rx<DriverProfileModel?>(
    null,
  );
  final RxList<DocumentModel> selectedDriverDocuments = <DocumentModel>[].obs;

  /// Debounce worker — cancelled in [onClose].
  Worker? _searchDebounce;

  @override
  void onInit() {
    super.onInit();
    loadDrivers();

    // Debounce search
    _searchDebounce = debounce(
      searchQuery,
      (_) => loadDrivers(reset: true),
      time: const Duration(milliseconds: 500),
    );
  }

  @override
  void onClose() {
    _searchDebounce?.dispose();
    searchTextController.dispose();
    super.onClose();
  }

  /// Load drivers with filters and pagination
  Future<void> loadDrivers({bool reset = false}) async {
    if (reset) {
      currentPage.value = 1;
      lastDocument = null;
      hasMore.value = true;
      drivers.clear();
    }

    if (isLoading.value || !hasMore.value) return;

    try {
      isLoading.value = true;

      final result = await AdminFirestoreService.getDriverUsersForAdmin(
        search: searchQuery.value.isNotEmpty ? searchQuery.value : null,
        startAfter: lastDocument,
        pageSize: pageSize,
      );

      if (result.items.isEmpty) {
        hasMore.value = false;
        return;
      }

      hasMore.value = result.hasMore;
      lastDocument = result.lastDocument;

      // Fetch driver profiles for each user
      final List<Map<String, dynamic>> loadedDrivers = [];

      for (final user in result.items) {
        final profile = await AdminFirestoreService.getDriverProfile(user.uid);

        if (profile == null) continue;

        // Apply filters
        if (approvalFilter.value != 'all') {
          if (approvalFilter.value == 'approved' && !profile.isApproved) {
            continue;
          }
          if (approvalFilter.value == 'pending' &&
              (profile.isApproved || user.status == UserStatus.suspended)) {
            continue;
          }
          if (approvalFilter.value == 'rejected' &&
              user.status != UserStatus.suspended) {
            continue;
          }
        }

        if (onlineFilter.value != 'all') {
          if (onlineFilter.value == 'online' && !profile.isOnline) continue;
          if (onlineFilter.value == 'offline' && profile.isOnline) continue;
        }

        loadedDrivers.add({'user': user, 'profile': profile});
      }

      drivers.addAll(loadedDrivers);
    } catch (e) {
      AppSnackbar.error(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  /// Filter by approval status
  void filterByApproval(String status) {
    approvalFilter.value = status;
    loadDrivers(reset: true);
  }

  /// Filter by online status
  void filterByOnline(String status) {
    onlineFilter.value = status;
    loadDrivers(reset: true);
  }

  /// Load driver detail
  Future<void> loadDriverDetail(String uid) async {
    try {
      isLoading.value = true;

      final user = await AdminFirestoreService.getUserById(uid);
      if (user == null) {
        AppSnackbar.error('admin.drivers.driver_not_found'.tr);
        return;
      }
      selectedDriver.value = user;

      selectedDriverProfile.value =
          await AdminFirestoreService.getDriverProfile(uid);

      selectedDriverDocuments.value =
          await AdminFirestoreService.getDriverDocuments(uid);
    } catch (e) {
      AppSnackbar.error(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  /// Approve driver
  Future<void> approveDriver(String uid) async {
    try {
      isLoading.value = true;

      await AdminFirestoreService.callCloudFunction(
        'approveDriver',
        {'uid': uid},
      );

      AppSnackbar.success('admin.drivers.driver_approved'.tr);

      // Reload driver detail
      await loadDriverDetail(uid);

      // Reload list
      loadDrivers(reset: true);
    } catch (e) {
      AppSnackbar.error(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  /// Reject driver
  Future<void> rejectDriver(String uid, String reason) async {
    try {
      isLoading.value = true;

      await AdminFirestoreService.batchRejectDocuments(uid, reason);

      AppSnackbar.success('admin.drivers.driver_rejected'.tr);

      // Reload driver detail
      await loadDriverDetail(uid);

      // Reload list
      loadDrivers(reset: true);
    } catch (e) {
      AppSnackbar.error(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  /// Suspend driver
  Future<void> suspendDriver(String uid, String reason) async {
    try {
      isLoading.value = true;

      await AdminFirestoreService.callCloudFunction(
        'suspendUser',
        {'uid': uid, 'reason': reason},
      );

      AppSnackbar.success('admin.drivers.driver_suspended'.tr);

      // Reload driver detail
      await loadDriverDetail(uid);

      // Reload list
      loadDrivers(reset: true);
    } catch (e) {
      AppSnackbar.error(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  /// Activate driver
  Future<void> activateDriver(String uid) async {
    try {
      isLoading.value = true;

      await AdminFirestoreService.updateUserStatus(uid, 'active');

      AppSnackbar.success('admin.drivers.driver_activated'.tr);

      // Reload driver detail
      await loadDriverDetail(uid);

      // Reload list
      loadDrivers(reset: true);
    } catch (e) {
      AppSnackbar.error(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  /// Load next page
  void nextPage() {
    if (!hasMore.value || isLoading.value) return;
    currentPage.value++;
    loadDrivers();
  }

  /// Load previous page
  void previousPage() {
    if (currentPage.value <= 1) return;
    currentPage.value--;
    loadDrivers(reset: true);
  }

  /// Refresh list
  @override
  Future<void> refresh() async {
    await loadDrivers(reset: true);
  }
}
