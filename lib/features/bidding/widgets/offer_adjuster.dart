import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/features/bidding/controllers/bidding_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// +/- offer adjuster for the price negotiation screen.
///
/// Shows: circular "-" button | large bold amount | "EGP" label | circular "+" button
/// Uses Obx to reactively read/write BiddingController.offerAmount.
/// "-" is disabled at minOffer, "+" is disabled at 999 EGP.
class OfferAdjuster extends GetView<BiddingController> {
  const OfferAdjuster({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Minus button
          Obx(
            () => _CircularButton(
              icon: Icons.remove,
              onTap: controller.offerAmount.value > controller.minOffer.value
                  ? controller.decrementOffer
                  : null,
            ),
          ),

          const SizedBox(width: 24),

          // Offer amount
          Obx(
            () => Text(
              controller.offerAmount.value.toString(),
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),

          const SizedBox(width: 8),

          // EGP label
          Text(
            'trip.egp'.tr,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colors.textMuted,
            ),
          ),

          const SizedBox(width: 24),

          // Plus button
          Obx(
            () => _CircularButton(
              icon: Icons.add,
              onTap: controller.offerAmount.value < 999
                  ? controller.incrementOffer
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// Circular +/- button used by the offer adjuster.
class _CircularButton extends StatelessWidget {
  const _CircularButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    final isEnabled = onTap != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isEnabled ? colors.surfaceContainer : colors.borderSubtle,
          border: Border.all(
            color: isEnabled ? colors.border : colors.borderSubtle,
          ),
        ),
        child: Icon(
          icon,
          color: isEnabled
              ? Theme.of(context).colorScheme.onSurface
              : colors.textMuted,
          size: 20,
        ),
      ),
    );
  }
}
