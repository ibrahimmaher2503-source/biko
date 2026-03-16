import 'package:biko/core/routes/app_routes.dart';
import 'package:biko/features/onboarding/data/onboarding_data.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingController extends GetxController {
  final pageController = PageController();
  final currentPage = 0.obs;

  /// Slides are determined by the app type passed via arguments
  late final List<OnboardingSlide> slides;

  /// App type for persistence key differentiation
  late final String _appType;

  /// Whether we're on the last slide
  bool get isLastPage => currentPage.value == slides.length - 1;

  @override
  void onInit() {
    super.onInit();
    // Determine which slides to show based on app type argument
    _appType = Get.arguments as String? ?? 'customer';
    slides = _appType == 'driver'
        ? OnboardingSlide.driverSlides
        : OnboardingSlide.customerSlides;
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }

  void onPageChanged(int page) {
    currentPage.value = page;
  }

  void nextPage() {
    if (isLastPage) {
      _completeOnboarding();
    } else {
      pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void skip() {
    _completeOnboarding();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed_$_appType', true);
    Get.offAllNamed(AppRoutes.phoneLogin);
  }
}
