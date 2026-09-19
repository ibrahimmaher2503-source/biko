import 'package:app_core/app_core.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:user_app/features/orders/order_models.dart';
import 'package:user_app/features/maps/polyline_decoder.dart';

class RoutePreviewMap extends StatelessWidget {
  const RoutePreviewMap({required this.quote, super.key});
  final RouteQuote quote;

  @override
  Widget build(BuildContext context) {
    final pickup = LatLng(quote.pickup.latitude, quote.pickup.longitude);
    final destination = LatLng(
      quote.destination.latitude,
      quote.destination.longitude,
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(BikoRadius.large),
      child: SizedBox(
        height: 220,
        child: GoogleMap(
          initialCameraPosition: CameraPosition(target: pickup, zoom: 12),
          myLocationButtonEnabled: false,
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
          polylines: {
            Polyline(
              polylineId: const PolylineId('route'),
              points: decodeGooglePolyline(quote.encodedPolyline),
              width: 5,
              color: Theme.of(context).colorScheme.primary,
            ),
          },
          onMapCreated: (controller) {
            final bounds = LatLngBounds(
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
            );
            controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 44));
          },
        ),
      ),
    );
  }
}
