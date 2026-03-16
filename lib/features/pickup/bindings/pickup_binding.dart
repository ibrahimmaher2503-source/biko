import 'package:biko/features/pickup/controllers/pickup_controller.dart';
import 'package:get/get.dart';

/// GetX binding for the Set Pickup Location screen.
class PickupBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(PickupController.new);
  }
}
