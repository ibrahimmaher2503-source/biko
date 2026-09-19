import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/features/orders/order_models.dart';
import 'package:user_app/features/orders/order_rules.dart';
import 'package:user_app/features/maps/polyline_decoder.dart';

void main() {
  test('trusted quote parses exact pricing and expiry boundaries', () {
    final quote = RouteQuote.fromJson({
      'id': 'quote-1',
      'pickup_lat': 30.0444,
      'pickup_lng': 31.2357,
      'destination_lat': 30.1,
      'destination_lng': 31.3,
      'distance_meters': 5000,
      'duration_seconds': 900,
      'encoded_polyline': '_p~iF~ps|U_ulLnnqC_mqNvxq`@',
      'suggested_price': 100,
      'minimum_customer_price': 70,
      'expires_at': '2026-08-30T12:10:00Z',
    });
    expect(quote.suggestedPrice, 100);
    expect(quote.minimumCustomerPrice, 70);
    expect(quote.distanceMeters, 5000);
    expect(proposedPriceForQuote('69.99', quote), isNotNull);
    expect(proposedPriceForQuote('70', quote), isNull);
    expect(proposedPriceForQuote('150', quote), isNull);
  });

  test('Google encoded route becomes the expected preview points', () {
    final points = decodeGooglePolyline('_p~iF~ps|U_ulLnnqC_mqNvxq`@');
    expect(points, hasLength(3));
    expect(points.first.latitude, closeTo(38.5, 0.00001));
    expect(points.last.longitude, closeTo(-126.453, 0.00001));
  });
}
