import 'package:biko/core/models/enums.dart';
import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_button.dart';
import 'package:biko/core/widgets/app_card.dart';
import 'package:biko/core/widgets/app_loading.dart';
import 'package:biko/core/widgets/app_text_field.dart';
import 'package:biko/features/admin/controllers/admin_trips_controller.dart';
import 'package:biko/features/admin/utils/admin_status_colors.dart';
import 'package:biko/features/admin/widgets/confirm_dialog.dart';
import 'package:biko/features/admin/widgets/status_badge.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// Admin Trip Detail screen (US7).
///
/// Displays comprehensive trip information:
/// - Trip info (type, status timeline, pickup/dropoff)
/// - Payment details (suggested price, final price, commission)
/// - Customer and driver mini-cards
/// - Bids table (all bids with driver name, amount, status)
/// - Issue credit button (for completed trips only)
class AdminTripDetailScreen extends GetView<AdminTripsController> {
  const AdminTripDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;
    final tripId = Get.arguments as String;

    // Load trip detail on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadTripDetail(tripId);
    });

    return Scaffold(
      appBar: AppBar(
        title: Text('admin.trips.detail_title'.tr),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.loadTripDetail(tripId),
            tooltip: 'admin.common.refresh'.tr,
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value &&
            controller.selectedTrip.value == null) {
          return const Center(child: AppLoading());
        }

        final trip = controller.selectedTrip.value;
        if (trip == null) {
          return Center(
            child: Text(
              'admin.trips.no_trip_loaded'.tr,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colors.textMuted,
              ),
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Trip Info Card
              _buildTripInfoCard(context, trip),
              const SizedBox(height: 16),

              // Payment Card
              _buildPaymentCard(context, trip),
              const SizedBox(height: 16),

              // Customer and Driver Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildCustomerCard(context)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildDriverCard(context)),
                ],
              ),
              const SizedBox(height: 16),

              // Bids Table
              _buildBidsCard(context),
              const SizedBox(height: 16),

              // Issue Credit Button (only for completed trips)
              if (trip.status == TripStatus.completed)
                _buildIssueCreditButton(context, trip),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildTripInfoCard(BuildContext context, trip) {
    final theme = Theme.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'admin.trips.trip_information'.tr,
                style: theme.textTheme.titleMedium,
              ),
              StatusBadge.fromTripStatus(trip.status),
            ],
          ),
          const SizedBox(height: 16),

          // Trip ID
          _buildInfoRow(context, 'admin.trips.trip_id'.tr, trip.tripId),
          const Divider(height: 20),

          // Trip Type
          _buildInfoRow(
            context,
            'admin.trips.type'.tr,
            trip.type.toJson().replaceAll('_', ' '),
          ),
          const Divider(height: 20),

          // Pickup Address
          _buildInfoRow(context, 'admin.trips.pickup'.tr, trip.pickupAddress),
          const Divider(height: 20),

          // Dropoff Address
          _buildInfoRow(context, 'admin.trips.dropoff'.tr, trip.dropoffAddress),
          const Divider(height: 20),

          // Distance
          _buildInfoRow(
            context,
            'admin.trips.distance'.tr,
            '${trip.distanceKm.toStringAsFixed(2)} km',
          ),
          const Divider(height: 20),

          // Duration
          _buildInfoRow(
            context,
            'admin.trips.duration'.tr,
            '${trip.durationMins.toStringAsFixed(0)} min',
          ),
          const Divider(height: 20),

          // Created At
          _buildInfoRow(
            context,
            'admin.trips.created_at'.tr,
            DateFormat('dd/MM/yyyy HH:mm:ss').format(trip.createdAt),
          ),

          // Accepted At
          if (trip.acceptedAt != null) ...[
            const Divider(height: 20),
            _buildInfoRow(
              context,
              'admin.trips.accepted_at'.tr,
              DateFormat('dd/MM/yyyy HH:mm:ss').format(trip.acceptedAt!),
            ),
          ],

          // Completed At
          if (trip.completedAt != null) ...[
            const Divider(height: 20),
            _buildInfoRow(
              context,
              'admin.trips.completed_at'.tr,
              DateFormat('dd/MM/yyyy HH:mm:ss').format(trip.completedAt!),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentCard(BuildContext context, trip) {
    final theme = Theme.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'admin.trips.payment_details'.tr,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 16),

          // Suggested Price
          _buildInfoRow(
            context,
            'admin.trips.suggested_price'.tr,
            '${trip.suggestedPrice.toStringAsFixed(2)} ${'currency.egp'.tr}',
          ),
          const Divider(height: 20),

          // Final Price
          _buildInfoRow(
            context,
            'admin.trips.final_price'.tr,
            '${trip.finalPrice.toStringAsFixed(2)} ${'currency.egp'.tr}',
            valueStyle: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
          const Divider(height: 20),

          // Commission
          if (trip.commissionAmount != null)
            _buildInfoRow(
              context,
              'admin.trips.commission'.tr,
              '${trip.commissionAmount!.toStringAsFixed(2)} ${'currency.egp'.tr}',
            ),
          if (trip.commissionAmount != null) const Divider(height: 20),

          // Payment Method
          _buildInfoRow(
            context,
            'admin.trips.payment_method'.tr,
            trip.paymentMethod.toJson().replaceAll('_', ' '),
          ),

          // Promo Code
          if (trip.promoCodeUsed != null) ...[
            const Divider(height: 20),
            _buildInfoRow(
              context,
              'admin.trips.promo_code'.tr,
              trip.promoCodeUsed!,
            ),
          ],

          // Discount
          if (trip.discountAmount != null && trip.discountAmount! > 0) ...[
            const Divider(height: 20),
            _buildInfoRow(
              context,
              'admin.trips.discount'.tr,
              '${trip.discountAmount!.toStringAsFixed(2)} ${'currency.egp'.tr}',
              valueStyle: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCustomerCard(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;
    final customer = controller.tripCustomer.value;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('admin.trips.customer'.tr, style: theme.textTheme.titleMedium),
          const SizedBox(height: 16),
          if (customer != null) ...[
            _buildInfoRow(context, 'admin.trips.name'.tr, customer.name),
            const Divider(height: 20),
            _buildInfoRow(context, 'admin.trips.phone'.tr, customer.phone),
          ] else
            Text(
              'admin.trips.loading'.tr,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.textMuted,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDriverCard(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;
    final driver = controller.tripDriver.value;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('admin.trips.driver'.tr, style: theme.textTheme.titleMedium),
          const SizedBox(height: 16),
          if (driver != null) ...[
            _buildInfoRow(context, 'admin.trips.name'.tr, driver.name),
            const Divider(height: 20),
            _buildInfoRow(context, 'admin.trips.phone'.tr, driver.phone),
          ] else
            Text(
              'admin.trips.no_driver_assigned'.tr,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.textMuted,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBidsCard(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;
    final bids = controller.tripBids;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('admin.trips.bids'.tr, style: theme.textTheme.titleMedium),
          const SizedBox(height: 16),
          if (bids.isEmpty)
            Text(
              'admin.trips.no_bids'.tr,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.textMuted,
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: bids.length,
              separatorBuilder: (_, __) => const Divider(height: 20),
              itemBuilder: (context, index) {
                final bid = bids[index];
                final driverName = bid['driver_name'] ?? 'Unknown';
                final amount = (bid['amount'] as num?)?.toDouble() ?? 0.0;
                final status = bid['status'] ?? 'pending';
                final createdAt = bid['created_at'] != null
                    ? (bid['created_at'] as Timestamp).toDate()
                    : DateTime.now();

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            driverName,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('dd/MM/yyyy HH:mm').format(createdAt),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${amount.toStringAsFixed(2)} ${'currency.egp'.tr}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getBidStatusColor(
                              status,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusFull,
                            ),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _getBidStatusColor(status),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildIssueCreditButton(BuildContext context, trip) {
    return AppButton(
      text: 'admin.trips.issue_credit'.tr,
      onPressed: () => _showIssueCreditDialog(context, trip),
      variant: ButtonVariant.secondary,
      leadingIcon: Icons.account_balance_wallet,
    );
  }

  Future<void> _showIssueCreditDialog(BuildContext context, trip) async {
    final theme = Theme.of(context);
    final amountController = TextEditingController();
    final reasonController = TextEditingController();

    await Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'admin.trips.issue_credit_title'.tr,
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 20),

                // Amount field
                AppTextField(
                  controller: amountController,
                  label: 'admin.trips.credit_amount'.tr,
                  hint: 'admin.trips.enter_amount'.tr,
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.money,
                ),
                const SizedBox(height: 16),

                // Reason field
                AppTextField(
                  controller: reasonController,
                  label: 'admin.trips.credit_reason'.tr,
                  hint: 'admin.trips.enter_reason'.tr,
                  maxLines: 3,
                  prefixIcon: Icons.note,
                ),
                const SizedBox(height: 24),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(
                      width: 100,
                      child: AppButton(
                        text: 'common.cancel'.tr,
                        variant: ButtonVariant.text,
                        onPressed: Get.back,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 120,
                      child: AppButton(
                        text: 'common.confirm'.tr,
                        onPressed: () async {
                          final amount = double.tryParse(amountController.text);
                          final reason = reasonController.text.trim();

                          if (amount == null || amount <= 0) {
                            Get.snackbar(
                              'admin.trips.invalid_amount'.tr,
                              'admin.trips.invalid_amount_message'.tr,
                              snackPosition: SnackPosition.BOTTOM,
                            );
                            return;
                          }

                          if (reason.isEmpty) {
                            Get.snackbar(
                              'admin.trips.invalid_reason'.tr,
                              'admin.trips.invalid_reason_message'.tr,
                              snackPosition: SnackPosition.BOTTOM,
                            );
                            return;
                          }

                          final confirmed = await ConfirmDialog.show(
                            title: 'admin.trips.confirm_credit'.tr,
                            message: 'admin.trips.confirm_credit_message'
                                .trParams({
                                  'amount': amount.toStringAsFixed(2),
                                }),
                            confirmLabel: 'admin.trips.issue'.tr,
                          );

                          if (confirmed) {
                            Get.back();
                            await controller.issueCredit(
                              tripId: trip.tripId,
                              customerUid: trip.customerUid,
                              amount: amount,
                              reason: reason,
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value, {
    TextStyle? valueStyle,
  }) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(color: colors.textMuted),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 3,
          child: Text(value, style: valueStyle ?? theme.textTheme.bodyMedium),
        ),
      ],
    );
  }

  Color _getBidStatusColor(String status) {
    switch (status) {
      case 'accepted':
        return AdminStatusColors.success;
      case 'rejected':
        return AdminStatusColors.error;
      default:
        return AdminStatusColors.warning;
    }
  }
}
