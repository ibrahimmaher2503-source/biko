import 'package:biko/features/driver_trips/controllers/trip_requests_controller.dart';
import 'package:get/get.dart';

class DriverTripsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TripRequestsController>(TripRequestsController.new);
  }
}
