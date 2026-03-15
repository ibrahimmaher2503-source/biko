import 'package:biko/features/history/controllers/trip_history_controller.dart';
import 'package:biko/features/home/controllers/home_controller.dart';
import 'package:biko/features/profile/controllers/profile_controller.dart';
import 'package:biko/features/wallet/controllers/wallet_controller.dart';
import 'package:get/get.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(HomeController.new);
    // Tab controllers for the bottom nav IndexedStack
    Get.lazyPut(TripHistoryController.new);
    Get.lazyPut(WalletController.new);
    Get.lazyPut(ProfileController.new);
  }
}
