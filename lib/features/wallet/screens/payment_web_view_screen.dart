import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_button.dart';
import 'package:biko/core/widgets/app_loading.dart';
import 'package:biko/core/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// WebView screen for Paymob payment processing.
///
/// Note: This is a placeholder that shows payment status.
/// Full WebView integration requires `webview_flutter` package
/// and a deployed Cloud Function to generate Paymob payment URLs.
class PaymentWebViewScreen extends StatelessWidget {
  const PaymentWebViewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>?;
    final amount = args?['amount'] as double? ?? 0;
    final method = args?['method'] as String? ?? '';
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('wallet.payment'.tr)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const AppLoading(),
              const SizedBox(height: 24),
              Text(
                'wallet.processing_payment'.tr,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '${amount.toStringAsFixed(2)} EGP via $method',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.textMuted,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'wallet.payment_pending_note'.tr,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              AppButton(
                text: 'common.back'.tr,
                onPressed: () {
                  AppSnackbar.info('wallet.payment_pending'.tr);
                  Get.back<void>();
                },
                variant: ButtonVariant.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
