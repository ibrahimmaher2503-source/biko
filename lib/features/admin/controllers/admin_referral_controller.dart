import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../core/widgets/app_snackbar.dart';
import '../models/referral_stats_model.dart';
import '../services/admin_firestore_service.dart';
import 'admin_auth_controller.dart';

class AdminReferralController extends GetxController {
  final _authController = Get.find<AdminAuthController>();

  final referralStats = const ReferralStatsModel().obs;
  final referralHistory = <Map<String, dynamic>>[].obs;
  final referrerReward = 0.0.obs;
  final refereeReward = 0.0.obs;

  final referrerRewardController = TextEditingController();
  final refereeRewardController = TextEditingController();

  final isLoading = false.obs;
  final hasMore = true.obs;
  final currentPage = 0.obs;

  dynamic lastDocument;

  static const int pageSize = 20;

  @override
  void onInit() {
    super.onInit();
    loadStats();
    loadHistory();
    _loadRewardConfig();
  }

  Future<void> loadStats() async {
    try {
      isLoading.value = true;

      // Get total referrals
      final allReferrals = await AdminFirestoreService.getAllReferrals();
      final total = allReferrals.length;

      // Get rewarded referrals
      final rewardedReferrals =
          await AdminFirestoreService.getRewardedReferrals();
      final rewarded = rewardedReferrals.length;

      // Calculate total payout
      double payout = 0.0;
      for (final data in rewardedReferrals) {
        payout += (data['reward_amount'] as num?)?.toDouble() ?? 0.0;
      }

      referralStats.value = ReferralStatsModel(
        totalReferrals: total,
        totalRewarded: rewarded,
        totalPayout: payout,
      );
    } catch (e) {
      AppSnackbar.error('Failed to load referral stats');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadHistory({bool refresh = false}) async {
    if (isLoading.value || (!hasMore.value && !refresh)) return;

    if (refresh) {
      lastDocument = null;
      currentPage.value = 0;
      hasMore.value = true;
      referralHistory.clear();
    }

    try {
      isLoading.value = true;

      final result = await AdminFirestoreService.getPaginatedReferrals(
        startAfter: lastDocument,
      );

      if (result.items.isEmpty) {
        hasMore.value = false;
        return;
      }

      hasMore.value = result.hasMore;
      lastDocument = result.lastDocument;
      currentPage.value++;

      referralHistory.addAll(result.items);
    } catch (e) {
      AppSnackbar.error('Failed to load referral history');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadRewardConfig() async {
    try {
      final data = await AdminFirestoreService.getAppConfig();
      if (data != null) {
        referrerReward.value =
            (data['referrer_reward'] as num?)?.toDouble() ?? 0.0;
        refereeReward.value =
            (data['referee_reward'] as num?)?.toDouble() ?? 0.0;
        referrerRewardController.text = referrerReward.value.toString();
        refereeRewardController.text = refereeReward.value.toString();
      }
    } catch (e) {
      AppSnackbar.error('Failed to load reward configuration');
    }
  }

  Future<void> saveRewards(double referrerAmount, double refereeAmount) async {
    // Check super admin permission
    if (!_authController.isSuperAdmin) {
      Get.snackbar(
        'admin.error'.tr,
        'admin.config.super_admin_only'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      isLoading.value = true;

      await AdminFirestoreService.callCloudFunction('updateAppConfig', {
        'referrer_reward': referrerAmount,
        'referee_reward': refereeAmount,
      });

      referrerReward.value = referrerAmount;
      refereeReward.value = refereeAmount;

      Get.snackbar(
        'admin.success'.tr,
        'admin.referral.rewards_updated'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );

      await loadStats();
    } catch (e) {
      Get.snackbar(
        'admin.error'.tr,
        'admin.referral.rewards_update_failed'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    referrerRewardController.dispose();
    refereeRewardController.dispose();
    super.onClose();
  }
}
