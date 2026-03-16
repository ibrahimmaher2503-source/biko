import 'package:biko/core/widgets/app_button.dart';
import 'package:biko/core/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RejectionReasonDialog extends StatefulWidget {
  const RejectionReasonDialog({super.key});

  static Future<String?> show(BuildContext context) {
    return showDialog<String>(
      context: context,
      builder: (_) => const RejectionReasonDialog(),
    );
  }

  @override
  State<RejectionReasonDialog> createState() => _RejectionReasonDialogState();
}

class _RejectionReasonDialogState extends State<RejectionReasonDialog> {
  String? _selectedReason;
  final _customController = TextEditingController();

  final _reasons = [
    'admin.approvals.blurry_image',
    'admin.approvals.expired_document',
    'admin.approvals.wrong_document',
    'admin.approvals.info_mismatch',
    'admin.approvals.other_reason',
  ];

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                'admin.approvals.select_rejection_reason'.tr,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              RadioGroup<String>(
                groupValue: _selectedReason,
                onChanged: (v) => setState(() => _selectedReason = v),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _reasons
                      .map(
                        (r) => RadioListTile<String>(
                          title: Text(r.tr),
                          value: r,
                        ),
                      )
                      .toList(),
                ),
              ),
              if (_selectedReason == 'admin.approvals.other_reason') ...[
                const SizedBox(height: 12),
                AppTextField(
                  label: 'admin.approvals.custom_reason'.tr,
                  controller: _customController,
                  maxLines: 3,
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
                      text: 'admin.approvals.reject'.tr,
                      onPressed: _selectedReason == null
                          ? null
                          : () {
                              final reason = _selectedReason ==
                                      'admin.approvals.other_reason'
                                  ? _customController.text.trim()
                                  : _selectedReason!.tr;
                              if (reason.isNotEmpty) {
                                Navigator.pop(context, reason);
                              }
                            },
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
