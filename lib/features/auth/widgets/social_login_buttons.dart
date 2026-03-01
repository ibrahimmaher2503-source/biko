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
        Row(
          children: [
            Expanded(
              child: Obx(() {
                final authController = Get.find<AuthController>();
                final isSigningIn = authController.authState ==
                    AuthState.signingInWithGoogle;
                return _SocialButton(
                  label: 'phone.google'.tr,
                  icon: 'G',
                  iconColor: const Color(0xFFDB4437),
                  isLoading: isSigningIn,
                  onTap: isSigningIn
                      ? null
                      : () => authController.signInWithGoogle(),
                );
              }),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SocialButton(
                label: 'phone.facebook'.tr,
                icon: 'f',
                iconColor: const Color(0xFF1877F2),
                onTap: () => _showComingSoon(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showComingSoon() {
    Get.snackbar(
      'phone.coming_soon'.tr,
      '',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(16),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final String icon;
  final Color iconColor;
  final bool isLoading;
  final VoidCallback? onTap;

  const _SocialButton({
    required this.label,
    required this.icon,
    required this.iconColor,
    this.isLoading = false,
    required this.onTap,
  });

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
