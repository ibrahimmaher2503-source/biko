import 'package:biko/core/models/place_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  group('PlaceModel', () {
    const testPlace = PlaceModel(
      placeId: 'test_place_id',
      name: 'Cairo Tower',
      address: 'Gezira, Cairo, Egypt',
      lat: 30.0459,
      lng: 31.2243,
    );

    // ===== fromMap =====

    group('fromMap', () {
      test('parses all fields from a complete map', () {
        final map = {
          'place_id': 'place_001',
          'name': 'Tahrir Square',
          'address': 'Tahrir Sq, Cairo Governorate',
          'lat': 30.0444,
          'lng': 31.2357,
        };

        final place = PlaceModel.fromMap(map);

        expect(place.placeId, equals('place_001'));
        expect(place.name, equals('Tahrir Square'));
        expect(place.address, equals('Tahrir Sq, Cairo Governorate'));
        expect(place.lat, equals(30.0444));
        expect(place.lng, equals(31.2357));
      });

      test('uses defaults for missing fields', () {
        final place = PlaceModel.fromMap({});

        expect(place.placeId, equals(''));
        expect(place.name, equals(''));
        expect(place.address, equals(''));
        expect(place.lat, equals(0.0));
        expect(place.lng, equals(0.0));
      });

      test('handles integer lat/lng values', () {
        final map = {'lat': 30, 'lng': 31, 'name': 'Test', 'address': ''};
        final place = PlaceModel.fromMap(map);
        expect(place.lat, equals(30.0));
        expect(place.lng, equals(31.0));
      });
    });

    // ===== toMap =====

    group('toMap', () {
      test('serializes all fields correctly', () {
        final map = testPlace.toMap();

        expect(map['place_id'], equals('test_place_id'));
        expect(map['name'], equals('Cairo Tower'));
        expect(map['address'], equals('Gezira, Cairo, Egypt'));
        expect(map['lat'], equals(30.0459));
        expect(map['lng'], equals(31.2243));
      });

      test('round-trips through toMap and fromMap', () {
        final map = testPlace.toMap();
        final restored = PlaceModel.fromMap(map);

        expect(restored.placeId, equals(testPlace.placeId));
        expect(restored.name, equals(testPlace.name));
        expect(restored.address, equals(testPlace.address));
        expect(restored.lat, equals(testPlace.lat));
        expect(restored.lng, equals(testPlace.lng));
      });
    });

    // ===== copyWith =====

    group('copyWith', () {
      test('returns equal model when no fields changed', () {
        final copy = testPlace.copyWith();

        expect(copy.placeId, equals(testPlace.placeId));
        expect(copy.name, equals(testPlace.name));
        expect(copy.address, equals(testPlace.address));
        expect(copy.lat, equals(testPlace.lat));
        expect(copy.lng, equals(testPlace.lng));
      });

      test('updates only specified fields', () {
        final updated = testPlace.copyWith(name: 'Ramses Square');

        expect(updated.name, equals('Ramses Square'));
        expect(updated.placeId, equals(testPlace.placeId));
        expect(updated.lat, equals(testPlace.lat));
      });

      test('can update all fields', () {
        final updated = testPlace.copyWith(
          placeId: 'new_id',
          name: 'New Place',
          address: 'New Address',
          lat: 29.9773,
          lng: 31.1325,
        );

        expect(updated.placeId, equals('new_id'));
        expect(updated.name, equals('New Place'));
        expect(updated.address, equals('New Address'));
        expect(updated.lat, equals(29.9773));
        expect(updated.lng, equals(31.1325));
      });
    });

    // ===== latLng getter =====

    group('latLng getter', () {
      test('returns LatLng from lat and lng fields', () {
        final latLng = testPlace.latLng;

        expect(latLng, isA<LatLng>());
        expect(latLng.latitude, equals(testPlace.lat));
        expect(latLng.longitude, equals(testPlace.lng));
      });
    });

    // ===== fromGooglePlaces =====

    group('fromGooglePlaces', () {
      test('parses Google Places API result', () {
        final result = {
          'place_id': 'gp_001',
          'name': 'Cairo International Airport',
          'formatted_address': 'Cairo Airport, Cairo, Egypt',
          'geometry': {
            'location': {'lat': 30.1219, 'lng': 31.4056},
          },
        };

        final place = PlaceModel.fromGooglePlaces(result);

        expect(place.placeId, equals('gp_001'));
        expect(place.name, equals('Cairo International Airport'));
        expect(place.address, equals('Cairo Airport, Cairo, Egypt'));
        expect(place.lat, equals(30.1219));
        expect(place.lng, equals(31.4056));
      });

      test('defaults to empty strings when fields are missing', () {
        final place = PlaceModel.fromGooglePlaces({});

        expect(place.placeId, equals(''));
        expect(place.name, equals(''));
        expect(place.address, equals(''));
        expect(place.lat, equals(0.0));
        expect(place.lng, equals(0.0));
      });
    });

    // ===== equality =====

    group('equality', () {
      test('equal places have the same placeId', () {
        const a = PlaceModel(
          placeId: 'same_id',
          name: 'A',
          address: 'addr',
          lat: 1.0,
          lng: 2.0,
        );
        const b = PlaceModel(
          placeId: 'same_id',
          name: 'B',
          address: 'different',
          lat: 3.0,
          lng: 4.0,
        );

        expect(a, equals(b));
      });

      test('places with different placeIds are not equal', () {
        const a = PlaceModel(
          placeId: 'id_a',
          name: 'A',
          address: '',
          lat: 0.0,
          lng: 0.0,
        );
        const b = PlaceModel(
          placeId: 'id_b',
          name: 'A',
          address: '',
          lat: 0.0,
          lng: 0.0,
        );

        expect(a, isNot(equals(b)));
      });
    });

    // ===== toString =====

    group('toString', () {
      test('includes name, lat, and lng', () {
        final str = testPlace.toString();
        expect(str, contains('Cairo Tower'));
        expect(str, contains('30.0459'));
        expect(str, contains('31.2243'));
      });
    });
  });

  group('PlaceAutocompleteResult', () {
    group('fromJson', () {
      test('parses complete structured formatting', () {
        final json = {
          'place_id': 'auto_001',
          'description': 'Cairo Tower, Gezira Island',
          'structured_formatting': {
            'main_text': 'Cairo Tower',
            'secondary_text': 'Gezira Island, Cairo',
          },
        };

        final result = PlaceAutocompleteResult.fromJson(json);

        expect(result.placeId, equals('auto_001'));
        expect(result.description, equals('Cairo Tower, Gezira Island'));
        expect(result.mainText, equals('Cairo Tower'));
        expect(result.secondaryText, equals('Gezira Island, Cairo'));
      });

      test('uses empty strings for missing structured_formatting', () {
        final json = {
          'place_id': 'auto_002',
          'description': 'Test',
        };

        final result = PlaceAutocompleteResult.fromJson(json);

        expect(result.mainText, equals(''));
        expect(result.secondaryText, equals(''));
      });
    });
  });
}
