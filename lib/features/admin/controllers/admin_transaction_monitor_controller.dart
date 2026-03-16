import 'dart:async';

import 'package:biko/core/widgets/app_snackbar.dart';
import 'package:biko/features/admin/models/finance/suspicious_transaction_model.dart';
import 'package:biko/features/admin/services/transaction_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show DateTimeRange;
import 'package:get/get.dart';

class AdminTransactionMonitorController extends GetxController {
  final transactions = <Map<String, dynamic>>[].obs;
  final suspiciousTransactions = <SuspiciousTransactionModel>[].obs;
  final searchQuery = ''.obs;
  final isLoading = false.obs;
  final isLive = true.obs;

  StreamSubscription<List<Map<String, dynamic>>>? _transactionSubscription;
  Worker? _searchDebounce;

  @override
  void onInit() {
    super.onInit();
    _startLiveUpdates();
    loadSuspicious();

    _searchDebounce = debounce(
      searchQuery,
      (_) => search(),
      time: const Duration(milliseconds: 500),
    );
  }

  @override
  void onClose() {
    _transactionSubscription?.cancel();
    _searchDebounce?.dispose();
    super.onClose();
  }

  void _startLiveUpdates() {
    _transactionSubscription = TransactionService.getRecentTransactions()
        .listen(
      (data) {
        if (isLive.value) {
          transactions.value = data;
        }
      },
      onError: (e) {
        debugPrint('Transaction stream error: $e');
      },
    );
  }

  void toggleLive() {
    isLive.value = !isLive.value;
    if (isLive.value) {
      _startLiveUpdates();
    } else {
      _transactionSubscription?.cancel();
    }
  }

  Future<void> search({
    String? type,
    String? status,
    DateTimeRange? dateRange,
    double? minAmount,
    double? maxAmount,
  }) async {
    try {
      isLoading.value = true;
      transactions.value = await TransactionService.searchTransactions(
        query: searchQuery.value.isEmpty ? null : searchQuery.value,
        type: type,
        status: status,
        dateRange: dateRange,
        minAmount: minAmount,
        maxAmount: maxAmount,
      );
    } catch (e, stack) {
      debugPrint('search error: $e\n$stack');
      AppSnackbar.error(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> flagSuspicious(
    String transactionId,
    String reason,
  ) async {
    try {
      await TransactionService.flagSuspiciousTransaction(
        transactionId,
        reason,
      );
      AppSnackbar.success('admin.finance.flag_suspicious'.tr);
      await loadSuspicious();
    } catch (e, stack) {
      debugPrint('flagSuspicious error: $e\n$stack');
      AppSnackbar.error(e.toString());
    }
  }

  Future<void> clearFlag(String id) async {
    try {
      await TransactionService.clearSuspiciousFlag(id);
      AppSnackbar.success('admin.finance.clear_flag'.tr);
      await loadSuspicious();
    } catch (e, stack) {
      debugPrint('clearFlag error: $e\n$stack');
      AppSnackbar.error(e.toString());
    }
  }

  Future<void> loadSuspicious() async {
    try {
      suspiciousTransactions.value =
          await TransactionService.getSuspiciousTransactions();
    } catch (e, stack) {
      debugPrint('loadSuspicious error: $e\n$stack');
    }
  }
}
