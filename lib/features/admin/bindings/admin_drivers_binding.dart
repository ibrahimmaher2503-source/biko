import 'package:biko/features/admin/controllers/admin_drivers_controller.dart';
import 'package:get/get.dart';

class AdminDriversBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AdminDriversController>(AdminDriversController.new);
  }
}
