import 'package:biko/core/widgets/app_snackbar.dart';
import 'package:biko/features/admin/models/finance/commission_breakdown_model.dart';
import 'package:biko/features/admin/models/finance/commission_rates_model.dart';
import 'package:biko/features/admin/services/commission_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show DateTimeRange;
import 'package:get/get.dart';

class AdminCommissionController extends GetxController {
  final Rx<CommissionRatesModel?> rates =
      Rx<CommissionRatesModel?>(null);
  final Rx<CommissionBreakdownModel?> breakdown =
      Rx<CommissionBreakdownModel?>(null);
  final collection = <Map<String, dynamic>>[].obs;
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
        _loadRates(),
        _loadBreakdown(),
        _loadCollection(),
      ]);
    } catch (e, stack) {
      debugPrint('loadData error: $e\n$stack');
      AppSnackbar.error(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadRates() async {
    rates.value = await CommissionService.getCommissionRates();
  }

  Future<void> _loadBreakdown() async {
    breakdown.value =
        await CommissionService.getCommissionBreakdown(dateRange);
  }

  Future<void> _loadCollection() async {
    collection.value =
        await CommissionService.getCommissionCollection(dateRange);
  }

  Future<void> updateRates(CommissionRatesModel newRates) async {
    if (!validateRates(newRates)) return;

    try {
      isLoading.value = true;
      await CommissionService.updateCommissionRates(newRates);
      AppSnackbar.success('admin.finance.update_rates'.tr);
      await _loadRates();
    } catch (e, stack) {
      debugPrint('updateRates error: $e\n$stack');
      AppSnackbar.error(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  bool validateRates(CommissionRatesModel newRates) {
    if (newRates.rideRate < 0.05 || newRates.rideRate > 0.30) {
      AppSnackbar.warning('admin.finance.commission_rate_range'.tr);
      return false;
    }
    if (newRates.c2cRate < 0.05 || newRates.c2cRate > 0.30) {
      AppSnackbar.warning('admin.finance.commission_rate_range'.tr);
      return false;
    }
    if (newRates.b2bDefaultRate < 0.05 ||
        newRates.b2bDefaultRate > 0.30) {
      AppSnackbar.warning('admin.finance.commission_rate_range'.tr);
      return false;
    }
    return true;
  }
}
