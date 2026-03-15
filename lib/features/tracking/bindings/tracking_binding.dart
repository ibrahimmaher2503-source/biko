import 'package:biko/features/tracking/controllers/tracking_controller.dart';
import 'package:get/get.dart';

/// GetX binding for the Trip Tracking screen.
class TrackingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(TrackingController.new);
  }
}
