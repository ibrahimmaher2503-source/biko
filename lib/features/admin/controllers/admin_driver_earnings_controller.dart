import 'package:biko/core/widgets/app_snackbar.dart';
import 'package:biko/features/admin/models/finance/driver_earnings_report_model.dart';
import 'package:biko/features/admin/services/driver_earnings_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show DateTimeRange;
import 'package:get/get.dart';

class AdminDriverEarningsController extends GetxController {
  final earningsSummary = <DriverEarningsReportModel>[].obs;
  final Rx<DriverEarningsReportModel?> selectedDriver =
      Rx<DriverEarningsReportModel?>(null);
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
    loadEarnings();
  }

  Future<void> loadEarnings() async {
    try {
      isLoading.value = true;
      earningsSummary.value =
          await DriverEarningsService.getDriverEarningsSummary(dateRange);
    } catch (e, stack) {
      debugPrint('loadEarnings error: $e\n$stack');
      AppSnackbar.error(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadDriverDetail(String driverUid) async {
    try {
      isLoading.value = true;
      selectedDriver.value =
          await DriverEarningsService.getDriverEarningsReport(
        driverUid,
        dateRange,
      );
    } catch (e, stack) {
      debugPrint('loadDriverDetail error: $e\n$stack');
      AppSnackbar.error(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> processPayout(
    String driverUid,
    double amount,
    String method,
  ) async {
    try {
      isLoading.value = true;
      await DriverEarningsService.processPayout(driverUid, amount, method);
      AppSnackbar.success('admin.finance.process_payout'.tr);
      await loadEarnings();
    } catch (e, stack) {
      debugPrint('processPayout error: $e\n$stack');
      AppSnackbar.error(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addBonus(
    String driverUid,
    double amount,
    String reason,
  ) async {
    try {
      isLoading.value = true;
      await DriverEarningsService.addBonus(driverUid, amount, reason);
      AppSnackbar.success('admin.finance.add_bonus'.tr);
      await loadEarnings();
    } catch (e, stack) {
      debugPrint('addBonus error: $e\n$stack');
      AppSnackbar.error(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  void filterByDate(DateTimeRange range) {
    startDate.value = range.start;
    endDate.value = range.end;
    loadEarnings();
  }
}
