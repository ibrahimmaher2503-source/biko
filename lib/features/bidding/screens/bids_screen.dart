import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_dialog.dart';
import 'package:biko/core/widgets/app_loading.dart';
import 'package:biko/features/bidding/controllers/bids_controller.dart';
import 'package:biko/features/bidding/widgets/bids_list.dart';
import 'package:biko/features/bidding/widgets/search_timeout_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Screen displaying incoming driver bids for a trip.
///
/// Shows trip summary header, timeout suggestion if applicable,
/// and the live list of bids.
class BidsScreen extends GetView<BidsController> {
  const BidsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final confirmed = await AppDialog.confirm(
          title: 'bids.cancel_trip_title'.tr,
          content: 'bids.cancel_trip_message'.tr,
          confirmText: 'bids.yes_cancel'.tr,
          cancelText: 'common.no'.tr,
          isDestructive: true,
        );
        if (confirmed) {
          await controller.cancelTrip();
          Get.back();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('bids.incoming_bids'.tr),
          actions: [
            TextButton(
              onPressed: () => _showCancelDialog(context),
              child: Text(
                'bids.cancel_search'.tr,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Trip summary header
            _TripSummaryHeader(colors: colors, theme: theme),

            // Search timeout suggestion
            Obx(
              () => controller.hasTimedOut.value
                  ? const SearchTimeoutWidget()
                  : const SizedBox.shrink(),
            ),

            // Bids list
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const AppLoading();
                }

                return BidsList(
                  bids: controller.bids,
                  onAccept: controller.acceptBid,
                  onReject: controller.rejectBid,
                  isAccepting: controller.isAcceptingBid.value,
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  void _showCancelDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: Text('bids.cancel_search'.tr),
        content: Text('bids.cancel_search_confirm'.tr),
        actions: [
          TextButton(onPressed: Get.back, child: Text('common.no'.tr)),
          TextButton(
            onPressed: () {
              Get.back();
              controller.cancelSearch();
            },
            child: Text(
              'common.yes'.tr,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}

/// Header showing pickup → dropoff and offered price.
class _TripSummaryHeader extends GetView<BidsController> {
  const _TripSummaryHeader({required this.colors, required this.theme});

  final AppColorsExtension colors;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pickup row
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: colors.success,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Obx(
                  () => Text(
                    controller.pickupAddress.value,
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),

          // Connector line
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 3),
            child: Container(width: 2, height: 16, color: colors.borderSubtle),
          ),

          // Dropoff row
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Obx(
                  () => Text(
                    controller.dropoffAddress.value,
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          Divider(height: 1, color: colors.borderSubtle),
          const SizedBox(height: 12),

          // Offered price
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'bids.your_offer'.tr,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.textMuted,
                ),
              ),
              Obx(
                () => Text(
                  '${controller.offeredPrice.value.toStringAsFixed(0)} ${'bids.egp'.tr}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
