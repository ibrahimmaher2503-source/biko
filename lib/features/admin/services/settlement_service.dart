import 'package:biko/features/admin/models/finance/driver_settlement_model.dart';
import 'package:biko/features/admin/models/finance/settlement_record_model.dart';
import 'package:biko/features/admin/models/finance/settlement_summary_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

/// Service for driver settlement operations including summary,
/// driver listing, history, and batch settlement processing.
class SettlementService {
  SettlementService._();

  static final _firestore = FirebaseFirestore.instance;
  static final _functions = FirebaseFunctions.instance;

  /// Fetches the current settlement summary (counts, totals).
  static Future<SettlementSummaryModel> getSettlementSummary() async {
    try {
      final snapshot = await _firestore
          .collection('settlements')
          .doc('summary')
          .get();

      if (!snapshot.exists || snapshot.data() == null) {
        return const SettlementSummaryModel();
      }

      return SettlementSummaryModel.fromJson(snapshot.data()!);
    } catch (e, st) {
      debugPrint('SettlementService.getSettlementSummary error: $e\n$st');
      rethrow;
    }
  }

  /// Fetches the list of drivers with pending settlement amounts.
  static Future<List<DriverSettlementModel>> getDriversForSettlement() async {
    try {
      final snapshot = await _firestore
          .collection('driver_settlements')
          .where('status', isEqualTo: 'pending')
          .orderBy('pending_amount', descending: true)
          .get();

      return snapshot.docs
          .map(
            (doc) => DriverSettlementModel.fromJson({
              ...doc.data(),
              'driver_uid': doc.id,
            }),
          )
          .toList();
    } catch (e, st) {
      debugPrint(
        'SettlementService.getDriversForSettlement error: $e\n$st',
      );
      rethrow;
    }
  }

  /// Fetches the history of completed settlement batches.
  static Future<List<SettlementRecordModel>> getSettlementHistory() async {
    try {
      final snapshot = await _firestore
          .collection('settlement_history')
          .orderBy('processed_at', descending: true)
          .limit(50)
          .get();

      return snapshot.docs
          .map(
            (doc) => SettlementRecordModel.fromJson({
              ...doc.data(),
              'id': doc.id,
            }),
          )
          .toList();
    } catch (e, st) {
      debugPrint(
        'SettlementService.getSettlementHistory error: $e\n$st',
      );
      rethrow;
    }
  }

  /// Processes settlements for the selected drivers via Cloud Functions.
  /// Write operations on wallets/transactions MUST go through
  /// Cloud Functions -- never direct Firestore writes.
  static Future<void> processSettlement(List<String> driverUids) async {
    try {
      final callable = _functions.httpsCallable('processSettlement');
      final result = await callable.call<Map<String, dynamic>>({
        'driver_uids': driverUids,
      });

      final data = result.data;
      if (data['success'] == false) {
        final errorMessage =
            data['error'] as String? ?? 'Settlement processing failed';
        throw Exception(errorMessage);
      }
    } catch (e, st) {
      debugPrint('SettlementService.processSettlement error: $e\n$st');
      rethrow;
    }
  }
}
