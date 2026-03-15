import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_button.dart';
import 'package:biko/features/auth/controllers/auth_controller.dart';
import 'package:biko/features/auth/widgets/phone_input_field.dart';
import 'package:biko/features/auth/widgets/social_login_buttons.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Scaffold(
      body: Column(
        children: [
          // Top section — Cairo map background with branding
          _buildTopSection(context),
          // Bottom section — phone input and actions
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Phone input field
                  Obx(
                    () => PhoneInputField(
                      controller: _phoneController,
                      errorText: authController.errorMessage.value.isNotEmpty
                          ? authController.errorMessage.value
                          : null,
                      onChanged: (_) {
                        if (authController.errorMessage.value.isNotEmpty) {
                          authController.errorMessage.value = '';
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Continue button
                  Obx(
                    () => AppButton(
                      text: 'phone.continue'.tr,
                      onPressed: () =>
                          authController.sendOtp(_phoneController.text),
                      trailingIcon: Icons.arrow_forward,
                      isLoading: authController.isLoading,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Social login buttons
                  const SocialLoginButtons(),
                  const SizedBox(height: 24),
                  // Terms and privacy
                  _buildTermsText(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 24,
        right: 24,
        bottom: 32,
      ),
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/backgrounds/cairo_map.png'),
          fit: BoxFit.cover,
        ),
        // Red gradient overlay
        color: AppTheme.primary,
      ),
      child: Stack(
        children: [
          // Gradient overlay on top of image
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.primary.withValues(alpha: 0.7),
                    AppTheme.primary.withValues(alpha: 0.85),
                  ],
                ),
              ),
            ),
          ),
          // Content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // BikeRide icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                ),
                child: const Icon(
                  Icons.directions_bike,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              // "Yalla!" title
              Text(
                'phone.title'.tr,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              // "Let's get moving" subtitle
              Text(
                'phone.subtitle'.tr,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              // "Ride or deliver across Cairo" tagline
              Text(
                'phone.tagline'.tr,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTermsText(BuildContext context) {
    return Center(
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          children: [
            TextSpan(text: 'phone.terms_prefix'.tr),
            const TextSpan(text: ' '),
            TextSpan(
              text: 'phone.terms'.tr,
              style: const TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(text: ' ${'phone.and'.tr} '),
            TextSpan(
              text: 'phone.privacy'.tr,
              style: const TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const TextSpan(text: '.'),
          ],
        ),
      ),
    );
  }
}
