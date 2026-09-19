import 'package:app_core/app_core.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'driver_models.dart';

class DriverRouteMap extends StatelessWidget {
  const DriverRouteMap({
    required this.order,
    this.currentLocationEnabled = false,
    super.key,
  });
  final DriverOrder order;
  final bool currentLocationEnabled;

  @override
  Widget build(BuildContext context) {
    if (!order.hasRouteCoordinates) return const SizedBox.shrink();
    final pickup = LatLng(order.pickupLatitude!, order.pickupLongitude!);
    final destination = LatLng(
      order.destinationLatitude!,
      order.destinationLongitude!,
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: 230,
        child: GoogleMap(
          initialCameraPosition: CameraPosition(target: pickup, zoom: 12),
          myLocationEnabled: currentLocationEnabled,
          myLocationButtonEnabled: currentLocationEnabled,
          zoomControlsEnabled: false,
          markers: {
            Marker(markerId: const MarkerId('pickup'), position: pickup),
            Marker(
              markerId: const MarkerId('destination'),
              position: destination,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueGreen,
              ),
            ),
          },
          polylines: order.routePolyline?.isNotEmpty == true
              ? {
                  Polyline(
                    polylineId: const PolylineId('route'),
                    points: _decode(order.routePolyline!),
                    color: Theme.of(context).colorScheme.primary,
                    width: 5,
                  ),
                }
              : const {},
          onMapCreated: (controller) => controller.animateCamera(
            CameraUpdate.newLatLngBounds(
              LatLngBounds(
                southwest: LatLng(
                  pickup.latitude < destination.latitude
                      ? pickup.latitude
                      : destination.latitude,
                  pickup.longitude < destination.longitude
                      ? pickup.longitude
                      : destination.longitude,
                ),
                northeast: LatLng(
                  pickup.latitude > destination.latitude
                      ? pickup.latitude
                      : destination.latitude,
                  pickup.longitude > destination.longitude
                      ? pickup.longitude
                      : destination.longitude,
                ),
              ),
              44,
            ),
          ),
        ),
      ),
    );
  }
}

Future<bool> openExternalNavigation(DriverOrder order) {
  final toDestination = order.status == OrderStatus.inProgress;
  final latitude = toDestination
      ? order.destinationLatitude
      : order.pickupLatitude;
  final longitude = toDestination
      ? order.destinationLongitude
      : order.pickupLongitude;
  if (latitude == null || longitude == null) return Future.value(false);
  return launchUrl(
    Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': '$latitude,$longitude',
      'travelmode': 'driving',
    }),
    mode: LaunchMode.externalApplication,
  );
}

List<LatLng> _decode(String encoded) {
  final points = <LatLng>[];
  var index = 0;
  var latitude = 0;
  var longitude = 0;
  while (index < encoded.length) {
    int next() {
      var result = 0;
      var shift = 0;
      int value;
      do {
        value = encoded.codeUnitAt(index++) - 63;
        result |= (value & 0x1f) << shift;
        shift += 5;
      } while (value >= 0x20 && index < encoded.length);
      return (result & 1) != 0 ? ~(result >> 1) : result >> 1;
    }

    latitude += next();
    longitude += next();
    points.add(LatLng(latitude / 1e5, longitude / 1e5));
  }
  return points;
}
