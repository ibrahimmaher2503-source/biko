import 'dart:async';

import 'package:biko/core/models/trip_model.dart';
import 'package:biko/core/widgets/app_snackbar.dart';
import 'package:biko/features/admin/models/chart_data_point.dart';
import 'package:biko/features/admin/models/dashboard_stats_model.dart';
import 'package:biko/features/admin/services/admin_firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class AdminDashboardController extends GetxController {
  final stats = DashboardStatsModel().obs;
  final revenueChartData = <ChartDataPoint>[].obs;
  final recentTrips = <TripModel>[].obs;
  final isLoading = false.obs;

  final _firestore = FirebaseFirestore.instance;
  final _realtimeDb = FirebaseDatabase.instance;

  /// RTDB subscription for live driver count — cancelled in [onClose].
  StreamSubscription<DatabaseEvent>? _driversOnlineSub;

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
      final weekStartTimestamp = Timestamp.fromDate(weekStart);

      // Trips today
      final tripsToday = await AdminFirestoreService.getTripsTodayCount();

      // Revenue today (commission)
      final revenueToday = await AdminFirestoreService.getRevenueTodaySum();

      // Pending reviews (documents with status = 'pending')
      final pendingDocsSnapshot = await _firestore
          .collection('documents')
          .where('status', isEqualTo: 'pending')
          .get();
      final pendingReviews = pendingDocsSnapshot.docs.length;

      // Total customers
      final customersSnapshot = await _firestore
          .collection('users')
          .where('type', isEqualTo: 'customer')
          .count()
          .get();
      final totalCustomers = customersSnapshot.count ?? 0;

      // Total drivers
      final driversSnapshot = await _firestore
          .collection('users')
          .where('type', isEqualTo: 'driver')
          .count()
          .get();
      final totalDrivers = driversSnapshot.count ?? 0;

      // Weekly trips
      final weeklyTripsSnapshot = await _firestore
          .collection('trips')
          .where('created_at', isGreaterThanOrEqualTo: weekStartTimestamp)
          .get();
      final weeklyTrips = weeklyTripsSnapshot.docs.length;

      // Weekly commission revenue
      double weeklyRevenue = 0.0;
      for (final doc in weeklyTripsSnapshot.docs) {
        final data = doc.data();
        if (data['status'] == 'completed') {
          weeklyRevenue +=
              (data['commission_amount'] as num?)?.toDouble() ?? 0.0;
        }
      }

      // Cancellation rate (last 100 trips)
      final last100TripsSnapshot = await _firestore
          .collection('trips')
          .orderBy('created_at', descending: true)
          .limit(100)
          .get();

      int cancelledCount = 0;
      final int totalCount = last100TripsSnapshot.docs.length;
      for (final doc in last100TripsSnapshot.docs) {
        if (doc.data()['status'] == 'cancelled') {
          cancelledCount++;
        }
      }
      final cancellationRate =
          totalCount > 0 ? (cancelledCount / totalCount) * 100 : 0.0;

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

    final ref = _realtimeDb.ref('driver_locations');
    _driversOnlineSub = ref.onValue.listen((event) {
      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        int onlineCount = 0;

        data.forEach((key, value) {
          if (value is Map && value['is_online'] == true) {
            // Check if updated within last 5 minutes
            final updatedAt = value['updated_at'] as int?;
            if (updatedAt != null) {
              final lastUpdate =
                  DateTime.fromMillisecondsSinceEpoch(updatedAt);
              final diff = DateTime.now().difference(lastUpdate);
              if (diff.inMinutes < 5) {
                onlineCount++;
              }
            }
          }
        });

        stats.value = stats.value.copyWith(driversOnline: onlineCount);
      }
    });
  }

  Future<void> loadRevenueChart() async {
    try {
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));
      final thirtyDaysAgoTimestamp = Timestamp.fromDate(thirtyDaysAgo);

      // Get all completed trips in last 30 days
      final tripsSnapshot = await _firestore
          .collection('trips')
          .where('status', isEqualTo: 'completed')
          .where(
            'completed_at',
            isGreaterThanOrEqualTo: thirtyDaysAgoTimestamp,
          )
          .orderBy('completed_at')
          .get();

      // Aggregate by day
      final Map<String, double> dailyRevenue = {};

      for (final doc in tripsSnapshot.docs) {
        final data = doc.data();
        final completedAt = (data['completed_at'] as Timestamp?)?.toDate();
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
      final tripsSnapshot = await _firestore
          .collection('trips')
          .orderBy('created_at', descending: true)
          .limit(10)
          .get();

      recentTrips.value = tripsSnapshot.docs
          .map((doc) => TripModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      AppSnackbar.error('admin.dashboard.trips_error'.tr);
    }
  }
}
