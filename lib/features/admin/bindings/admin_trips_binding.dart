import 'package:biko/features/admin/controllers/admin_trips_controller.dart';
import 'package:get/get.dart';

/// Dependency binding for Admin Trips Management screens.
class AdminTripsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AdminTripsController>(AdminTripsController.new);
  }
}
