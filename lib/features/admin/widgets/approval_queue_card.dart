import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_button.dart';
import 'package:biko/core/widgets/app_card.dart';
import 'package:biko/features/admin/models/driver_review_data.dart';
import 'package:biko/features/admin/widgets/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Card displaying driver info in the approval queue with
/// name, phone, vehicle type, document thumbnails, and action buttons.
class ApprovalQueueCard extends StatelessWidget {
  const ApprovalQueueCard({
    required this.data,
    required this.onApprove,
    required this.onReject,
    super.key,
    this.onTap,
  });

  /// Driver review data containing user, profile, and documents.
  final DriverReviewData data;

  /// Called when the admin taps the Approve button.
  final VoidCallback onApprove;

  /// Called when the admin taps the Reject button with a reason.
  final Function(String) onReject;

  /// Called when the card body is tapped (open detail).
  final VoidCallback? onTap;

  String _timeSinceRegistration() {
    final diff = DateTime.now().difference(data.user.createdAt);
    if (diff.inDays > 0) {
      return '${diff.inDays} ${'admin.widgets.days_ago'.tr}';
    }
    if (diff.inHours > 0) {
      return '${diff.inHours} ${'admin.widgets.hours_ago'.tr}';
    }
    return '${diff.inMinutes} ${'admin.widgets.minutes_ago'.tr}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: avatar + name + time
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: theme.colorScheme.primary.withValues(
                  alpha: 0.1,
                ),
                child: Text(
                  data.user.name.isNotEmpty
                      ? data.user.name[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.user.name,
                      style: theme.textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data.user.phone,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  StatusBadge.fromUserStatus(data.user.status),
                  const SizedBox(height: 4),
                  Text(
                    _timeSinceRegistration(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Vehicle info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colors.surfaceContainer,
              borderRadius: BorderRadius.circular(AppTheme.radiusDefault),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.two_wheeler,
                  size: 18,
                  color: colors.textMuted,
                ),
                const SizedBox(width: 8),
                Text(
                  data.driverProfile.vehicleType.toJson().tr,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.textMuted,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.confirmation_number_outlined,
                  size: 18,
                  color: colors.textMuted,
                ),
                const SizedBox(width: 8),
                Text(
                  data.driverProfile.plateNumber.isNotEmpty
                      ? data.driverProfile.plateNumber
                      : 'admin.widgets.no_plate'.tr,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Document thumbnails row
          if (data.documents.isNotEmpty) ...[
            SizedBox(
              height: 60,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: data.documents.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final doc = data.documents[index];
                  return Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        AppTheme.radiusDefault,
                      ),
                      border: Border.all(color: colors.border),
                      image: doc.fileUrl.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(doc.fileUrl),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: doc.fileUrl.isEmpty
                        ? Icon(
                            Icons.description_outlined,
                            color: colors.textMuted,
                          )
                        : null,
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            // Document counts
            Row(
              children: [
                _DocumentCountChip(
                  label: 'admin.widgets.docs_approved'.tr,
                  count: data.approvedDocumentCount,
                  color: colors.success,
                ),
                const SizedBox(width: 8),
                _DocumentCountChip(
                  label: 'admin.widgets.docs_pending'.tr,
                  count: data.pendingDocumentCount,
                  color: colors.warning,
                ),
                const SizedBox(width: 8),
                _DocumentCountChip(
                  label: 'admin.widgets.docs_rejected'.tr,
                  count: data.rejectedDocumentCount,
                  color: theme.colorScheme.error,
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          // Action buttons
          Row(
            children: [
              Expanded(
                child: AppButton(
                  text: 'admin.users.reject'.tr,
                  onPressed: () => onReject(''),
                  variant: ButtonVariant.outline,
                  height: 40,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  text: 'admin.users.approve'.tr,
                  onPressed: onApprove,
                  height: 40,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DocumentCountChip extends StatelessWidget {
  const _DocumentCountChip({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Text(
        '$count $label',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
