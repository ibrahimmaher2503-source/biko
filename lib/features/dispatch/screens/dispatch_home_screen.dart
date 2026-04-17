import 'package:biko/core/models/driver_location_model.dart';
import 'package:biko/core/models/trip_model.dart';
import 'package:biko/core/routes/app_routes.dart';
import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_loading.dart';
import 'package:biko/features/admin/controllers/admin_auth_controller.dart';
import 'package:biko/features/dispatch/controllers/dispatch_controller.dart';
import 'package:biko/features/dispatch/widgets/dispatch_driver_tile.dart';
import 'package:biko/features/dispatch/widgets/dispatch_trip_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Phone-optimised live dispatch control screen.
///
/// Three tabs — Waiting trips | Active trips | Online drivers.
/// Dispatcher can assign a driver to any waiting trip or cancel it.
class DispatchHomeScreen extends GetView<DispatchController> {
  const DispatchHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('dispatch.title'.tr),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              tooltip: 'dispatch.sign_out'.tr,
              onPressed: () => Get.find<AdminAuthController>().signOut(),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Obx(
              () => TabBar(
                tabs: [
                  Tab(
                    text:
                        '${'dispatch.waiting'.tr} (${controller.searchingTrips.length})',
                  ),
                  Tab(
                    text:
                        '${'dispatch.active'.tr} (${controller.activeTrips.length})',
                  ),
                  Tab(
                    text:
                        '${'dispatch.drivers'.tr} (${controller.onlineDrivers.length})',
                  ),
                ],
              ),
            ),
          ),
        ),
        body: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: AppLoading());
          }
          return TabBarView(
            children: [
              _WaitingTab(controller: controller),
              _ActiveTab(controller: controller),
              _DriversTab(controller: controller),
            ],
          );
        }),
      ),
    );
  }
}

// ──────────────────────────────────────────
// Waiting trips tab
// ──────────────────────────────────────────

class _WaitingTab extends StatelessWidget {
  const _WaitingTab({required this.controller});

  final DispatchController controller;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;

    return Obx(() {
      final trips = controller.searchingTrips;

      if (trips.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.hourglass_empty_rounded,
                  size: 48, color: colors.textMuted),
              const SizedBox(height: 12),
              Text(
                'dispatch.no_waiting'.tr,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: colors.textMuted),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () async {},
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 12),
          itemCount: trips.length,
          itemBuilder: (_, i) => DispatchTripCard(
            trip: trips[i],
            onAssign: () => _showAssignSheet(context, trips[i], controller),
            onCancel: () => _confirmCancel(context, trips[i].id, controller),
          ),
        ),
      );
    });
  }
}

// ──────────────────────────────────────────
// Active trips tab
// ──────────────────────────────────────────

class _ActiveTab extends StatelessWidget {
  const _ActiveTab({required this.controller});

  final DispatchController controller;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;

    return Obx(() {
      final trips = controller.activeTrips;

      if (trips.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.navigation_rounded, size: 48, color: colors.textMuted),
              const SizedBox(height: 12),
              Text(
                'dispatch.no_active'.tr,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: colors.textMuted),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemCount: trips.length,
        itemBuilder: (_, i) => DispatchTripCard(
          trip: trips[i],
          showCancel: false,
          onAssign: () => _showAssignSheet(context, trips[i], controller),
        ),
      );
    });
  }
}

// ──────────────────────────────────────────
// Online drivers tab
// ──────────────────────────────────────────

class _DriversTab extends StatelessWidget {
  const _DriversTab({required this.controller});

  final DispatchController controller;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;

    return Obx(() {
      final drivers = controller.onlineDrivers;

      if (drivers.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off_rounded, size: 48, color: colors.textMuted),
              const SizedBox(height: 12),
              Text(
                'dispatch.no_drivers'.tr,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: colors.textMuted),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        itemCount: drivers.length,
        itemBuilder: (_, i) => DispatchDriverTile(driver: drivers[i]),
      );
    });
  }
}

// ──────────────────────────────────────────
// Helpers
// ──────────────────────────────────────────

void _showAssignSheet(
  BuildContext context,
  TripModel trip,
  DispatchController controller,
) {
  Get.bottomSheet<void>(
    _AssignDriverSheet(trip: trip, controller: controller),
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
  );
}

void _confirmCancel(
  BuildContext context,
  String tripId,
  DispatchController controller,
) {
  Get.dialog<void>(
    AlertDialog(
      title: Text('dispatch.cancel_trip'.tr),
      content: Text('dispatch.cancel_confirm'.tr),
      actions: [
        TextButton(
          onPressed: Get.back,
          child: Text('common.cancel'.tr),
        ),
        TextButton(
          onPressed: () {
            Get.back<void>();
            controller.cancelTrip(tripId);
          },
          child: Text(
            'common.confirm'.tr,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ],
    ),
  );
}

// ──────────────────────────────────────────
// Assign-driver bottom sheet
// ──────────────────────────────────────────

class _AssignDriverSheet extends StatelessWidget {
  const _AssignDriverSheet({
    required this.trip,
    required this.controller,
  });

  final TripModel trip;
  final DispatchController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, scrollController) {
        return Column(
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                'dispatch.select_driver'.tr,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),

            // Driver list
            Expanded(
              child: Obx(() {
                final drivers = controller.onlineDrivers;

                if (drivers.isEmpty) {
                  return Center(
                    child: Text('dispatch.no_drivers'.tr),
                  );
                }

                return ListView.builder(
                  controller: scrollController,
                  itemCount: drivers.length,
                  itemBuilder: (_, i) {
                    return _SelectableDriverTile(
                      driver: drivers[i],
                      onSelect: () {
                        Get.back<void>();
                        controller.assignDriver(
                          tripId: trip.id,
                          driverUid: drivers[i].uid,
                          price: trip.customerPrice,
                        );
                      },
                    );
                  },
                );
              }),
            ),
          ],
        );
      },
    );
  }
}

class _SelectableDriverTile extends StatelessWidget {
  const _SelectableDriverTile({
    required this.driver,
    required this.onSelect,
  });

  final DriverLocationModel driver;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return DispatchDriverTile(
      driver: driver,
      isSelectable: true,
      onSelect: onSelect,
    );
  }
}

/// Guard that redirects to [AppRoutes.adminLogin] when the admin
/// auth controller reports the user is not authenticated.
class DispatchAuthGuard extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final auth = Get.find<AdminAuthController>();
    if (auth.isCheckingAuth.value) return null;
    if (!auth.isAuthenticated.value) {
      return const RouteSettings(name: AppRoutes.adminLogin);
    }
    return null;
  }
}
