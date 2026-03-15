import 'package:biko/features/wallet/controllers/wallet_controller.dart';
import 'package:get/get.dart';

/// Binding for wallet screens
class WalletBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<WalletController>(WalletController.new);
  }
}
