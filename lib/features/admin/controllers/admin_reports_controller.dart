import 'package:biko/core/services/web_download.dart';
import 'package:biko/core/widgets/app_snackbar.dart';
import 'package:biko/features/admin/models/finance/generated_report_model.dart';
import 'package:biko/features/admin/models/finance/scheduled_report_model.dart';
import 'package:biko/features/admin/services/financial_report_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show DateTimeRange;
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class AdminReportsController extends GetxController {
  final reportHistory = <GeneratedReportModel>[].obs;
  final scheduledReports = <ScheduledReportModel>[].obs;
  final isLoading = false.obs;
  final isGenerating = false.obs;
  final selectedType = 'revenue'.obs;

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
    loadHistory();
    loadScheduledReports();
  }

  Future<void> generateReport({String format = 'pdf'}) async {
    try {
      isGenerating.value = true;

      final report = await FinancialReportService.generateReport(
        selectedType.value,
        dateRange,
        format,
      );

      AppSnackbar.success('admin.finance.generate_report'.tr);
      reportHistory.insert(0, report);
    } catch (e, stack) {
      debugPrint('generateReport error: $e\n$stack');
      AppSnackbar.error(e.toString());
    } finally {
      isGenerating.value = false;
    }
  }

  Future<void> scheduleReport(ScheduledReportModel schedule) async {
    try {
      isLoading.value = true;
      await FinancialReportService.scheduleReport(schedule);
      AppSnackbar.success('admin.finance.schedule_report'.tr);
      await loadScheduledReports();
    } catch (e, stack) {
      debugPrint('scheduleReport error: $e\n$stack');
      AppSnackbar.error(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadHistory() async {
    try {
      isLoading.value = true;
      reportHistory.value =
          await FinancialReportService.getReportHistory();
    } catch (e, stack) {
      debugPrint('loadHistory error: $e\n$stack');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadScheduledReports() async {
    try {
      scheduledReports.value =
          await FinancialReportService.getScheduledReports();
    } catch (e, stack) {
      debugPrint('loadScheduledReports error: $e\n$stack');
    }
  }

  Future<void> downloadReport(GeneratedReportModel report) async {
    try {
      if (report.downloadUrl.isEmpty) {
        AppSnackbar.warning('admin.finance.no_download_url'.tr);
        return;
      }

      final response = await http.get(Uri.parse(report.downloadUrl));

      if (response.statusCode == 200) {
        final extension = report.type == 'csv' ? 'csv' : 'pdf';
        final filename = '${report.name}.$extension';
        downloadFileAsBlob(response.bodyBytes, filename);
        AppSnackbar.success('admin.finance.download_success'.tr);
      } else {
        AppSnackbar.error('admin.finance.download_error'.tr);
      }
    } catch (e, stack) {
      debugPrint('downloadReport error: $e\n$stack');
      AppSnackbar.error('admin.finance.download_error'.tr);
    }
  }
}
