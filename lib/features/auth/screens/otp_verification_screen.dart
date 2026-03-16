import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_button.dart';
import 'package:biko/features/auth/controllers/auth_controller.dart';
import 'package:biko/features/auth/widgets/otp_input_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OtpVerificationScreen extends StatelessWidget {
  OtpVerificationScreen({super.key});

  /// Reactive OTP code — kept outside build() to avoid recreation on rebuild.
  final RxString otpCode = ''.obs;

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Back button header
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: IconButton(
                  onPressed: Get.back,
                  icon: Icon(
                    Directionality.of(context) == TextDirection.rtl
                        ? Icons.arrow_forward
                        : Icons.arrow_back,
                  ),
                ),
              ),
            ),
            // Main content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    // Header text
                    Text(
                      'otp.title'.tr,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    // Masked phone number
                    Obx(() {
                      final phone = authController.phoneNumber.value;
                      final masked = phone.length >= 2
                          ? '**${phone.substring(phone.length - 2)}'
                          : '**';
                      return Text(
                        '${'otp.subtitle'.tr} $masked.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        textAlign: TextAlign.center,
                      );
                    }),
                    const SizedBox(height: 32),
                    // OTP input fields
                    OtpInputField(
                      onCompleted: (otp) {
                        otpCode.value = otp;
                        authController.verifyOtp(otp);
                      },
                    ),
                    const SizedBox(height: 24),
                    // Timer badge
                    Obx(() {
                      final seconds = authController.secondsRemaining.value;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.neutralTint,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusFull,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.timer,
                              color: AppTheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '00:${seconds.toString().padLeft(2, '0')}',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                    // Resend code
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'otp.didnt_receive'.tr,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.5),
                              ),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Obx(
                            () => AppButton(
                              text: 'otp.resend'.tr,
                              onPressed: authController.isResendEnabled
                                  ? authController.resendOtp
                                  : null,
                              variant: ButtonVariant.text,
                              height: 36,
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Error message
                    Obx(() {
                      if (authController.errorMessage.value.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          authController.errorMessage.value,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.error,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }),
                    const Spacer(),
                    // Verify button
                    Obx(
                      () => AppButton(
                        text: 'otp.verify'.tr,
                        onPressed:
                            otpCode.value.length == 6 &&
                                !authController.isLoading
                            ? () => authController.verifyOtp(otpCode.value)
                            : null,
                        trailingIcon: Icons.check,
                        isLoading: authController.isLoading,
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
