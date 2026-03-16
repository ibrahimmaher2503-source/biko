import 'package:biko/features/history/controllers/trip_history_controller.dart';
import 'package:get/get.dart';

/// Binding for trip history screen
class TripHistoryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TripHistoryController>(TripHistoryController.new);
  }
}
