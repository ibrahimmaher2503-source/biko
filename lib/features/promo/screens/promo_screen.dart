import 'package:biko/core/models/promo_code_model.dart';
import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_button.dart';
import 'package:biko/core/widgets/app_card.dart';
import 'package:biko/core/widgets/app_empty_state.dart';
import 'package:biko/core/widgets/app_text_field.dart';
import 'package:biko/features/promo/controllers/promo_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// Promo codes screen with styled input and section headers
///
/// Uses StatefulWidget to properly manage TextEditingController lifecycle.
class PromoScreen extends StatefulWidget {
  const PromoScreen({super.key});

  @override
  State<PromoScreen> createState() => _PromoScreenState();
}

class _PromoScreenState extends State<PromoScreen> {
  late final PromoController controller;
  late final TextEditingController codeController;

  @override
  void initState() {
    super.initState();
    controller = Get.find<PromoController>();
    codeController = TextEditingController();
  }

  @override
  void dispose() {
    codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = theme.extension<AppColorsExtension>()!;

    return Scaffold(
      appBar: AppBar(title: Text('promo.title'.tr), centerTitle: false),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Section header with icon
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
                    Icons.local_offer_rounded,
                    color: AppTheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'promo.title'.tr,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Promo code input with apply button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ext.surfaceElevated,
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                border: Border.all(color: ext.borderSubtle),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: codeController,
                      hint: 'promo.enter_code'.tr,
                      prefixIcon: Icons.local_offer_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  AppButton(
                    text: 'promo.apply'.tr,
                    onPressed: () =>
                        controller.applyPromoCode(codeController.text.trim()),
                    width: 100,
                    height: 48,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Active promos section header
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
                    Icons.card_giftcard_rounded,
                    color: ext.success,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'promo.my_promos'.tr,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Promo codes list
            Expanded(
              child: Obx(() {
                if (controller.promoCodes.isEmpty) {
                  return Center(
                    child: AppEmptyState(
                      icon: Icons.local_offer_outlined,
                      title: 'promo.no_promos'.tr,
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: controller.promoCodes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final promo = controller.promoCodes[index];
                    return _PromoCodeCard(promo: promo);
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card widget displaying a single promo code with its details and status
class _PromoCodeCard extends StatelessWidget {
  const _PromoCodeCard({required this.promo});

  final PromoCodeModel promo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = theme.extension<AppColorsExtension>()!;
    final dateFormat = DateFormat.yMMMd();

    // Determine status label and color
    final String statusLabel;
    final Color statusColor;
    final Color statusBgColor;

    if (promo.isUsed) {
      statusLabel = 'promo.status_used'.tr;
      statusColor = ext.textMuted;
      statusBgColor = ext.surfaceContainer;
    } else if (promo.isExpired) {
      statusLabel = 'promo.status_expired'.tr;
      statusColor = ext.warning;
      statusBgColor = ext.warningBg;
    } else {
      statusLabel = 'promo.status_active'.tr;
      statusColor = ext.success;
      statusBgColor = ext.successBg;
    }

    return AppCard(
      padding: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: code + status badge
            Row(
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
                    Icons.local_offer_rounded,
                    color: AppTheme.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    promo.code,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(
                      AppTheme.radiusFull,
                    ),
                  ),
                  child: Text(
                    statusLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Discount and max discount info
            Row(
              children: [
                Icon(
                  Icons.percent_rounded,
                  size: 16,
                  color: ext.textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  '${'promo.discount'.tr}: ${promo.formattedDiscount}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: ext.textMuted,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.arrow_upward_rounded,
                  size: 16,
                  color: ext.textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  '${'promo.max_discount'.tr}: ${promo.maxDiscount.toStringAsFixed(0)} ${'common.egp'.tr}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: ext.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Expiry date
            Row(
              children: [
                Icon(
                  Icons.schedule_rounded,
                  size: 16,
                  color: ext.textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  '${'promo.expires'.tr}: ${dateFormat.format(promo.expiresAt)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: ext.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
