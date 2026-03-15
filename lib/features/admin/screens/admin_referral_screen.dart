import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/app_text_field.dart';
import '../controllers/admin_referral_controller.dart';
import '../utils/admin_status_colors.dart';
import '../widgets/admin_data_table.dart';
import '../widgets/stat_card.dart';
import '../widgets/status_badge.dart';

class AdminReferralScreen extends GetView<AdminReferralController> {
  const AdminReferralScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;
    final currencyFormat = NumberFormat.currency(
      symbol: 'EGP ',
      decimalDigits: 2,
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('admin.referral.title'.tr),
        backgroundColor: colors.surfaceContainer,
      ),
      body: Obx(
        () => controller.isLoading.value && controller.referralHistory.isEmpty
            ? const Center(child: AppLoading())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats Cards
                    Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            titleKey: 'admin.referral.total_referrals',
                            value: controller.referralStats.value.totalReferrals
                                .toString(),
                            icon: Icons.people_outline,
                            iconColor: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: StatCard(
                            titleKey: 'admin.referral.total_rewarded',
                            value: controller.referralStats.value.totalRewarded
                                .toString(),
                            icon: Icons.card_giftcard,
                            iconColor: colors.success,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: StatCard(
                            titleKey: 'admin.referral.total_payout',
                            value: currencyFormat.format(
                              controller.referralStats.value.totalPayout,
                            ),
                            icon: Icons.payments_outlined,
                            iconColor: colors.warning,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Reward Configuration
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'admin.referral.reward_config'.tr,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'admin.referral.referrer_reward'.tr,
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                    const SizedBox(height: 8),
                                    AppTextField(
                                      controller:
                                          controller.referrerRewardController,
                                      hint:
                                          'admin.referral.enter_amount'.tr,
                                      keyboardType: TextInputType.number,
                                      onChanged: (value) {
                                        controller.referrerReward.value =
                                            double.tryParse(value) ?? 0.0;
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'admin.referral.referee_reward'.tr,
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                    const SizedBox(height: 8),
                                    AppTextField(
                                      controller:
                                          controller.refereeRewardController,
                                      hint:
                                          'admin.referral.enter_amount'.tr,
                                      keyboardType: TextInputType.number,
                                      onChanged: (value) {
                                        controller.refereeReward.value =
                                            double.tryParse(value) ?? 0.0;
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Padding(
                                padding: const EdgeInsets.only(top: 24),
                                child: AppButton(
                                  text: 'admin.save'.tr,
                                  onPressed: () => controller.saveRewards(
                                    controller.referrerReward.value,
                                    controller.refereeReward.value,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Referral History
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'admin.referral.history'.tr,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 500,
                            child: AdminDataTable<Map<String, dynamic>>(
                              columns: [
                                AdminColumn(
                                  label: 'admin.referral.referrer_uid'.tr,
                                ),
                                AdminColumn(
                                  label: 'admin.referral.referee_uid'.tr,
                                ),
                                AdminColumn(
                                  label: 'admin.referral.reward_amount'.tr,
                                ),
                                AdminColumn(label: 'admin.status'.tr),
                                AdminColumn(label: 'admin.date'.tr),
                              ],
                              rows: controller.referralHistory,
                              cellBuilder: (referral, colIndex) {
                                switch (colIndex) {
                                  case 0:
                                    return Text(
                                      referral['referrer_uid'] as String? ??
                                          '-',
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 12,
                                      ),
                                    );
                                  case 1:
                                    return Text(
                                      referral['referee_uid'] as String? ?? '-',
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 12,
                                      ),
                                    );
                                  case 2:
                                    final rewardAmount =
                                        (referral['reward_amount'] as num?)
                                            ?.toDouble() ??
                                        0.0;
                                    return Text(
                                      currencyFormat.format(rewardAmount),
                                    );
                                  case 3:
                                    final status =
                                        referral['status'] as String? ??
                                        'pending';
                                    return StatusBadge(
                                      label: status,
                                      color: _getReferralStatusColor(status),
                                    );
                                  case 4:
                                    final createdAt =
                                        referral['created_at'] as Timestamp?;
                                    final dateStr = createdAt != null
                                        ? DateFormat(
                                            'dd/MM/yyyy HH:mm',
                                          ).format(createdAt.toDate())
                                        : '-';
                                    return Text(dateStr);
                                  default:
                                    return const SizedBox.shrink();
                                }
                              },
                              isLoading: controller.isLoading.value,
                              emptyMessage: 'admin.referral.no_referrals'.tr,
                              hasNextPage: controller.hasMore.value,
                              onNextPage: () => controller.loadHistory(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Color _getReferralStatusColor(String status) {
    return AdminStatusColors.statusColor(status);
  }
}
