import 'package:biko/core/models/enums.dart';
import 'package:biko/core/routes/app_routes.dart';
import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/features/admin/controllers/admin_trips_controller.dart';
import 'package:biko/features/admin/utils/admin_status_colors.dart';
import 'package:biko/features/admin/widgets/admin_data_table.dart';
import 'package:biko/features/admin/widgets/date_range_picker.dart';
import 'package:biko/features/admin/widgets/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// Admin Trips Management screen (US7).
///
/// Displays paginated trip list with filters:
/// - Trip type (ride, c2c_delivery, b2b_delivery)
/// - Trip status
/// - Date range
///
/// Each row is tappable to navigate to trip detail screen.
class AdminTripsScreen extends GetView<AdminTripsController> {
  const AdminTripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;

    return Scaffold(
      appBar: AppBar(
        title: Text('admin.trips.title'.tr),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.loadTrips,
            tooltip: 'admin.common.refresh'.tr,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page title and filter reset
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'admin.trips.list_title'.tr,
                  style: theme.textTheme.headlineSmall,
                ),
                TextButton.icon(
                  icon: const Icon(Icons.clear_all, size: 18),
                  label: Text('admin.common.reset_filters'.tr),
                  onPressed: controller.resetFilters,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Data table with filters
            Expanded(
              child: Obx(
                () => AdminDataTable(
                  columns: [
                    AdminColumn(label: 'admin.trips.trip_id'.tr, flex: 2),
                    AdminColumn(label: 'admin.trips.type'.tr, flex: 2),
                    AdminColumn(label: 'admin.trips.status'.tr, flex: 2),
                    AdminColumn(label: 'admin.trips.customer'.tr, flex: 2),
                    AdminColumn(label: 'admin.trips.driver'.tr, flex: 2),
                    AdminColumn(
                      label: 'admin.trips.fare'.tr,
                      flex: 2,
                      alignment: AlignmentDirectional.centerEnd,
                    ),
                    AdminColumn(label: 'admin.trips.payment'.tr, flex: 2),
                    AdminColumn(label: 'admin.trips.date'.tr, flex: 2),
                  ],
                  rows: controller.trips,
                  cellBuilder: (trip, colIndex) {
                    switch (colIndex) {
                      case 0:
                        // Trip ID (truncated)
                        final id = trip.id;
                        final truncated = id.length > 12
                            ? '${id.substring(0, 8)}...'
                            : id;
                        return Text(
                          truncated,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                            color: colors.textMuted,
                          ),
                        );
                      case 1:
                        // Type badge
                        return _buildTypeBadge(trip.type);
                      case 2:
                        // Status badge
                        return StatusBadge.fromTripStatus(trip.status);
                      case 3:
                        // Customer name (placeholder if not loaded)
                        return Text(
                          trip.customerUid.substring(0, 8),
                          style: theme.textTheme.bodyMedium,
                        );
                      case 4:
                        // Driver name (placeholder if not assigned)
                        return Text(
                          trip.driverUid?.substring(0, 8) ?? '-',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: trip.driverUid == null
                                ? colors.textMuted
                                : null,
                          ),
                        );
                      case 5:
                        // Fare
                        return Text(
                          '${(trip.acceptedPrice ?? trip.customerPrice).toStringAsFixed(2)} ${'currency.egp'.tr}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.end,
                        );
                      case 6:
                        // Payment method
                        return _buildPaymentBadge(trip.paymentMethod);
                      case 7:
                        // Date
                        return Text(
                          DateFormat('dd/MM/yyyy HH:mm').format(trip.createdAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.textMuted,
                          ),
                        );
                      default:
                        return const SizedBox.shrink();
                    }
                  },
                  filterWidgets: [
                    // Type filter
                    Obx(
                      () => DropdownButton<TripType?>(
                        value: controller.typeFilter.value,
                        hint: Text('admin.trips.filter_type'.tr),
                        items: [
                          DropdownMenuItem(
                            child: Text('admin.trips.all_types'.tr),
                          ),
                          ...TripType.values.map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text(
                                'admin.trips.type_${type.toJson()}'.tr,
                              ),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          controller.typeFilter.value = value;
                          controller.applyFilter();
                        },
                      ),
                    ),

                    // Status filter
                    Obx(
                      () => DropdownButton<TripStatus?>(
                        value: controller.statusFilter.value,
                        hint: Text('admin.trips.filter_status'.tr),
                        items: [
                          DropdownMenuItem(
                            child: Text('admin.trips.all_statuses'.tr),
                          ),
                          ...TripStatus.values.map((status) {
                            return DropdownMenuItem(
                              value: status,
                              child: Text(status.toJson().replaceAll('_', ' ')),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          controller.statusFilter.value = value;
                          controller.applyFilter();
                        },
                      ),
                    ),

                    // Date range filter
                    Obx(
                      () => AdminDateRangePicker(
                        selectedRange: controller.dateRange.value,
                        onRangeSelected: (range) {
                          controller.dateRange.value = range;
                          controller.applyFilter();
                        },
                      ),
                    ),
                  ],
                  onRowTap: (trip) {
                    Get.toNamed(AppRoutes.adminTripDetail, arguments: trip.id);
                  },
                  isLoading: controller.isLoading.value,
                  emptyMessage: 'admin.trips.no_trips'.tr,
                  hasNextPage: controller.hasMore.value,
                  hasPreviousPage: controller.currentPage.value > 1,
                  onNextPage: controller.nextPage,
                  onPreviousPage: controller.previousPage,
                  currentPage: controller.currentPage.value,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeBadge(TripType type) {
    final typeKey = type.toJson();
    final color = AdminStatusColors.tripTypeColor(typeKey);
    final bg = AdminStatusColors.tripTypeBgColor(typeKey);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Text(
        typeKey.replaceAll('_', ' '),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildPaymentBadge(PaymentMethod method) {
    String label;
    switch (method) {
      case PaymentMethod.cash:
        label = 'Cash';
      case PaymentMethod.wallet:
        label = 'Wallet';
      case PaymentMethod.card:
        label = 'Card';
      case PaymentMethod.vodafoneCash:
        label = 'Vodafone Cash';
      case PaymentMethod.fawry:
        label = 'Fawry';
    }
    return Text(
      label,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
    );
  }
}
