import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_button.dart';
import 'package:biko/core/widgets/app_error_widget.dart';
import 'package:biko/core/widgets/app_loading.dart';
import 'package:biko/features/trip/controllers/trip_completion_controller.dart';
import 'package:biko/features/trip/widgets/comment_chips.dart';
import 'package:biko/features/trip/widgets/star_rating_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Standalone rate-driver screen (alternative to integrated flow).
///
/// Shows driver info header, star rating, comment chips, and submit.
/// Reuses the same [TripCompletionController].
class RateDriverScreen extends GetView<TripCompletionController> {
  const RateDriverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = theme.extension<AppColorsExtension>()!;

    return Scaffold(
      appBar: AppBar(title: Text('completion.rate_your_trip'.tr)),
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
              onRetry: () {},
            ),
          );
        }

        final summary = controller.summary.value;
        final driver = summary?.driver;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 16),

              // Driver avatar with border ring
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.2),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 45,
                  backgroundImage: driver?.photoUrl != null
                      ? NetworkImage(driver!.photoUrl!)
                      : null,
                  backgroundColor: ext.surfaceContainer,
                  child: driver?.photoUrl == null
                      ? Icon(Icons.person, size: 44, color: ext.textMuted)
                      : null,
                ),
              ),
              const SizedBox(height: 16),

              // Driver name
              Text(
                driver?.name ?? '',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),

              // Plate number badge
              if (driver?.plateNumber != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: ext.surfaceContainer,
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                    border: Border.all(color: ext.borderSubtle),
                  ),
                  child: Text(
                    driver!.plateNumber!,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: ext.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(height: 32),

              // Rating label
              Text(
                'completion.rate_your_trip'.tr,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),

              // Star rating
              Obx(
                () => StarRatingWidget(
                  rating: controller.rating.value,
                  onRatingChanged: controller.setRating,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),

              // Comment chips
              Obx(
                () => CommentChips(
                  selectedChips: controller.selectedChips,
                  onChipToggled: controller.toggleChip,
                ),
              ),
              const SizedBox(height: 36),

              // Submit
              Obx(
                () => AppButton(
                  text: 'completion.submit_rating'.tr,
                  onPressed: controller.submitRating,
                  isLoading: controller.isSubmitting.value,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
