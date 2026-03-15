import 'package:biko/features/driver_wallet/controllers/wallet_controller.dart';
import 'package:get/get.dart';

/// Binding for the driver wallet screen.
class WalletBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<WalletController>(WalletController.new);
  }
}
