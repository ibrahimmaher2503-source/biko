import 'package:biko/features/admin/models/finance/driver_earnings_report_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart' show DateTimeRange;

/// Service for driver earnings queries and payout operations.
class DriverEarningsService {
  DriverEarningsService._();

  static final _firestore = FirebaseFirestore.instance;
  static final _functions = FirebaseFunctions.instance;

  /// Fetches earnings summary for all drivers within a date range.
  static Future<List<DriverEarningsReportModel>> getDriverEarningsSummary(
    DateTimeRange dateRange,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('driver_earnings')
          .where(
            'period_start',
            isGreaterThanOrEqualTo: Timestamp.fromDate(dateRange.start),
          )
          .where(
            'period_start',
            isLessThanOrEqualTo: Timestamp.fromDate(dateRange.end),
          )
          .orderBy('period_start', descending: true)
          .get();

      return snapshot.docs
          .map(
            (doc) => DriverEarningsReportModel.fromJson(
              doc.data(),
            ),
          )
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Fetches detailed earnings report for a specific driver.
  static Future<DriverEarningsReportModel> getDriverEarningsReport(
    String driverUid,
    DateTimeRange dateRange,
  ) async {
    try {
      final callable = _functions.httpsCallable('getDriverEarningsReport');
      final result = await callable.call<Map<String, dynamic>>({
        'driver_uid': driverUid,
        'start_date': dateRange.start.toIso8601String(),
        'end_date': dateRange.end.toIso8601String(),
      });

      return DriverEarningsReportModel.fromJson(
        result.data,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Processes a payout to a driver via Cloud Functions.
  /// Write operations on wallets/transactions MUST go through
  /// Cloud Functions -- never direct Firestore writes.
  static Future<void> processPayout(
    String driverUid,
    double amount,
    String method,
  ) async {
    try {
      final callable = _functions.httpsCallable('processDriverPayout');
      await callable.call<Map<String, dynamic>>({
        'driver_uid': driverUid,
        'amount': amount,
        'method': method,
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Adds a bonus to a driver via Cloud Functions.
  /// Write operations on wallets/transactions MUST go through
  /// Cloud Functions -- never direct Firestore writes.
  static Future<void> addBonus(
    String driverUid,
    double amount,
    String reason,
  ) async {
    try {
      final callable = _functions.httpsCallable('addDriverBonus');
      await callable.call<Map<String, dynamic>>({
        'driver_uid': driverUid,
        'amount': amount,
        'reason': reason,
      });
    } catch (e) {
      rethrow;
    }
  }
}
