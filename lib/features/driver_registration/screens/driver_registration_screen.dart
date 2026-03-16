import 'package:biko/core/models/enums.dart';
import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_button.dart';
import 'package:biko/core/widgets/app_text_field.dart';
import 'package:biko/features/driver_registration/controllers/driver_registration_controller.dart';
import 'package:biko/features/driver_registration/widgets/document_upload_item.dart';
import 'package:biko/features/driver_registration/widgets/step_progress_indicator.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DriverRegistrationScreen extends GetView<DriverRegistrationController> {
  const DriverRegistrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Sticky header
            _buildHeader(context),
            // Progress indicator
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: StepProgressIndicator(currentStep: 1),
            ),
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsetsDirectional.fromSTEB(24, 0, 24, 96),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section title
                    Text(
                      'registration.section_title'.tr,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'registration.section_desc'.tr,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Vehicle form fields
                    _buildVehicleFields(context),
                    const SizedBox(height: 32),
                    // Required documents
                    Text(
                      'registration.required_docs'.tr,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDocumentsList(),
                    const SizedBox(height: 24),
                    // Info tip box
                    _buildInfoTip(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // Sticky bottom button
      bottomNavigationBar: _buildSubmitButton(context),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(4, 4, 4, 0),
      child: Row(
        children: [
          IconButton(onPressed: Get.back, icon: const Icon(Icons.arrow_back)),
          Expanded(
            child: Text(
              'registration.title'.tr,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildVehicleFields(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Motorcycle Model
        AppTextField(
          controller: controller.vehicleModelController,
          label: 'registration.motorcycle_model'.tr,
          hint: 'registration.motorcycle_hint'.tr,
          suffixIcon: Icons.two_wheeler,
        ),
        const SizedBox(height: 20),
        // Plate Number
        AppTextField(
          controller: controller.plateNumberController,
          label: 'registration.plate_number'.tr,
          hint: 'registration.plate_hint'.tr,
          suffixIcon: Icons.pin,
        ),
      ],
    );
  }

  Widget _buildDocumentsList() {
    return Obx(
      () => Column(
        children: [
          DocumentUploadItem(
            icon: Icons.badge,
            name: 'registration.national_id'.tr,
            hint: 'registration.national_id_hint'.tr,
            isUploaded: controller.isDocumentUploaded(DocumentType.nationalId),
            onTap: () => controller.uploadDocument(DocumentType.nationalId),
          ),
          const SizedBox(height: 12),
          DocumentUploadItem(
            icon: Icons.badge_outlined,
            name: 'registration.driving_license'.tr,
            hint: 'registration.license_hint'.tr,
            isUploaded: controller.isDocumentUploaded(DocumentType.license),
            onTap: () => controller.uploadDocument(DocumentType.license),
          ),
          const SizedBox(height: 12),
          DocumentUploadItem(
            icon: Icons.assignment,
            name: 'registration.vehicle_reg'.tr,
            hint: 'registration.vehicle_reg_hint'.tr,
            isUploaded: controller.isDocumentUploaded(
              DocumentType.vehicleRegistration,
            ),
            onTap: () =>
                controller.uploadDocument(DocumentType.vehicleRegistration),
          ),
          const SizedBox(height: 12),
          DocumentUploadItem(
            icon: Icons.verified_user,
            name: 'registration.criminal_record'.tr,
            hint: 'registration.criminal_hint'.tr,
            isUploaded: controller.isDocumentUploaded(
              DocumentType.criminalRecord,
            ),
            onTap: () => controller.uploadDocument(DocumentType.criminalRecord),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTip(BuildContext context) {
    final ext = Theme.of(context).extension<AppColorsExtension>()!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ext.infoBg,
        borderRadius: BorderRadius.circular(AppTheme.radiusDefault),
        border: Border.all(color: ext.infoBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info, color: ext.info, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'registration.tip'.tr,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: ext.info, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    final ext = Theme.of(context).extension<AppColorsExtension>()!;

    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: ext.borderSubtle)),
      ),
      child: Obx(
        () => AppButton(
          text: 'registration.submit'.tr,
          onPressed: controller.isSubmitting.value
              ? null
              : controller.submitApplication,
          trailingIcon: Icons.arrow_forward,
          isLoading: controller.isSubmitting.value,
        ),
      ),
    );
  }
}
