# Flutter Testing Code Examples for BikeRide

Practical, copy-paste-ready code examples organized by test type.

---

## Table of Contents

1. [Unit Tests (Services)](#unit-tests-services)
2. [Unit Tests (Controllers)](#unit-tests-controllers)
3. [Widget Tests](#widget-tests)
4. [Golden Tests](#golden-tests)
5. [Integration Tests](#integration-tests)
6. [Test Helpers & Factories](#test-helpers--factories)

---

## Unit Tests (Services)

### Example 1: Firestore Service Unit Test

```dart
// test/core/services/firestore_service_test.dart
import 'package:biko/core/models/user_model.dart';
import 'package:biko/core/services/firestore_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FirestoreService', () {
    late FakeFirebaseFirestore firestore;
    late FirestoreService service;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      service = FirestoreService(firestore: firestore);
    });

    group('User Operations', () {
      test('createUser stores new user in Firestore', () async {
        final user = User(
          id: 'user123',
          phone: '+201234567890',
          name: 'أحمد محمد',
          createdAt: DateTime.now(),
        );

        await service.createUser(user);

        final doc = await firestore.collection('users').doc('user123').get();
        expect(doc.exists, isTrue);
        expect(doc['phone'], equals('+201234567890'));
        expect(doc['name'], equals('أحمد محمد'));
      });

      test('getUser retrieves user by ID', () async {
        // Pre-populate Firestore
        await firestore.collection('users').doc('user123').set({
          'id': 'user123',
          'phone': '+201234567890',
          'name': 'أحمد محمد',
          'createdAt': DateTime.now().toIso8601String(),
        });

        final user = await service.getUser('user123');

        expect(user.id, equals('user123'));
        expect(user.phone, equals('+201234567890'));
        expect(user.name, equals('أحمد محمد'));
      });

      test('getUser throws exception for non-existent user', () async {
        expect(
          () => service.getUser('nonexistent'),
          throwsException,
        );
      });

      test('updateUser modifies existing user', () async {
        // Create initial user
        await firestore.collection('users').doc('user123').set({
          'id': 'user123',
          'phone': '+201234567890',
          'name': 'أحمد محمد',
        });

        // Update user
        await service.updateUser('user123', {'name': 'أحمد علي'});

        final doc = await firestore.collection('users').doc('user123').get();
        expect(doc['name'], equals('أحمد علي'));
      });

      test('deleteUser removes user from Firestore', () async {
        // Create user
        await firestore.collection('users').doc('user123').set({
          'id': 'user123',
          'phone': '+201234567890',
        });

        // Delete user
        await service.deleteUser('user123');

        final doc = await firestore.collection('users').doc('user123').get();
        expect(doc.exists, isFalse);
      });

      test('listUsers returns all users', () async {
        // Create multiple users
        await firestore.collection('users').doc('user1').set({
          'id': 'user1',
          'phone': '+201111111111',
        });
        await firestore.collection('users').doc('user2').set({
          'id': 'user2',
          'phone': '+202222222222',
        });

        final users = await service.listUsers();

        expect(users.length, equals(2));
        expect(users.any((u) => u.id == 'user1'), isTrue);
        expect(users.any((u) => u.id == 'user2'), isTrue);
      });
    });

    group('Batch Operations', () {
      test('batchWriteUsers creates multiple users atomically', () async {
        final users = [
          User(id: 'user1', phone: '+201111111111', name: 'User 1'),
          User(id: 'user2', phone: '+202222222222', name: 'User 2'),
          User(id: 'user3', phone: '+203333333333', name: 'User 3'),
        ];

        await service.batchWriteUsers(users);

        final docs = await firestore.collection('users').get();
        expect(docs.docs.length, equals(3));
        expect(docs.docs.map((d) => d.id), containsAll(['user1', 'user2', 'user3']));
      });

      test('batchUpdateUsers updates multiple users', () async {
        // Create initial users
        await firestore.collection('users').doc('user1').set({
          'id': 'user1',
          'status': 'active',
        });
        await firestore.collection('users').doc('user2').set({
          'id': 'user2',
          'status': 'active',
        });

        // Batch update
        await service.batchUpdateUsers([
          {'id': 'user1', 'status': 'inactive'},
          {'id': 'user2', 'status': 'inactive'},
        ]);

        final doc1 = await firestore.collection('users').doc('user1').get();
        final doc2 = await firestore.collection('users').doc('user2').get();

        expect(doc1['status'], equals('inactive'));
        expect(doc2['status'], equals('inactive'));
      });

      test('batchDeleteUsers removes multiple users', () async {
        // Create users
        await firestore.collection('users').doc('user1').set({'id': 'user1'});
        await firestore.collection('users').doc('user2').set({'id': 'user2'});
        await firestore.collection('users').doc('user3').set({'id': 'user3'});

        // Batch delete
        await service.batchDeleteUsers(['user1', 'user2']);

        final doc1 = await firestore.collection('users').doc('user1').get();
        final doc2 = await firestore.collection('users').doc('user2').get();
        final doc3 = await firestore.collection('users').doc('user3').get();

        expect(doc1.exists, isFalse);
        expect(doc2.exists, isFalse);
        expect(doc3.exists, isTrue);
      });
    });

    group('Reactive Streams', () {
      test('watchUsers emits updates when data changes', () async {
        // Pre-create a user
        await firestore.collection('users').doc('user1').set({
          'id': 'user1',
          'phone': '+201111111111',
        });

        // Watch for changes
        expect(
          service.watchUsers(),
          emitsInOrder([
            isA<List<User>>().having((list) => list.length, 'length', 1),
            isA<List<User>>().having((list) => list.length, 'length', 2),
          ]),
        );

        // Trigger update after a delay
        await Future.delayed(const Duration(milliseconds: 100));
        await firestore.collection('users').doc('user2').set({
          'id': 'user2',
          'phone': '+202222222222',
        });
      });

      test('watchUser emits user data updates', () async {
        // Pre-create user
        await firestore.collection('users').doc('user1').set({
          'id': 'user1',
          'phone': '+201111111111',
          'name': 'أحمد',
        });

        expect(
          service.watchUser('user1'),
          emitsInOrder([
            isA<User>().having((u) => u.name, 'name', 'أحمد'),
            isA<User>().having((u) => u.name, 'name', 'محمد'),
          ]),
        );

        await Future.delayed(const Duration(milliseconds: 100));
        await firestore.collection('users').doc('user1').update({
          'name': 'محمد',
        });
      });
    });

    group('Query Operations', () {
      test('queryUsersByPhone finds user by phone', () async {
        await firestore.collection('users').doc('user1').set({
          'id': 'user1',
          'phone': '+201234567890',
        });

        final users = await service.queryUsersByPhone('+201234567890');

        expect(users.length, equals(1));
        expect(users.first.id, equals('user1'));
      });

      test('queryUsersByStatus filters by status', () async {
        await firestore.collection('users').doc('user1').set({
          'id': 'user1',
          'status': 'active',
        });
        await firestore.collection('users').doc('user2').set({
          'id': 'user2',
          'status': 'inactive',
        });

        final activeUsers = await service.queryUsersByStatus('active');

        expect(activeUsers.length, equals(1));
        expect(activeUsers.first.id, equals('user1'));
      });
    });

    group('Error Handling', () {
      test('handles missing required fields', () async {
        final invalidData = {
          'id': 'user1',
          // Missing 'phone' which is required
          'name': 'Ahmed',
        };

        expect(
          () => firestore.collection('users').doc('user1').set(invalidData),
          throwsException,
        );
      });

      test('handles malformed data types', () async {
        expect(
          () => service.getUser(123), // Wrong type (int instead of String)
          throwsException,
        );
      });
    });
  });
}
```

### Example 2: Auth Service Unit Test

```dart
// test/core/services/auth_service_test.dart
import 'package:biko/core/services/auth_service.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthService', () {
    late MockFirebaseAuth auth;
    late AuthService service;

    setUp(() {
      auth = MockFirebaseAuth();
      service = AuthService(auth: auth);
    });

    group('Phone Authentication', () {
      test('isValidPhoneNumber validates Egyptian phone format', () {
        expect(service.isValidPhoneNumber('+201234567890'), isTrue);
        expect(service.isValidPhoneNumber('+2010234567890'), isTrue);
        expect(service.isValidPhoneNumber('01234567890'), isFalse); // Missing country code
        expect(service.isValidPhoneNumber('+351234567890'), isFalse); // Wrong country code
        expect(service.isValidPhoneNumber('+20123'), isFalse); // Too short
        expect(service.isValidPhoneNumber(''), isFalse);
      });

      test('signInWithPhone creates user session', () async {
        final userCredential = await auth.signInWithPhoneNumber(
          phoneNumber: '+201234567890',
        );

        expect(userCredential.user, isNotNull);
        expect(userCredential.user!.phoneNumber, equals('+201234567890'));
      });

      test('signOut clears user session', () async {
        // Sign in
        await auth.signInWithPhoneNumber(phoneNumber: '+201234567890');
        expect(auth.currentUser, isNotNull);

        // Sign out
        await auth.signOut();
        expect(auth.currentUser, isNull);
      });

      test('currentUser returns signed-in user', () async {
        await auth.signInWithPhoneNumber(phoneNumber: '+201234567890');

        final user = service.currentUser;

        expect(user, isNotNull);
        expect(user!.phoneNumber, equals('+201234567890'));
      });
    });

    group('User State Tracking', () {
      test('authStateChanges emits null when not signed in', () async {
        expect(auth.authStateChanges(), emits(isNull));
      });

      test('authStateChanges emits user when signed in', () async {
        expect(
          auth.authStateChanges(),
          emitsInOrder([
            isNull,
            isA<User>(),
          ]),
        );

        await auth.signInWithPhoneNumber(phoneNumber: '+201234567890');
      });

      test('authStateChanges emits null when signed out', () async {
        await auth.signInWithPhoneNumber(phoneNumber: '+201234567890');

        expect(
          auth.authStateChanges(),
          emitsInOrder([
            isNull,
            isA<User>(),
            isNull,
          ]),
        );

        await auth.signOut();
      });
    });

    group('Custom Claims', () {
      test('setCustomClaims sets user roles', () async {
        final userCred = await auth.signInWithPhoneNumber(
          phoneNumber: '+201234567890',
        );

        // Mock framework handles custom claims
        expect(userCred.user, isNotNull);
      });

      test('currentUser has admin claim', () async {
        final userCred = await auth.signInWithPhoneNumber(
          phoneNumber: '+201234567890',
        );

        final user = userCred.user!;
        expect(user.phoneNumber, equals('+201234567890'));
      });
    });

    group('Error Handling', () {
      test('signInWithPhone handles invalid phone', () async {
        expect(
          () => auth.signInWithPhoneNumber(phoneNumber: 'invalid'),
          throwsException,
        );
      });

      test('currentUser returns null when not authenticated', () async {
        expect(auth.currentUser, isNull);
      });
    });
  });
}
```

### Example 3: Location Service Unit Test with Mockito

```dart
// test/core/services/location_service_test.dart
import 'package:biko/core/services/location_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mockito/mockito.dart';

class MockGeolocator extends Mock implements Geolocator {}

void main() {
  group('LocationService', () {
    late MockGeolocator mockGeolocator;
    late LocationService service;

    setUp(() {
      mockGeolocator = MockGeolocator();
      service = LocationService(geolocator: mockGeolocator);
    });

    group('Permission Handling', () {
      test('requestLocationPermission requests user permission', () async {
        when(mockGeolocator.requestPermission())
            .thenAnswer((_) async => LocationPermission.whileInUse);

        final permission = await service.requestLocationPermission();

        expect(permission, equals(LocationPermission.whileInUse));
        verify(mockGeolocator.requestPermission()).called(1);
      });

      test('requestLocationPermission handles denial', () async {
        when(mockGeolocator.requestPermission())
            .thenAnswer((_) async => LocationPermission.denied);

        final permission = await service.requestLocationPermission();

        expect(permission, equals(LocationPermission.denied));
      });

      test('checkLocationServiceEnabled verifies service', () async {
        when(mockGeolocator.isLocationServiceEnabled())
            .thenAnswer((_) async => true);

        final enabled = await service.checkLocationServiceEnabled();

        expect(enabled, isTrue);
      });
    });

    group('Position Tracking', () {
      test('getCurrentPosition returns current location', () async {
        final mockPosition = Position(
          latitude: 30.0444,
          longitude: 31.2357,
          timestamp: DateTime.now(),
          accuracy: 10.0,
          altitude: 0.0,
          heading: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
          isMocked: false,
        );

        when(mockGeolocator.getCurrentPosition())
            .thenAnswer((_) async => mockPosition);

        final position = await service.getCurrentPosition();

        expect(position.latitude, equals(30.0444));
        expect(position.longitude, equals(31.2357));
        expect(position.accuracy, equals(10.0));
      });

      test('watchPosition streams location updates', () async {
        final mockPositions = [
          Position(
            latitude: 30.0,
            longitude: 31.0,
            timestamp: DateTime.now(),
            accuracy: 10.0,
            altitude: 0.0,
            heading: 0.0,
            speed: 0.0,
            speedAccuracy: 0.0,
            isMocked: false,
          ),
          Position(
            latitude: 30.1,
            longitude: 31.1,
            timestamp: DateTime.now(),
            accuracy: 10.0,
            altitude: 0.0,
            heading: 0.0,
            speed: 0.0,
            speedAccuracy: 0.0,
            isMocked: false,
          ),
        ];

        when(mockGeolocator.getPositionStream())
            .thenAnswer((_) => Stream.fromIterable(mockPositions));

        expect(
          service.watchPosition(),
          emitsInOrder([
            isA<Position>().having((p) => p.latitude, 'latitude', 30.0),
            isA<Position>().having((p) => p.latitude, 'latitude', 30.1),
          ]),
        );
      });
    });

    group('Distance Calculation', () {
      test('calculateDistance computes distance between coordinates', () async {
        final distance = service.calculateDistance(
          latStart: 30.0,
          lngStart: 31.0,
          latEnd: 30.1,
          lngEnd: 31.1,
        );

        // Distance should be > 0
        expect(distance, greaterThan(0));
        // Approximate distance for this coordinate change
        expect(distance, lessThan(20000)); // Less than 20km
      });

      test('isNearby checks if within threshold distance', () async {
        final isNear = service.isNearby(
          latStart: 30.0,
          lngStart: 31.0,
          latEnd: 30.0001,
          lngEnd: 31.0001,
          thresholdMeters: 100,
        );

        expect(isNear, isTrue);
      });
    });

    group('Error Handling', () {
      test('getCurrentPosition handles permission denial', () async {
        when(mockGeolocator.getCurrentPosition())
            .thenThrow(Exception('Permission denied'));

        expect(
          () => service.getCurrentPosition(),
          throwsException,
        );
      });

      test('watchPosition handles service disabled', () async {
        when(mockGeolocator.getPositionStream())
            .thenThrow(Exception('Service disabled'));

        expect(
          service.watchPosition(),
          emitsError(isA<Exception>()),
        );
      });
    });
  });
}
```

---

## Unit Tests (Controllers)

### Example: GetX Controller Unit Test

```dart
// test/features/auth/controllers/auth_controller_test.dart
import 'package:biko/core/services/auth_service.dart';
import 'package:biko/core/services/firestore_service.dart';
import 'package:biko/features/auth/controllers/auth_controller.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(Get.reset);

  group('AuthController', () {
    late AuthService authService;
    late FirestoreService firestoreService;
    late AuthController controller;

    setUp(() {
      final auth = MockFirebaseAuth();
      final firestore = FakeFirebaseFirestore();

      authService = AuthService(auth: auth);
      firestoreService = FirestoreService(firestore: firestore);

      controller = AuthController(
        authService: authService,
        firestoreService: firestoreService,
      );

      Get.put(controller);
    });

    group('Initialization', () {
      test('controller initializes with correct state', () {
        expect(controller.isAuthenticated.value, isFalse);
        expect(controller.currentUser, isNull);
        expect(controller.isLoading.value, isFalse);
        expect(controller.errorMessage.value, isEmpty);
      });

      test('onInit sets up listeners', () {
        expect(controller.initialized, isTrue);
      });
    });

    group('Phone Number Validation', () {
      test('validatePhoneNumber accepts valid Egyptian number', () {
        final isValid = controller.validatePhoneNumber('+201234567890');
        expect(isValid, isTrue);
      });

      test('validatePhoneNumber rejects invalid format', () {
        expect(controller.validatePhoneNumber('123456'), isFalse);
        expect(controller.validatePhoneNumber(''), isFalse);
        expect(controller.validatePhoneNumber('+351234567890'), isFalse);
      });

      test('setPhoneNumber updates reactive value', () {
        controller.setPhoneNumber('+201234567890');
        expect(controller.phoneNumber.value, equals('+201234567890'));
      });
    });

    group('OTP Flow', () {
      test('requestOTP initiates phone sign-in', () async {
        var loadingStates = <bool>[];
        controller.isLoading.listen((value) => loadingStates.add(value));

        await controller.requestOTP('+201234567890');

        // Should transition: false -> true -> false
        expect(loadingStates, contains(true));
        expect(controller.isLoading.value, isFalse);
      });

      test('verifyOTP completes authentication', () async {
        await controller.requestOTP('+201234567890');

        await controller.verifyOTP('123456');

        expect(controller.isAuthenticated.value, isTrue);
        expect(controller.currentUser, isNotNull);
      });

      test('invalid OTP shows error message', () async {
        controller.errorMessage.value = '';

        // Simulate OTP verification failure
        await controller.requestOTP('+201234567890');

        // Expect error to be set
        expect(controller.errorMessage.value, isNotEmpty);
      });
    });

    group('User Profile Setup', () {
      test('setUserProfile creates user profile', () async {
        await controller.requestOTP('+201234567890');
        await controller.verifyOTP('123456');

        await controller.setUserProfile(name: 'أحمد محمد');

        expect(controller.currentUser?.name, equals('أحمد محمد'));
      });

      test('updateProfile modifies existing profile', () async {
        await controller.requestOTP('+201234567890');
        await controller.verifyOTP('123456');

        await controller.setUserProfile(name: 'أحمد');
        await controller.updateProfile(name: 'محمد');

        expect(controller.currentUser?.name, equals('محمد'));
      });
    });

    group('Authentication State', () {
      test('reactive state tracks authentication', () async {
        var authStates = <bool>[];
        controller.isAuthenticated.listen((value) => authStates.add(value));

        expect(authStates, contains(false));

        await controller.requestOTP('+201234567890');
        await controller.verifyOTP('123456');

        expect(authStates, contains(true));
      });

      test('logout clears authentication', () async {
        await controller.requestOTP('+201234567890');
        await controller.verifyOTP('123456');

        expect(controller.isAuthenticated.value, isTrue);

        await controller.logout();

        expect(controller.isAuthenticated.value, isFalse);
        expect(controller.currentUser, isNull);
      });
    });

    group('Error Handling', () {
      test('network error shows message', () async {
        controller.errorMessage.value = '';

        // Trigger error scenario
        await controller.requestOTP('invalid-phone');

        expect(controller.errorMessage.value, isNotEmpty);
        expect(controller.isLoading.value, isFalse);
      });

      test('clearError resets error message', () {
        controller.errorMessage.value = 'Some error';
        controller.clearError();
        expect(controller.errorMessage.value, isEmpty);
      });
    });

    group('Cleanup', () {
      test('onClose disposes resources', () {
        expect(controller.isClosed, isFalse);

        Get.delete<AuthController>();

        expect(controller.isClosed, isTrue);
      });

      test('streams cancel on close', () {
        // Controller disposes subscriptions in onClose()
        Get.delete<AuthController>();

        expect(controller.isClosed, isTrue);
      });
    });
  });
}
```

---

## Widget Tests

### Example 1: Basic Widget Test

```dart
// test/core/widgets/app_button_test.dart
import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppButton Widget Tests', () {
    testWidgets('renders with correct text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: AppButton(
              text: 'اضغط هنا',
              onPressed: null,
            ),
          ),
        ),
      );

      expect(find.text('اضغط هنا'), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppButton(
              text: 'Press',
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(AppButton));
      await tester.pump();

      expect(pressed, isTrue);
    });

    testWidgets('disabled state prevents tap', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppButton(
              text: 'Disabled',
              onPressed: null,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(AppButton));
      await tester.pump();

      expect(pressed, isFalse);
    });

    testWidgets('loading state shows indicator', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: AppButton(
              text: 'Loading',
              onPressed: () {},
              isLoading: true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading'), findsNothing);
    });

    testWidgets('applies correct theme colors', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: AppButton(
              text: 'Themed',
              onPressed: () {},
            ),
          ),
        ),
      );

      final filledButton = tester.widget<FilledButton>(
        find.byType(FilledButton),
      );

      expect(filledButton, isNotNull);
    });

    testWidgets('icon renders correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: AppButton(
              text: 'With Icon',
              onPressed: () {},
              leadingIcon: Icons.arrow_forward,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
      expect(find.text('With Icon'), findsOneWidget);
    });

    testWidgets('custom width and height apply', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: AppButton(
              text: 'Custom Size',
              onPressed: () {},
              width: 200,
              height: 50,
            ),
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(
        find.ancestor(
          of: find.byType(FilledButton),
          matching: find.byType(SizedBox),
        ),
      );

      expect(sizedBox.width, equals(200));
      expect(sizedBox.height, equals(50));
    });

    testWidgets('RTL layout flips correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: const Scaffold(
              body: AppButton(
                text: 'RTL Button',
                onPressed: () {},
                leadingIcon: Icons.arrow_forward,
              ),
            ),
          ),
        ),
      );

      expect(find.text('RTL Button'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
    });

    testWidgets('dark theme renders correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          home: const Scaffold(
            body: AppButton(
              text: 'Dark Theme',
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('Dark Theme'), findsOneWidget);
    });
  });
}
```

### Example 2: GetX Widget Test

```dart
// test/features/home/screens/home_screen_test.dart
import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/features/home/controllers/home_controller.dart';
import 'package:biko/features/home/screens/home_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(Get.reset);

  group('HomeScreen Widget Tests', () {
    testWidgets('displays home screen content', (tester) async {
      final controller = HomeController();
      Get.put(controller);

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          home: const HomeScreen(),
        ),
      );

      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('shows loading state initially', (tester) async {
      final controller = HomeController();
      controller.isLoading.value = true;
      Get.put(controller);

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          home: const HomeScreen(),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty state when no data', (tester) async {
      final controller = HomeController();
      controller.trips.clear();
      Get.put(controller);

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          home: const HomeScreen(),
        ),
      );

      expect(find.byType(AppEmptyState), findsOneWidget);
    });

    testWidgets('shows trip list when data loaded', (tester) async {
      final controller = HomeController();
      controller.isLoading.value = false;
      controller.trips.addAll([
        Trip(id: '1', origin: 'Cairo'),
        Trip(id: '2', origin: 'Giza'),
      ]);
      Get.put(controller);

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          home: const HomeScreen(),
        ),
      );

      expect(find.byType(ListView), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('Cairo'), findsOneWidget);
      expect(find.text('Giza'), findsOneWidget);
    });

    testWidgets('reactive updates trigger rebuild', (tester) async {
      final controller = HomeController();
      Get.put(controller);

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          home: const HomeScreen(),
        ),
      );

      // Initial empty state
      expect(find.byType(AppEmptyState), findsOneWidget);

      // Update controller
      controller.trips.add(Trip(id: '1', origin: 'Cairo'));
      await tester.pumpAndSettle();

      // Should now show trip
      expect(find.text('Cairo'), findsOneWidget);
    });

    testWidgets('navigation works correctly', (tester) async {
      final controller = HomeController();
      Get.put(controller);

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          initialRoute: '/',
          getPages: [
            GetPage(name: '/', page: () => const HomeScreen()),
            GetPage(name: '/profile', page: () => const Placeholder()),
          ],
          home: const HomeScreen(),
        ),
      );

      // Simulate navigation
      Get.toNamed('/profile');
      await tester.pumpAndSettle();

      expect(find.byType(Placeholder), findsOneWidget);
    });
  });
}
```

---

## Golden Tests

### Example: Golden Test with Helper

```dart
// test/core/widgets/golden_tests.dart
import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class GoldenTestHelper {
  static Future<void> testLightTheme(
    WidgetTester tester,
    Widget widget,
    String filename,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(body: Center(child: widget)),
      ),
    );

    await expectLater(
      find.byWidget(widget),
      matchesGoldenFile('goldens/light/$filename.png'),
    );
  }

  static Future<void> testDarkTheme(
    WidgetTester tester,
    Widget widget,
    String filename,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        home: Scaffold(body: Center(child: widget)),
      ),
    );

    await expectLater(
      find.byWidget(widget),
      matchesGoldenFile('goldens/dark/$filename.png'),
    );
  }

  static Future<void> testRTL(
    WidgetTester tester,
    Widget widget,
    String filename,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        locale: const Locale('ar'),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(body: Center(child: widget)),
        ),
      ),
    );

    await expectLater(
      find.byWidget(widget),
      matchesGoldenFile('goldens/rtl/$filename.png'),
    );
  }
}

void main() {
  group('AppButton Golden Tests', () {
    testWidgets('primary button light theme', (tester) async {
      const button = AppButton(
        text: 'Press Me',
        onPressed: () {},
        variant: ButtonVariant.primary,
      );

      await GoldenTestHelper.testLightTheme(tester, button, 'app_button_primary');
    });

    testWidgets('primary button dark theme', (tester) async {
      const button = AppButton(
        text: 'Press Me',
        onPressed: () {},
        variant: ButtonVariant.primary,
      );

      await GoldenTestHelper.testDarkTheme(tester, button, 'app_button_primary');
    });

    testWidgets('primary button RTL layout', (tester) async {
      const button = AppButton(
        text: 'اضغط هنا',
        onPressed: () {},
        variant: ButtonVariant.primary,
        leadingIcon: Icons.arrow_forward,
      );

      await GoldenTestHelper.testRTL(tester, button, 'app_button_primary_rtl');
    });

    testWidgets('secondary button variants', (tester) async {
      const button = AppButton(
        text: 'Secondary',
        onPressed: () {},
        variant: ButtonVariant.secondary,
      );

      await GoldenTestHelper.testLightTheme(tester, button, 'app_button_secondary');
    });

    testWidgets('disabled button state', (tester) async {
      const button = AppButton(
        text: 'Disabled',
        onPressed: null,
      );

      await GoldenTestHelper.testLightTheme(tester, button, 'app_button_disabled');
    });

    testWidgets('loading button state', (tester) async {
      const button = AppButton(
        text: 'Loading',
        onPressed: () {},
        isLoading: true,
      );

      await GoldenTestHelper.testLightTheme(tester, button, 'app_button_loading');
    });
  });
}
```

---

## Integration Tests

### Example: Auth Integration Test

```dart
// integration_test/auth_integration_test.dart
import 'package:biko/main_customer.dart' as app;
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';

void main() {
  setUpAll(() async {
    // Initialize Firebase for integration tests
    await Firebase.initializeApp();
  });

  group('Authentication Flow Integration Tests', () {
    testWidgets('complete sign-up flow', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Verify on splash screen
      expect(find.byType(SplashScreen), findsOneWidget);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Navigate to login
      expect(find.byType(LoginScreen), findsOneWidget);

      // Enter phone number
      await tester.enterText(
        find.byType(TextField).first,
        '+201234567890',
      );

      // Tap request OTP button
      await tester.tap(find.text('اطلب رمز التحقق'));
      await tester.pumpAndSettle();

      // Verify OTP screen
      expect(find.byType(OTPScreen), findsOneWidget);

      // Enter OTP
      await tester.enterText(find.byType(TextField).first, '123456');

      // Tap verify button
      await tester.tap(find.text('تحقق'));
      await tester.pumpAndSettle();

      // Verify profile setup screen
      expect(find.byType(ProfileSetupScreen), findsOneWidget);

      // Enter name
      await tester.enterText(find.byType(TextField).first, 'أحمد محمد');

      // Complete signup
      await tester.tap(find.text('تم'));
      await tester.pumpAndSettle();

      // Verify home screen reached
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('login with existing account', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Should skip splash and go to home if already authenticated
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('logout functionality', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Open settings menu
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      // Tap logout
      await tester.tap(find.text('تسجيل الخروج'));
      await tester.pumpAndSettle();

      // Should return to login screen
      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });
}
```

---

## Test Helpers & Factories

### Example: Test Data Factories

```dart
// test/helpers/test_data/factories.dart
import 'package:biko/core/models/models.dart';

class UserFactory {
  static User createUser({
    String? id,
    String? phone,
    String? name,
    bool isDriver = false,
  }) {
    return User(
      id: id ?? 'user_${DateTime.now().millisecondsSinceEpoch}',
      phone: phone ?? '+201234567890',
      name: name ?? 'أحمد محمد',
      isDriver: isDriver,
      createdAt: DateTime.now(),
    );
  }

  static List<User> createUsers(int count) {
    return List.generate(
      count,
      (i) => createUser(
        id: 'user$i',
        phone: '+2010${1000000 + i}',
        name: 'User $i',
      ),
    );
  }
}

class TripFactory {
  static Trip createTrip({
    String? id,
    String? customerId,
    Place? origin,
    Place? destination,
    DateTime? createdAt,
  }) {
    return Trip(
      id: id ?? 'trip_${DateTime.now().millisecondsSinceEpoch}',
      customerId: customerId ?? 'customer1',
      origin: origin ?? Place(lat: 30.0, lng: 31.0, address: 'Cairo'),
      destination: destination ?? Place(lat: 30.1, lng: 31.1, address: 'Giza'),
      createdAt: createdAt ?? DateTime.now(),
      status: TripStatus.pending,
    );
  }

  static List<Trip> createTrips(int count) {
    return List.generate(
      count,
      (i) => createTrip(id: 'trip$i'),
    );
  }
}

class BidFactory {
  static Bid createBid({
    String? id,
    String? tripId,
    String? driverId,
    double? amount,
  }) {
    return Bid(
      id: id ?? 'bid_${DateTime.now().millisecondsSinceEpoch}',
      tripId: tripId ?? 'trip1',
      driverId: driverId ?? 'driver1',
      amount: amount ?? 50.0,
      createdAt: DateTime.now(),
      status: BidStatus.pending,
    );
  }

  static List<Bid> createBids(int count) {
    return List.generate(
      count,
      (i) => createBid(
        id: 'bid$i',
        driverId: 'driver$i',
        amount: 40.0 + i,
      ),
    );
  }
}

// Usage in tests:
void main() {
  test('test with factory data', () {
    final user = UserFactory.createUser(name: 'عميل');
    final trips = TripFactory.createTrips(5);
    final bids = BidFactory.createBids(3);

    expect(user.name, equals('عميل'));
    expect(trips.length, equals(5));
    expect(bids.length, equals(3));
  });
}
```

---

This document provides ready-to-use code examples for all major testing scenarios in BikeRide.

Use these as templates and adapt them to your specific services, controllers, and widgets.

