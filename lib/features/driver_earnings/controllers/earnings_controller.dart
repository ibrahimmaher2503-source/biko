import 'package:biko/core/models/transaction_model.dart';
import 'package:biko/core/services/auth_service.dart';
import 'package:biko/core/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Controller for the driver earnings screen.
///
/// Shows earnings breakdown by period (today, this week, this month)
/// with a bar chart and trip list.
class EarningsController extends GetxController
    with GetSingleTickerProviderStateMixin {
  late final TabController tabController;

  final isLoading = true.obs;
  final transactions = <TransactionModel>[].obs;
  final totalEarnings = 0.0.obs;
  final currentPeriod = 0.obs; // 0=today, 1=week, 2=month

  // Chart data: daily earnings for the selected period
  final chartData = <double>[].obs;
  final chartLabels = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 3, vsync: this);
    tabController.addListener(_onTabChanged);
    _loadEarnings();
  }

  void _onTabChanged() {
    if (!tabController.indexIsChanging) {
      currentPeriod.value = tabController.index;
      _loadEarnings();
    }
  }

  Future<void> _loadEarnings() async {
    isLoading.value = true;
    final uid = AuthService.currentUser?.uid;
    if (uid == null) {
      isLoading.value = false;
      return;
    }

    try {
      final now = DateTime.now();
      final DateTime from;
      switch (currentPeriod.value) {
        case 0: // Today
          from = DateTime(now.year, now.month, now.day);
        case 1: // This week
          from = now.subtract(Duration(days: now.weekday - 1));
        case 2: // This month
          from = DateTime(now.year, now.month);
        default:
          from = DateTime(now.year, now.month, now.day);
      }

      final results = await FirestoreService.getDriverEarnings(
        uid,
        from: from,
        to: now,
      );
      transactions.assignAll(results);

      // Calculate total
      var total = 0.0;
      for (final txn in results) {
        total += txn.amount;
      }
      totalEarnings.value = total;

      // Build chart data
      _buildChartData(results, from, now);
    } catch (e) {
      debugPrint('EarningsController._loadEarnings error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void _buildChartData(
    List<TransactionModel> txns,
    DateTime from,
    DateTime to,
  ) {
    final days = to.difference(from).inDays + 1;
    final data = List<double>.filled(days, 0);
    final labels = <String>[];

    for (var i = 0; i < days; i++) {
      final day = from.add(Duration(days: i));
      labels.add('${day.day}');
    }

    for (final txn in txns) {
      final dayIndex = txn.createdAt.difference(from).inDays;
      if (dayIndex >= 0 && dayIndex < days) {
        data[dayIndex] += txn.amount;
      }
    }

    chartData.assignAll(data);
    chartLabels.assignAll(labels);
  }

  @override
  Future<void> refresh() async {
    await _loadEarnings();
  }

  @override
  void onClose() {
    tabController.dispose();
    super.onClose();
  }
}
