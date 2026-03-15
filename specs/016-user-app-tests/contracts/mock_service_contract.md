# Mock Service Contract

**Version**: 1.0.0
**Last Updated**: 2026-03-11
**Applies To**: All mock services in `test/helpers/mock_services.dart`

## Purpose

Mock services replace Firebase dependencies (Auth, Firestore, Realtime DB, Storage, Location) for offline testing. Every mock service MUST implement the same interface as the real service it replaces, ensuring tests can swap implementations without code changes.

## Contract

### Interface Compliance

Mock services MUST implement the exact same public interface as the real service:

```dart
// Real service
abstract class AuthService extends GetxService {
  User? get currentUser;
  Stream<User?> get authStateChanges;
  Future<UserCredential> signInWithPhoneNumber(String phoneNumber);
  Future<void> signOut();
}

// Mock MUST implement the same interface
class MockAuthService implements AuthService {
  @override
  User? get currentUser => _currentUser.value;

  @override
  Stream<User?> get authStateChanges => _authStateChanges.stream;

  @override
  Future<UserCredential> signInWithPhoneNumber(String phoneNumber) async {
    // Mock implementation
  }

  @override
  Future<void> signOut() async {
    // Mock implementation
  }
}
```

### Required Methods

Every mock service MUST implement:

```dart
/// Resets the mock to initial state, clears all data
Future<void> reset();

/// Seeds the mock with predefined test data
Future<void> seed(Map<String, dynamic> testData);

/// Cleans up resources (stream controllers, subscriptions)
void dispose();
```

### In-Memory Storage

Mock services MUST:
- Store all data in memory (never persist to real Firebase)
- Use `Map<String, dynamic>` or `List` for data storage
- Clear storage on `reset()`

### Stream Management

Mocks with reactive streams MUST:
- Use `StreamController` for broadcasting changes
- Close all stream controllers in `dispose()`
- Emit events when data changes (matching real service behavior)

## Constraints

### Behavior Parity

Mocks MUST replicate real service behavior:
- ✅ Return types match exactly
- ✅ Async operations use `Future` (even if mock is synchronous internally)
- ✅ Stream emissions match real service patterns
- ✅ Error conditions throw the same exception types

### Performance

Mocks MUST be fast:
- ✅ All operations complete in <10ms
- ✅ No network calls
- ✅ No file I/O
- ✅ No CPU-intensive operations

### Determinism

Mocks MUST be deterministic:
- ✅ Same input always produces same output
- ✅ No random behavior (unless explicitly seeded)
- ✅ Timestamps use controllable test values

## Example: MockAuthService

```dart
class MockAuthService implements AuthService {
  final Rx<User?> _currentUser = Rx<User?>(null);
  final StreamController<User?> _authStateChanges = StreamController.broadcast();

  @override
  User? get currentUser => _currentUser.value;

  @override
  Stream<User?> get authStateChanges => _authStateChanges.stream;

  @override
  Future<UserCredential> signInWithPhoneNumber(String phoneNumber) async {
    final mockUser = User(
      uid: 'test_${phoneNumber.replaceAll('+', '')}',
      phoneNumber: phoneNumber,
    );
    _currentUser.value = mockUser;
    _authStateChanges.add(mockUser);

    return MockUserCredential(mockUser);
  }

  @override
  Future<void> signOut() async {
    _currentUser.value = null;
    _authStateChanges.add(null);
  }

  Future<void> reset() async {
    _currentUser.value = null;
    _authStateChanges.add(null);
  }

  Future<void> seed(Map<String, dynamic> testData) async {
    if (testData.containsKey('user')) {
      _currentUser.value = testData['user'] as User;
      _authStateChanges.add(_currentUser.value);
    }
  }

  void dispose() {
    _authStateChanges.close();
  }
}
```

## Example: MockFirestoreService

