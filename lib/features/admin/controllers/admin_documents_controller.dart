import 'dart:async';
import 'package:biko/core/models/document_model.dart';
import 'package:biko/core/models/user_model.dart';
import 'package:biko/core/widgets/app_snackbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:get/get.dart';

/// Controller for Admin Document Review feature.
class AdminDocumentsController extends GetxController {
  final _firestore = FirebaseFirestore.instance;
  final _functions = FirebaseFunctions.instance;

  /// Map of driver UID to list of pending documents.
  final pendingDrivers = <String, List<DocumentModel>>{}.obs;

  /// Map of driver UID to user model.
  final driverUsers = <String, UserModel>{}.obs;

  /// Currently selected driver UID.
  final selectedDriverUid = Rx<String?>(null);

  /// Documents for the selected driver.
  final documentsForSelectedDriver = <DocumentModel>[].obs;

  /// Loading state.
  final isLoading = false.obs;

  StreamSubscription<QuerySnapshot>? _documentsSubscription;

  @override
  void onInit() {
    super.onInit();
    loadPendingDrivers();
  }

  @override
  void onClose() {
    _documentsSubscription?.cancel();
    super.onClose();
  }

  /// Load all pending documents grouped by driver UID.
  void loadPendingDrivers() {
    isLoading.value = true;

    _documentsSubscription = _firestore
        .collection('documents')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen(
          (snapshot) async {
            final Map<String, List<DocumentModel>> groupedDocs = {};

            for (final doc in snapshot.docs) {
              final document = DocumentModel.fromJson(doc.data());
              final driverUid = document.driverUid;

              if (!groupedDocs.containsKey(driverUid)) {
                groupedDocs[driverUid] = [];
              }
              groupedDocs[driverUid]!.add(document);

              // Load driver user data if not already loaded.
              if (!driverUsers.containsKey(driverUid)) {
                final userDoc = await _firestore
                    .collection('users')
                    .doc(driverUid)
                    .get();
                if (userDoc.exists && userDoc.data() != null) {
                  driverUsers[driverUid] = UserModel.fromJson(userDoc.data()!);
                }
              }
            }

            pendingDrivers.value = groupedDocs;

            // If selected driver has no more pending docs, clear selection.
            if (selectedDriverUid.value != null &&
                !groupedDocs.containsKey(selectedDriverUid.value)) {
              selectedDriverUid.value = null;
              documentsForSelectedDriver.clear();
            }

            isLoading.value = false;
          },
          onError: (e) {
            isLoading.value = false;
            AppSnackbar.error('Failed to load pending documents');
          },
        );
  }

  /// Load documents for a specific driver.
  void loadDocumentsForDriver(String uid) {
    selectedDriverUid.value = uid;
    documentsForSelectedDriver.value = pendingDrivers[uid] ?? [];
  }

  /// Approve all documents for a driver by calling Cloud Function.
  Future<void> approveAll(String driverUid) async {
    try {
      isLoading.value = true;

      final callable = _functions.httpsCallable('approveDriver');
      await callable.call({'driverUid': driverUid});

      AppSnackbar.success('admin.documents.approve_confirm'.tr);

      // Clear selection after approval.
      selectedDriverUid.value = null;
      documentsForSelectedDriver.clear();
    } catch (e) {
      AppSnackbar.error('error.unknown'.tr);
    } finally {
      isLoading.value = false;
    }
  }

  /// Reject documents for a driver.
  Future<void> reject(String driverUid, String reason) async {
    try {
      isLoading.value = true;

      // Get all document IDs for this driver.
      final docs = pendingDrivers[driverUid] ?? [];

      // Update all documents to rejected status.
      final batch = _firestore.batch();
      for (final doc in docs) {
        final docRef = _firestore.collection('documents').doc(doc.id);
        batch.update(docRef, {
          'status': 'rejected',
          'admin_note': reason,
          'updated_at': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();

      AppSnackbar.success('admin.documents.reject_confirm'.tr);

      // Clear selection after rejection.
      selectedDriverUid.value = null;
      documentsForSelectedDriver.clear();
    } catch (e) {
      AppSnackbar.error('error.unknown'.tr);
    } finally {
      isLoading.value = false;
    }
  }
}
