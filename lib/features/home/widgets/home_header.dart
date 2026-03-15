import 'dart:ui';

import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/features/home/controllers/home_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Fixed header displaying current location and wallet balance badge.
class HomeHeader extends GetView<HomeController> {
  const HomeHeader({required this.onWalletTap, super.key});

  final VoidCallback onWalletTap;

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppColorsExtension>()!;
    final topPadding = MediaQuery.of(context).padding.top;

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(24),
        bottomRight: Radius.circular(24),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.only(
            top: topPadding + 12,
            bottom: 16,
            left: 20,
            right: 20,
          ),
          decoration: BoxDecoration(
            color: ext.surfaceElevated.withValues(alpha: 0.95),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Location info
              Expanded(child: _buildLocationSection(context, ext)),
              const SizedBox(width: 12),
              // Wallet badge
              _buildWalletBadge(context, ext),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationSection(BuildContext context, AppColorsExtension ext) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_on, color: AppTheme.primary, size: 20),
            const SizedBox(width: 6),
            Text(
              'home.current_location'.tr.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: ext.textMuted,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Obx(() {
          final loaded = controller.locationLoaded.value;
          final name = controller.locationName.value;
          return Text(
            loaded && name.isNotEmpty ? name : 'home.location_unavailable'.tr,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
        }),
      ],
    );
  }

  Widget _buildWalletBadge(BuildContext context, AppColorsExtension ext) {
    return GestureDetector(
      onTap: onWalletTap,
      child: Container(
        padding: const EdgeInsets.only(left: 8, right: 12, top: 6, bottom: 6),
        decoration: BoxDecoration(
          color: ext.surfaceContainer,
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(color: ext.borderSubtle),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Wallet icon circle
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.account_balance_wallet,
                color: AppTheme.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            // Balance text
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'home.balance'.tr,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: ext.textMuted,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Obx(() {
                  final loaded = controller.walletLoaded.value;
                  final balance = controller.walletBalance.value;
                  return Text(
                    loaded
                        ? 'EGP ${balance.toStringAsFixed(0)}'
                        : 'home.balance_error'.tr,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
