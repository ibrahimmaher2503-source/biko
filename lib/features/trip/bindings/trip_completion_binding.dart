import 'package:biko/features/trip/controllers/trip_completion_controller.dart';
import 'package:get/get.dart';

/// Binding for the trip completion/rating screens
class TripCompletionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TripCompletionController>(TripCompletionController.new);
  }
}
