import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_button.dart';
import 'package:biko/core/widgets/app_card.dart';
import 'package:biko/core/widgets/app_empty_state.dart';
import 'package:biko/core/widgets/app_loading.dart';
import 'package:biko/features/admin/controllers/admin_approval_controller.dart';
import 'package:biko/features/admin/widgets/confirm_dialog.dart';
import 'package:biko/features/admin/widgets/document_review_grid.dart';
import 'package:biko/features/admin/widgets/rejection_reason_dialog.dart';
import 'package:biko/features/admin/widgets/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' hide TextDirection;

/// Admin screen for reviewing a single driver's application,
/// including personal info, documents, and approval timeline.
class AdminDriverReviewScreen extends StatelessWidget {
  const AdminDriverReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AdminApprovalController>();
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Obx(() {
        if (controller.isLoading.value &&
            controller.selectedDriver.value == null) {
          return const Center(child: AppLoading());
        }

        final driver = controller.selectedDriver.value;
        if (driver == null) {
          return Center(
            child: AppEmptyState(
              icon: Icons.person_search,
              title: 'admin.approvals.no_driver_selected'.tr,
              subtitle: 'admin.approvals.select_driver_hint'.tr,
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth > 900;

            if (isDesktop) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left column: driver info + timeline
                  Expanded(
                    flex: 2,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildBackButton(context),
                          const SizedBox(height: 16),
                          _buildDriverInfo(
                            context,
                            driver,
                            colors,
                            theme,
                          ),
                          const SizedBox(height: 24),
                          _buildApprovalTimeline(
                            context,
                            driver,
                            colors,
                            theme,
                          ),
                          const SizedBox(height: 24),
                          _buildActionButtons(
                            context,
                            controller,
                            driver,
                            theme,
                          ),
                        ],
                      ),
                    ),
                  ),
                  VerticalDivider(width: 1, color: colors.border),
                  // Right column: document grid
                  Expanded(
                    flex: 3,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'admin.approvals.documents'.tr,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          DocumentReviewGrid(
                            documents: driver.documents,
                            onApprove: (docId) {},
                            onReject: (docId, reason) {},
                            onViewFull: (url) =>
                                _showFullImage(context, url),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }

            // Mobile layout: single column
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBackButton(context),
                  const SizedBox(height: 16),
                  _buildDriverInfo(context, driver, colors, theme),
                  const SizedBox(height: 24),
                  Text(
                    'admin.approvals.documents'.tr,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  DocumentReviewGrid(
                    documents: driver.documents,
                    onApprove: (docId) {},
                    onReject: (docId, reason) {},
                    onViewFull: (url) =>
                        _showFullImage(context, url),
                  ),
                  const SizedBox(height: 24),
                  _buildApprovalTimeline(
                    context,
                    driver,
                    colors,
                    theme,
                  ),
                  const SizedBox(height: 24),
                  _buildActionButtons(
                    context,
                    controller,
                    driver,
                    theme,
                  ),
                ],
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: Icon(
            Directionality.of(context) == TextDirection.rtl
                ? Icons.arrow_forward
                : Icons.arrow_back,
          ),
          onPressed: () => Get.back<void>(),
          tooltip: 'common.back'.tr,
        ),
        const SizedBox(width: 8),
        Text(
          'admin.approvals.driver_review'.tr,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDriverInfo(
    BuildContext context,
    dynamic driver,
    AppColorsExtension colors,
    ThemeData theme,
  ) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: theme.colorScheme.primary.withValues(
                  alpha: 0.1,
                ),
                child: Text(
                  driver.user.name.isNotEmpty
                      ? driver.user.name[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driver.user.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      driver.user.phone,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              StatusBadge.fromUserStatus(driver.user.status),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: colors.borderSubtle),
          const SizedBox(height: 16),
          // Vehicle info
          Row(
            children: [
              _buildInfoItem(
                context,
                Icons.two_wheeler,
                'admin.approvals.vehicle_type'.tr,
                driver.driverProfile.vehicleType.toJson().tr,
                colors,
              ),
              const SizedBox(width: 24),
              _buildInfoItem(
                context,
                Icons.confirmation_number_outlined,
                'admin.approvals.plate_number'.tr,
                driver.driverProfile.plateNumber.isNotEmpty
                    ? driver.driverProfile.plateNumber
                    : 'admin.widgets.no_plate'.tr,
                colors,
              ),
              const SizedBox(width: 24),
              _buildInfoItem(
                context,
                Icons.calendar_today,
                'admin.approvals.registered'.tr,
                DateFormat('yyyy-MM-dd').format(driver.user.createdAt),
                colors,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Document counts
          Row(
            children: [
              _buildDocCountChip(
                'admin.widgets.docs_pending'.tr,
                driver.pendingDocumentCount,
                colors.warning,
              ),
              const SizedBox(width: 8),
              _buildDocCountChip(
                'admin.widgets.docs_approved'.tr,
                driver.approvedDocumentCount,
                colors.success,
              ),
              const SizedBox(width: 8),
              _buildDocCountChip(
                'admin.widgets.docs_rejected'.tr,
                driver.rejectedDocumentCount,
                Theme.of(context).colorScheme.error,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    AppColorsExtension colors,
  ) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 18, color: colors.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocCountChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Text(
        '$count $label',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildApprovalTimeline(
    BuildContext context,
    dynamic driver,
    AppColorsExtension colors,
    ThemeData theme,
  ) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'admin.approvals.timeline'.tr,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildTimelineItem(
            context,
            icon: Icons.person_add,
            title: 'admin.approvals.registered'.tr,
            subtitle: DateFormat('yyyy-MM-dd HH:mm').format(
              driver.user.createdAt,
            ),
            isCompleted: true,
            colors: colors,
          ),
          _buildTimelineItem(
            context,
            icon: Icons.upload_file,
            title: 'admin.approvals.documents_submitted'.tr,
            subtitle: driver.documents.isNotEmpty
                ? '${driver.documents.length} ${'admin.approvals.documents'.tr}'
                : 'admin.approvals.no_documents'.tr,
            isCompleted: driver.documents.isNotEmpty,
            colors: colors,
          ),
          _buildTimelineItem(
            context,
            icon: Icons.rate_review,
            title: 'admin.approvals.under_review'.tr,
            subtitle: 'admin.approvals.in_progress'.tr,
            isCompleted: false,
            isLast: true,
            colors: colors,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isCompleted,
    required AppColorsExtension colors,
    bool isLast = false,
  }) {
    final theme = Theme.of(context);
    final color = isCompleted ? colors.success : colors.textMuted;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: colors.borderSubtle,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    AdminApprovalController controller,
    dynamic driver,
    ThemeData theme,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        SizedBox(
          width: 160,
          child: AppButton(
            text: 'admin.approvals.reject'.tr,
            variant: ButtonVariant.outline,
            onPressed: () async {
              final reason =
                  await RejectionReasonDialog.show(context);
              if (reason != null && reason.isNotEmpty) {
                await controller.rejectCompletely(
                  driver.user.uid,
                  reason,
                );
              }
            },
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 160,
          child: AppButton(
            text: 'admin.approvals.approve'.tr,
            onPressed: () async {
              final confirmed = await ConfirmDialog.show(
                title: 'common.confirm'.tr,
                message: 'admin.approvals.approve_confirm'.tr,
                confirmLabel: 'admin.users.approve'.tr,
              );
              if (confirmed) {
                await controller.approveDriver(driver.user.uid);
              }
            },
          ),
        ),
      ],
    );
  }

  void _showFullImage(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: InteractiveViewer(
          child: Image.network(url),
        ),
      ),
    );
  }
}
