import 'package:biko/core/models/enums.dart';
import 'package:biko/core/models/trip_model.dart';
import 'package:biko/core/models/user_model.dart';
import 'package:biko/core/services/firestore_service.dart';
import 'package:biko/core/widgets/app_snackbar.dart';
import 'package:biko/features/admin/services/admin_firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

/// Controller for Admin Customer Management (US5)
///
/// Manages customer list, search, pagination, and individual customer operations.
class AdminUsersController extends GetxController {
  // ==================== Observables ====================

  /// List of customers
  final customers = <UserModel>[].obs;

  /// Search query string
  final searchQuery = ''.obs;

  /// Status filter (null = all statuses)
  final statusFilter = Rx<UserStatus?>(null);

  /// Last document for cursor pagination
  DocumentSnapshot? lastDocument;

  /// Whether there are more pages
  final hasMore = false.obs;

  /// Loading state
  final isLoading = false.obs;

  /// Current page number
  final currentPage = 1.obs;

  /// Selected user for detail view
  final selectedUser = Rx<UserModel?>(null);

  /// Selected user's recent trips
  final selectedUserTrips = <TripModel>[].obs;

  // ==================== Lifecycle ====================

  @override
  void onInit() {
    super.onInit();
    loadCustomers();
  }

  @override
  // ignore: unnecessary_overrides
  void onClose() {
    super.onClose();
  }

  // ==================== Customer List ====================

  /// Load customers with pagination
  Future<void> loadCustomers({bool refresh = false}) async {
    if (isLoading.value) return;

    try {
      isLoading.value = true;

      if (refresh) {
        lastDocument = null;
        currentPage.value = 1;
      }

      final result = await AdminFirestoreService.getPaginatedUsers(
        type: UserType.customer,
        statusFilter: statusFilter.value,
        startAfter: lastDocument,
      );

      if (refresh) {
        customers.value = result.items;
      } else {
        customers.addAll(result.items);
      }

      lastDocument = result.lastDocument;
      hasMore.value = result.hasMore;
    } catch (e, stack) {
      debugPrint('loadCustomers error: $e\n$stack');
      AppSnackbar.error('admin.users.load_error'.tr);
    } finally {
      isLoading.value = false;
    }
  }

  /// Search customers by phone or name
  Future<void> searchCustomers(String query) async {
    searchQuery.value = query.trim();

    if (searchQuery.value.isEmpty) {
      // Reset to paginated list
      await loadCustomers(refresh: true);
      return;
    }

    try {
      isLoading.value = true;

      // Search by phone first (exact prefix match)
      List<UserModel> results = await AdminFirestoreService.searchUsersByPhone(
        searchQuery.value,
      );

      // If no phone results, try name search
      if (results.isEmpty) {
        results = await AdminFirestoreService.searchUsersByName(
          searchQuery.value,
        );
      }

      // Filter by customer type and status filter if set
      customers.value = results.where((user) {
        if (user.type != UserType.customer) return false;
        if (statusFilter.value != null && user.status != statusFilter.value) {
          return false;
        }
        return true;
      }).toList();

      // Disable pagination for search results
      hasMore.value = false;
    } catch (e) {
      AppSnackbar.error('admin.users.search_error'.tr);
    } finally {
      isLoading.value = false;
    }
  }

  /// Filter by status
  Future<void> filterByStatus(UserStatus? status) async {
    statusFilter.value = status;
    await loadCustomers(refresh: true);
  }

  // ==================== Pagination ====================

  /// Load next page
  Future<void> nextPage() async {
    if (!hasMore.value) return;
    currentPage.value++;
    await loadCustomers();
  }

  /// Load previous page (reset to page 1)
  Future<void> previousPage() async {
    if (currentPage.value <= 1) return;
    currentPage.value = 1;
    await loadCustomers(refresh: true);
  }

  // ==================== Customer Detail ====================

  /// Load customer detail and recent trips
  Future<void> loadUserDetail(String uid) async {
    try {
      isLoading.value = true;

      // Fetch user
      final user = await FirestoreService.getUser(uid);
      if (user == null) {
        AppSnackbar.error('admin.users.user_not_found'.tr);
        return;
      }
      selectedUser.value = user;

      // Fetch recent trips (last 10)
      final tripsResult = await AdminFirestoreService.getPaginatedTrips(
        pageSize: 10,
      );

      // Filter trips for this customer
      selectedUserTrips.value = tripsResult.items
          .where((trip) => trip.customerUid == uid)
          .toList();
    } catch (e) {
      AppSnackbar.error('admin.users.detail_load_error'.tr);
    } finally {
      isLoading.value = false;
    }
  }

  // ==================== Cloud Functions ====================

  /// Suspend user account
  Future<void> suspendUser(String uid, String reason) async {
    try {
      isLoading.value = true;

      await AdminFirestoreService.callCloudFunction(
        'suspendUser',
        {'uid': uid, 'reason': reason, 'action': 'suspend'},
      );

      AppSnackbar.success('admin.users.suspend_success'.tr);

      // Refresh user detail
      await loadUserDetail(uid);
    } catch (e) {
      AppSnackbar.error('admin.users.suspend_error'.tr);
    } finally {
      isLoading.value = false;
    }
  }

  /// Activate suspended user account
  Future<void> activateUser(String uid) async {
    try {
      isLoading.value = true;

      await AdminFirestoreService.callCloudFunction(
        'suspendUser',
        {'uid': uid, 'action': 'activate'},
      );

      AppSnackbar.success('admin.users.activate_success'.tr);

      // Refresh user detail
      await loadUserDetail(uid);
    } catch (e) {
      AppSnackbar.error('admin.users.activate_error'.tr);
    } finally {
      isLoading.value = false;
    }
  }

  /// Adjust wallet balance
  Future<void> adjustWallet(String uid, double amount, String reason) async {
    try {
      isLoading.value = true;

      await AdminFirestoreService.callCloudFunction(
        'adjustWalletBalance',
        {'uid': uid, 'amount': amount, 'reason': reason},
      );

      AppSnackbar.success('admin.users.wallet_adjust_success'.tr);

      // Refresh user detail
      await loadUserDetail(uid);
    } catch (e) {
      AppSnackbar.error('admin.users.wallet_adjust_error'.tr);
    } finally {
      isLoading.value = false;
    }
  }
}
