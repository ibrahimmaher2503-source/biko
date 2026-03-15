import 'package:biko/core/models/referral_model.dart';
import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_button.dart';
import 'package:biko/core/widgets/app_card.dart';
import 'package:biko/core/widgets/app_empty_state.dart';
import 'package:biko/features/referral/controllers/referral_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// Referral program screen with styled code card and earnings
class ReferralScreen extends GetView<ReferralController> {
  const ReferralScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = Theme.of(context).extension<AppColorsExtension>()!;

    return Scaffold(
      appBar: AppBar(title: Text('referral.title'.tr), centerTitle: false),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Referral code card
            AppCard(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Header icon
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.card_giftcard_rounded,
                        color: AppTheme.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'referral.your_code'.tr,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: ext.textMuted,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Code display in bordered container
                    Obx(
                      () => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: ext.surfaceContainer,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusLarge,
                          ),
                          border: Border.all(color: ext.borderSubtle),
                        ),
                        child: Text(
                          controller.referralCode.value.isNotEmpty
                              ? controller.referralCode.value
                              : '---',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 4,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            text: 'referral.copy'.tr,
                            onPressed: controller.copyReferralCode,
                            variant: ButtonVariant.outline,
                            leadingIcon: Icons.copy_rounded,
                            height: 44,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppButton(
                            text: 'referral.share'.tr,
                            onPressed: controller.shareReferralCode,
                            leadingIcon: Icons.share_rounded,
                            height: 44,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Earnings summary card
            AppCard(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: ext.successBg,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.monetization_on_rounded,
                        color: ext.success,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'referral.total_earnings'.tr,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Obx(
                      () => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: ext.successBg,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusFull,
                          ),
                        ),
                        child: Text(
                          '${controller.totalEarnings.value.toStringAsFixed(0)} ${'common.egp'.tr}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: ext.success,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Referral history header
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: ext.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  ),
                  child: Icon(
                    Icons.people_outline_rounded,
                    color: ext.info,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'referral.history'.tr,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Obx(() {
              if (controller.referrals.isEmpty) {
                return AppEmptyState(
                  icon: Icons.people_outline_rounded,
                  title: 'referral.no_referrals'.tr,
                );
              }
              return Column(
                children: controller.referrals
                    .map(
                      (referral) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ReferralCard(referral: referral),
                      ),
                    )
                    .toList(),
              );
            }),
          ],
        ),
      ),
    );
  }
}

/// Card widget displaying a single referral entry with status and reward
class _ReferralCard extends StatelessWidget {
  const _ReferralCard({required this.referral});

  final ReferralModel referral;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = theme.extension<AppColorsExtension>()!;
    final dateFormat = DateFormat.yMMMd();

    final bool isCompleted = referral.isRewarded;
    final String statusLabel = isCompleted
        ? 'referral.status_completed'.tr
        : 'referral.status_pending'.tr;
    final Color statusColor = isCompleted ? ext.success : ext.warning;
    final Color statusBgColor = isCompleted ? ext.successBg : ext.warningBg;

    return AppCard(
      padding: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: user icon + referred user ID + status badge
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: ext.info.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person_outline_rounded,
                    color: ext.info,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'referral.referred_user'.tr,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: ext.textMuted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        referral.referredUid.length > 12
                            ? '${referral.referredUid.substring(0, 12)}...'
                            : referral.referredUid,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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
            // Bottom row: date + reward
            Row(
              children: [
                Icon(
                  Icons.schedule_rounded,
                  size: 16,
                  color: ext.textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  '${'referral.date'.tr}: ${dateFormat.format(referral.createdAt)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: ext.textMuted,
                  ),
                ),
                const Spacer(),
                if (isCompleted) ...[
                  Icon(
                    Icons.monetization_on_rounded,
                    size: 16,
                    color: ext.success,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${'referral.reward'.tr}: ${referral.rewardAmount.toStringAsFixed(0)} ${'common.egp'.tr}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: ext.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
