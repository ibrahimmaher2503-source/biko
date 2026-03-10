import 'package:get/get.dart';

/// Admin layout controller
///
/// Manages the admin sidebar navigation state.
/// Registered permanently in the Admin app entry point.
class AdminLayoutController extends GetxController {
  final selectedIndex = 0.obs;
  final isSidebarExpanded = true.obs;

  /// Select a sidebar menu item
  void selectItem(int index) {
    selectedIndex.value = index;
  }

  /// Toggle sidebar expanded/collapsed state
  void toggleSidebar() {
    isSidebarExpanded.value = !isSidebarExpanded.value;
  }
}
