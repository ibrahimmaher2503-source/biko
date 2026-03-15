import 'package:biko/features/driver_trips/controllers/bid_controller.dart';
import 'package:get/get.dart';

class BidBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BidController>(BidController.new);
  }
}
