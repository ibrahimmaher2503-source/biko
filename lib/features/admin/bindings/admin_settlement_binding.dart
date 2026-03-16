import 'package:biko/features/admin/controllers/admin_settlement_controller.dart';
import 'package:get/get.dart';

class AdminSettlementBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AdminSettlementController>(AdminSettlementController.new);
  }
}
