import 'package:biko/features/driver_earnings/controllers/earnings_controller.dart';
import 'package:get/get.dart';

/// Binding for the earnings screen.
class EarningsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EarningsController>(EarningsController.new);
  }
}
