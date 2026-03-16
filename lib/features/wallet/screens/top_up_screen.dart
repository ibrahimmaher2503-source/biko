import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_button.dart';
import 'package:biko/features/wallet/controllers/wallet_controller.dart';
import 'package:biko/features/wallet/widgets/payment_method_selector.dart';
import 'package:biko/features/wallet/widgets/top_up_amount_selector.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Screen for selecting top-up amount and payment method
class TopUpScreen extends GetView<WalletController> {
  const TopUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = theme.extension<AppColorsExtension>()!;

    return Scaffold(
      appBar: AppBar(title: Text('wallet.top_up'.tr)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount section header with tinted icon
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: ext.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  ),
                  child: Icon(
                    Icons.attach_money_rounded,
                    color: ext.success,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'wallet.select_amount'.tr,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Amount selector
            Obx(
              () => TopUpAmountSelector(
                selectedAmount: controller.selectedTopUpAmount.value,
                onAmountSelected: controller.setTopUpAmount,
              ),
            ),
            const SizedBox(height: 28),

            // Payment method section header
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  ),
                  child: const Icon(
                    Icons.payment_rounded,
                    color: AppTheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'wallet.payment_method'.tr,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Payment method selector
            Obx(
              () => PaymentMethodSelector(
                selectedMethod: controller.selectedPaymentMethod.value,
                onMethodSelected: controller.setPaymentMethod,
              ),
            ),
            const SizedBox(height: 32),

            // Proceed button
            Obx(
              () => AppButton(
                text: 'wallet.proceed'.tr,
                onPressed: controller.selectedTopUpAmount.value != null
                    ? controller.initiateTopUp
                    : null,
                isLoading: controller.isProcessingTopUp.value,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
