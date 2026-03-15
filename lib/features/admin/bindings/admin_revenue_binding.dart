import 'package:biko/features/admin/controllers/admin_revenue_controller.dart';
import 'package:get/get.dart';

class AdminRevenueBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AdminRevenueController>(AdminRevenueController.new);
  }
}
