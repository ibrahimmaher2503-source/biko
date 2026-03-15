import 'package:biko/features/bidding/controllers/bidding_controller.dart';
import 'package:get/get.dart';

/// Binding for the Price Negotiation screen.
///
/// Lazily creates the [BiddingController] when the route is first accessed.
class BiddingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(BiddingController.new);
  }
}
