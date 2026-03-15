import 'dart:async';

import 'package:get/get.dart';

import '../../../core/models/enums.dart';
import '../../../core/models/user_model.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../services/admin_firestore_service.dart';

class AdminSearchController extends GetxController {
  final searchQuery = ''.obs;
  final searchResults = <UserModel>[].obs;
  final isSearching = false.obs;

  Timer? _debounce;

  void search(String query) {
    searchQuery.value = query;

    // Cancel previous timer
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
    }

    // Clear results if query is too short
    if (query.trim().length < 2) {
      searchResults.clear();
      return;
    }

    // Debounce search for 300ms
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      isSearching.value = true;

      try {
        // Search by phone and name
        final phoneResults = await AdminFirestoreService.searchUsersByPhone(
          query,
        );
        final nameResults = await AdminFirestoreService.searchUsersByName(
          query,
        );

        // Combine results and remove duplicates
        final Map<String, UserModel> uniqueResults = {};

        for (final user in phoneResults) {
          uniqueResults[user.uid] = user;
        }

        for (final user in nameResults) {
          uniqueResults[user.uid] = user;
        }

        searchResults.value = uniqueResults.values.toList();
      } catch (e) {
        AppSnackbar.error('Failed to search users');
        searchResults.clear();
      } finally {
        isSearching.value = false;
      }
    });
  }

  void clearSearch() {
    searchQuery.value = '';
    searchResults.clear();
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
    }
  }

  void navigateToResult(UserModel user) {
    if (user.type == UserType.customer) {
      Get.toNamed(AppRoutes.adminCustomerDetail, arguments: {'uid': user.uid});
    } else if (user.type == UserType.driver) {
      Get.toNamed(AppRoutes.adminDriverDetail, arguments: {'uid': user.uid});
    }
  }

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }
}
