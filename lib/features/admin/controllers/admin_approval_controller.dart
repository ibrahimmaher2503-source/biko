import 'package:biko/core/models/document_model.dart';
import 'package:biko/core/models/driver_profile_model.dart';
import 'package:biko/core/models/user_model.dart';
import 'package:biko/core/widgets/app_snackbar.dart';
import 'package:biko/features/admin/models/approval_stats_model.dart';
import 'package:biko/features/admin/models/driver_review_data.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
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

  final _firestore = FirebaseFirestore.instance;

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

  @override
  // ignore: unnecessary_overrides
  void onClose() {
    super.onClose();
  }

  Future<void> loadPendingDrivers() async {
    try {
      isLoading.value = true;

      final usersSnapshot = await _firestore
          .collection('users')
          .where('type', isEqualTo: 'driver')
          .where('status', isEqualTo: 'pending_approval')
          .orderBy('created_at', descending: false)
          .get();

      final List<DriverReviewData> results = [];

      for (final userDoc in usersSnapshot.docs) {
        final user = UserModel.fromJson(
          userDoc.data(),
        );

        final profileDoc = await _firestore
            .collection('driver_profiles')
            .doc(user.uid)
            .get();

        final profile = profileDoc.exists
            ? DriverProfileModel.fromJson(profileDoc.data()!)
            : DriverProfileModel(uid: user.uid);

        final docsSnapshot = await _firestore
            .collection('documents')
            .where('driver_uid', isEqualTo: user.uid)
            .get();

        final documents = docsSnapshot.docs
            .map((d) => DocumentModel.fromJson(d.data()))
            .toList();

        results.add(DriverReviewData(
          user: user,
          driverProfile: profile,
          documents: documents,
        ));
      }

      pendingDrivers.value = results;
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

      final userDoc =
          await _firestore.collection('users').doc(uid).get();
      if (!userDoc.exists) {
        AppSnackbar.error('admin.drivers.driver_not_found'.tr);
        return;
      }

      final user = UserModel.fromJson(userDoc.data()!);

      final profileDoc =
          await _firestore.collection('driver_profiles').doc(uid).get();
      final profile = profileDoc.exists
          ? DriverProfileModel.fromJson(profileDoc.data()!)
          : DriverProfileModel(uid: uid);

      final docsSnapshot = await _firestore
          .collection('documents')
          .where('driver_uid', isEqualTo: uid)
          .get();

      final documents = docsSnapshot.docs
          .map((d) => DocumentModel.fromJson(d.data()))
          .toList();

      selectedDriver.value = DriverReviewData(
        user: user,
        driverProfile: profile,
        documents: documents,
      );
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

      final callable =
          FirebaseFunctions.instance.httpsCallable('approveDriver');
      await callable.call({'uid': uid});

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

      final batch = _firestore.batch();

      for (final docId in docIds) {
        batch.update(
          _firestore.collection('documents').doc(docId),
          {
            'status': 'rejected',
            'admin_note': reason,
            'updated_at': FieldValue.serverTimestamp(),
          },
        );
      }

      await batch.commit();

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

      final batch = _firestore.batch();

      batch.update(
        _firestore.collection('users').doc(uid),
        {
          'status': 'suspended',
          'rejection_reason': reason,
          'updated_at': FieldValue.serverTimestamp(),
        },
      );

      final docsSnapshot = await _firestore
          .collection('documents')
          .where('driver_uid', isEqualTo: uid)
          .get();

      for (final doc in docsSnapshot.docs) {
        batch.update(doc.reference, {
          'status': 'rejected',
          'admin_note': reason,
          'updated_at': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

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
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      final pendingCount = await _firestore
          .collection('users')
          .where('type', isEqualTo: 'driver')
          .where('status', isEqualTo: 'pending_approval')
          .count()
          .get();

      final approvedToday = await _firestore
          .collection('driver_profiles')
          .where('is_approved', isEqualTo: true)
          .where(
            'approved_at',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .count()
          .get();

      approvalStats.value = ApprovalStatsModel(
        pendingCount: pendingCount.count ?? 0,
        approvedTodayCount: approvedToday.count ?? 0,
      );
    } catch (e, stack) {
      debugPrint('loadApprovalStats error: $e\n$stack');
    }
  }
}
