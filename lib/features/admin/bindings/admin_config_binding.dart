import 'package:biko/features/admin/controllers/admin_config_controller.dart';
import 'package:get/get.dart';

class AdminConfigBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AdminConfigController>(AdminConfigController.new);
  }
}
