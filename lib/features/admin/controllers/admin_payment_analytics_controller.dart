import 'package:biko/core/widgets/app_snackbar.dart';
import 'package:biko/features/admin/models/finance/payment_success_model.dart';
import 'package:biko/features/admin/services/payment_analytics_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show DateTimeRange;
import 'package:get/get.dart';

class AdminPaymentAnalyticsController extends GetxController {
  final successReport = <PaymentSuccessModel>[].obs;
  final cashVsDigital = <String, dynamic>{}.obs;
  final failedPayments = <Map<String, dynamic>>[].obs;
  final isLoading = false.obs;

  final Rx<DateTime> startDate = DateTime.now()
      .subtract(const Duration(days: 30))
      .obs;
  final Rx<DateTime> endDate = DateTime.now().obs;

  DateTimeRange get dateRange => DateTimeRange(
        start: startDate.value,
        end: endDate.value,
      );

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  Future<void> loadData() async {
    try {
      isLoading.value = true;

      await Future.wait([
        _loadSuccessReport(),
        _loadCashVsDigital(),
      ]);
    } catch (e, stack) {
      debugPrint('loadData error: $e\n$stack');
      AppSnackbar.error(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadSuccessReport() async {
    successReport.value =
        await PaymentAnalyticsService.getPaymentSuccessReport(dateRange);
  }

  Future<void> _loadCashVsDigital() async {
    cashVsDigital.value =
        await PaymentAnalyticsService.getCashVsDigitalReport(dateRange);
  }

  bool get hasHighFailureRate {
    if (successReport.isEmpty) return false;
    final totalFails = successReport.fold<int>(
      0,
      (sum, r) => sum + r.failCount,
    );
    final totalAttempts = successReport.fold<int>(
      0,
      (sum, r) => sum + r.totalAttempts,
    );
    if (totalAttempts == 0) return false;
    return (totalFails / totalAttempts) > 0.10;
  }

  @override
  // ignore: unnecessary_overrides
  void onClose() {
    super.onClose();
  }

  void filterByDate(DateTimeRange range) {
    startDate.value = range.start;
    endDate.value = range.end;
    loadData();
  }
}
