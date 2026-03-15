import 'package:biko/features/admin/controllers/admin_financial_controller.dart';
import 'package:get/get.dart';

class AdminFinancialBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AdminFinancialController>(AdminFinancialController.new);
  }
}
