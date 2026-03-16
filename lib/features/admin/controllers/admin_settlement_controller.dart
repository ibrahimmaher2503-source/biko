import 'package:biko/core/widgets/app_snackbar.dart';
import 'package:biko/features/admin/models/finance/driver_settlement_model.dart';
import 'package:biko/features/admin/models/finance/settlement_record_model.dart';
import 'package:biko/features/admin/models/finance/settlement_summary_model.dart';
import 'package:biko/features/admin/services/settlement_service.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class AdminSettlementController extends GetxController {
  final Rx<SettlementSummaryModel?> summary =
      Rx<SettlementSummaryModel?>(null);
  final drivers = <DriverSettlementModel>[].obs;
  final history = <SettlementRecordModel>[].obs;
  final isLoading = false.obs;
  final selectedDriverUids = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  Future<void> loadData() async {
    try {
      isLoading.value = true;

      await Future.wait([
        _loadSummary(),
        _loadDrivers(),
        _loadHistory(),
      ]);
    } catch (e, stack) {
      debugPrint('loadData error: $e\n$stack');
      AppSnackbar.error(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadSummary() async {
    summary.value = await SettlementService.getSettlementSummary();
  }

  Future<void> _loadDrivers() async {
    drivers.value = await SettlementService.getDriversForSettlement();
  }

  Future<void> _loadHistory() async {
    history.value = await SettlementService.getSettlementHistory();
  }

  void toggleDriverSelection(String uid) {
    if (selectedDriverUids.contains(uid)) {
      selectedDriverUids.remove(uid);
    } else {
      selectedDriverUids.add(uid);
    }
  }

  void selectAll() {
    selectedDriverUids.value =
        drivers.map((d) => d.driverUid).toList();
  }

  void deselectAll() {
    selectedDriverUids.clear();
  }

  Future<void> processSettlement() async {
    if (selectedDriverUids.isEmpty) {
      AppSnackbar.warning('admin.finance.select_driver'.tr);
      return;
    }

    final hasDriversWithPendingAmounts = drivers
        .where((d) => selectedDriverUids.contains(d.driverUid))
        .any((d) => d.pendingAmount > 0);

    if (!hasDriversWithPendingAmounts) {
      AppSnackbar.warning('admin.finance.no_pending_amounts'.tr);
      return;
    }

    try {
      isLoading.value = true;
      await SettlementService.processSettlement(selectedDriverUids.toList());
      AppSnackbar.success('admin.finance.process_settlement'.tr);
      selectedDriverUids.clear();
      await loadData();
    } catch (e, stack) {
      debugPrint('processSettlement error: $e\n$stack');
      AppSnackbar.error(e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}
