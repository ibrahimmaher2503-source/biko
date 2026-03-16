import 'dart:async';

import 'package:biko/core/models/transaction_model.dart';
import 'package:biko/core/models/wallet_model.dart';
import 'package:biko/core/routes/app_routes.dart';
import 'package:biko/core/services/auth_service.dart';
import 'package:biko/core/services/firestore_service.dart';
import 'package:biko/core/widgets/app_snackbar.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

/// Controller for wallet screen and top-up flow
class WalletController extends GetxController {
  // ==================== Observable State ====================

  final Rx<WalletModel?> wallet = Rx<WalletModel?>(null);
  final RxList<TransactionModel> transactions = <TransactionModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isPaginating = false.obs;
  final RxBool hasMore = true.obs;
  final RxString errorMessage = ''.obs;

  // Top-up state
  final Rxn<double> selectedTopUpAmount = Rxn<double>();
  final RxString selectedPaymentMethod = 'card'.obs;
  final RxBool isProcessingTopUp = false.obs;

  StreamSubscription<WalletModel?>? _walletSub;
  String _uid = '';

  /// Opaque pagination cursor — never inspect, just pass back to service.
  Object? _cursor;

  static const _pageSize = 20;

  // ==================== Lifecycle ====================

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>?;
    _uid = args?['uid'] as String? ?? '';
    // Fallback to current auth user if arguments are missing
    if (_uid.isEmpty) {
      _uid = AuthService.currentUid ?? '';
    }
    if (_uid.isEmpty) {
      errorMessage.value = 'wallet.load_error';
      isLoading.value = false;
      return;
    }
    _listenToWallet();
    _loadTransactions();
  }

  @override
  void onClose() {
    _walletSub?.cancel();
    super.onClose();
  }

  // ==================== Data Loading ====================

  void _listenToWallet() {
    if (_uid.isEmpty) return;
    _walletSub = FirestoreService.listenToWallet(_uid).listen(
      (walletData) {
        wallet.value = walletData;
        isLoading.value = false;
      },
      onError: (Object e) {
        debugPrint('❌ WalletController._listenToWallet: $e');
        isLoading.value = false;
        errorMessage.value = 'wallet.load_error'.tr;
      },
    );
  }

  Future<void> _loadTransactions() async {
    if (_uid.isEmpty) return;
    try {
      _cursor = null;
      final result = await FirestoreService.getTransactionsPaginated(_uid);
      transactions.assignAll(result.items);
      _cursor = result.cursor;
      hasMore.value = result.hasMore(_pageSize);
    } catch (e) {
      debugPrint('❌ WalletController._loadTransactions: $e');
    }
  }

  /// Load more transactions (pagination)
  Future<void> loadMore() async {
    if (isPaginating.value || !hasMore.value || _cursor == null) return;
    try {
      isPaginating.value = true;
      final result = await FirestoreService.getTransactionsPaginated(
        _uid,
        cursor: _cursor,
      );
      if (result.items.isEmpty) {
        hasMore.value = false;
      } else {
        transactions.addAll(result.items);
        _cursor = result.cursor;
        hasMore.value = result.hasMore(_pageSize);
      }
    } catch (e) {
      debugPrint('❌ WalletController.loadMore: $e');
    } finally {
      isPaginating.value = false;
    }
  }

  /// Pull-to-refresh
  @override
  Future<void> refresh() async {
    await _loadTransactions();
  }

  // ==================== Top Up ====================

  /// Set top-up amount
  void setTopUpAmount(double? amount) {
    selectedTopUpAmount.value = amount;
  }

  /// Set payment method
  void setPaymentMethod(String method) {
    selectedPaymentMethod.value = method;
  }

  /// Initiate top-up
  Future<void> initiateTopUp() async {
    final amount = selectedTopUpAmount.value;
    if (amount == null || amount <= 0) {
      AppSnackbar.warning('wallet.select_amount'.tr);
      return;
    }

    try {
      isProcessingTopUp.value = true;
      final requestId = await FirestoreService.initiateTopUp(
        amount,
        selectedPaymentMethod.value,
        _uid,
      );

      if (requestId != null) {
        // Refresh transactions after returning from the payment screen.
        // Wallet balance is kept up to date by the live stream in _listenToWallet.
        await Get.toNamed<void>(
          AppRoutes.topUpWallet,
          arguments: {
            'requestId': requestId,
            'amount': amount,
            'method': selectedPaymentMethod.value,
          },
        );
        await _loadTransactions();
      } else {
        AppSnackbar.error('wallet.topup_error'.tr);
      }
    } catch (e) {
      debugPrint('❌ WalletController.initiateTopUp: $e');
      AppSnackbar.error('wallet.topup_error'.tr);
    } finally {
      isProcessingTopUp.value = false;
    }
  }
}
