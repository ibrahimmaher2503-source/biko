import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_button.dart';
import 'package:biko/core/widgets/app_error_widget.dart';
import 'package:biko/core/widgets/app_loading.dart';
import 'package:biko/features/trip/controllers/trip_completion_controller.dart';
import 'package:biko/features/trip/widgets/comment_chips.dart';
import 'package:biko/features/trip/widgets/star_rating_widget.dart';
import 'package:biko/features/trip/widgets/tip_buttons.dart';
import 'package:biko/features/trip/widgets/trip_summary_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Screen shown after a trip is completed.
///
/// Displays trip summary, fare breakdown, rating stars,
/// comment chips, tip selection, and a submit button.
class TripCompletedScreen extends GetView<TripCompletionController> {
  const TripCompletedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = theme.extension<AppColorsExtension>()!;

    return Scaffold(
      appBar: AppBar(
        title: Text('completion.trip_completed'.tr),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: controller.skipRating,
            child: Text(
              'common.done'.tr,
              style: theme.textTheme.labelLarge?.copyWith(
                color: ext.textMuted,
              ),
            ),
          ),
        ],
      ),
      body: Obx(() {
        // Loading state
        if (controller.isLoading.value) {
          return const Center(child: AppLoading());
        }

        // Error state
        if (controller.errorMessage.isNotEmpty) {
          return Center(
            child: AppErrorWidget(
              message: controller.errorMessage.value.tr,
              onRetry: controller.skipRating,
            ),
          );
        }

        final summary = controller.summary.value;
        if (summary == null) {
          return const Center(child: AppLoading());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            children: [
              const SizedBox(height: 24),

              // Success icon with gradient ring
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      ext.success.withValues(alpha: 0.15),
                      ext.success.withValues(alpha: 0.05),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: ext.success.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: ext.success.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.check_circle_rounded,
                    size: 48,
                    color: ext.success,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'completion.trip_completed'.tr,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'completion.rate_your_trip'.tr,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: ext.textMuted,
                ),
              ),
              const SizedBox(height: 28),

              // Trip summary card
              TripSummaryCard(summary: summary),
              const SizedBox(height: 28),

              // Rating section with header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // Section header
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: ext.warning.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusLarge,
                            ),
                          ),
                          child: Icon(
                            Icons.star_rounded,
                            color: ext.warning,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'completion.rate_your_trip'.tr,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Star rating
                    Obx(
                      () => StarRatingWidget(
                        rating: controller.rating.value,
                        onRatingChanged: controller.setRating,
                        size: 44,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Comment chips
                    Obx(
                      () => CommentChips(
                        selectedChips: controller.selectedChips,
                        onChipToggled: controller.toggleChip,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Tip section
                    Obx(
                      () => TipButtons(
                        selectedAmount: controller.tipAmount.value,
                        onAmountSelected: controller.setTip,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Submit button
                    Obx(
                      () => AppButton(
                        text: 'completion.submit_rating'.tr,
                        onPressed: controller.submitRating,
                        isLoading: controller.isSubmitting.value,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
