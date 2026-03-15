import 'package:biko/core/models/document_model.dart';
import 'package:biko/core/models/driver_profile_model.dart';
import 'package:biko/core/models/enums.dart';
import 'package:biko/core/models/user_model.dart';
import 'package:biko/core/widgets/app_snackbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
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
  DocumentSnapshot? lastDocument;

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

      // Build query
      Query query = FirebaseFirestore.instance
          .collection('users')
          .where('type', isEqualTo: 'driver');

      // Apply search filter
      if (searchQuery.value.isNotEmpty) {
        // Note: Firestore doesn't support case-insensitive search
        // In production, use Algolia or similar for better search
        query = query
            .where('name', isGreaterThanOrEqualTo: searchQuery.value)
            .where('name', isLessThanOrEqualTo: '${searchQuery.value}\uf8ff');
      }

      // Pagination
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument!);
      }

      query = query.limit(pageSize);

      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        hasMore.value = false;
        return;
      }

      if (snapshot.docs.length < pageSize) {
        hasMore.value = false;
      }

      lastDocument = snapshot.docs.last;

      // Fetch driver profiles for each user
      final List<Map<String, dynamic>> loadedDrivers = [];

      for (final doc in snapshot.docs) {
        final user = UserModel.fromJson(doc.data() as Map<String, dynamic>);

        // Fetch driver profile
        final profileDoc = await FirebaseFirestore.instance
            .collection('driver_profiles')
            .doc(user.uid)
            .get();

        if (!profileDoc.exists) continue;

        final profile = DriverProfileModel.fromJson(
          profileDoc.data() as Map<String, dynamic>,
        );

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

      // Fetch user
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (!userDoc.exists) {
        AppSnackbar.error('admin.drivers.driver_not_found'.tr);
        return;
      }

      selectedDriver.value = UserModel.fromJson(
        userDoc.data() as Map<String, dynamic>,
      );

      // Fetch driver profile
      final profileDoc = await FirebaseFirestore.instance
          .collection('driver_profiles')
          .doc(uid)
          .get();

      if (profileDoc.exists) {
        selectedDriverProfile.value = DriverProfileModel.fromJson(
          profileDoc.data()!,
        );
      }

      // Fetch documents
      final documentsSnapshot = await FirebaseFirestore.instance
          .collection('documents')
          .where('driver_uid', isEqualTo: uid)
          .get();

      selectedDriverDocuments.value = documentsSnapshot.docs
          .map((d) => DocumentModel.fromJson(d.data()))
          .toList();
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

      final callable = FirebaseFunctions.instance.httpsCallable(
        'approveDriver',
      );
      await callable.call({'uid': uid});

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

      // Update all documents to rejected status with reason
      final documentsSnapshot = await FirebaseFirestore.instance
          .collection('documents')
          .where('driver_uid', isEqualTo: uid)
          .get();

      final batch = FirebaseFirestore.instance.batch();

      for (final doc in documentsSnapshot.docs) {
        batch.update(doc.reference, {
          'status': 'rejected',
          'admin_note': reason,
          'updated_at': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

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

      final callable = FirebaseFunctions.instance.httpsCallable('suspendUser');
      await callable.call({'uid': uid, 'reason': reason});

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

      // Update user status to active
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'status': 'active',
        'updated_at': FieldValue.serverTimestamp(),
      });

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
