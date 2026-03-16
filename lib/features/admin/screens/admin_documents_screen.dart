import 'package:biko/core/models/enums.dart';
import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_button.dart';
import 'package:biko/core/widgets/app_card.dart';
import 'package:biko/core/widgets/app_loading.dart';
import 'package:biko/features/admin/controllers/admin_documents_controller.dart';
import 'package:biko/features/admin/widgets/confirm_dialog.dart';
import 'package:biko/features/admin/widgets/document_image_viewer.dart';
import 'package:biko/features/admin/widgets/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:timeago/timeago.dart' as timeago;

/// Admin screen for reviewing driver documents.
class AdminDocumentsScreen extends GetView<AdminDocumentsController> {
  const AdminDocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;

    return Scaffold(
      backgroundColor: colors.surfaceContainer,
      body: Obx(() {
        if (controller.isLoading.value && controller.pendingDrivers.isEmpty) {
          return const Center(child: AppLoading());
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final isWideScreen = constraints.maxWidth > 800;

            if (isWideScreen) {
              return Row(
                children: [
                  // Left panel - pending drivers list
                  SizedBox(
                    width: 320,
                    child: _buildDriverList(context, colors),
                  ),
                  const VerticalDivider(width: 1),
                  // Right panel - selected driver documents
                  Expanded(child: _buildDocumentView(context, colors)),
                ],
              );
            } else {
              // Mobile layout - show one panel at a time
              return controller.selectedDriverUid.value == null
                  ? _buildDriverList(context, colors)
                  : _buildDocumentView(context, colors);
            }
          },
        );
      }),
    );
  }

  /// Build the left panel with the list of pending drivers.
  Widget _buildDriverList(BuildContext context, AppColorsExtension colors) {
    return ColoredBox(
      color: colors.surfaceElevated,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'admin.documents.pending_drivers'.tr,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.pendingDrivers.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 64,
                        color: colors.textMuted,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'admin.documents.no_pending'.tr,
                        style: TextStyle(fontSize: 16, color: colors.textMuted),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: controller.pendingDrivers.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final driverUid = controller.pendingDrivers.keys.elementAt(
                    index,
                  );
                  final docs = controller.pendingDrivers[driverUid]!;
                  final user = controller.driverUsers[driverUid];

                  return Obx(() {
                    final isSelected =
                        controller.selectedDriverUid.value == driverUid;

                    return AppCard(
                      onTap: () => controller.loadDocumentsForDriver(driverUid),
                      backgroundColor: isSelected
                          ? colors.infoBg
                          : colors.surfaceElevated,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  user?.name ?? 'Unknown Driver',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              StatusBadge.fromDocumentStatus(
                                DocumentStatus.pending,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            user?.phone ?? '',
                            style: TextStyle(
                              fontSize: 14,
                              color: colors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${'admin.documents.submitted'.tr} ${timeago.format(docs.first.createdAt)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    );
                  });
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  /// Build the right panel with the selected driver's documents.
  Widget _buildDocumentView(BuildContext context, AppColorsExtension colors) {
    return Obx(() {
      final selectedUid = controller.selectedDriverUid.value;

      if (selectedUid == null) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.description_outlined,
                size: 64,
                color: colors.textMuted,
              ),
              const SizedBox(height: 16),
              Text(
                'admin.documents.select_driver'.tr,
                style: TextStyle(fontSize: 16, color: colors.textMuted),
              ),
            ],
          ),
        );
      }

      final user = controller.driverUsers[selectedUid];
      final docs = controller.documentsForSelectedDriver;

      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with driver info
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    Directionality.of(context) == TextDirection.rtl
                        ? Icons.arrow_forward
                        : Icons.arrow_back,
                  ),
                  onPressed: () {
                    controller.selectedDriverUid.value = null;
                    controller.documentsForSelectedDriver.clear();
                  },
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? 'Unknown Driver',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Text(
                        user?.phone ?? '',
                        style: TextStyle(fontSize: 14, color: colors.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Document images grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 300,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
              ),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getDocumentLabel(doc.type),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: DocumentImageViewer(
                        fileUrl: doc.fileUrl,
                        label: _getDocumentLabel(doc.type),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                  width: 140,
                  child: AppButton(
                    text: 'admin.documents.reject'.tr,
                    variant: ButtonVariant.outline,
                    onPressed: () => _handleReject(context, selectedUid),
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 160,
                  child: AppButton(
                    text: 'admin.documents.approve_all'.tr,
                    onPressed: () => _handleApprove(context, selectedUid),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  /// Get the translated label for a document type.
  String _getDocumentLabel(DocumentType type) {
    switch (type) {
      case DocumentType.nationalId:
        return 'admin.documents.national_id'.tr;
      case DocumentType.license:
        return 'admin.documents.license'.tr;
      case DocumentType.vehicleRegistration:
        return 'admin.documents.vehicle_registration'.tr;
      case DocumentType.criminalRecord:
        return 'admin.documents.criminal_record'.tr;
    }
  }

  /// Handle approve action.
  Future<void> _handleApprove(BuildContext context, String driverUid) async {
    final confirmed = await ConfirmDialog.show(
      title: 'common.confirm'.tr,
      message: 'admin.documents.approve_confirm'.tr,
      confirmLabel: 'admin.users.approve'.tr,
    );

    if (confirmed) {
      await controller.approveAll(driverUid);
    }
  }

  /// Handle reject action.
  Future<void> _handleReject(BuildContext context, String driverUid) async {
    final reasonController = TextEditingController();

    final confirmed = await Get.dialog<bool>(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'admin.users.reject_reason'.tr,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'admin.users.reject_reason'.tr,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppTheme.radiusDefault,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(
                      width: 100,
                      child: AppButton(
                        text: 'common.cancel'.tr,
                        variant: ButtonVariant.text,
                        onPressed: () => Get.back(result: false),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 120,
                      child: AppButton(
                        text: 'admin.users.reject'.tr,
                        onPressed: () => Get.back(result: true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if ((confirmed ?? false) && reasonController.text.isNotEmpty) {
      await controller.reject(driverUid, reasonController.text);
    }
  }
}
