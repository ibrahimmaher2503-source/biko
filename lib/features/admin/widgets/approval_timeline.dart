import 'package:biko/core/models/document_model.dart';
import 'package:biko/core/models/driver_profile_model.dart';
import 'package:biko/core/models/user_model.dart';
import 'package:biko/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class ApprovalTimeline extends StatelessWidget {
  const ApprovalTimeline({
    required this.user,
    required this.profile,
    required this.documents,
    super.key,
  });

  final UserModel user;
  final DriverProfileModel profile;
  final List<DocumentModel> documents;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    final fmt = DateFormat('dd/MM/yyyy HH:mm');

    final steps = <_TimelineStep>[
      _TimelineStep(
        title: 'admin.approvals.registration_date'.tr,
        date: fmt.format(user.createdAt),
        isCompleted: true,
      ),
      _TimelineStep(
        title: 'admin.approvals.document_upload'.tr,
        date: documents.isNotEmpty
            ? fmt.format(documents.first.createdAt)
            : '-',
        isCompleted: documents.isNotEmpty,
      ),
      _TimelineStep(
        title: 'admin.approvals.review_date'.tr,
        date: '-',
        isCompleted: false,
      ),
      _TimelineStep(
        title: 'admin.approvals.approval_date'.tr,
        date: profile.isApproved ? 'common.completed'.tr : '-',
        isCompleted: profile.isApproved,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < steps.length; i++) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: steps[i].isCompleted
                          ? colors.success
                          : colors.border,
                    ),
                    child: steps[i].isCompleted
                        ? const Icon(
                            Icons.check,
                            size: 14,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  if (i < steps.length - 1)
                    Container(
                      width: 2,
                      height: 40,
                      color: colors.borderSubtle,
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      steps[i].title,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      steps[i].date,
                      style: TextStyle(
                        color: colors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _TimelineStep {
  const _TimelineStep({
    required this.title,
    required this.date,
    required this.isCompleted,
  });

  final String title;
  final String date;
  final bool isCompleted;
}
