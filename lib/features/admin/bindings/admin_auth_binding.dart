import 'package:biko/features/admin/controllers/admin_auth_controller.dart';
import 'package:get/get.dart';

class AdminAuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AdminAuthController>(AdminAuthController.new);
  }
}
