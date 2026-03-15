import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

/// Mock Firebase and service implementations for testing.
///
/// These mocks replace real services to enable:
/// - Offline testing without Firebase backend
/// - Deterministic test behavior
/// - Fast test execution
/// - Controlled test data

/// Mock authentication service for testing.
///
/// Provides fake authentication state without connecting to Firebase Auth.
///
/// Example:
/// ```dart
/// final mockAuth = MockAuthService();
/// await mockAuth.signInWithPhoneNumber('+201234567890');
/// expect(mockAuth.currentUser, isNotNull);
/// ```
class MockAuthService extends GetxService {
  final Rx<MockUser?> _currentUser = Rx<MockUser?>(null);
  final _authStateController = StreamController<MockUser?>.broadcast();

  MockUser? get currentUser => _currentUser.value;
  Stream<MockUser?> get authStateChanges => _authStateController.stream;

  Future<void> signInWithPhoneNumber(String phoneNumber) async {
    final user = MockUser(
      uid: 'test_${phoneNumber.replaceAll('+', '')}',
      phoneNumber: phoneNumber,
    );
    _currentUser.value = user;
    _authStateController.add(user);
  }

  Future<void> signOut() async {
    _currentUser.value = null;
    _authStateController.add(null);
  }

  Future<void> reset() async {
    _currentUser.value = null;
    _authStateController.add(null);
  }

  void dispose() {
    _authStateController.close();
  }
}

/// Mock user object for authentication testing.
class MockUser {
  MockUser({
    required this.uid,
    this.phoneNumber,
    this.email,
    this.displayName,
  });

  final String uid;
  final String? phoneNumber;
  final String? email;
  final String? displayName;
}

/// Mock Firestore service for testing.
///
/// Uses FakeFirebaseFirestore to provide in-memory Firestore implementation.
///
/// Example:
/// ```dart
/// final mockFirestore = MockFirestoreService();
/// await mockFirestore.collection('users').doc('user1').set({'name': 'Ahmed'});
/// final doc = await mockFirestore.collection('users').doc('user1').get();
/// ```
class MockFirestoreService extends GetxService {
  final FakeFirebaseFirestore _firestore = FakeFirebaseFirestore();

  FakeFirebaseFirestore get instance => _firestore;

  /// Reset mock Firestore by clearing all collections.
  Future<void> reset() async {
    final collections = [
      'users',
      'trips',
      'bids',
      'wallets',
      'transactions',
      'promo_codes',
      'referrals',
      'ratings',
      'notifications',
      'documents',
      'chat_messages',
    ];

    for (final collection in collections) {
      final docs = await _firestore.collection(collection).get();
      for (final doc in docs.docs) {
        await doc.reference.delete();
      }
    }
  }

  /// Seed Firestore with test data.
  Future<void> seed(Map<String, List<Map<String, dynamic>>> data) async {
    for (final entry in data.entries) {
      final collection = entry.key;
      final docs = entry.value;

      for (final doc in docs) {
        final docId = doc['uid'] ?? doc['tripId'] ?? doc['bidId'] ?? doc['id'];
        if (docId != null) {
          await _firestore.collection(collection).doc(docId as String).set(doc);
        } else {
          await _firestore.collection(collection).add(doc);
        }
      }
    }
  }

  void dispose() {
    // FakeFirebaseFirestore doesn't require explicit disposal
  }
}

/// Mock location service for testing.
///
/// Provides fake GPS positions without requiring device location access.
///
/// Example:
/// ```dart
/// final mockLocation = MockLocationService();
/// mockLocation.setMockLocation(30.0444, 31.2357); // Cairo
/// final position = await mockLocation.getCurrentLocation();
/// expect(position.latitude, equals(30.0444));
/// ```
class MockLocationService extends GetxService {
  Position? _currentPosition;
  final Map<String, String> _mockAddresses = {};

  Future<Position> getCurrentLocation() async {
    // Default to Cairo center
    _currentPosition ??= Position(
      latitude: 30.0444,
      longitude: 31.2357,
      timestamp: DateTime.now(),
      accuracy: 10.0,
      altitude: 0.0,
      heading: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
      altitudeAccuracy: 0.0,
      headingAccuracy: 0.0,
    );
    return _currentPosition!;
  }

  Future<String> getAddressFromCoordinates(double lat, double lng) async {
    final key = '${lat}_$lng';
    return _mockAddresses[key] ??
        'Mock Address: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
  }

  Future<LocationPermission> requestLocationPermission() async {
    return LocationPermission.always;
  }

  /// Set a mock GPS location for testing.
  void setMockLocation(double latitude, double longitude) {
    _currentPosition = Position(
      latitude: latitude,
      longitude: longitude,
      timestamp: DateTime.now(),
      accuracy: 10.0,
      altitude: 0.0,
      heading: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
      altitudeAccuracy: 0.0,
      headingAccuracy: 0.0,
    );
  }

  /// Set a mock address for specific coordinates.
  void setMockAddress(double lat, double lng, String address) {
    _mockAddresses['${lat}_$lng'] = address;
  }

  Future<void> reset() async {
    _currentPosition = null;
    _mockAddresses.clear();
  }

  void dispose() {
    // No resources to clean up
  }
}
