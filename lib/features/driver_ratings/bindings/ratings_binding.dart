import 'package:biko/features/driver_ratings/controllers/ratings_controller.dart';
import 'package:get/get.dart';

/// Binding for the driver ratings screen.
class RatingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RatingsController>(RatingsController.new);
  }
}
