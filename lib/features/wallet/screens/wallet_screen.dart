import 'package:biko/core/routes/app_routes.dart';
import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_empty_state.dart';
import 'package:biko/core/widgets/app_error_widget.dart';
import 'package:biko/core/widgets/app_loading.dart';
import 'package:biko/features/wallet/controllers/wallet_controller.dart';
import 'package:biko/features/wallet/widgets/transaction_list_item.dart';
import 'package:biko/features/wallet/widgets/wallet_balance_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Main wallet screen showing balance and transaction history
class WalletScreen extends GetView<WalletController> {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppColorsExtension>()!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('wallet.title'.tr)),
      body: Obx(() {
        // Loading state
        if (controller.isLoading.value) {
          return const Center(child: AppLoading());
        }

        // Error state
        if (controller.errorMessage.isNotEmpty) {
          return Center(
            child: AppErrorWidget(
              message: controller.errorMessage.value.tr,
              onRetry: controller.refresh,
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.refresh,
          color: AppTheme.primary,
          child: ListView(
            children: [
              // Balance card
              WalletBalanceCard(
                balance:
                    controller.wallet.value?.formattedBalance ?? '0.00 EGP',
                onTopUp: () => Get.toNamed(
                  AppRoutes.topUpWallet,
                  arguments: Get.arguments,
                ),
              ),

              // Transaction history header with icon
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusLarge,
                        ),
                      ),
                      child: const Icon(
                        Icons.receipt_long_rounded,
                        color: AppTheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'wallet.transaction_history'.tr,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    if (controller.transactions.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: ext.surfaceContainer,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusFull,
                          ),
                        ),
                        child: Text(
                          '${controller.transactions.length}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: ext.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Transaction list (no nested Obx — already in outer Obx)
              if (controller.transactions.isEmpty)
                AppEmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'wallet.no_transactions'.tr,
                )
              else ...[
                ...controller.transactions.map(
                  (txn) => TransactionListItem(transaction: txn),
                ),
                if (controller.isPaginating.value)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: AppLoading()),
                  ),
              ],
              const SizedBox(height: 20),
            ],
          ),
        );
      }),
    );
  }
}
