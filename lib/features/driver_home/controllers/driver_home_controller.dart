import 'dart:async';

import 'package:biko/core/models/wallet_model.dart';
import 'package:biko/core/services/auth_service.dart';
import 'package:biko/core/services/background_location_service.dart';
import 'package:biko/core/services/firestore_service.dart';
import 'package:biko/core/widgets/app_snackbar.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

/// Controller for the driver home screen.
///
/// Manages online/offline toggle, today's trip stats,
/// weekly earnings, and wallet balance monitoring.
class DriverHomeController extends GetxController {
  // ==================== State ====================

  /// Current bottom nav index (0=Home, 1=Trips, 2=Earnings, 3=Profile)
  final currentNavIndex = 0.obs;

  /// Loading state for stats
  final isLoading = true.obs;

  /// Error state
  final hasError = false.obs;

  /// Today's trip count
  final todayTrips = 0.obs;

  /// Today's total earnings (EGP)
  final todayEarnings = 0.0.obs;

  /// This week's total earnings (EGP)
  final weeklyEarnings = 0.0.obs;

  /// Wallet balance (to check if driver can go online)
  final walletBalance = 0.0.obs;

  /// Whether the wallet has a negative balance (commission debt)
  bool get hasDebt => walletBalance.value < 0;

  /// Online status from BackgroundLocationService
  bool get isOnline => Get.find<BackgroundLocationService>().isOnline.value;

  // ==================== Private ====================

  StreamSubscription<WalletModel?>? _walletSubscription;
  String? _uid;

  // ==================== Lifecycle ====================

  @override
  void onInit() {
    super.onInit();
    _uid = AuthService.currentUid;
    if (_uid != null) {
      _loadStats();
      _listenToWallet();
    }
  }

  @override
  void onClose() {
    _walletSubscription?.cancel();
    super.onClose();
  }

  // ==================== Public Methods ====================

  /// Toggle driver online/offline status.
  Future<void> toggleOnline() async {
    final bgService = Get.find<BackgroundLocationService>();

    if (bgService.isOnline.value) {
      await bgService.stop();
    } else {
      // Check for negative wallet balance
      if (hasDebt) {
        AppSnackbar.warning('driver_home.top_up_required'.tr);
        return;
      }
      await bgService.start();
    }
  }

  /// Refresh stats data.
  Future<void> refreshStats() async {
    await _loadStats();
  }

  /// Change bottom navigation tab.
  void onNavTap(int index) {
    currentNavIndex.value = index;
  }

  // ==================== Private Methods ====================

  Future<void> _loadStats() async {
    if (_uid == null) return;

    try {
      isLoading.value = true;
      hasError.value = false;

      final results = await Future.wait([
        FirestoreService.getDriverTodayStats(_uid!),
        FirestoreService.getDriverWeeklyEarnings(_uid!),
      ]);

      final todayStats = results[0] as Map<String, dynamic>;
      todayTrips.value = todayStats['tripCount'] as int;
      todayEarnings.value = todayStats['totalEarned'] as double;
      weeklyEarnings.value = results[1] as double;
    } catch (e) {
      debugPrint('❌ DriverHomeController._loadStats failed: $e');
      hasError.value = true;
    } finally {
      isLoading.value = false;
    }
  }

  void _listenToWallet() {
    _walletSubscription = FirestoreService.listenToWallet(_uid!).listen(
      (wallet) {
        walletBalance.value = wallet?.balance ?? 0.0;
      },
      onError: (e) {
        debugPrint('⚠️ DriverHomeController wallet stream error: $e');
      },
    );
  }
}
