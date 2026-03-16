import 'package:biko/features/admin/models/finance/commission_breakdown_model.dart';
import 'package:biko/features/admin/models/finance/commission_rates_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show DateTimeRange;

/// Reads and updates commission configuration and provides commission
/// analytics from completed trips.
class CommissionService {
  CommissionService._();

  static final _firestore = FirebaseFirestore.instance;
  static final _functions = FirebaseFunctions.instance;

  /// Reads commission rates from the `app_config/config` document.
  static Future<CommissionRatesModel> getCommissionRates() async {
    try {
      final doc =
          await _firestore.collection('app_config').doc('config').get();

      if (!doc.exists || doc.data() == null) {
        debugPrint(
          'CommissionService.getCommissionRates: '
          'app_config/config not found, returning defaults',
        );
        return const CommissionRatesModel();
      }

      final data = doc.data()!;
      final commissionData =
          data['commission'] as Map<String, dynamic>? ?? data;

      return CommissionRatesModel.fromJson(commissionData);
    } catch (e, st) {
      debugPrint(
        'CommissionService.getCommissionRates error: $e\n$st',
      );
      rethrow;
    }
  }

  /// Updates commission rates via the `updateAppConfig` Cloud Function.
  ///
  /// Never writes directly to Firestore -- delegates to Cloud Functions
  /// to ensure validation and audit logging.
  static Future<void> updateCommissionRates(
    CommissionRatesModel rates,
  ) async {
    try {
      final callable = _functions.httpsCallable('updateAppConfig');
      await callable.call<dynamic>({
        'section': 'commission',
        'data': rates.toJson(),
      });
    } catch (e, st) {
      debugPrint(
        'CommissionService.updateCommissionRates error: $e\n$st',
      );
      rethrow;
    }
  }

  /// Calculates commission breakdown by trip type for the given
  /// [dateRange].
  static Future<CommissionBreakdownModel> getCommissionBreakdown(
    DateTimeRange dateRange,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('trips')
          .where('status', isEqualTo: 'completed')
          .where(
            'completed_at',
            isGreaterThanOrEqualTo:
                Timestamp.fromDate(dateRange.start),
          )
          .where(
            'completed_at',
            isLessThanOrEqualTo: Timestamp.fromDate(dateRange.end),
          )
          .get();

      double rideCommission = 0;
      double c2cCommission = 0;
      double b2bCommission = 0;
      double rideFare = 0;
      double c2cFare = 0;
      double b2bFare = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final tripType = data['type'] as String? ?? 'ride';
        final commission =
            (data['commission_amount'] as num?)?.toDouble() ?? 0;
        final finalPrice =
            (data['accepted_price'] as num?)?.toDouble() ??
            (data['customer_price'] as num?)?.toDouble() ??
            0;

        switch (tripType) {
          case 'ride':
            rideCommission += commission;
            rideFare += finalPrice;
          case 'c2c_delivery':
            c2cCommission += commission;
            c2cFare += finalPrice;
          case 'b2b_delivery':
            b2bCommission += commission;
            b2bFare += finalPrice;
        }
      }

      final totalCommission =
          rideCommission + c2cCommission + b2bCommission;

      return CommissionBreakdownModel(
        rideCommission: rideCommission,
        c2cCommission: c2cCommission,
        b2bCommission: b2bCommission,
        totalCommission: totalCommission,
        rideRate: rideFare > 0 ? (rideCommission / rideFare * 100) : 0,
        c2cRate: c2cFare > 0 ? (c2cCommission / c2cFare * 100) : 0,
        b2bRate: b2bFare > 0 ? (b2bCommission / b2bFare * 100) : 0,
      );
    } catch (e, st) {
      debugPrint(
        'CommissionService.getCommissionBreakdown error: $e\n$st',
      );
      rethrow;
    }
  }

  /// Returns per-driver commission collected vs pending for the
  /// given [dateRange].
  ///
  /// Each map entry contains: `driver_uid`, `driver_name`,
  /// `commission_collected`, `commission_pending`, `trip_count`.
  static Future<List<Map<String, dynamic>>> getCommissionCollection(
    DateTimeRange dateRange,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('trips')
          .where('status', isEqualTo: 'completed')
          .where(
            'completed_at',
            isGreaterThanOrEqualTo:
                Timestamp.fromDate(dateRange.start),
          )
          .where(
            'completed_at',
            isLessThanOrEqualTo: Timestamp.fromDate(dateRange.end),
          )
          .limit(1000)
          .get();

      final Map<String, Map<String, dynamic>> byDriver = {};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final driverUid = data['driver_uid'] as String? ?? '';
        if (driverUid.isEmpty) continue;

        final commission =
            (data['commission_amount'] as num?)?.toDouble() ?? 0;
        final commissionStatus =
            data['commission_status'] as String? ?? 'collected';

        if (!byDriver.containsKey(driverUid)) {
          byDriver[driverUid] = {
            'driver_uid': driverUid,
            'driver_name': data['driver_name'] as String? ?? '',
            'commission_collected': 0.0,
            'commission_pending': 0.0,
            'trip_count': 0,
          };
        }

        final entry = byDriver[driverUid]!;
        entry['trip_count'] = (entry['trip_count'] as int) + 1;

        if (commissionStatus == 'pending') {
          entry['commission_pending'] =
              (entry['commission_pending'] as double) + commission;
        } else {
          entry['commission_collected'] =
              (entry['commission_collected'] as double) + commission;
        }
      }

      final results = byDriver.values.toList();
      results.sort(
        (a, b) => (b['commission_collected'] as double)
            .compareTo(a['commission_collected'] as double),
      );

      return results;
    } catch (e, st) {
      debugPrint(
        'CommissionService.getCommissionCollection error: $e\n$st',
      );
      rethrow;
    }
  }
}
