import 'package:biko/core/widgets/app_snackbar.dart';
import 'package:biko/features/admin/models/finance/wallet_activity_model.dart';
import 'package:biko/features/admin/models/finance/wallet_summary_model.dart';
import 'package:biko/features/admin/services/wallet_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show DateTimeRange;
import 'package:get/get.dart';

class AdminWalletController extends GetxController {
  final Rx<WalletSummaryModel?> summary =
      Rx<WalletSummaryModel?>(null);
  final activity = <WalletActivityModel>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadWalletData();
  }

  Future<void> loadWalletData() async {
    try {
      isLoading.value = true;

      await Future.wait([
        _loadSummary(),
        _loadActivity(),
      ]);
    } catch (e, stack) {
      debugPrint('loadWalletData error: $e\n$stack');
      AppSnackbar.error(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadSummary() async {
    summary.value = await WalletService.getWalletSummary();
  }

  Future<void> _loadActivity({
    String? userUid,
    String? type,
    DateTimeRange? dateRange,
  }) async {
    activity.value = await WalletService.getWalletActivity(
      userUid: userUid,
      type: type,
      dateRange: dateRange,
    );
  }

  Future<void> adjustWallet(
    String userUid,
    double amount,
    String reason,
  ) async {
    try {
      isLoading.value = true;
      await WalletService.adjustWallet(userUid, amount, reason);
      AppSnackbar.success('admin.finance.adjust_wallet'.tr);
      await loadWalletData();
    } catch (e, stack) {
      debugPrint('adjustWallet error: $e\n$stack');
      AppSnackbar.error(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  void filterActivity({
    String? userUid,
    String? type,
    DateTimeRange? dateRange,
  }) {
    _loadActivity(userUid: userUid, type: type, dateRange: dateRange);
  }
}
