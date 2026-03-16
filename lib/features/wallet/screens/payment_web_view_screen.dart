import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Placeholder screen shown in place of the Paymob WebView integration.
///
/// Full WebView integration requires `webview_flutter` and a deployed
/// Cloud Function to generate Paymob payment URLs — disabled for MVP.
class PaymentWebViewScreen extends StatelessWidget {
  const PaymentWebViewScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
              Icon(
                Icons.account_balance_wallet_outlined,
                size: 72,
                color: colors.textMuted,
              ),
              const SizedBox(height: 24),
              Text(
                'wallet.topup_coming_soon'.tr,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'wallet.topup_coming_soon_subtitle'.tr,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              AppButton(
                text: 'common.back'.tr,
                onPressed: () => Get.back<void>(),
                variant: ButtonVariant.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
