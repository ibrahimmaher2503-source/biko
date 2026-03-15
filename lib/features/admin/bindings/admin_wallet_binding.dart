import 'package:biko/features/admin/controllers/admin_wallet_controller.dart';
import 'package:get/get.dart';

class AdminWalletBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AdminWalletController>(AdminWalletController.new);
  }
}
