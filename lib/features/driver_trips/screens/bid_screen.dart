import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_button.dart';
import 'package:biko/core/widgets/app_card.dart';
import 'package:biko/core/widgets/app_loading.dart';
import 'package:biko/core/widgets/app_text_field.dart';
import 'package:biko/features/driver_trips/controllers/bid_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Screen for submitting a counter-bid on a trip request.
class BidScreen extends GetView<BidController> {
  const BidScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = theme.extension<AppColorsExtension>()!;

    return Scaffold(
      appBar: AppBar(
        title: Text('driver_trips.bid_title'.tr),
        centerTitle: false,
      ),
      body: Obx(() {
        // Waiting state
        if (controller.isWaiting.value) {
          return _buildWaitingState(context);
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Trip details card
              AppCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'driver_trips.trip_details'.tr,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Pickup
                      _DetailRow(
                        icon: Icons.circle,
                        iconColor: ext.success,
                        text: controller.pickupAddress,
                      ),
                      const SizedBox(height: 8),
                      // Dropoff
                      _DetailRow(
                        icon: Icons.circle,
                        iconColor: AppTheme.primary,
                        text: controller.dropoffAddress,
                      ),
                      const SizedBox(height: 12),
                      // Distance + Duration
                      Row(
                        children: [
                          Icon(
                            Icons.straighten,
                            size: 16,
                            color: ext.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${controller.distanceKm.toStringAsFixed(1)} ${'driver_trips.km'.tr}',
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(width: 16),
                          Icon(Icons.schedule, size: 16, color: ext.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            '${controller.durationMinutes} ${'driver_trips.min'.tr}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Customer offered price
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'driver_trips.customer_price'.tr,
                            style: theme.textTheme.bodyMedium,
                          ),
                          Text(
                            '${controller.customerPrice.toStringAsFixed(0)} ${'common.egp'.tr}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Your bid section
              Text(
                'driver_trips.your_bid'.tr,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Obx(
                () => Text(
                  '${'driver_trips.suggested_price'.tr}: ${controller.suggestedPrice.value.toStringAsFixed(0)} ${'common.egp'.tr}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: ext.textMuted,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Price input
              Obx(
                () => AppTextField(
                  controller: controller.priceController,
                  label: 'driver_trips.bid_amount'.tr,
                  hint: 'driver_trips.enter_amount'.tr,
                  keyboardType: TextInputType.number,
                  errorText: controller.priceError.value.isEmpty
                      ? null
                      : controller.priceError.value,
                  suffixIcon: Icons.currency_pound,
                ),
              ),
              const SizedBox(height: 8),
              Obx(
                () => Text(
                  '${'driver_trips.min_price'.tr}: ${controller.floorPrice.value.toStringAsFixed(0)} ${'common.egp'.tr}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: ext.textMuted,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Submit button
              Obx(
                () => AppButton(
                  text: 'driver_trips.submit_bid'.tr,
                  onPressed: controller.submitBid,
                  isLoading: controller.isSubmitting.value,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildWaitingState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AppLoading(size: 60),
            const SizedBox(height: 24),
            Text(
              'driver_trips.waiting_customer'.tr,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'driver_trips.waiting_message'.tr,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.extension<AppColorsExtension>()!.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            AppButton(
              text: 'common.cancel'.tr,
              onPressed: controller.cancelBid,
              variant: ButtonVariant.outline,
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.iconColor,
    required this.text,
  });

  final IconData icon;
  final Color iconColor;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 10, color: iconColor),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
