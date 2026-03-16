import 'package:biko/features/admin/controllers/admin_users_controller.dart';
import 'package:get/get.dart';

/// Binding for Admin Users feature (US5)
class AdminUsersBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AdminUsersController>(AdminUsersController.new);
  }
}
