import 'package:biko/core/models/driver_profile_model.dart';
import 'package:biko/core/models/enums.dart';
import 'package:biko/core/models/user_model.dart';
import 'package:biko/core/routes/app_routes.dart';
import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_text_field.dart';
import 'package:biko/features/admin/controllers/admin_drivers_controller.dart';
import 'package:biko/features/admin/utils/admin_status_colors.dart';
import 'package:biko/features/admin/widgets/admin_data_table.dart';
import 'package:biko/features/admin/widgets/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AdminDriversScreen extends GetView<AdminDriversController> {
  const AdminDriversScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;

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
                Icon(
                  Icons.people_outline,
                  size: 32,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 16),
                Text(
                  'admin.drivers.title'.tr,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Obx(
                  () => Text(
                    '${'admin.drivers.total'.tr}: ${controller.drivers.length}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Filters
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surfaceContainer,
              border: Border(bottom: BorderSide(color: colors.border)),
            ),
            child: Row(
              children: [
                // Search
                Expanded(
                  flex: 2,
                  child: AppTextField(
                    controller: controller.searchTextController,
                    hint: 'admin.drivers.search_hint'.tr,
                    prefixIcon: Icons.search,
                    onChanged: (value) => controller.searchQuery.value = value,
                  ),
                ),
                const SizedBox(width: 16),

                // Approval filter
                Expanded(
                  child: Obx(
                    () => DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: controller.approvalFilter.value,
                      decoration: InputDecoration(
                        labelText: 'admin.drivers.approval_status'.tr,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusDefault,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'all',
                          child: Text('admin.drivers.all'.tr),
                        ),
                        DropdownMenuItem(
                          value: 'approved',
                          child: Text('admin.drivers.approved'.tr),
                        ),
                        DropdownMenuItem(
                          value: 'pending',
                          child: Text('admin.drivers.pending'.tr),
                        ),
                        DropdownMenuItem(
                          value: 'rejected',
                          child: Text('admin.drivers.rejected'.tr),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          controller.filterByApproval(value);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Online filter
                Expanded(
                  child: Obx(
                    () => DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: controller.onlineFilter.value,
                      decoration: InputDecoration(
                        labelText: 'admin.drivers.online_status'.tr,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusDefault,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'all',
                          child: Text('admin.drivers.all'.tr),
                        ),
                        DropdownMenuItem(
                          value: 'online',
                          child: Text('admin.drivers.online'.tr),
                        ),
                        DropdownMenuItem(
                          value: 'offline',
                          child: Text('admin.drivers.offline'.tr),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          controller.filterByOnline(value);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Data table
          Expanded(
            child: Obx(
              () => AdminDataTable<Map<String, dynamic>>(
                columns: [
                  AdminColumn(label: 'admin.drivers.name'.tr, flex: 2),
                  AdminColumn(label: 'admin.drivers.phone'.tr),
                  AdminColumn(label: 'admin.drivers.vehicle_type'.tr),
                  AdminColumn(label: 'admin.drivers.approval'.tr),
                  AdminColumn(label: 'admin.drivers.status'.tr),
                  AdminColumn(label: 'admin.drivers.rating'.tr),
                  AdminColumn(label: 'admin.drivers.trips'.tr),
                ],
                rows: controller.drivers,
                cellBuilder: (driver, colIndex) {
                  final user = driver['user'] as UserModel;
                  final profile = driver['profile'] as DriverProfileModel;

                  switch (colIndex) {
                    case 0:
                      return Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: theme.colorScheme.primary
                                .withValues(alpha: 0.1),
                            backgroundImage: user.avatarUrl != null
                                ? NetworkImage(user.avatarUrl!)
                                : null,
                            child: user.avatarUrl == null
                                ? Icon(
                                    Icons.person,
                                    size: 16,
                                    color: theme.colorScheme.primary,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              user.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      );
                    case 1:
                      return Text(user.phone);
                    case 2:
                      return Text(_getVehicleTypeLabel(profile.vehicleType));
                    case 3:
                      return StatusBadge(
                        label: profile.isApproved
                            ? 'admin.drivers.approved'.tr
                            : 'admin.drivers.pending'.tr,
                        color: profile.isApproved
                            ? AdminStatusColors.success
                            : AdminStatusColors.warning,
                        backgroundColor: profile.isApproved
                            ? AdminStatusColors.successBg
                            : AdminStatusColors.warningBg,
                      );
                    case 4:
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
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
                            ),
                          ),
                        ],
                      );
                    case 5:
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, size: 16, color: colors.warning),
                          const SizedBox(width: 4),
                          Text(profile.ratingAvg.toStringAsFixed(1)),
                        ],
                      );
                    case 6:
                      return Text(profile.totalTrips.toString());
                    default:
                      return const SizedBox.shrink();
                  }
                },
                onRowTap: (driver) {
                  final user = driver['user'] as UserModel;
                  Get.toNamed(AppRoutes.adminDriverDetail, arguments: user.uid);
                },
                isLoading: controller.isLoading.value,
                emptyMessage: 'admin.drivers.no_drivers'.tr,
                hasNextPage: controller.hasMore.value,
                hasPreviousPage: controller.currentPage.value > 1,
                onNextPage: controller.nextPage,
                onPreviousPage: controller.previousPage,
                currentPage: controller.currentPage.value,
              ),
            ),
          ),
        ],
      ),
    );
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
