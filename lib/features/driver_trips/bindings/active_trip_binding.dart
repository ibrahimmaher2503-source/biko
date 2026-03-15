import 'package:biko/features/driver_trips/controllers/active_trip_controller.dart';
import 'package:get/get.dart';

/// Binding for the active trip screen.
class ActiveTripBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ActiveTripController>(ActiveTripController.new);
  }
}
