import 'package:biko/core/models/enums.dart';
import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/features/auth/controllers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Google and Facebook social login buttons
/// Currently show "Coming Soon" snackbar on tap (per research R-011)
class SocialLoginButtons extends StatelessWidget {
  const SocialLoginButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Divider with "OR CONTINUE WITH"
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'phone.or_continue'.tr,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.5),
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 16),
        // Social buttons row
        Obx(() {
          final authController = Get.find<AuthController>();
          final isSocialLoading =
              authController.authState == AuthState.signingInWithGoogle ||
              authController.authState == AuthState.signingInWithFacebook;
          return Row(
            children: [
              Expanded(
                child: _SocialButton(
                  label: 'phone.google'.tr,
                  icon: 'G',
                  iconColor: const Color(0xFFDB4437),
                  isLoading: authController.authState ==
                      AuthState.signingInWithGoogle,
                  onTap: isSocialLoading
                      ? null
                      : authController.signInWithGoogle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SocialButton(
                  label: 'phone.facebook'.tr,
                  icon: 'f',
                  iconColor: const Color(0xFF1877F2),
                  isLoading: authController.authState ==
                      AuthState.signingInWithFacebook,
                  onTap: isSocialLoading
                      ? null
                      : authController.signInWithFacebook,
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.onTap,
    this.isLoading = false,
  });

  final String label;
  final String icon;
  final Color iconColor;
  final bool isLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppColorsExtension>()!;

    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        side: BorderSide(
          color: ext.border,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
      ),
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  icon,
                  style: TextStyle(
                    color: iconColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
    );
  }
}
