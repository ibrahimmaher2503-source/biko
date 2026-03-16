import 'dart:ui';

import 'package:biko/core/routes/app_routes.dart';
import 'package:biko/core/services/auth_service.dart';
import 'package:biko/core/services/firestore_service.dart';
import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_button.dart';
import 'package:biko/core/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class PendingApprovalScreen extends StatelessWidget {
  const PendingApprovalScreen({super.key});

  // Default fallback values
  static const _defaultSupportPhone = '+201000000000';
  static const _defaultSupportEmail = 'support@bikeride.eg';

  Future<void> _contactSupport() async {
    final uid = AuthService.currentUid ?? '';
    final message = 'pending.support_message'.trParams({'uid': uid});
    final subject = 'pending.support_email_subject'.trParams({'uid': uid});

    // Fetch config
    String supportPhone = _defaultSupportPhone;
    String supportEmail = _defaultSupportEmail;
    try {
      final config = await FirestoreService.getAppConfig();
      if (config != null) {
        if (config['support_phone'] != null &&
            config['support_phone'].toString().isNotEmpty) {
          supportPhone = config['support_phone'].toString();
        }
        if (config['support_email'] != null &&
            config['support_email'].toString().isNotEmpty) {
          supportEmail = config['support_email'].toString();
        }
      }
    } catch (_) {
      // Ignore errors and use default
    }

    final whatsAppUrl = Uri.parse(
      'https://wa.me/$supportPhone?text=${Uri.encodeComponent(message)}',
    );
    final mailUrl = Uri.parse(
      'mailto:$supportEmail?subject=${Uri.encodeComponent(subject)}',
    );

    try {
      if (await canLaunchUrl(whatsAppUrl)) {
        await launchUrl(whatsAppUrl, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(mailUrl);
      }
    } catch (_) {
      try {
        await launchUrl(mailUrl);
      } catch (_) {
        AppSnackbar.error('error.contact_support_failed'.tr);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppColorsExtension>()!;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: Get.back,
                    icon: Icon(
                      Directionality.of(context) == TextDirection.rtl
                          ? Icons.arrow_forward
                          : Icons.arrow_back,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'pending.title'.tr,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Illustration with blur blob
                    SizedBox(
                      width: 280,
                      height: 280,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                              child: const SizedBox.shrink(),
                            ),
                          ),
                          Icon(
                            Icons.hourglass_top_rounded,
                            size: 120,
                            color: AppTheme.primary.withValues(alpha: 0.7),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Heading
                    Text(
                      'pending.heading'.tr,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    // Description
                    Text(
                      'pending.description'.tr,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    // Status timeline card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: ext.surfaceElevated,
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusLarge,
                        ),
                        border: Border.all(color: ext.border),
                      ),
                      child: Row(
                        children: [
                          // Timeline dots and line
                          Column(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppTheme.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Container(
                                width: 2,
                                height: 32,
                                color: AppTheme.primary.withValues(alpha: 0.2),
                              ),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withValues(
                                    alpha: 0.2,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          // Timeline steps
                          Expanded(
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'pending.docs_submitted'.tr,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    const Icon(
                                      Icons.check_circle,
                                      color: AppTheme.primary,
                                      size: 18,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                Opacity(
                                  opacity: 0.6,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'pending.verification'.tr,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w500,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withValues(alpha: 0.5),
                                            ),
                                      ),
                                      Icon(
                                        Icons.pending,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.4),
                                        size: 18,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Bottom buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                children: [
                  // Contact Support
                  AppButton(
                    text: 'pending.contact_support'.tr,
                    onPressed: _contactSupport,
                  ),
                  const SizedBox(height: 12),
                  // Back to Home
                  AppButton(
                    text: 'pending.back_home'.tr,
                    onPressed: () => Get.offAllNamed(AppRoutes.splash),
                    variant: ButtonVariant.text,
                    height: 48,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
