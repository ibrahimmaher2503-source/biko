import 'dart:async';

import 'package:biko/core/models/transaction_model.dart';
import 'package:biko/core/models/wallet_model.dart';
import 'package:biko/core/services/auth_service.dart';
import 'package:biko/core/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Controller for the driver wallet screen.
///
/// Manages wallet balance stream, transaction history,
/// and top-up flow via Paymob WebView.
class WalletController extends GetxController {
  final isLoading = true.obs;
  final wallet = Rxn<WalletModel>();
  final transactions = <TransactionModel>[].obs;
  final isTopUpLoading = false.obs;

  StreamSubscription<WalletModel?>? _walletSub;

  @override
  void onInit() {
    super.onInit();
    _init();
  }

  Future<void> _init() async {
    final uid = AuthService.currentUid;
    if (uid == null) {
      isLoading.value = false;
      return;
    }

    // Listen to wallet balance
    _walletSub = FirestoreService.listenToWallet(uid).listen(
      (w) => wallet.value = w,
      onError: (Object e) =>
          debugPrint('WalletController._init wallet error: $e'),
    );

    await _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    isLoading.value = true;
    final uid = AuthService.currentUid;
    if (uid == null) {
      isLoading.value = false;
      return;
    }

    try {
      final result = await FirestoreService.getTransactionsPaginated(uid);
      transactions.assignAll(result.items);
    } catch (e) {
      debugPrint('WalletController._loadTransactions error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Initiate a top-up via Paymob.
  ///
  /// Returns the payment request ID for tracking.
  Future<String?> initiateTopUp(double amount, String method) async {
    isTopUpLoading.value = true;
    final uid = AuthService.currentUid;
    if (uid == null) {
      isTopUpLoading.value = false;
      return null;
    }

    try {
      final requestId = await FirestoreService.initiateTopUp(
        amount,
        method,
        uid,
      );
      return requestId;
    } catch (e) {
      debugPrint('WalletController.initiateTopUp error: $e');
      return null;
    } finally {
      isTopUpLoading.value = false;
    }
  }

  @override
  Future<void> refresh() async {
    await _loadTransactions();
  }

  @override
  void onClose() {
    _walletSub?.cancel();
    super.onClose();
  }
}
