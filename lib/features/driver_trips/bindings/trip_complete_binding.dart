import 'package:biko/features/driver_trips/controllers/trip_complete_controller.dart';
import 'package:get/get.dart';

/// Binding for the trip complete screen.
class TripCompleteBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TripCompleteController>(TripCompleteController.new);
  }
}
