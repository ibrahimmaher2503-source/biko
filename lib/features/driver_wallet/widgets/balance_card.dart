import 'package:biko/core/models/wallet_model.dart';
import 'package:biko/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Card showing the driver's current wallet balance.
///
/// Matches stitch design: gradient primary background,
/// large centered balance amount, and negative warning badge.
class BalanceCard extends StatelessWidget {
  const BalanceCard({required this.wallet, super.key});

  final WalletModel? wallet;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final balance = wallet?.balance ?? 0.0;
    final isNegative = balance < 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [
            AppTheme.primary,
            AppTheme.primary.withValues(alpha: 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Wallet icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'wallet.balance'.tr,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${balance.toStringAsFixed(0)} ${'common.egp'.tr}',
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          if (isNegative) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'wallet.negative_balance_warning'.tr,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
