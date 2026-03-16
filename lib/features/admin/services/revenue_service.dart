import 'package:biko/features/admin/models/finance/daily_revenue_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show DateTimeRange;

/// Service for querying and aggregating revenue data from completed trips.
class RevenueService {
  RevenueService._();

  static final _firestore = FirebaseFirestore.instance;

  /// Returns revenue grouped by day within [dateRange].
  ///
  /// The [period] parameter is reserved for future grouping modes
  /// (e.g. 'weekly', 'monthly'). Currently defaults to daily grouping.
  static Future<List<DailyRevenueModel>> getRevenueByPeriod(
    DateTimeRange dateRange, {
    String period = 'daily',
  }) async {
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
          .orderBy('completed_at')
          .get();

      final Map<String, Map<String, dynamic>> grouped = {};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final completedAt = data['completed_at'] is Timestamp
            ? (data['completed_at'] as Timestamp).toDate()
            : DateTime.now();

        final dayKey = _dayKey(completedAt, period);

        final tripType = data['type'] as String? ?? 'ride';
        final finalPrice =
            (data['accepted_price'] as num?)?.toDouble() ??
            (data['customer_price'] as num?)?.toDouble() ??
            0;
        final commission =
            (data['commission_amount'] as num?)?.toDouble() ?? 0;

        if (!grouped.containsKey(dayKey)) {
          grouped[dayKey] = {
            'date': DateTime(
              completedAt.year,
              completedAt.month,
              completedAt.day,
            ),
            'trip_revenue': 0.0,
            'delivery_revenue': 0.0,
            'total_revenue': 0.0,
            'commission': 0.0,
            'trip_count': 0,
          };
        }

        final entry = grouped[dayKey]!;
        entry['total_revenue'] =
            (entry['total_revenue'] as double) + finalPrice;
        entry['commission'] =
            (entry['commission'] as double) + commission;
        entry['trip_count'] = (entry['trip_count'] as int) + 1;

        if (tripType == 'ride') {
          entry['trip_revenue'] =
              (entry['trip_revenue'] as double) + finalPrice;
        } else {
          entry['delivery_revenue'] =
              (entry['delivery_revenue'] as double) + finalPrice;
        }
      }

      final results = grouped.values
          .map(DailyRevenueModel.fromJson)
          .toList();

      results.sort((a, b) => a.date.compareTo(b.date));
      return results;
    } catch (e, st) {
      debugPrint('RevenueService.getRevenueByPeriod error: $e\n$st');
      rethrow;
    }
  }

  /// Returns revenue broken down by service type within [dateRange].
  ///
  /// Keys: `ride`, `c2c_delivery`, `b2b_delivery`.
  static Future<Map<String, double>> getRevenueByServiceType(
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

      final result = <String, double>{
        'ride': 0,
        'c2c_delivery': 0,
        'b2b_delivery': 0,
      };

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final tripType = data['type'] as String? ?? 'ride';
        final finalPrice =
            (data['accepted_price'] as num?)?.toDouble() ??
            (data['customer_price'] as num?)?.toDouble() ??
            0;

        result[tripType] = (result[tripType] ?? 0) + finalPrice;
      }

      return result;
    } catch (e, st) {
      debugPrint(
        'RevenueService.getRevenueByServiceType error: $e\n$st',
      );
      rethrow;
    }
  }

  /// Returns a map of hour (0-23) to total revenue for that hour
  /// across all completed trips in [dateRange].
  static Future<Map<int, double>> getHourlyRevenuePattern(
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

      final result = <int, double>{
        for (int i = 0; i < 24; i++) i: 0,
      };

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final completedAt = data['completed_at'] is Timestamp
            ? (data['completed_at'] as Timestamp).toDate()
            : DateTime.now();
        final finalPrice =
            (data['accepted_price'] as num?)?.toDouble() ??
            (data['customer_price'] as num?)?.toDouble() ??
            0;

        final hour = completedAt.hour;
        result[hour] = (result[hour] ?? 0) + finalPrice;
      }

      return result;
    } catch (e, st) {
      debugPrint(
        'RevenueService.getHourlyRevenuePattern error: $e\n$st',
      );
      rethrow;
    }
  }

  /// Generates a day-key string for grouping.
  static String _dayKey(DateTime date, String period) {
    switch (period) {
      case 'weekly':
        // ISO week start (Monday)
        final monday = date.subtract(Duration(days: date.weekday - 1));
        return '${monday.year}-${monday.month.toString().padLeft(2, '0')}'
            '-${monday.day.toString().padLeft(2, '0')}';
      case 'monthly':
        return '${date.year}-${date.month.toString().padLeft(2, '0')}';
      default: // daily
        return '${date.year}-${date.month.toString().padLeft(2, '0')}'
            '-${date.day.toString().padLeft(2, '0')}';
    }
  }
}
