import 'package:biko/core/models/enums.dart';
import 'package:biko/core/widgets/app_button.dart';
import 'package:biko/core/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CreateDriverDialog extends StatefulWidget {
  const CreateDriverDialog({super.key});

  static Future<Map<String, dynamic>?> show(BuildContext context) {
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const CreateDriverDialog(),
    );
  }

  @override
  State<CreateDriverDialog> createState() => _CreateDriverDialogState();
}

class _CreateDriverDialogState extends State<CreateDriverDialog> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _plateNumberController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  VehicleType _vehicleType = VehicleType.motorcycle;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _plateNumberController.dispose();
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
                    'admin.drivers.create'.tr,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'common.name'.tr,
                    controller: _nameController,
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'common.name_required'.tr
                        : null,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'common.phone'.tr,
                    controller: _phoneController,
                    hint: 'common.phone_format_hint'.tr,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'common.phone_required'.tr;
                      }
                      final clean = v.replaceAll(RegExp(r'[^\d]'), '');
                      if (clean.length != 11 || !clean.startsWith('01')) {
                        return 'common.invalid_phone'.tr;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'common.email'.tr,
                    controller: _emailController,
                    validator: (v) {
                      if (v != null &&
                          v.isNotEmpty &&
                          !GetUtils.isEmail(v)) {
                        return 'common.invalid_email'.tr;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<VehicleType>(
                    initialValue: _vehicleType,
                    decoration: InputDecoration(
                      labelText: 'admin.drivers.vehicle_type'.tr,
                    ),
                    items: VehicleType.values
                        .map(
                          (v) => DropdownMenuItem(
                            value: v,
                            child: Text(
                              'admin.drivers.vehicle_${v.name}'.tr,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => _vehicleType = v);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'admin.drivers.plate_number'.tr,
                    controller: _plateNumberController,
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'admin.drivers.plate_required'.tr
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
                        width: 120,
                        child: AppButton(
                          text: 'common.save'.tr,
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              Navigator.pop(context, {
                                'name': _nameController.text.trim(),
                                'phone': _phoneController.text.trim(),
                                'email': _emailController.text.trim(),
                                'vehicle_type': _vehicleType.toJson(),
                                'plate_number':
                                    _plateNumberController.text.trim(),
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
