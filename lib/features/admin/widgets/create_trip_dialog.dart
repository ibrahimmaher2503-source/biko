import 'package:biko/core/models/enums.dart';
import 'package:biko/core/widgets/app_button.dart';
import 'package:biko/core/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CreateTripDialog extends StatefulWidget {
  const CreateTripDialog({super.key});

  static Future<Map<String, dynamic>?> show(BuildContext context) {
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const CreateTripDialog(),
    );
  }

  @override
  State<CreateTripDialog> createState() => _CreateTripDialogState();
}

class _CreateTripDialogState extends State<CreateTripDialog> {
  final _customerController = TextEditingController();
  final _pickupController = TextEditingController();
  final _dropoffController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  TripType _tripType = TripType.ride;

  @override
  void dispose() {
    _customerController.dispose();
    _pickupController.dispose();
    _dropoffController.dispose();
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
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'admin.trips.create'.tr,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'admin.trips.customer_id'.tr,
                    controller: _customerController,
                    hint: 'admin.trips.customer_id_hint'.tr,
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'admin.trips.customer_required'.tr
                        : null,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'admin.trips.pickup_address'.tr,
                    controller: _pickupController,
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'admin.trips.pickup_required'.tr
                        : null,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'admin.trips.dropoff_address'.tr,
                    controller: _dropoffController,
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'admin.trips.dropoff_required'.tr
                        : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<TripType>(
                    initialValue: _tripType,
                    decoration: InputDecoration(
                      labelText: 'admin.trips.service_type'.tr,
                    ),
                    items: TripType.values
                        .map(
                          (t) => DropdownMenuItem(
                            value: t,
                            child: Text(
                              'admin.trips.type_${t.name}'.tr,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => _tripType = v);
                      }
                    },
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
                        width: 120,
                        child: AppButton(
                          text: 'common.save'.tr,
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              Navigator.pop(context, {
                                'customer_uid':
                                    _customerController.text.trim(),
                                'pickup': _pickupController.text.trim(),
                                'dropoff': _dropoffController.text.trim(),
                                'trip_type': _tripType.toJson(),
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
      ),
    );
  }
}
