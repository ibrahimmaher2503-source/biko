import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Map widget for trip tracking with driver marker, route, and pins.
///
/// Wraps GoogleMap with pickup/dropoff markers and driver position.
class TrackingMapWidget extends StatelessWidget {
  const TrackingMapWidget({
    required this.driverLocation,
    required this.driverHeading,
    this.pickupLocation,
    this.dropoffLocation,
    this.onMapCreated,
    super.key,
  });

  final LatLng? driverLocation;
  final double driverHeading;
  final LatLng? pickupLocation;
  final LatLng? dropoffLocation;
  final void Function(GoogleMapController)? onMapCreated;

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>{};

    // Pickup marker
    if (pickupLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: pickupLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
        ),
      );
    }

    // Dropoff marker
    if (dropoffLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('dropoff'),
          position: dropoffLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }

    // Driver marker
    if (driverLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: driverLocation!,
          rotation: driverHeading,
          anchor: const Offset(0.5, 0.5),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange,
          ),
        ),
      );
    }

    // Initial camera position
    final initialTarget =
        driverLocation ?? pickupLocation ?? const LatLng(30.0444, 31.2357);

    return GoogleMap(
      initialCameraPosition: CameraPosition(target: initialTarget, zoom: 15),
      markers: markers,
      onMapCreated: onMapCreated,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: false,
    );
  }
}
