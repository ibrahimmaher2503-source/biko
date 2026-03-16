import 'package:biko/features/admin/controllers/admin_dashboard_controller.dart';
import 'package:get/get.dart';

class AdminDashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AdminDashboardController>(AdminDashboardController.new);
  }
}
