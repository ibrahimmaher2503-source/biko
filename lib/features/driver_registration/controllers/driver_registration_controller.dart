import 'dart:io';

import 'package:biko/core/models/document_model.dart';
import 'package:biko/core/models/driver_profile_model.dart';
import 'package:biko/core/models/enums.dart';
import 'package:biko/core/routes/app_routes.dart';
import 'package:biko/core/services/auth_service.dart';
import 'package:biko/core/services/firestore_service.dart';
import 'package:biko/core/services/storage_service.dart';
import 'package:biko/core/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class DriverRegistrationController extends GetxController {
  final vehicleModelController = TextEditingController();
  final plateNumberController = TextEditingController();
  final isSubmitting = false.obs;

  /// Tracks upload status per document type — value is download URL if uploaded
  final uploadedDocuments = <DocumentType, String?>{
    DocumentType.nationalId: null,
    DocumentType.license: null,
    DocumentType.vehicleRegistration: null,
    DocumentType.criminalRecord: null,
  }.obs;

  @override
  void onClose() {
    vehicleModelController.dispose();
    plateNumberController.dispose();
    super.onClose();
  }

  bool isDocumentUploaded(DocumentType type) => uploadedDocuments[type] != null;

  int get uploadedCount =>
      uploadedDocuments.values.where((v) => v != null).length;

  /// Pick and upload a document
  Future<void> uploadDocument(DocumentType type) async {
    final file = await StorageService.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    try {
      final uid = AuthService.currentUser!.uid;
      final url = await StorageService.uploadDocument(
        uid,
        type,
        File(file.path),
      );

      // Save to Firestore
      await FirestoreService.createDocument(
        DocumentModel(
          id: '',
          driverUid: uid,
          type: type,
          fileUrl: url,
          createdAt: DateTime.now(),
        ),
      );

      uploadedDocuments[type] = url;
    } catch (e) {
      AppSnackbar.error(e.toString());
    }
  }

  /// Validate all fields and submit application
  Future<void> submitApplication() async {
    final model = vehicleModelController.text.trim();
    final plate = plateNumberController.text.trim().toUpperCase();

    if (model.isEmpty || plate.isEmpty) {
      AppSnackbar.warning('registration.fill_all'.tr);
      return;
    }

    if (uploadedCount < 4) {
      AppSnackbar.warning('registration.upload_all'.tr);
      return;
    }

    isSubmitting.value = true;
    try {
      final uid = AuthService.currentUser!.uid;

      // Create driver profile
      await FirestoreService.createDriverProfile(
        DriverProfileModel(uid: uid, vehicleModel: model, plateNumber: plate),
      );

      // Update user status to pending_approval
      await FirestoreService.updateUser(uid, {
        'status': UserStatus.pendingApproval.toJson(),
        'type': UserType.driver.toJson(),
      });

      Get.offAllNamed(AppRoutes.pendingApproval);
    } catch (e) {
      AppSnackbar.error(e.toString());
    } finally {
      isSubmitting.value = false;
    }
  }
}
