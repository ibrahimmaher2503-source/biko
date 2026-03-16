import 'package:biko/features/admin/controllers/admin_transaction_monitor_controller.dart';
import 'package:get/get.dart';

class AdminTransactionMonitorBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AdminTransactionMonitorController>(
      AdminTransactionMonitorController.new,
    );
  }
}
