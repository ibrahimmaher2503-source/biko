import 'package:biko/features/admin/models/finance/payment_success_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart' show DateTimeRange;

/// Service for payment analytics and success rate reporting.
class PaymentAnalyticsService {
  PaymentAnalyticsService._();

  static final _firestore = FirebaseFirestore.instance;

  /// Fetches payment success/failure report grouped by payment method
  /// for the given date range.
  static Future<List<PaymentSuccessModel>> getPaymentSuccessReport(
    DateTimeRange dateRange,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('payment_analytics')
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
            (doc) => PaymentSuccessModel.fromJson(
              doc.data(),
            ),
          )
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Fetches cash vs digital payment breakdown for the given date range.
  static Future<Map<String, dynamic>> getCashVsDigitalReport(
    DateTimeRange dateRange,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('transactions')
          .where('status', isEqualTo: 'completed')
          .where(
            'created_at',
            isGreaterThanOrEqualTo: Timestamp.fromDate(dateRange.start),
          )
          .where(
            'created_at',
            isLessThanOrEqualTo: Timestamp.fromDate(dateRange.end),
          )
          .get();

      double cashTotal = 0;
      int cashCount = 0;
      double digitalTotal = 0;
      int digitalCount = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
        final method = data['method'] as String? ?? '';

        if (method == 'cash') {
          cashTotal += amount;
          cashCount++;
        } else {
          digitalTotal += amount;
          digitalCount++;
        }
      }

      final totalCount = cashCount + digitalCount;

      return {
        'cash_total': cashTotal,
        'cash_count': cashCount,
        'cash_percentage':
            totalCount > 0 ? (cashCount / totalCount) * 100 : 0.0,
        'digital_total': digitalTotal,
        'digital_count': digitalCount,
        'digital_percentage':
            totalCount > 0 ? (digitalCount / totalCount) * 100 : 0.0,
        'total_count': totalCount,
        'total_amount': cashTotal + digitalTotal,
      };
    } catch (e) {
      rethrow;
    }
  }
}
