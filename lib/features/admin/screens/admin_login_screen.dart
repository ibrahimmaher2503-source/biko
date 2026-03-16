import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_button.dart';
import 'package:biko/core/widgets/app_text_field.dart';
import 'package:biko/features/admin/controllers/admin_auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Admin login screen with email/password form and BikeRide branding.
class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  late final TextEditingController _emailCtrl;
  late final TextEditingController _passwordCtrl;
  final _formKey = GlobalKey<FormState>();
  late final AdminAuthController _controller;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController();
    _passwordCtrl = TextEditingController();
    _controller = Get.find<AdminAuthController>();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusXl),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo / branding
                      Icon(
                        Icons.admin_panel_settings_rounded,
                        size: 64,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'admin.login.title'.tr,
                        style: theme.textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'admin.login.subtitle'.tr,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.textMuted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),

                      // Email field
                      AppTextField(
                        controller: _emailCtrl,
                        label: 'admin.login.email'.tr,
                        hint: 'admin@bikeride.eg',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'validation.required'.tr;
                          }
                          if (!GetUtils.isEmail(v.trim())) {
                            return 'validation.invalid_email'.tr;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Password field
                      AppTextField(
                        controller: _passwordCtrl,
                        label: 'admin.login.password'.tr,
                        prefixIcon: Icons.lock_outlined,
                        obscureText: true,
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'validation.required'.tr;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),

                      // Error message
                      Obx(() {
                        if (_controller.errorMessage.value.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 8),
                          child: Text(
                            _controller.errorMessage.value,
                            style: TextStyle(
                              color: theme.colorScheme.error,
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }),
                      const SizedBox(height: 16),

                      // Login button
                      Obx(
                        () => AppButton(
                          text: 'admin.login.sign_in'.tr,
                          isLoading: _controller.isLoading.value,
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              _controller.signIn(
                                _emailCtrl.text,
                                _passwordCtrl.text,
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
