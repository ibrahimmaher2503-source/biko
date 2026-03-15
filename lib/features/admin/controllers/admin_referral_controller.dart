import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../core/widgets/app_snackbar.dart';
import '../models/referral_stats_model.dart';
import 'admin_auth_controller.dart';

class AdminReferralController extends GetxController {
  final _firestore = FirebaseFirestore.instance;
  final _functions = FirebaseFunctions.instance;
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

  DocumentSnapshot? lastDocument;

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
      final totalSnapshot = await _firestore.collection('referrals').get();
      final total = totalSnapshot.docs.length;

      // Get rewarded referrals
      final rewardedSnapshot = await _firestore
          .collection('referrals')
          .where('status', isEqualTo: 'rewarded')
          .get();
      final rewarded = rewardedSnapshot.docs.length;

      // Calculate total payout
      double payout = 0.0;
      for (final doc in rewardedSnapshot.docs) {
        final data = doc.data();
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

      Query query = _firestore
          .collection('referrals')
          .orderBy('created_at', descending: true)
          .limit(pageSize);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument!);
      }

      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        hasMore.value = false;
        return;
      }

      if (snapshot.docs.length < pageSize) {
        hasMore.value = false;
      }

      lastDocument = snapshot.docs.last;
      currentPage.value++;

      final List<Map<String, dynamic>> newHistory = [];
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        newHistory.add({'id': doc.id, ...data});
      }

      referralHistory.addAll(newHistory);
    } catch (e) {
      AppSnackbar.error('Failed to load referral history');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadRewardConfig() async {
    try {
      final configDoc = await _firestore
          .collection('app_config')
          .doc('config')
          .get();
      if (configDoc.exists) {
        final data = configDoc.data()!;
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

      final callable = _functions.httpsCallable('updateAppConfig');
      await callable.call({
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
