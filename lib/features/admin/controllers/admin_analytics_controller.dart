import 'dart:convert';

import 'package:biko/core/services/web_download.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/app_snackbar.dart';
import '../models/chart_data_point.dart';

class AdminAnalyticsController extends GetxController {
  final _firestore = FirebaseFirestore.instance;

  final selectedPeriod = 30.obs;
  final tripVolumeData = <ChartDataPoint>[].obs;
  final paymentBreakdown = <String, double>{}.obs;
  final cancellationTrend = <ChartDataPoint>[].obs;
  final topDrivers = <Map<String, dynamic>>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadAllCharts(30);
  }

  Future<void> loadAllCharts(int period) async {
    selectedPeriod.value = period;
    isLoading.value = true;

    try {
      await Future.wait([
        _loadTripVolumeData(period),
        _loadPaymentBreakdown(period),
        _loadCancellationTrend(period),
        _loadTopDrivers(period),
      ]);
    } catch (e) {
      AppSnackbar.error('admin.analytics.load_failed'.tr);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadTripVolumeData(int period) async {
    try {
      final startDate = DateTime.now().subtract(Duration(days: period));
      final snapshot = await _firestore
          .collection('trips')
          .where(
            'created_at',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          )
          .get();

      // Group trips by date and type
      final Map<String, Map<String, int>> groupedData = {};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final createdAt = (data['created_at'] as Timestamp).toDate();
        final dateKey = DateFormat('yyyy-MM-dd').format(createdAt);
        final tripType = data['type'] as String? ?? 'ride';

        if (!groupedData.containsKey(dateKey)) {
          groupedData[dateKey] = {
            'ride': 0,
            'c2c_delivery': 0,
            'b2b_delivery': 0,
          };
        }

        groupedData[dateKey]![tripType] =
            (groupedData[dateKey]![tripType] ?? 0) + 1;
      }

      // Convert to chart data points
      final List<ChartDataPoint> volumeData = [];
      final sortedDates = groupedData.keys.toList()..sort();

      for (final dateKey in sortedDates) {
        final counts = groupedData[dateKey]!;
        volumeData.add(
          ChartDataPoint(
            date: DateTime.parse(dateKey),
            label: dateKey,
            value:
                (counts['ride']! +
                        counts['c2c_delivery']! +
                        counts['b2b_delivery']!)
                    .toDouble(),
            extraData: {
              'ride': counts['ride']!.toDouble(),
              'c2c_delivery': counts['c2c_delivery']!.toDouble(),
              'b2b_delivery': counts['b2b_delivery']!.toDouble(),
            },
          ),
        );
      }

      tripVolumeData.value = volumeData;
    } catch (e) {
      AppSnackbar.error('admin.analytics.trip_volume_failed'.tr);
    }
  }

  Future<void> _loadPaymentBreakdown(int period) async {
    try {
      final startDate = DateTime.now().subtract(Duration(days: period));
      final snapshot = await _firestore
          .collection('trips')
          .where(
            'created_at',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          )
          .where('status', isEqualTo: 'completed')
          .get();

      final Map<String, double> breakdown = {
        'cash': 0.0,
        'wallet': 0.0,
        'card': 0.0,
        'vodafone_cash': 0.0,
        'fawry': 0.0,
      };

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final method = data['payment_method'] as String? ?? 'cash';
        final amount = (data['final_price'] as num?)?.toDouble() ?? 0.0;
        breakdown[method] = (breakdown[method] ?? 0.0) + amount;
      }

      paymentBreakdown.value = breakdown;
    } catch (e) {
      AppSnackbar.error('admin.analytics.payment_breakdown_failed'.tr);
    }
  }

  Future<void> _loadCancellationTrend(int period) async {
    try {
      final startDate = DateTime.now().subtract(Duration(days: period));
      final snapshot = await _firestore
          .collection('trips')
          .where(
            'created_at',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          )
          .get();

      // Group by date
      final Map<String, Map<String, int>> groupedData = {};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final createdAt = (data['created_at'] as Timestamp).toDate();
        final dateKey = DateFormat('yyyy-MM-dd').format(createdAt);
        final status = data['status'] as String? ?? 'completed';

        if (!groupedData.containsKey(dateKey)) {
          groupedData[dateKey] = {'total': 0, 'cancelled': 0};
        }

        groupedData[dateKey]!['total'] =
            (groupedData[dateKey]!['total'] ?? 0) + 1;
        if (status == 'cancelled') {
          groupedData[dateKey]!['cancelled'] =
              (groupedData[dateKey]!['cancelled'] ?? 0) + 1;
        }
      }

      // Calculate cancellation rate
      final List<ChartDataPoint> trendData = [];
      final sortedDates = groupedData.keys.toList()..sort();

      for (final dateKey in sortedDates) {
        final counts = groupedData[dateKey]!;
        final total = counts['total']!;
        final cancelled = counts['cancelled']!;
        final rate = total > 0 ? (cancelled / total) * 100 : 0.0;

        trendData.add(
          ChartDataPoint(
            date: DateTime.parse(dateKey),
            label: dateKey,
            value: rate,
          ),
        );
      }

      cancellationTrend.value = trendData;
    } catch (e) {
      AppSnackbar.error('admin.analytics.cancellation_trend_failed'.tr);
    }
  }

  Future<void> _loadTopDrivers(int period) async {
    try {
      final startDate = DateTime.now().subtract(Duration(days: period));
      final snapshot = await _firestore
          .collection('trips')
          .where(
            'created_at',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          )
          .where('status', isEqualTo: 'completed')
          .get();

      // Aggregate by driver
      final Map<String, Map<String, dynamic>> driverStats = {};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final driverUid = data['driver_uid'] as String?;
        if (driverUid == null) continue;

        if (!driverStats.containsKey(driverUid)) {
          driverStats[driverUid] = {
            'uid': driverUid,
            'trips': 0,
            'earnings': 0.0,
            'name': '',
          };
        }

        driverStats[driverUid]!['trips'] =
            (driverStats[driverUid]!['trips'] as int) + 1;
        final finalPrice = (data['final_price'] as num?)?.toDouble() ?? 0.0;
        final commission =
            (data['commission_amount'] as num?)?.toDouble() ?? 0.0;
        driverStats[driverUid]!['earnings'] =
            (driverStats[driverUid]!['earnings'] as double) +
            (finalPrice - commission);
      }

      // Fetch driver details
      final List<Map<String, dynamic>> driversWithDetails = [];
      for (final driverUid in driverStats.keys) {
        final userDoc = await _firestore
            .collection('users')
            .doc(driverUid)
            .get();
        final driverDoc = await _firestore
            .collection('driver_profiles')
            .doc(driverUid)
            .get();

        if (userDoc.exists && driverDoc.exists) {
          final userData = userDoc.data()!;
          final driverData = driverDoc.data()!;

          driversWithDetails.add({
            'uid': driverUid,
            'name': userData['name'] ?? 'Unknown',
            'trips': driverStats[driverUid]!['trips'],
            'earnings': driverStats[driverUid]!['earnings'],
            'rating': (driverData['rating_avg'] as num?)?.toDouble() ?? 0.0,
          });
        }
      }

      // Sort by trips (descending) and take top 10
      driversWithDetails.sort(
        (a, b) => (b['trips'] as int).compareTo(a['trips'] as int),
      );
      topDrivers.value = driversWithDetails.take(10).toList();
    } catch (e) {
      AppSnackbar.error('admin.analytics.top_drivers_failed'.tr);
    }
  }

  @override
  // ignore: unnecessary_overrides
  void onClose() {
    super.onClose();
  }

  void exportReport() {
    try {
      final List<List<dynamic>> csvData = [];

      // Add header
      csvData.add([
        'Report Type',
        'Period (Days)',
        'Generated At',
        DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
      ]);
      csvData.add([]);

      // Trip Volume Data
      csvData.add(['Trip Volume by Date']);
      csvData.add([
        'Date',
        'Total Trips',
        'Ride',
        'C2C Delivery',
        'B2B Delivery',
      ]);
      for (final point in tripVolumeData) {
        csvData.add([
          point.label,
          point.value,
          point.extraData?['ride'] ?? 0,
          point.extraData?['c2c_delivery'] ?? 0,
          point.extraData?['b2b_delivery'] ?? 0,
        ]);
      }
      csvData.add([]);

      // Payment Breakdown
      csvData.add(['Payment Method Breakdown']);
      csvData.add(['Method', 'Total Amount (EGP)']);
      paymentBreakdown.forEach((method, amount) {
        csvData.add([method, amount]);
      });
      csvData.add([]);

      // Cancellation Trend
      csvData.add(['Cancellation Rate Trend']);
      csvData.add(['Date', 'Cancellation Rate (%)']);
      for (final point in cancellationTrend) {
        csvData.add([point.label, point.value]);
      }
      csvData.add([]);

      // Top Drivers
      csvData.add(['Top 10 Drivers']);
      csvData.add(['Rank', 'Name', 'Trips', 'Earnings (EGP)', 'Rating']);
      for (int i = 0; i < topDrivers.length; i++) {
        final driver = topDrivers[i];
        csvData.add([
          i + 1,
          driver['name'],
          driver['trips'],
          driver['earnings'],
          driver['rating'],
        ]);
      }

      // Convert to CSV string
      final csvString = csvData.map((row) => row.join(',')).join('\n');

      // Create blob and trigger download
      final bytes = utf8.encode(csvString);
      downloadFileAsBlob(
        bytes,
        'analytics_report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv',
      );

      AppSnackbar.success('admin.analytics.report_exported'.tr);
    } catch (e) {
      AppSnackbar.error('admin.analytics.export_failed'.tr);
    }
  }
}
