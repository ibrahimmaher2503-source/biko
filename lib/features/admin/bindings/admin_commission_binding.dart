import 'package:biko/features/admin/controllers/admin_commission_controller.dart';
import 'package:get/get.dart';

class AdminCommissionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AdminCommissionController>(AdminCommissionController.new);
  }
}
