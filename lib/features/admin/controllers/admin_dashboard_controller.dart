import 'dart:async';

import 'package:biko/core/models/trip_model.dart';
import 'package:biko/core/widgets/app_snackbar.dart';
import 'package:biko/features/admin/models/chart_data_point.dart';
import 'package:biko/features/admin/models/dashboard_stats_model.dart';
import 'package:biko/features/admin/services/admin_firestore_service.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class AdminDashboardController extends GetxController {
  final stats = DashboardStatsModel().obs;
  final revenueChartData = <ChartDataPoint>[].obs;
  final recentTrips = <TripModel>[].obs;
  final isLoading = false.obs;

  /// RTDB subscription for live driver count — cancelled in [onClose].
  StreamSubscription<int>? _driversOnlineSub;

  @override
  void onInit() {
    super.onInit();
    loadDashboard();
  }

  @override
  void onClose() {
    _driversOnlineSub?.cancel();
    super.onClose();
  }

  Future<void> loadDashboard() async {
    isLoading.value = true;
    try {
      await Future.wait([_loadStats(), loadRevenueChart(), loadRecentTrips()]);
    } catch (e, stack) {
      debugPrint('loadDashboard error: $e\n$stack');
      AppSnackbar.error('admin.dashboard.load_error'.tr);
    } finally {
      isLoading.value = false;
    }
  }

  /// Callable refresh action (does not shadow [GetxController.refresh]).
  Future<void> refreshDashboard() async {
    await loadDashboard();
  }

  Future<void> _loadStats() async {
    try {
      final now = DateTime.now();
      final weekStart =
          DateTime(now.year, now.month, now.day).subtract(
            const Duration(days: 7),
          );

      // Trips today
      final tripsToday = await AdminFirestoreService.getTripsTodayCount();

      // Revenue today (commission)
      final revenueToday = await AdminFirestoreService.getRevenueTodaySum();

      // Pending reviews (documents with status = 'pending')
      final pendingReviews =
          await AdminFirestoreService.getPendingDocumentsCount();

      // Total customers
      final totalCustomers =
          await AdminFirestoreService.getUserCountByType('customer');

      // Total drivers
      final totalDrivers =
          await AdminFirestoreService.getUserCountByType('driver');

      // Weekly trips data
      final weeklyTripsData =
          await AdminFirestoreService.getTripsSince(weekStart);
      final weeklyTrips = weeklyTripsData.length;

      // Weekly commission revenue
      double weeklyRevenue = 0.0;
      for (final data in weeklyTripsData) {
        if (data['status'] == 'completed') {
          weeklyRevenue +=
              (data['commission_amount'] as num?)?.toDouble() ?? 0.0;
        }
      }

      // Cancellation rate (last 100 trips)
      final cancellationRate = await AdminFirestoreService.getCancellationRate();

      // Listen to drivers online from Realtime DB
      _listenToDriversOnline();

      stats.value = DashboardStatsModel(
        tripsToday: tripsToday,
        revenueToday: revenueToday,
        driversOnline: stats.value.driversOnline,
        pendingReviews: pendingReviews,
        totalCustomers: totalCustomers,
        totalDrivers: totalDrivers,
        weeklyTrips: weeklyTrips,
        weeklyRevenue: weeklyRevenue,
        cancellationRate: cancellationRate,
      );
    } catch (e, stack) {
      debugPrint('_loadStats error: $e\n$stack');
      AppSnackbar.error('admin.dashboard.stats_error'.tr);
    }
  }

  void _listenToDriversOnline() {
    // Cancel previous subscription to avoid duplicates
    _driversOnlineSub?.cancel();

    _driversOnlineSub =
        AdminFirestoreService.onlineDriversStream().listen((onlineCount) {
      stats.value = stats.value.copyWith(driversOnline: onlineCount);
    });
  }

  Future<void> loadRevenueChart() async {
    try {
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));

      // Get all completed trips in last 30 days
      final tripsData = await AdminFirestoreService.getCompletedTripsInRange(
        thirtyDaysAgo,
        now,
      );

      // Aggregate by day
      final Map<String, double> dailyRevenue = {};

      for (final data in tripsData) {
        final completedAt = AdminFirestoreService.timestampToDateTime(
          data['completed_at'],
        );
        final commissionAmount =
            (data['commission_amount'] as num?)?.toDouble() ?? 0.0;

        if (completedAt != null) {
          final dateKey = DateTime(
            completedAt.year,
            completedAt.month,
            completedAt.day,
          ).toIso8601String().split('T')[0];

          dailyRevenue[dateKey] =
              (dailyRevenue[dateKey] ?? 0.0) + commissionAmount;
        }
      }

      // Convert to chart data points
      final chartData = <ChartDataPoint>[];
      for (int i = 29; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final dateKey = DateTime(
          date.year,
          date.month,
          date.day,
        ).toIso8601String().split('T')[0];

        chartData.add(
          ChartDataPoint(date: date, value: dailyRevenue[dateKey] ?? 0.0),
        );
      }

      revenueChartData.value = chartData;
    } catch (e) {
      AppSnackbar.error('admin.dashboard.chart_error'.tr);
    }
  }

  Future<void> loadRecentTrips() async {
    try {
      recentTrips.value = await AdminFirestoreService.getRecentTrips();
    } catch (e) {
      AppSnackbar.error('admin.dashboard.trips_error'.tr);
    }
  }
}