```dart
class MockFirestoreService implements FirestoreService {
  final FakeFirebaseFirestore _firestore = FakeFirebaseFirestore();

  @override
  Future<void> createUser(UserModel user) async {
    await _firestore.collection('users').doc(user.uid).set(user.toMap());
  }

  @override
  Future<UserModel?> getUser(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!);
  }

  @override
  Stream<List<TripModel>> watchUserTrips(String userId) {
    return _firestore
        .collection('trips')
        .where('customerId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => TripModel.fromMap(doc.data()))
          .toList();
    });
  }

  Future<void> reset() async {
    final collections = ['users', 'trips', 'bids', 'wallets', 'transactions'];
    for (final collection in collections) {
      final docs = await _firestore.collection(collection).get();
      for (final doc in docs.docs) {
        await doc.reference.delete();
      }
    }
  }

  Future<void> seed(Map<String, dynamic> testData) async {
    if (testData.containsKey('users')) {
      for (final user in testData['users'] as List<UserModel>) {
        await createUser(user);
      }
    }
    if (testData.containsKey('trips')) {
      for (final trip in testData['trips'] as List<TripModel>) {
        await _firestore.collection('trips').doc(trip.tripId).set(trip.toMap());
      }
    }
  }

  void dispose() {
    // FakeFirebaseFirestore doesn't require explicit disposal
  }
}
```

## Example: MockLocationService

```dart
class MockLocationService implements LocationService {
  Position? _currentPosition;
  final Map<String, String> _mockAddresses = {};

  @override
  Future<Position> getCurrentLocation() async {
    if (_currentPosition == null) {
      // Default to Cairo center
      _currentPosition = Position(
        latitude: 30.0444,
        longitude: 31.2357,
        timestamp: DateTime.now(),
        accuracy: 10.0,
        altitude: 0.0,
        heading: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      );
    }
    return _currentPosition!;
  }

  @override
  Future<String> getAddressFromCoordinates(double lat, double lng) async {
    final key = '${lat}_${lng}';
    return _mockAddresses[key] ??
        'Mock Address: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
  }

  @override
  Future<LocationPermission> requestLocationPermission() async {
    return LocationPermission.always;
  }

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
    );
  }

  void setMockAddress(double lat, double lng, String address) {
    _mockAddresses['${lat}_${lng}'] = address;
  }

  Future<void> reset() async {
    _currentPosition = null;
    _mockAddresses.clear();
  }

  Future<void> seed(Map<String, dynamic> testData) async {
    if (testData.containsKey('position')) {
      _currentPosition = testData['position'] as Position;
    }
    if (testData.containsKey('addresses')) {
      _mockAddresses.addAll(testData['addresses'] as Map<String, String>);
    }
  }

  void dispose() {
    // No resources to clean up
  }
}
```

## Usage in Tests

```dart
void main() {
  late MockAuthService mockAuth;
  late MockFirestoreService mockFirestore;
  late AuthController controller;

  setUp(() {
    // Register mocks
    Get.testMode = true;
    mockAuth = MockAuthService();
    mockFirestore = MockFirestoreService();
    Get.put<AuthService>(mockAuth);
    Get.put<FirestoreService>(mockFirestore);

    // Seed with test data
    mockAuth.seed({'user': UserFactory.create()});

    // Initialize controller
    controller = AuthController();
  });

  tearDown(() async {
    // Reset mocks
    await mockAuth.reset();
    await mockFirestore.reset();
    mockAuth.dispose();
    mockFirestore.dispose();

    // Clean up GetX
    Get.reset();
  });

  test('login updates current user', () async {
    await controller.login('+201234567890');

    expect(mockAuth.currentUser, isNotNull);
    expect(mockAuth.currentUser!.phoneNumber, equals('+201234567890'));
  });
}
```

## Validation

Mock services MUST pass these validation checks:
- ✅ Implements all methods from real service interface
- ✅ `reset()` clears all data
- ✅ `seed()` populates data correctly
- ✅ `dispose()` closes all stream controllers
- ✅ All async methods return `Future` (even if instantly resolved)
- ✅ Stream emissions match real service behavior
- ✅ No Firebase network calls are made

## Non-Goals

Mock services MUST NOT:
- ❌ Connect to real Firebase (always offline)
- ❌ Persist data to disk (all in-memory)
- ❌ Have network latency (instant responses)
- ❌ Randomly fail (deterministic behavior only)
- ❌ Implement business logic (that belongs in controllers/services being tested)
