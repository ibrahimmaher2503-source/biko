import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_empty_state.dart';
import 'package:biko/core/widgets/app_loading.dart';
import 'package:biko/features/driver_ratings/controllers/ratings_controller.dart';
import 'package:biko/features/driver_ratings/widgets/rating_overview_card.dart';
import 'package:biko/features/driver_ratings/widgets/review_tile.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Screen showing the driver's ratings overview and review list.
///
/// Matches stitch design: large overview card with star distribution,
/// section header with icon, and bordered review tiles.
class RatingsScreen extends GetView<RatingsController> {
  const RatingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = theme.extension<AppColorsExtension>()!;

    return Scaffold(
      appBar: AppBar(title: Text('ratings.title'.tr), centerTitle: false),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: AppLoading());
        }

        return RefreshIndicator(
          onRefresh: controller.refresh,
          color: AppTheme.primary,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Rating overview card
              Obx(
                () => RatingOverviewCard(
                  averageRating:
                      controller.driverProfile.value?.ratingAvg ?? 0.0,
                  totalRatings: controller.ratings.length,
                  distribution: controller.starDistribution,
                ),
              ),
              const SizedBox(height: 28),

              // Reviews header with icon
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
                      Icons.rate_review_rounded,
                      color: ext.warning,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'ratings.reviews'.tr,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Reviews list
              Obx(() {
                if (controller.ratings.isEmpty) {
                  return AppEmptyState(
                    icon: Icons.star_border,
                    title: 'ratings.no_ratings'.tr,
                    subtitle: 'ratings.no_ratings_desc'.tr,
                  );
                }

                return Column(
                  children: controller.ratings
                      .map((rating) => ReviewTile(rating: rating))
                      .toList(),
                );
              }),
            ],
          ),
        );
      }),
    );
  }
}
