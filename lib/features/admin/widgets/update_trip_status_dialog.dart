import 'package:biko/core/models/enums.dart';
import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_button.dart';
import 'package:biko/core/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class UpdateTripStatusDialog extends StatefulWidget {
  const UpdateTripStatusDialog({
    required this.currentStatus,
    super.key,
  });

  final TripStatus currentStatus;

  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    required TripStatus currentStatus,
  }) {
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => UpdateTripStatusDialog(currentStatus: currentStatus),
    );
  }

  @override
  State<UpdateTripStatusDialog> createState() =>
      _UpdateTripStatusDialogState();
}

class _UpdateTripStatusDialogState extends State<UpdateTripStatusDialog> {
  late TripStatus _selectedStatus;
  final _reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.currentStatus;
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    final theme = Theme.of(context);

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
                'admin.trips.update_status'.tr,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Text(
                '${'admin.trips.current_status'.tr}: '
                '${'admin.trips.status_${widget.currentStatus.name}'.tr}',
                style: TextStyle(color: colors.textMuted),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<TripStatus>(
                initialValue: _selectedStatus,
                decoration: InputDecoration(
                  labelText: 'admin.trips.new_status'.tr,
                ),
                items: TripStatus.values
                    .map(
                      (s) => DropdownMenuItem(
                        value: s,
                        child: Text(
                          'admin.trips.status_${s.name}'.tr,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _selectedStatus = v);
                  }
                },
              ),
              if (_selectedStatus == TripStatus.cancelled) ...[
                const SizedBox(height: 12),
                AppTextField(
                  label: 'admin.trips.cancellation_reason'.tr,
                  controller: _reasonController,
                  maxLines: 3,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'admin.trips.reason_required'.tr
                      : null,
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
                      text: 'common.save'.tr,
                      onPressed: _selectedStatus == widget.currentStatus
                          ? null
                          : () {
                              if (_selectedStatus == TripStatus.cancelled &&
                                  _reasonController.text.trim().isEmpty) {
                                return;
                              }
                              Navigator.pop(context, {
                                'status': _selectedStatus.toJson(),
                                if (_selectedStatus == TripStatus.cancelled)
                                  'reason': _reasonController.text.trim(),
                              });
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
