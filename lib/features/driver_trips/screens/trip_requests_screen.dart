import 'package:biko/core/widgets/app_empty_state.dart';
import 'package:biko/core/widgets/app_loading.dart';
import 'package:biko/features/driver_trips/controllers/trip_requests_controller.dart';
import 'package:biko/features/driver_trips/widgets/trip_request_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Screen showing incoming trip requests for drivers.
class TripRequestsScreen extends GetView<TripRequestsController> {
  const TripRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('driver_trips.requests_title'.tr),
        centerTitle: false,
      ),
      body: Obx(_buildBody),
    );
  }

  Widget _buildBody() {
    if (!controller.isOnline) {
      return AppEmptyState(
        icon: Icons.wifi_off,
        title: 'driver_trips.offline_title'.tr,
        subtitle: 'driver_trips.offline_message'.tr,
      );
    }

    if (controller.isLoading.value) {
      return const AppLoading();
    }

    if (controller.tripRequests.isEmpty) {
      return AppEmptyState(
        icon: Icons.inbox_outlined,
        title: 'driver_trips.no_requests_title'.tr,
        subtitle: 'driver_trips.no_requests_message'.tr,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: controller.tripRequests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final request = controller.tripRequests[index];
        return TripRequestCard(
          request: request,
          onAccept: () => controller.acceptTrip(request),
          onBid: () => controller.submitBid(request),
          onDismiss: () => controller.dismissRequest(request.tripId),
        );
      },
    );
  }
}
