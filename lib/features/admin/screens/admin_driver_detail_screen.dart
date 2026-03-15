import 'package:biko/core/models/enums.dart';
import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_button.dart';
import 'package:biko/core/widgets/app_card.dart';
import 'package:biko/core/widgets/app_loading.dart';
import 'package:biko/core/widgets/app_text_field.dart';
import 'package:biko/features/admin/controllers/admin_drivers_controller.dart';
import 'package:biko/features/admin/utils/admin_status_colors.dart';
import 'package:biko/features/admin/widgets/confirm_dialog.dart';
import 'package:biko/features/admin/widgets/document_image_viewer.dart';
import 'package:biko/features/admin/widgets/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AdminDriverDetailScreen extends GetView<AdminDriversController> {
  const AdminDriverDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    final String uid = Get.arguments as String;

    // Load driver detail on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadDriverDetail(uid);
    });

    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colors.surfaceContainer,
              border: Border(bottom: BorderSide(color: colors.border)),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: Get.back,
                  icon: Icon(
                    Directionality.of(context) == TextDirection.rtl
                        ? Icons.arrow_forward
                        : Icons.arrow_back,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.person_outline,
                  size: 32,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 16),
                Text(
                  'admin.drivers.detail_title'.tr,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value &&
                  controller.selectedDriver.value == null) {
                return const Center(child: AppLoading());
              }

              final user = controller.selectedDriver.value;
              final profile = controller.selectedDriverProfile.value;

              if (user == null) {
                return Center(child: Text('admin.drivers.driver_not_found'.tr));
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile card
                    AppCard(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 40,
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: 0.1),
                                  backgroundImage: user.avatarUrl != null
                                      ? NetworkImage(user.avatarUrl!)
                                      : null,
                                  child: user.avatarUrl == null
                                      ? Icon(
                                          Icons.person,
                                          size: 40,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        user.phone,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.copyWith(color: colors.textMuted),
                                      ),
                                      const SizedBox(height: 8),
                                      StatusBadge(
                                        label: _getStatusLabel(user.status),
                                        color: _getStatusBadgeColor(
                                          user.status,
                                        ),
                                        backgroundColor: _getStatusBadgeBgColor(
                                          user.status,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Vehicle info card
                    if (profile != null) ...[
                      Text(
                        'admin.drivers.vehicle_info'.tr,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      AppCard(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildInfoItem(
                                  context,
                                  'admin.drivers.vehicle_type'.tr,
                                  _getVehicleTypeLabel(profile.vehicleType),
                                  Icons.motorcycle,
                                ),
                              ),
                              Expanded(
                                child: _buildInfoItem(
                                  context,
                                  'admin.drivers.plate_number'.tr,
                                  profile.plateNumber,
                                  Icons.pin,
                                ),
                              ),
                              Expanded(
                                child: _buildInfoItem(
                                  context,
                                  'admin.drivers.vehicle_model'.tr,
                                  profile.vehicleModel,
                                  Icons.directions_bike,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Performance card
                      Text(
                        'admin.drivers.performance'.tr,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      AppCard(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildInfoItem(
                                  context,
                                  'admin.drivers.total_trips'.tr,
                                  profile.totalTrips.toString(),
                                  Icons.local_shipping,
                                ),
                              ),
                              Expanded(
                                child: _buildInfoItem(
                                  context,
                                  'admin.drivers.avg_rating'.tr,
                                  profile.ratingAvg.toStringAsFixed(1),
                                  Icons.star,
                                ),
                              ),
                              Expanded(
                                child: _buildInfoItem(
                                  context,
                                  'admin.drivers.total_earnings'.tr,
                                  '${profile.totalEarnings.toStringAsFixed(0)} ${'admin.drivers.egp'.tr}',
                                  Icons.monetization_on,
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'admin.drivers.online_status'.tr,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: colors.textMuted),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: profile.isOnline
                                                ? colors.success
                                                : colors.textMuted,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          profile.isOnline
                                              ? 'admin.drivers.online'.tr
                                              : 'admin.drivers.offline'.tr,
                                          style: TextStyle(
                                            color: profile.isOnline
                                                ? colors.success
                                                : colors.textMuted,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Documents card
                    Text(
                      'admin.drivers.documents'.tr,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Obx(() {
                      final documents = controller.selectedDriverDocuments;

                      if (documents.isEmpty) {
                        return AppCard(
                          child: Padding(
                            padding: const EdgeInsets.all(40),
                            child: Center(
                              child: Text(
                                'admin.drivers.no_documents'.tr,
                                style: TextStyle(color: colors.textMuted),
                              ),
                            ),
                          ),
                        );
                      }

                      return Row(
                        children: [
                          Expanded(
                            child: DocumentImageViewer(
                              fileUrl: documents
                                  .firstWhere(
                                    (d) => d.type == DocumentType.nationalId,
                                    orElse: () => documents.first,
                                  )
                                  .fileUrl,
                              label: 'admin.drivers.national_id'.tr,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DocumentImageViewer(
                              fileUrl: documents
                                  .firstWhere(
                                    (d) => d.type == DocumentType.license,
                                    orElse: () => documents.first,
                                  )
                                  .fileUrl,
                              label: 'admin.drivers.license'.tr,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DocumentImageViewer(
                              fileUrl: documents
                                  .firstWhere(
                                    (d) =>
                                        d.type ==
                                        DocumentType.vehicleRegistration,
                                    orElse: () => documents.first,
                                  )
                                  .fileUrl,
                              label: 'admin.drivers.vehicle_registration'.tr,
                            ),
                          ),
                        ],
                      );
                    }),
                    const SizedBox(height: 32),

                    // Action buttons
                    if (profile != null)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (!profile.isApproved &&
                              user.status != UserStatus.suspended) ...[
                            AppButton(
                              text: 'admin.drivers.approve'.tr,
                              onPressed: () async {
                                final confirmed = await Get.dialog<bool>(
                                  ConfirmDialog(
                                    title: 'admin.drivers.approve_title'.tr,
                                    message: 'admin.drivers.approve_message'.tr,
                                    confirmLabel: 'admin.drivers.approve'.tr,
                                    cancelLabel: 'admin.drivers.cancel'.tr,
                                  ),
                                );

                                if (confirmed ?? false) {
                                  await controller.approveDriver(uid);
                                }
                              },
                            ),
                            const SizedBox(width: 12),
                            AppButton(
                              text: 'admin.drivers.reject'.tr,
                              onPressed: () async {
                                final reasonController =
                                    TextEditingController();

                                final confirmed = await Get.dialog<bool>(
                                  AlertDialog(
                                    title: Text(
                                      'admin.drivers.reject_title'.tr,
                                    ),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('admin.drivers.reject_message'.tr),
                                        const SizedBox(height: 16),
                                        AppTextField(
                                          controller: reasonController,
                                          hint: 'admin.drivers.rejection_reason'
                                              .tr,
                                          maxLines: 3,
                                        ),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Get.back(result: false),
                                        child: Text('admin.drivers.cancel'.tr),
                                      ),
                                      TextButton(
                                        onPressed: () => Get.back(result: true),
                                        child: Text('admin.drivers.reject'.tr),
                                      ),
                                    ],
                                  ),
                                );

                                if ((confirmed ?? false) &&
                                    reasonController.text.isNotEmpty) {
                                  await controller.rejectDriver(
                                    uid,
                                    reasonController.text,
                                  );
                                }
                              },
                              variant: ButtonVariant.outline,
                            ),
                            const SizedBox(width: 12),
                          ],
                          if (user.status == UserStatus.active) ...[
                            AppButton(
                              text: 'admin.drivers.suspend'.tr,
                              onPressed: () async {
                                final reasonController =
                                    TextEditingController();

                                final confirmed = await Get.dialog<bool>(
                                  AlertDialog(
                                    title: Text(
                                      'admin.drivers.suspend_title'.tr,
                                    ),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'admin.drivers.suspend_message'.tr,
                                        ),
                                        const SizedBox(height: 16),
                                        AppTextField(
                                          controller: reasonController,
                                          hint:
                                              'admin.drivers.suspension_reason'
                                                  .tr,
                                          maxLines: 3,
                                        ),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Get.back(result: false),
                                        child: Text('admin.drivers.cancel'.tr),
                                      ),
                                      TextButton(
                                        onPressed: () => Get.back(result: true),
                                        child: Text('admin.drivers.suspend'.tr),
                                      ),
                                    ],
                                  ),
                                );

                                if ((confirmed ?? false) &&
                                    reasonController.text.isNotEmpty) {
                                  await controller.suspendDriver(
                                    uid,
                                    reasonController.text,
                                  );
                                }
                              },
                              variant: ButtonVariant.outline,
                            ),
                          ] else if (user.status == UserStatus.suspended) ...[
                            AppButton(
                              text: 'admin.drivers.activate'.tr,
                              onPressed: () async {
                                final confirmed = await Get.dialog<bool>(
                                  ConfirmDialog(
                                    title: 'admin.drivers.activate_title'.tr,
                                    message:
                                        'admin.drivers.activate_message'.tr,
                                    confirmLabel: 'admin.drivers.activate'.tr,
                                    cancelLabel: 'admin.drivers.cancel'.tr,
                                  ),
                                );

                                if (confirmed ?? false) {
                                  await controller.activateDriver(uid);
                                }
                              },
                            ),
                          ],
                        ],
                      ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: colors.textMuted),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  String _getStatusLabel(UserStatus status) {
    switch (status) {
      case UserStatus.active:
        return 'admin.drivers.active'.tr;
      case UserStatus.suspended:
        return 'admin.drivers.suspended'.tr;
      case UserStatus.pendingApproval:
        return 'admin.drivers.pending_approval'.tr;
    }
  }

  Color _getStatusBadgeColor(UserStatus status) {
    switch (status) {
      case UserStatus.active:
        return AdminStatusColors.success;
      case UserStatus.suspended:
        return AdminStatusColors.error;
      case UserStatus.pendingApproval:
        return AdminStatusColors.warning;
    }
  }

  Color _getStatusBadgeBgColor(UserStatus status) {
    switch (status) {
      case UserStatus.active:
        return AdminStatusColors.successBg;
      case UserStatus.suspended:
        return AdminStatusColors.errorBg;
      case UserStatus.pendingApproval:
        return AdminStatusColors.warningBg;
    }
  }

  String _getVehicleTypeLabel(VehicleType type) {
    switch (type) {
      case VehicleType.motorcycle:
        return 'admin.drivers.motorcycle'.tr;
      case VehicleType.scooter:
        return 'admin.drivers.scooter'.tr;
      case VehicleType.ebike:
        return 'admin.drivers.ebike'.tr;
    }
  }
}
