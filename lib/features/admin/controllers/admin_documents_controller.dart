import 'dart:async';
import 'package:biko/core/models/document_model.dart';
import 'package:biko/core/models/user_model.dart';
import 'package:biko/core/widgets/app_snackbar.dart';
import 'package:biko/features/admin/services/admin_firestore_service.dart';
import 'package:get/get.dart';

/// Controller for Admin Document Review feature.
class AdminDocumentsController extends GetxController {
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

  StreamSubscription<List<Map<String, dynamic>>>? _documentsSubscription;

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

    _documentsSubscription =
        AdminFirestoreService.streamPendingDocuments().listen(
          (docMaps) async {
            final Map<String, List<DocumentModel>> groupedDocs = {};

            for (final docMap in docMaps) {
              final document = DocumentModel.fromJson(docMap);
              final driverUid = document.driverUid;

              if (!groupedDocs.containsKey(driverUid)) {
                groupedDocs[driverUid] = [];
              }
              groupedDocs[driverUid]!.add(document);

              // Load driver user data if not already loaded.
              if (!driverUsers.containsKey(driverUid)) {
                final user =
                    await AdminFirestoreService.getUserById(driverUid);
                if (user != null) {
                  driverUsers[driverUid] = user;
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

      await AdminFirestoreService.callCloudFunction(
        'approveDriver',
        {'driverUid': driverUid},
      );

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

      await AdminFirestoreService.batchRejectDocuments(driverUid, reason);

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
