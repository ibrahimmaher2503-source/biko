import 'package:biko/core/widgets/app_button.dart';
import 'package:biko/features/onboarding/controllers/onboarding_controller.dart';
import 'package:biko/features/onboarding/widgets/onboarding_page.dart';
import 'package:biko/features/onboarding/widgets/page_indicator.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OnboardingScreen extends GetView<OnboardingController> {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top bar — back button + Skip
            _buildTopBar(context),
            // PageView — swipeable slides
            Expanded(
              child: PageView.builder(
                controller: controller.pageController,
                onPageChanged: controller.onPageChanged,
                itemCount: controller.slides.length,
                itemBuilder: (context, index) {
                  return OnboardingPage(slide: controller.slides[index]);
                },
              ),
            ),
            // Bottom — indicators + action button
            _buildBottom(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button (hidden on first page or just skip)
          const SizedBox(width: 48, height: 48),
          // Skip button
          AppButton(
            text: 'onboarding.skip'.tr,
            onPressed: controller.skip,
            variant: ButtonVariant.text,
            width: null,
          ),
        ],
      ),
    );
  }

  Widget _buildBottom(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Column(
        children: [
          // Page indicators
          Obx(
            () => PageIndicator(
              currentPage: controller.currentPage.value,
              pageCount: controller.slides.length,
            ),
          ),
          const SizedBox(height: 32),
          // Action button
          Obx(() {
            final isLastPage = controller.isLastPage;
            return AppButton(
              text: isLastPage
                  ? 'onboarding.get_started'.tr
                  : 'onboarding.next'.tr,
              onPressed: controller.nextPage,
              trailingIcon: Icons.arrow_forward,
            );
          }),
        ],
      ),
    );
  }
}
