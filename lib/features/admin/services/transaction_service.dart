import 'package:biko/features/admin/models/finance/suspicious_transaction_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart' show DateTimeRange;

/// Service for transaction monitoring, search, and suspicious
/// transaction management.
class TransactionService {
  TransactionService._();

  static final _firestore = FirebaseFirestore.instance;
  static final _functions = FirebaseFunctions.instance;

  /// Returns a real-time stream of the most recent transactions.
  static Stream<List<Map<String, dynamic>>> getRecentTransactions() {
    return _firestore
        .collection('transactions')
        .orderBy('created_at', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => {
                  ...doc.data(),
                  'id': doc.id,
                },
              )
              .toList(),
        );
  }

  /// Searches transactions with optional filters.
  static Future<List<Map<String, dynamic>>> searchTransactions({
    String? query,
    String? type,
    String? status,
    DateTimeRange? dateRange,
    double? minAmount,
    double? maxAmount,
  }) async {
    try {
      Query q = _firestore
          .collection('transactions')
          .orderBy('created_at', descending: true);

      if (type != null) {
        q = q.where('type', isEqualTo: type);
      }

      if (status != null) {
        q = q.where('status', isEqualTo: status);
      }

      if (dateRange != null) {
        q = q
            .where(
              'created_at',
              isGreaterThanOrEqualTo: Timestamp.fromDate(dateRange.start),
            )
            .where(
              'created_at',
              isLessThanOrEqualTo: Timestamp.fromDate(dateRange.end),
            );
      }

      if (minAmount != null) {
        q = q.where('amount', isGreaterThanOrEqualTo: minAmount);
      }

      if (maxAmount != null) {
        q = q.where('amount', isLessThanOrEqualTo: maxAmount);
      }

      final snapshot = await q.limit(100).get();

      List<Map<String, dynamic>> results = snapshot.docs
          .map(
            (doc) => {
              ...doc.data() as Map<String, dynamic>,
              'id': doc.id,
            },
          )
          .toList();

      // Client-side text filter for query string since Firestore
      // does not support full-text search natively.
      if (query != null && query.isNotEmpty) {
        final lowerQuery = query.toLowerCase();
        results = results
            .where(
              (tx) =>
                  (tx['user_uid'] as String? ?? '')
                      .toLowerCase()
                      .contains(lowerQuery) ||
                  (tx['user_name'] as String? ?? '')
                      .toLowerCase()
                      .contains(lowerQuery) ||
                  (tx['id'] as String? ?? '')
                      .toLowerCase()
                      .contains(lowerQuery),
            )
            .toList();
      }

      return results;
    } catch (e) {
      rethrow;
    }
  }

  /// Flags a transaction as suspicious via Cloud Functions.
  static Future<void> flagSuspiciousTransaction(
    String transactionId,
    String reason,
  ) async {
    try {
      final callable = _functions.httpsCallable('flagSuspiciousTransaction');
      await callable.call<Map<String, dynamic>>({
        'transaction_id': transactionId,
        'reason': reason,
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Clears a suspicious flag from a transaction via Cloud Functions.
  static Future<void> clearSuspiciousFlag(String id) async {
    try {
      final callable = _functions.httpsCallable('clearSuspiciousFlag');
      await callable.call<Map<String, dynamic>>({
        'id': id,
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Fetches all transactions flagged as suspicious that are
  /// not yet reviewed.
  static Future<List<SuspiciousTransactionModel>>
      getSuspiciousTransactions() async {
    try {
      final snapshot = await _firestore
          .collection('suspicious_transactions')
          .where('is_reviewed', isEqualTo: false)
          .orderBy('flagged_at', descending: true)
          .get();

      return snapshot.docs
          .map(
            (doc) => SuspiciousTransactionModel.fromJson({
              ...doc.data(),
              'id': doc.id,
            }),
          )
          .toList();
    } catch (e) {
      rethrow;
    }
  }
}
