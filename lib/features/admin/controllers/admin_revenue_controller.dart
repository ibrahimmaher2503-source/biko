import 'package:biko/core/widgets/app_snackbar.dart';
import 'package:biko/features/admin/models/finance/daily_revenue_model.dart';
import 'package:biko/features/admin/services/revenue_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show DateTimeRange;
import 'package:get/get.dart';

class AdminRevenueController extends GetxController {
  final revenueByType = <String, double>{}.obs;
  final hourlyPattern = <int, double>{}.obs;
  final revenueData = <DailyRevenueModel>[].obs;
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
    loadRevenueData();
  }

  Future<void> loadRevenueData() async {
    try {
      isLoading.value = true;

      await Future.wait([
        _loadRevenueByPeriod(),
        _loadRevenueByType(),
        _loadHourlyPattern(),
      ]);
    } catch (e, stack) {
      debugPrint('loadRevenueData error: $e\n$stack');
      AppSnackbar.error(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadRevenueByPeriod() async {
    revenueData.value = await RevenueService.getRevenueByPeriod(dateRange);
  }

  Future<void> _loadRevenueByType() async {
    revenueByType.value =
        await RevenueService.getRevenueByServiceType(dateRange);
  }

  Future<void> _loadHourlyPattern() async {
    hourlyPattern.value =
        await RevenueService.getHourlyRevenuePattern(dateRange);
  }

  @override
  // ignore: unnecessary_overrides
  void onClose() {
    super.onClose();
  }

  void filterByDate(DateTimeRange range) {
    startDate.value = range.start;
    endDate.value = range.end;
    loadRevenueData();
  }
}
