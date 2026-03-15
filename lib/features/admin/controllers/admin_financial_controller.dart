import 'dart:convert';

import 'package:biko/core/services/web_download.dart';
import 'package:biko/features/admin/models/financial_summary_model.dart';
import 'package:biko/features/admin/services/admin_firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AdminFinancialController extends GetxController {
  final summary = Rx<FinancialReportModel?>(null);
  final transactions = <Map<String, dynamic>>[].obs;
  final commissionBreakdown = <Map<String, dynamic>>[].obs;

  final dateRange = Rx<DateTimeRange?>(null);
  final paymentMethodFilter = RxnString();
  final transactionTypeFilter = RxnString();

  final isLoading = false.obs;
  final hasMore = true.obs;
  final currentPage = 1.obs;
  DocumentSnapshot? lastDocument;

  @override
  void onInit() {
    super.onInit();
    // Set default date range to last 30 days
    final now = DateTime.now();
    dateRange.value = DateTimeRange(
      start: now.subtract(const Duration(days: 30)),
      end: now,
    );
    loadSummary(dateRange.value!);
    loadTransactions();
    loadCommissionBreakdown(dateRange.value!);
  }

  Future<void> loadSummary(DateTimeRange range) async {
    try {
      isLoading.value = true;

      final tripsQuery = FirebaseFirestore.instance
          .collection('trips')
          .where('status', isEqualTo: 'completed')
          .where('completed_at', isGreaterThanOrEqualTo: range.start)
          .where('completed_at', isLessThanOrEqualTo: range.end);

      final transactionsQuery = FirebaseFirestore.instance
          .collection('transactions')
          .where('created_at', isGreaterThanOrEqualTo: range.start)
          .where('created_at', isLessThanOrEqualTo: range.end);

      final tripsSnapshot = await tripsQuery.get();
      final transactionsSnapshot = await transactionsQuery.get();

      double totalRevenue = 0.0;
      double totalCommission = 0.0;
      double totalTopUps = 0.0;
      double totalRefunds = 0.0;

      // Calculate from completed trips
      for (final doc in tripsSnapshot.docs) {
        final data = doc.data();
        final finalPrice = (data['final_price'] ?? 0.0).toDouble();
        final commission = (data['commission_amount'] ?? 0.0).toDouble();
        totalRevenue += finalPrice;
        totalCommission += commission;
      }

      // Calculate from transactions
      for (final doc in transactionsSnapshot.docs) {
        final data = doc.data();
        final type = data['type'] as String?;
        final amount = (data['amount'] ?? 0.0).toDouble();
        final status = data['status'] as String?;

        if (status == 'completed') {
          if (type == 'top_up' || type == 'credit') {
            totalTopUps += amount;
          } else if (type == 'refund') {
            totalRefunds += amount;
          }
        }
      }

      summary.value = FinancialReportModel(
        totalRevenue: totalRevenue,
        totalCommission: totalCommission,
        totalTopUps: totalTopUps,
        totalRefunds: totalRefunds,
        dateFrom: range.start,
        dateTo: range.end,
      );
    } catch (e) {
      Get.snackbar(
        'admin.financial.error'.tr,
        'admin.financial.load_summary_error'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadTransactions({bool loadMore = false}) async {
    if (isLoading.value || (!loadMore && transactions.isNotEmpty)) return;
    if (loadMore && !hasMore.value) return;

    try {
      isLoading.value = true;

      if (!loadMore) {
        transactions.clear();
        lastDocument = null;
        currentPage.value = 1;
        hasMore.value = true;
      }

      final result = await AdminFirestoreService.getPaginatedTransactions(
        methodFilter: paymentMethodFilter.value,
        typeFilter: transactionTypeFilter.value,
        dateRange: dateRange.value,
        startAfter: lastDocument,
        pageSize: 20,
      );

      final newTransactions = result.items;
      transactions.addAll(newTransactions);
      lastDocument = result.lastDocument;
      hasMore.value = result.hasMore;
      if (loadMore) currentPage.value++;
    } catch (e) {
      Get.snackbar(
        'admin.financial.error'.tr,
        'admin.financial.load_transactions_error'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadCommissionBreakdown(DateTimeRange range) async {
    try {
      final tripsQuery = FirebaseFirestore.instance
          .collection('trips')
          .where('status', isEqualTo: 'completed')
          .where('completed_at', isGreaterThanOrEqualTo: range.start)
          .where('completed_at', isLessThanOrEqualTo: range.end);

      final snapshot = await tripsQuery.get();

      final Map<String, Map<String, dynamic>> breakdown = {};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final type = data['type'] as String? ?? 'ride';
        final finalPrice = (data['final_price'] ?? 0.0).toDouble();
        final commission = (data['commission_amount'] ?? 0.0).toDouble();

        if (!breakdown.containsKey(type)) {
          breakdown[type] = {
            'type': type,
            'tripCount': 0,
            'totalFare': 0.0,
            'commissionEarned': 0.0,
          };
        }

        breakdown[type]!['tripCount'] =
            (breakdown[type]!['tripCount'] as int) + 1;
        breakdown[type]!['totalFare'] =
            (breakdown[type]!['totalFare'] as double) + finalPrice;
        breakdown[type]!['commissionEarned'] =
            (breakdown[type]!['commissionEarned'] as double) + commission;
      }

      // Calculate commission rate for each type
      for (final entry in breakdown.values) {
        final totalFare = entry['totalFare'] as double;
        final commissionEarned = entry['commissionEarned'] as double;
        entry['commissionRate'] = totalFare > 0
            ? (commissionEarned / totalFare * 100)
            : 0.0;
      }

      commissionBreakdown.value = breakdown.values.toList();
    } catch (e) {
      Get.snackbar(
        'admin.financial.error'.tr,
        'admin.financial.load_breakdown_error'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void exportCsv() {
    try {
      final csv = StringBuffer();

      // Header
      csv.writeln(
        'Transaction ID,Type,User ID,Amount,Method,Status,Created At',
      );

      // Data
      for (final transaction in transactions) {
        final id = transaction['txn_id'] ?? '';
        final type = transaction['type'] ?? '';
        final uid = transaction['uid'] ?? '';
        final amount = transaction['amount'] ?? 0.0;
        final method = transaction['method'] ?? '';
        final status = transaction['status'] ?? '';
        final createdAt = transaction['created_at'] != null
            ? (transaction['created_at'] as Timestamp)
                  .toDate()
                  .toIso8601String()
            : '';

        csv.writeln('$id,$type,$uid,$amount,$method,$status,$createdAt');
      }

      // Create blob and trigger download
      final bytes = utf8.encode(csv.toString());
      downloadFileAsBlob(
        bytes,
        'transactions_export_${DateTime.now().millisecondsSinceEpoch}.csv',
      );

      Get.snackbar(
        'admin.financial.success'.tr,
        'admin.financial.export_success'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'admin.financial.error'.tr,
        'admin.financial.export_error'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  // ignore: unnecessary_overrides
  void onClose() {
    super.onClose();
  }

  void applyFilters() {
    transactions.clear();
    lastDocument = null;
    hasMore.value = true;
    loadTransactions();
  }

  void clearFilters() {
    paymentMethodFilter.value = null;
    transactionTypeFilter.value = null;
    applyFilters();
  }

  void updateDateRange(DateTimeRange? range) {
    if (range != null) {
      dateRange.value = range;
      loadSummary(range);
      loadCommissionBreakdown(range);
      applyFilters();
    }
  }
}
