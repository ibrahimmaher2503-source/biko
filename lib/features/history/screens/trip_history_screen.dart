import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_empty_state.dart';
import 'package:biko/core/widgets/app_error_widget.dart';
import 'package:biko/core/widgets/app_loading.dart';
import 'package:biko/features/history/controllers/trip_history_controller.dart';
import 'package:biko/features/history/widgets/trip_history_item.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Trip history screen with paginated list of past trips
class TripHistoryScreen extends GetView<TripHistoryController> {
  const TripHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppColorsExtension>()!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('history.title'.tr), centerTitle: false),
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
              onRetry: controller.refreshTrips,
            ),
          );
        }

        // Empty state
        if (controller.trips.isEmpty) {
          return Center(
            child: AppEmptyState(
              icon: Icons.history_rounded,
              title: 'history.no_trips'.tr,
            ),
          );
        }

        // Trip list with scroll-based pagination
        return RefreshIndicator(
          onRefresh: controller.refreshTrips,
          color: AppTheme.primary,
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollEndNotification &&
                  notification.metrics.extentAfter < 200 &&
                  controller.hasMore.value &&
                  !controller.isLoadingMore.value) {
                controller.loadMore();
              }
              return false;
            },
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              children: [
                // Section header
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusLarge,
                        ),
                      ),
                      child: const Icon(
                        Icons.history_rounded,
                        color: AppTheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'history.title'.tr,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: ext.surfaceContainer,
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusFull,
                        ),
                      ),
                      child: Text(
                        '${controller.trips.length}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: ext.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Trip items
                ...controller.trips.map(
                  (trip) => TripHistoryItem(trip: trip, onTap: () {}),
                ),

                // Load more indicator
                if (controller.isLoadingMore.value)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: AppLoading()),
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
