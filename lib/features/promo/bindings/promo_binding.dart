import 'package:biko/features/promo/controllers/promo_controller.dart';
import 'package:get/get.dart';

/// Binding for promo codes screen
class PromoBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PromoController>(PromoController.new);
  }
}
