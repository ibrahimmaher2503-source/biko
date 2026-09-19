import 'package:google_maps_flutter/google_maps_flutter.dart';

List<LatLng> decodeGooglePolyline(String encoded) {
  final points = <LatLng>[];
  var index = 0;
  var latitude = 0;
  var longitude = 0;
  while (index < encoded.length) {
    int decode() {
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

    latitude += decode();
    longitude += decode();
    points.add(LatLng(latitude / 1e5, longitude / 1e5));
  }
  return points;
}
