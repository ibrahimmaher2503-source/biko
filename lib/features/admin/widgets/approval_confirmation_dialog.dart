import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_button.dart';
import 'package:biko/features/admin/models/driver_review_data.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ApprovalConfirmationDialog extends StatelessWidget {
  const ApprovalConfirmationDialog({
    required this.data,
    super.key,
  });

  final DriverReviewData data;

  static Future<bool?> show(
    BuildContext context, {
    required DriverReviewData data,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => ApprovalConfirmationDialog(data: data),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    final hasUnapproved =
        data.pendingDocumentCount > 0 || data.rejectedDocumentCount > 0;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 450),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'admin.approvals.confirm_approve'.tr,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Text(
                data.user.name,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              Text(
                data.user.phone,
                style: TextStyle(color: colors.textMuted),
              ),
              const SizedBox(height: 12),
              Text(
                '${'admin.approvals.approved_docs'.tr}: '
                '${data.approvedDocumentCount}/${data.documents.length}',
              ),
              if (hasUnapproved) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.warningBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: colors.warning,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'admin.approvals.all_docs_must_be_approved'.tr,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 120,
                    child: AppButton(
                      text: 'common.cancel'.tr,
                      variant: ButtonVariant.outline,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 120,
                    child: AppButton(
                      text: 'admin.approvals.approve'.tr,
                      onPressed: hasUnapproved
                          ? null
                          : () => Navigator.pop(context, true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
