import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_empty_state.dart';
import 'package:biko/core/widgets/app_loading.dart';
import 'package:biko/features/admin/controllers/admin_approval_controller.dart';
import 'package:biko/features/admin/widgets/approval_queue_card.dart';
import 'package:biko/features/admin/widgets/rejection_reason_dialog.dart';
import 'package:biko/features/admin/widgets/stat_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Admin screen showing the driver approval queue with stats,
/// filters, and a list of pending driver applications.
class AdminApprovalQueueScreen extends StatelessWidget {
  const AdminApprovalQueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AdminApprovalController>();
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Obx(() {
        if (controller.isLoading.value &&
            controller.pendingDrivers.isEmpty) {
          return const Center(child: AppLoading());
        }

        return RefreshIndicator(
          onRefresh: controller.loadPendingDrivers,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'admin.approvals.title'.tr,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        Obx(
                          () => controller.isLoading.value
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : IconButton(
                                  icon: const Icon(Icons.refresh),
                                  onPressed: controller.loadPendingDrivers,
                                  tooltip: 'admin.common.refresh'.tr,
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Stats summary
                _buildStatsGrid(context, controller, colors),
                const SizedBox(height: 24),

                // Filter row
                _buildFilterRow(context, controller, colors),
                const SizedBox(height: 24),

                // Approval queue list
                _buildQueueList(context, controller, colors),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStatsGrid(
    BuildContext context,
    AdminApprovalController controller,
    AppColorsExtension colors,
  ) {
    return Obx(() {
      final stats = controller.approvalStats.value;
      if (stats == null) return const SizedBox.shrink();

      return LayoutBuilder(
        builder: (context, constraints) {
          int crossAxisCount = 1;
          if (constraints.maxWidth > 1200) {
            crossAxisCount = 4;
          } else if (constraints.maxWidth > 800) {
            crossAxisCount = 2;
          }

          return GridView.count(
            crossAxisCount: crossAxisCount,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: crossAxisCount == 1 ? 2.5 : 2.0,
            children: [
              StatCard(
                icon: Icons.pending_actions,
                titleKey: 'admin.approvals.pending_count',
                value: stats.pendingCount.toString(),
                iconColor: colors.warning,
              ),
              StatCard(
                icon: Icons.check_circle_outline,
                titleKey: 'admin.approvals.approved_today',
                value: stats.approvedTodayCount.toString(),
                iconColor: colors.success,
              ),
              StatCard(
                icon: Icons.cancel_outlined,
                titleKey: 'admin.approvals.rejected_today',
                value: stats.rejectedTodayCount.toString(),
                iconColor: Theme.of(context).colorScheme.error,
              ),
              StatCard(
                icon: Icons.timer_outlined,
                titleKey: 'admin.approvals.avg_approval_time',
                value:
                    '${stats.avgApprovalTimeHours.toStringAsFixed(1)} ${'admin.approvals.hours'.tr}',
                iconColor: colors.info,
              ),
            ],
          );
        },
      );
    });
  }

  Widget _buildFilterRow(
    BuildContext context,
    AdminApprovalController controller,
    AppColorsExtension colors,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppTheme.radiusDefault),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        children: [
          Expanded(
            child: Obx(
              () => DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: controller.vehicleTypeFilter.value,
                decoration: InputDecoration(
                  labelText: 'admin.approvals.vehicle_type'.tr,
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
                    child: Text('admin.common.all'.tr),
                  ),
                  DropdownMenuItem(
                    value: 'motorcycle',
                    child: Text('admin.drivers.motorcycle'.tr),
                  ),
                  DropdownMenuItem(
                    value: 'scooter',
                    child: Text('admin.drivers.scooter'.tr),
                  ),
                  DropdownMenuItem(
                    value: 'ebike',
                    child: Text('admin.drivers.ebike'.tr),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    controller.vehicleTypeFilter.value = value;
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Obx(
              () => DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: controller.sortBy.value,
                decoration: InputDecoration(
                  labelText: 'admin.approvals.sort_by'.tr,
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
                    value: 'oldest',
                    child: Text('admin.approvals.oldest_first'.tr),
                  ),
                  DropdownMenuItem(
                    value: 'newest',
                    child: Text('admin.approvals.newest_first'.tr),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    controller.sortBy.value = value;
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQueueList(
    BuildContext context,
    AdminApprovalController controller,
    AppColorsExtension colors,
  ) {
    return Obx(() {
      // Access reactive dependencies so Obx rebuilds on filter changes.
      controller.vehicleTypeFilter.value;
      controller.sortBy.value;
      final drivers = controller.filteredDrivers;

      if (drivers.isEmpty) {
        return AppEmptyState(
          icon: Icons.check_circle_outline,
          title: 'admin.approvals.no_pending'.tr,
          subtitle: 'admin.approvals.no_pending_subtitle'.tr,
        );
      }

      return LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 800;
          final crossAxisCount = isWide ? 2 : 1;

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: isWide ? 1.6 : 1.3,
            ),
            itemCount: drivers.length,
            itemBuilder: (context, index) {
              final data = drivers[index];
              return ApprovalQueueCard(
                data: data,
                onTap: () => controller.selectDriver(data.user.uid),
                onApprove: () =>
                    controller.approveDriver(data.user.uid),
                onReject: (reason) async {
                  final rejectionReason =
                      await RejectionReasonDialog.show(context);
                  if (rejectionReason != null &&
                      rejectionReason.isNotEmpty) {
                    await controller.rejectCompletely(
                      data.user.uid,
                      rejectionReason,
                    );
                  }
                },
              );
            },
          );
        },
      );
    });
  }
}
