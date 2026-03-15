import 'package:biko/features/admin/models/finance/financial_summary_model.dart';
import 'package:biko/features/admin/models/finance/payment_stats_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show DateTimeRange;

/// Aggregates financial summary and payment method distribution data
/// from completed trips and transactions.
class FinancialService {
  FinancialService._();

  static final _firestore = FirebaseFirestore.instance;

  /// Fetches a financial summary for the given [dateRange].
  ///
  /// Aggregates completed trips for revenue/commission and transactions
  /// for top-ups/refunds. If [dateRange] is null, returns all-time data.
  static Future<FinancialSummaryModel> getFinancialSummary(
    DateTimeRange? dateRange,
  ) async {
    try {
      // --- completed trips ---
      Query tripsQuery = _firestore
          .collection('trips')
          .where('status', isEqualTo: 'completed');

      if (dateRange != null) {
        tripsQuery = tripsQuery
            .where(
              'completed_at',
              isGreaterThanOrEqualTo:
                  Timestamp.fromDate(dateRange.start),
            )
            .where(
              'completed_at',
              isLessThanOrEqualTo: Timestamp.fromDate(dateRange.end),
            );
      }

      final tripsSnapshot = await tripsQuery.get();

      double totalRevenue = 0;
      double totalCommission = 0;
      int completedTrips = 0;

      for (final doc in tripsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        final finalPrice =
            (data['accepted_price'] as num?)?.toDouble() ??
            (data['customer_price'] as num?)?.toDouble() ??
            0;
        final commission =
            (data['commission_amount'] as num?)?.toDouble() ?? 0;

        totalRevenue += finalPrice;
        totalCommission += commission;
        completedTrips++;
      }

      // --- cancelled trips count ---
      Query cancelledQuery = _firestore
          .collection('trips')
          .where('status', isEqualTo: 'cancelled');

      if (dateRange != null) {
        cancelledQuery = cancelledQuery
            .where(
              'cancelled_at',
              isGreaterThanOrEqualTo:
                  Timestamp.fromDate(dateRange.start),
            )
            .where(
              'cancelled_at',
              isLessThanOrEqualTo: Timestamp.fromDate(dateRange.end),
            );
      }

      final cancelledSnapshot = await cancelledQuery.count().get();
      final cancelledTrips = cancelledSnapshot.count ?? 0;

      // --- payout data ---
      Query payoutQuery = _firestore
          .collection('transactions')
          .where('type', isEqualTo: 'payout')
          .where('status', isEqualTo: 'completed');

      if (dateRange != null) {
        payoutQuery = payoutQuery
            .where(
              'created_at',
              isGreaterThanOrEqualTo:
                  Timestamp.fromDate(dateRange.start),
            )
            .where(
              'created_at',
              isLessThanOrEqualTo: Timestamp.fromDate(dateRange.end),
            );
      }

      final payoutSnapshot = await payoutQuery.get();
      double driverPayouts = 0;
      for (final doc in payoutSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        driverPayouts += (data['amount'] as num?)?.toDouble() ?? 0;
      }

      // --- pending payouts ---
      final pendingPayoutSnapshot = await _firestore
          .collection('transactions')
          .where('type', isEqualTo: 'payout')
          .where('status', isEqualTo: 'pending')
          .get();

      double pendingPayouts = 0;
      for (final doc in pendingPayoutSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        pendingPayouts += (data['amount'] as num?)?.toDouble() ?? 0;
      }

      // --- wallet totals ---
      final walletsSnapshot =
          await _firestore.collection('wallets').get();
      double totalWalletBalance = 0;
      for (final doc in walletsSnapshot.docs) {
        final data = doc.data();
        totalWalletBalance +=
            (data['balance'] as num?)?.toDouble() ?? 0;
      }

      final totalTrips = completedTrips + cancelledTrips;
      final cancellationRate =
          totalTrips > 0 ? (cancelledTrips / totalTrips * 100) : 0.0;
      final netProfit = totalCommission - driverPayouts;

      return FinancialSummaryModel(
        totalRevenue: totalRevenue,
        totalCommission: totalCommission,
        driverPayouts: driverPayouts,
        netProfit: netProfit,
        pendingPayouts: pendingPayouts,
        totalWalletBalance: totalWalletBalance,
        completedTrips: completedTrips,
        cancelledTrips: cancelledTrips,
        cancellationRate: cancellationRate,
      );
    } catch (e, st) {
      debugPrint('FinancialService.getFinancialSummary error: $e\n$st');
      rethrow;
    }
  }

  /// Returns payment method distribution for transactions in [dateRange].
  ///
  /// Groups completed transactions by their `method` field and
  /// calculates count, total amount, average, and percentage share.
  static Future<List<PaymentStatsModel>> getPaymentMethodDistribution(
    DateTimeRange? dateRange,
  ) async {
    try {
      Query query = _firestore
          .collection('transactions')
          .where('status', isEqualTo: 'completed');

      if (dateRange != null) {
        query = query
            .where(
              'created_at',
              isGreaterThanOrEqualTo:
                  Timestamp.fromDate(dateRange.start),
            )
            .where(
              'created_at',
              isLessThanOrEqualTo: Timestamp.fromDate(dateRange.end),
            );
      }

      final snapshot = await query.get();

      final Map<String, Map<String, dynamic>> grouped = {};
      double grandTotal = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        final method = data['method'] as String? ?? 'unknown';
        final amount = (data['amount'] as num?)?.toDouble() ?? 0;

        grandTotal += amount;

        if (!grouped.containsKey(method)) {
          grouped[method] = {
            'method': method,
            'count': 0,
            'total_amount': 0.0,
          };
        }

        grouped[method]!['count'] =
            (grouped[method]!['count'] as int) + 1;
        grouped[method]!['total_amount'] =
            (grouped[method]!['total_amount'] as double) + amount;
      }

      // Calculate percentages and averages
      final results = <PaymentStatsModel>[];
      for (final entry in grouped.values) {
        final count = entry['count'] as int;
        final totalAmount = entry['total_amount'] as double;
        final percentage =
            grandTotal > 0 ? (totalAmount / grandTotal * 100) : 0.0;
        final avgPerTransaction = count > 0 ? totalAmount / count : 0.0;

        results.add(
          PaymentStatsModel(
            method: entry['method'] as String,
            count: count,
            totalAmount: totalAmount,
            percentage: percentage,
            avgPerTransaction: avgPerTransaction,
          ),
        );
      }

      // Sort by total amount descending
      results.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
      return results;
    } catch (e, st) {
      debugPrint(
        'FinancialService.getPaymentMethodDistribution error: $e\n$st',
      );
      rethrow;
    }
  }
}
