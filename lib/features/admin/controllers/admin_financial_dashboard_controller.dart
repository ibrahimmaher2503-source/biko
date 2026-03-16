import 'package:biko/core/widgets/app_snackbar.dart';
import 'package:biko/features/admin/models/finance/commission_breakdown_model.dart';
import 'package:biko/features/admin/models/finance/daily_revenue_model.dart';
import 'package:biko/features/admin/models/finance/financial_summary_model.dart';
import 'package:biko/features/admin/models/finance/payment_stats_model.dart';
import 'package:biko/features/admin/services/admin_firestore_service.dart';
import 'package:biko/features/admin/services/commission_service.dart';
import 'package:biko/features/admin/services/financial_service.dart';
import 'package:biko/features/admin/services/revenue_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show DateTimeRange;
import 'package:get/get.dart';

class AdminFinancialDashboardController extends GetxController {
  final Rx<FinancialSummaryModel?> summary =
      Rx<FinancialSummaryModel?>(null);
  final revenueData = <DailyRevenueModel>[].obs;
  final Rx<CommissionBreakdownModel?> commissionBreakdown =
      Rx<CommissionBreakdownModel?>(null);
  final paymentDistribution = <PaymentStatsModel>[].obs;
  final recentTransactions = <Map<String, dynamic>>[].obs;
  final isLoading = false.obs;

  final Rx<DateTime> startDate = DateTime.now()
      .subtract(const Duration(days: 30))
      .obs;
  final Rx<DateTime> endDate = DateTime.now().obs;
  final selectedPeriod = 'last_30_days'.obs;

  DateTimeRange get dateRange => DateTimeRange(
        start: startDate.value,
        end: endDate.value,
      );

  @override
  void onInit() {
    super.onInit();
    loadAllData();
  }

  Future<void> loadAllData() async {
    try {
      isLoading.value = true;

      await Future.wait([
        _loadSummary(),
        _loadRevenueData(),
        _loadCommissionBreakdown(),
        _loadPaymentDistribution(),
        _loadRecentTransactions(),
      ]);
    } catch (e, stack) {
      debugPrint('loadAllData error: $e\n$stack');
      // Show user-friendly message instead of raw Firestore errors
      final msg = e.toString();
      if (msg.contains('failed-precondition') ||
          msg.contains('requires an index')) {
        AppSnackbar.error('admin.finance.index_required'.tr);
      } else {
        AppSnackbar.error('admin.finance.load_error'.tr);
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadSummary() async {
    summary.value = await FinancialService.getFinancialSummary(dateRange);
  }

  Future<void> _loadRevenueData() async {
    revenueData.value = await RevenueService.getRevenueByPeriod(dateRange);
  }

  Future<void> _loadCommissionBreakdown() async {
    commissionBreakdown.value =
        await CommissionService.getCommissionBreakdown(dateRange);
  }

  Future<void> _loadPaymentDistribution() async {
    paymentDistribution.value =
        await FinancialService.getPaymentMethodDistribution(dateRange);
  }

  Future<void> _loadRecentTransactions() async {
    recentTransactions.value =
        await AdminFirestoreService.getRecentTransactions();
  }

  void setDateRange(String period) {
    selectedPeriod.value = period;
    final now = DateTime.now();

    switch (period) {
      case 'today':
        startDate.value = DateTime(now.year, now.month, now.day);
        endDate.value = now;
      case 'last_7_days':
        startDate.value = now.subtract(const Duration(days: 7));
        endDate.value = now;
      case 'last_30_days':
        startDate.value = now.subtract(const Duration(days: 30));
        endDate.value = now;
      case 'this_month':
        startDate.value = DateTime(now.year, now.month);
        endDate.value = now;
    }

    loadAllData();
  }

  void setCustomDateRange(DateTimeRange range) {
    startDate.value = range.start;
    endDate.value = range.end;
    selectedPeriod.value = 'custom';
    loadAllData();
  }

  @override
  // ignore: unnecessary_overrides
  void onClose() {
    super.onClose();
  }

  Future<void> refreshData() async => loadAllData();
}
