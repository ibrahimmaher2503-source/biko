import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_button.dart';
import 'package:biko/core/widgets/app_card.dart';
import 'package:biko/core/widgets/app_loading.dart';
import 'package:biko/features/driver_trips/controllers/trip_complete_controller.dart';
import 'package:biko/features/driver_trips/widgets/fare_breakdown_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Screen shown after a trip is completed.
///
/// Matches stitch design: large green success circle, prominent heading,
/// cash-to-collect card, fare breakdown, rating stars.
class TripCompleteScreen extends GetView<TripCompleteController> {
  const TripCompleteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = theme.extension<AppColorsExtension>()!;

    return Scaffold(
      appBar: AppBar(
        title: Text('trip_complete.title'.tr),
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: controller.goHome,
        ),
        actions: [
          IconButton(
            icon: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: ext.border),
              ),
              child: Icon(
                Icons.help_outline,
                size: 18,
                color: ext.textMuted,
              ),
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: AppLoading());
        }

        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),

                    // Large green success circle
                    Center(
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              ext.success,
                              ext.success.withValues(alpha: 0.8),
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: ext.success.withValues(alpha: 0.3),
                              blurRadius: 24,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Heading
                    Text(
                      'driver_trips.destination_reached'.tr,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'driver_trips.arrived_dropoff_desc'.tr,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: ext.textMuted,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // Cash to collect card (for cash trips)
                    Obx(() {
                      final trip = controller.trip.value;
                      if (trip == null) return const SizedBox.shrink();

                      if (trip.paymentMethod.toJson() == 'cash') {
                        return _CashCollectCard(
                          amount: controller.totalFare.value,
                        );
                      }
                      return const SizedBox.shrink();
                    }),

                    // Fare breakdown
                    Obx(
                      () => FareBreakdownCard(
                        totalFare: controller.totalFare.value,
                        commission: controller.commission.value,
                        netEarning: controller.netEarning.value,
                        commissionRate: controller.commissionRate.value,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Rating section
                    Text(
                      'trip_complete.rate_customer'.tr,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),

                    // Star rating
                    Obx(
                      () => Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          5,
                          (index) => GestureDetector(
                            onTap: controller.hasRated.value
                                ? null
                                : () =>
                                    controller.rating.value = index + 1,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              child: Icon(
                                index < controller.rating.value
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                size: 44,
                                color: index < controller.rating.value
                                    ? ext.warning
                                    : ext.border,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Submit rating / submitted state
                    Obx(() {
                      if (controller.hasRated.value) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: ext.successBg,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusLarge,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: ext.success,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'trip_complete.rating_submitted'.tr,
                                style:
                                    theme.textTheme.bodyMedium?.copyWith(
                                  color: ext.success,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return AppButton(
                        text: 'trip_complete.submit_rating'.tr,
                        onPressed: controller.submitRating,
                        isLoading: controller.isSubmitting.value,
                        variant: ButtonVariant.outline,
                      );
                    }),

                    // Cash collected button
                    Obx(() {
                      final trip = controller.trip.value;
                      if (trip == null) return const SizedBox.shrink();

                      if (trip.paymentMethod.toJson() == 'cash') {
                        return Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: AppButton(
                            text: 'trip_complete.cash_collected'.tr,
                            onPressed: controller.confirmCashCollected,
                            isLoading: controller.isSubmitting.value,
                            leadingIcon: Icons.payments,
                            variant: ButtonVariant.secondary,
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Fixed bottom button
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: BoxDecoration(
                color: ext.surfaceElevated,
                border: Border(top: BorderSide(color: ext.borderSubtle)),
              ),
              child: SafeArea(
                top: false,
                child: AppButton(
                  text: 'trip_complete.go_home'.tr,
                  onPressed: controller.goHome,
                  trailingIcon: Icons.arrow_forward,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

/// Cash-to-collect card matching the stitch delivery summary design.
class _CashCollectCard extends StatelessWidget {
  const _CashCollectCard({required this.amount});

  final double amount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = theme.extension<AppColorsExtension>()!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AppCard(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                'driver_trips.cash_to_collect'.tr,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: ext.textMuted,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${'common.egp'.tr} ${amount.toStringAsFixed(0)}',
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              // Warning badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: ext.warningBg,
                  borderRadius: BorderRadius.circular(
                    AppTheme.radiusDefault,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: ext.warning,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'driver_trips.do_not_leave_without_cash'.tr,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
