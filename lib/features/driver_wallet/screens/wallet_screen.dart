import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_button.dart';
import 'package:biko/core/widgets/app_empty_state.dart';
import 'package:biko/core/widgets/app_loading.dart';
import 'package:biko/features/driver_wallet/controllers/wallet_controller.dart';
import 'package:biko/features/driver_wallet/widgets/balance_card.dart';
import 'package:biko/features/driver_wallet/widgets/transaction_tile.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Driver wallet screen showing balance, top-up, and transaction history.
///
/// Matches stitch design: gradient balance card, styled top-up button,
/// clean transaction list with tinted icons, and drag-handle bottom sheet.
class WalletScreen extends GetView<WalletController> {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = theme.extension<AppColorsExtension>()!;

    return Scaffold(
      appBar: AppBar(title: Text('wallet.title'.tr), centerTitle: false),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: AppLoading());
        }

        return RefreshIndicator(
          onRefresh: controller.refresh,
          color: AppTheme.primary,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Balance card
              Obx(() => BalanceCard(wallet: controller.wallet.value)),
              const SizedBox(height: 20),

              // Top-up button
              AppButton(
                text: 'wallet.top_up'.tr,
                onPressed: _showTopUpSheet,
                leadingIcon: Icons.add_circle_outline,
              ),
              const SizedBox(height: 28),

              // Transaction history header
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: ext.info.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                        AppTheme.radiusLarge,
                      ),
                    ),
                    child: Icon(
                      Icons.receipt_long_rounded,
                      color: ext.info,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'wallet.history'.tr,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Transaction list
              Obx(() {
                if (controller.transactions.isEmpty) {
                  return AppEmptyState(
                    icon: Icons.receipt_long,
                    title: 'wallet.no_transactions'.tr,
                    subtitle: 'wallet.no_transactions_desc'.tr,
                  );
                }

                return Column(
                  children: controller.transactions
                      .map((txn) => TransactionTile(transaction: txn))
                      .toList(),
                );
              }),
            ],
          ),
        );
      }),
    );
  }

  void _showTopUpSheet() {
    final ext = Get.theme.extension<AppColorsExtension>()!;

    Get.bottomSheet<void>(
      Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        decoration: BoxDecoration(
          color: Get.theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: ext.borderSubtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'wallet.top_up'.tr,
              style: Get.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'wallet.top_up_desc'.tr,
              style: Get.textTheme.bodyMedium?.copyWith(
                color: ext.textMuted,
              ),
            ),
            const SizedBox(height: 24),
            // Quick amount buttons in grid
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [50, 100, 200, 500].map((amount) {
                return SizedBox(
                  width: (MediaQuery.of(Get.context!).size.width - 58) / 2,
                  child: OutlinedButton(
                    onPressed: () {
                      Get.back<void>();
                      controller.initiateTopUp(amount.toDouble(), 'paymob');
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusLarge,
                        ),
                      ),
                      side: BorderSide(color: ext.border),
                    ),
                    child: Text(
                      '$amount ${'common.egp'.tr}',
                      style: Get.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
