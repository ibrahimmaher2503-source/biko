import 'package:biko/features/admin/controllers/admin_reports_controller.dart';
import 'package:get/get.dart';

class AdminReportsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AdminReportsController>(AdminReportsController.new);
  }
}
