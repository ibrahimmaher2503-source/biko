import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_button.dart';
import 'package:biko/core/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ReassignTripDialog extends StatefulWidget {
  const ReassignTripDialog({
    required this.tripId,
    super.key,
  });

  final String tripId;

  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    required String tripId,
  }) {
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => ReassignTripDialog(tripId: tripId),
    );
  }

  @override
  State<ReassignTripDialog> createState() => _ReassignTripDialogState();
}

class _ReassignTripDialogState extends State<ReassignTripDialog> {
  final _driverSearchController = TextEditingController();
  final _reasonController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _driverSearchController.dispose();
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
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'admin.trips.reassign'.tr,
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  '${'admin.trips.trip_id'.tr}: ${widget.tripId}',
                  style: TextStyle(color: colors.textMuted),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'admin.trips.search_driver'.tr,
                  controller: _driverSearchController,
                  hint: 'admin.trips.search_driver_hint'.tr,
                  prefixIcon: Icons.search,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'admin.trips.driver_required'.tr
                      : null,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'admin.trips.reassign_reason'.tr,
                  controller: _reasonController,
                  maxLines: 3,
                  hint: 'admin.trips.reassign_reason_hint'.tr,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'admin.trips.reason_required'.tr
                      : null,
                ),
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
                      width: 140,
                      child: AppButton(
                        text: 'admin.trips.reassign'.tr,
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            Navigator.pop(context, {
                              'trip_id': widget.tripId,
                              'driver_id':
                                  _driverSearchController.text.trim(),
                              'reason': _reasonController.text.trim(),
                            });
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
      ),
    );
  }
}
