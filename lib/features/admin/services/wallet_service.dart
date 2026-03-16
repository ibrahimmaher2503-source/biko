import 'package:biko/features/admin/models/finance/wallet_activity_model.dart';
import 'package:biko/features/admin/models/finance/wallet_summary_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart' show DateTimeRange;

/// Service for wallet overview queries and admin wallet adjustments.
class WalletService {
  WalletService._();

  static final _firestore = FirebaseFirestore.instance;
  static final _functions = FirebaseFunctions.instance;

  /// Fetches aggregated wallet summary across all users.
  ///
  /// Tries Cloud Function first; falls back to direct Firestore read
  /// when the function is unavailable (CORS / not deployed).
  static Future<WalletSummaryModel> getWalletSummary() async {
    try {
      final callable = _functions.httpsCallable('getWalletSummary');
      final result = await callable.call<Map<String, dynamic>>();

      return WalletSummaryModel.fromJson(result.data);
    } catch (_) {
      // Fallback: aggregate from Firestore wallets collection directly.
      return _getWalletSummaryFallback();
    }
  }

  /// Direct Firestore fallback for wallet summary (read-only).
  static Future<WalletSummaryModel> _getWalletSummaryFallback() async {
    double totalCustomerBalance = 0.0;
    double totalDriverBalance = 0.0;

    final walletsSnapshot = await _firestore.collection('wallets').get();
    for (final doc in walletsSnapshot.docs) {
      final data = doc.data();
      final balance = (data['balance'] as num?)?.toDouble() ?? 0.0;
      final userType = data['user_type'] as String?;

      if (userType == 'driver') {
        totalDriverBalance += balance;
      } else {
        totalCustomerBalance += balance;
      }
    }

    return WalletSummaryModel(
      totalCustomerBalance: totalCustomerBalance,
      totalDriverBalance: totalDriverBalance,
    );
  }

  /// Fetches wallet activity (transactions) with optional filters.
  static Future<List<WalletActivityModel>> getWalletActivity({
    String? userUid,
    String? type,
    DateTimeRange? dateRange,
  }) async {
    try {
      Query query = _firestore
          .collection('transactions')
          .orderBy('timestamp', descending: true);

      if (userUid != null) {
        query = query.where('user_uid', isEqualTo: userUid);
      }

      if (type != null) {
        query = query.where('type', isEqualTo: type);
      }

      if (dateRange != null) {
        query = query
            .where(
              'timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(dateRange.start),
            )
            .where(
              'timestamp',
              isLessThanOrEqualTo: Timestamp.fromDate(dateRange.end),
            );
      }

      final snapshot = await query.limit(100).get();

      return snapshot.docs
          .map(
            (doc) => WalletActivityModel.fromJson({
              ...doc.data() as Map<String, dynamic>,
              'id': doc.id,
            }),
          )
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Adjusts a user's wallet balance via Cloud Functions.
  /// Write operations on wallets/transactions MUST go through
  /// Cloud Functions -- never direct Firestore writes.
  static Future<void> adjustWallet(
    String userUid,
    double amount,
    String reason,
  ) async {
    try {
      final callable = _functions.httpsCallable('adjustWallet');
      await callable.call<Map<String, dynamic>>({
        'user_uid': userUid,
        'amount': amount,
        'reason': reason,
      });
    } catch (e) {
      rethrow;
    }
  }
}
