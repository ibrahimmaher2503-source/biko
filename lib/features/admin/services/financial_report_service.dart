import 'package:biko/features/admin/models/finance/generated_report_model.dart';
import 'package:biko/features/admin/models/finance/scheduled_report_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart' show DateTimeRange;

/// Service for financial report generation, scheduling, and history.
class FinancialReportService {
  FinancialReportService._();

  static final _firestore = FirebaseFirestore.instance;
  static final _functions = FirebaseFunctions.instance;

  /// Generates a financial report via Cloud Functions and returns
  /// the created report model.
  static Future<GeneratedReportModel> generateReport(
    String type,
    DateTimeRange dateRange,
    String format,
  ) async {
    try {
      final callable = _functions.httpsCallable('generateFinancialReport');
      final result = await callable.call<Map<String, dynamic>>({
        'type': type,
        'start_date': dateRange.start.toIso8601String(),
        'end_date': dateRange.end.toIso8601String(),
        'format': format,
      });

      return GeneratedReportModel.fromJson(result.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Creates or updates a scheduled report configuration.
  static Future<void> scheduleReport(ScheduledReportModel schedule) async {
    try {
      final callable = _functions.httpsCallable('scheduleFinancialReport');
      await callable.call<Map<String, dynamic>>(schedule.toJson());
    } catch (e) {
      rethrow;
    }
  }

  /// Fetches the history of previously generated reports.
  static Future<List<GeneratedReportModel>> getReportHistory() async {
    try {
      final snapshot = await _firestore
          .collection('generated_reports')
          .orderBy('generated_at', descending: true)
          .limit(50)
          .get();

      return snapshot.docs
          .map(
            (doc) => GeneratedReportModel.fromJson({
              ...doc.data(),
              'id': doc.id,
            }),
          )
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Fetches all scheduled report configurations.
  static Future<List<ScheduledReportModel>> getScheduledReports() async {
    try {
      final snapshot = await _firestore
          .collection('scheduled_reports')
          .orderBy('report_type')
          .get();

      return snapshot.docs
          .map(
            (doc) => ScheduledReportModel.fromJson({
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
