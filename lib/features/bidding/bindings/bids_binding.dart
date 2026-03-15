import 'package:biko/features/bidding/controllers/bids_controller.dart';
import 'package:get/get.dart';

/// GetX binding for the Bids screen.
class BidsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(BidsController.new);
  }
}
