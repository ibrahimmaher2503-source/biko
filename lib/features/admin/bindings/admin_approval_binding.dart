import 'package:biko/features/admin/controllers/admin_approval_controller.dart';
import 'package:get/get.dart';

class AdminApprovalBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AdminApprovalController>(AdminApprovalController.new);
  }
}
