import 'package:biko/features/admin/controllers/admin_financial_dashboard_controller.dart';
import 'package:get/get.dart';

class AdminFinancialDashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AdminFinancialDashboardController>(
      AdminFinancialDashboardController.new,
    );
  }
}
