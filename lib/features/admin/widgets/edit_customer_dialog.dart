import 'package:biko/core/models/user_model.dart';
import 'package:biko/core/widgets/app_button.dart';
import 'package:biko/core/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EditCustomerDialog extends StatefulWidget {
  const EditCustomerDialog({
    required this.user,
    super.key,
  });

  final UserModel user;

  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    required UserModel user,
  }) {
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => EditCustomerDialog(user: user),
    );
  }

  @override
  State<EditCustomerDialog> createState() => _EditCustomerDialogState();
}

class _EditCustomerDialogState extends State<EditCustomerDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _phoneController = TextEditingController(text: widget.user.phone);
    _emailController = TextEditingController(text: widget.user.email ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'admin.customers.edit'.tr,
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
                              'uid': widget.user.uid,
                              'name': _nameController.text.trim(),
                              'phone': _phoneController.text.trim(),
                              'email': _emailController.text.trim(),
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
