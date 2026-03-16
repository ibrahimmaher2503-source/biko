import 'package:biko/core/models/trip_model.dart';
import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_empty_state.dart';
import 'package:biko/core/widgets/app_error_widget.dart';
import 'package:biko/core/widgets/app_loading.dart';
import 'package:biko/features/history/controllers/trip_history_controller.dart';
import 'package:biko/features/history/widgets/trip_history_item.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// Trip history screen with paginated list of past trips
class TripHistoryScreen extends GetView<TripHistoryController> {
  const TripHistoryScreen({super.key});

  void _showTripDetail(BuildContext context, TripModel trip) {
    final ext = Theme.of(context).extension<AppColorsExtension>()!;
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    final isCancelled = trip.status.name == 'cancelled';

    Get.bottomSheet<void>(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppTheme.radiusXl),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: ext.borderSubtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Route
            Row(
              children: [
                Column(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      width: 2,
                      height: 32,
                      color: ext.borderSubtle,
                    ),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: isCancelled
                            ? theme.colorScheme.error
                            : ext.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trip.pickup.name,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        trip.dropoff.name,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Divider(color: ext.borderSubtle),
            const SizedBox(height: 12),
            // Details row
            Row(
              children: [
                _DetailChip(
                  icon: Icons.schedule_rounded,
                  label: dateFormat.format(trip.createdAt),
                  color: ext.textMuted,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (trip.distanceKm != null)
                  _DetailChip(
                    icon: Icons.route_rounded,
                    label:
                        '${trip.distanceKm!.toStringAsFixed(1)} ${'driver_trips.km'.tr}',
                    color: ext.info,
                  ),
                if (trip.distanceKm != null) const SizedBox(width: 12),
                _DetailChip(
                  icon: Icons.payments_outlined,
                  label: trip.formattedPrice,
                  color: isCancelled ? ext.textMuted : ext.success,
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

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
                  (trip) => TripHistoryItem(
                    trip: trip,
                    onTap: () => _showTripDetail(context, trip),
                  ),
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

/// Small icon+label chip for the trip detail bottom sheet
class _DetailChip extends StatelessWidget {
  const _DetailChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppColorsExtension>()!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: ext.surfaceContainer,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(color: ext.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
