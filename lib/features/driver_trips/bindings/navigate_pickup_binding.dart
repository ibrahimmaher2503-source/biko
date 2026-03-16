import 'package:biko/features/driver_trips/controllers/navigate_pickup_controller.dart';
import 'package:get/get.dart';

/// Binding for the navigate-to-pickup screen.
class NavigatePickupBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<NavigatePickupController>(NavigatePickupController.new);
  }
}
