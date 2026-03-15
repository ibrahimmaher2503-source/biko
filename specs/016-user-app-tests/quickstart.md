# BikeRide Testing Quick Start Guide

**Last Updated**: 2026-03-11
**Target Audience**: Flutter developers working on BikeRide customer app

## Overview

This guide gets you writing and running tests for the BikeRide customer app in under 5 minutes.

---

## Prerequisites

- Flutter SDK installed
- BikeRide project cloned
- Dependencies installed: `flutter pub get`

---

## 5-Minute Quick Start

### 1. Run Existing Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/core/widgets/app_button_test.dart

# Run tests with coverage
flutter test --coverage

# View coverage report
genhtml coverage/lcov.info -o coverage/html && open coverage/html/index.html
```

### 2. Write Your First Widget Test

Create `test/core/widgets/my_widget_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:biko/core/widgets/my_widget.dart';
import '../../helpers/getx_test_helpers.dart';

void main() {
  setUp(() {
    GetXTestHelper.setup();
  });

  tearDown(() {
    GetXTestHelper.cleanup();
  });

  testWidgets('MyWidget displays text', (tester) async {
    await GetXTestHelper.pumpApp(
      tester,
      MyWidget(text: 'Hello'),
    );

    expect(find.text('Hello'), findsOneWidget);
  });
}
```

### 3. Write Your First Unit Test

Create `test/features/auth/controllers/auth_controller_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:biko/features/auth/controllers/auth_controller.dart';
import '../../../helpers/getx_test_helpers.dart';
import '../../../helpers/mock_services.dart';

void main() {
  setUp(() {
    GetXTestHelper.setup();
    GetXTestHelper.registerMockServices();
  });

  tearDown(() {
    GetXTestHelper.cleanup();
  });

  test('phone number validation', () {
    final controller = AuthController();

    controller.setPhoneNumber('+201234567890');
    expect(controller.isValidPhone, isTrue);

    controller.setPhoneNumber('123');
    expect(controller.isValidPhone, isFalse);
  });
}
```

### 4. Generate Test Data with Factories

```dart
import '../../../helpers/test_factories.dart';

void main() {
  test('create trip with factory', () {
    final user = UserFactory.createCustomer();
    final trip = TripFactory.create(customerId: user.uid);

    expect(trip.customerId, equals(user.uid));
    expect(trip.status, equals(TripStatus.pending));
  });
}
```

### 5. Run Golden Tests

```bash
# Generate/update golden files
flutter test --update-goldens test/core/widgets/app_button_test.dart

# Verify golden tests pass
flutter test test/core/widgets/app_button_test.dart
```

---

## Common Testing Patterns

### Pattern 1: Test a GetX Controller

```dart
void main() {
  late MyController controller;
  late MockMyService mockService;

  setUp(() {
    GetXTestHelper.setup();
    mockService = MockMyService();
    Get.put<MyService>(mockService);
    controller = MyController();
  });

  tearDown(() {
    GetXTestHelper.cleanup();
  });

  test('controller method updates reactive state', () {
    controller.incrementCounter();

    expect(controller.count.value, equals(1));
  });
}
```

### Pattern 2: Test a Widget with User Interaction

```dart
testWidgets('button tap updates state', (tester) async {
  await GetXTestHelper.pumpApp(
    tester,
    MyScreen(),
  );

  // Find and tap button
  await tester.tap(find.byType(AppButton));
  await tester.pumpAndSettle();

  // Verify state changed
  expect(find.text('Tapped'), findsOneWidget);
});
```

### Pattern 3: Test Navigation

```dart
testWidgets('button navigates to next screen', (tester) async {
  await tester.pumpWidget(
    GetMaterialApp(
      initialRoute: '/home',
      getPages: [
        GetPage(name: '/home', page: () => HomeScreen()),
        GetPage(name: '/profile', page: () => ProfileScreen()),
      ],
    ),
  );

  await tester.tap(find.text('Go to Profile'));
  await tester.pumpAndSettle();

  expect(Get.currentRoute, equals('/profile'));
  expect(find.byType(ProfileScreen), findsOneWidget);
});
```

### Pattern 4: Test Firestore Service

```dart
void main() {
  late FakeFirebaseFirestore firestore;
  late FirestoreService service;

  setUp(() {
    firestore = FirebaseTestHelper.createFakeFirestore();
    service = FirestoreService(firestore);
  });

  test('createUser stores user in Firestore', () async {
    final user = UserFactory.create();

    await service.createUser(user);

    final doc = await firestore.collection('users').doc(user.uid).get();
    expect(doc.exists, isTrue);
    expect(doc.data()!['phone'], equals(user.phone));
  });
}
```

### Pattern 5: Test with Async Data

```dart
test('fetch user loads data', () async {
  final user = UserFactory.create();
  mockService.seedUser(user);

  await controller.fetchUser(user.uid);

  expect(controller.user.value, isNotNull);
  expect(controller.user.value!.uid, equals(user.uid));
  expect(controller.isLoading.value, isFalse);
});
```

### Pattern 6: Golden Test (Visual Regression)

```dart
testWidgets('button light theme golden', (tester) async {
  const button = AppButton(text: 'Press Me', onPressed: null);

  await GoldenTestHelper.testLightTheme(
    tester,
    button,
    'app_button_primary',
  );
});

testWidgets('button RTL golden', (tester) async {
  const button = AppButton(
    text: 'اضغط عليّ',
    onPressed: null,
    leadingIcon: Icons.arrow_forward,
  );

  await GoldenTestHelper.testRTL(
    tester,
    button,
    'app_button_primary_rtl',
  );
});
```

---

## Test File Structure

```
test/
├── helpers/
│   ├── getx_test_helpers.dart       ← Setup/teardown for GetX tests
│   ├── golden_test_helpers.dart     ← Golden test utilities
│   ├── firebase_test_helpers.dart   ← Firebase mock factories
│   ├── mock_services.dart           ← Mock implementations
│   └── test_factories.dart          ← Test data factories
├── core/
│   ├── widgets/
│   │   ├── app_button_test.dart     ← Widget tests
│   │   └── goldens/                 ← Golden reference images
│   ├── services/
│   │   └── auth_service_test.dart   ← Service unit tests
│   └── models/
│       └── user_model_test.dart     ← Model unit tests
├── features/
│   ├── auth/
│   │   └── controllers/
│   │       └── auth_controller_test.dart  ← Controller unit tests
│   └── home/
│       └── controllers/
│           └── home_controller_test.dart
└── integration/
    ├── auth_flow_test.dart          ← Integration tests
    └── trip_booking_flow_test.dart
```

---

## Helper Utilities

### GetXTestHelper

```dart
GetXTestHelper.setup();                        // Enable test mode
GetXTestHelper.cleanup();                      // Reset GetX
GetXTestHelper.pumpApp(tester, widget);        // Pump with GetMaterialApp
GetXTestHelper.registerMockServices();         // Register all mocks
```

### GoldenTestHelper

```dart
GoldenTestHelper.testLightTheme(tester, widget, 'filename');
GoldenTestHelper.testDarkTheme(tester, widget, 'filename');
GoldenTestHelper.testRTL(tester, widget, 'filename');
GoldenTestHelper.testResponsive(tester, widget, 'filename', [sizes]);
```

### FirebaseTestHelper

```dart
FirebaseTestHelper.createFakeFirestore();
FirebaseTestHelper.createMockAuth(initialUser: user);
FirebaseTestHelper.seedFirestore(firestore, data);
FirebaseTestHelper.clearFirestore(firestore);
```

### Test Factories

```dart
UserFactory.create();                          // Create user with defaults
UserFactory.createCustomer();                  // Create customer user
UserFactory.createDriver();                    // Create driver user
UserFactory.createList(5, {'role': 'driver'}); // Create 5 drivers

TripFactory.create();                          // Create trip with defaults
TripFactory.createPending();                   // Create pending trip
TripFactory.createCompleted();                 // Create completed trip

BidFactory.create();                           // Create bid with defaults
BidFactory.createMultipleBids(tripId, 3);      // Create 3 bids for trip

PlaceFactory.createCairoLocation();            // Cairo center
PlaceFactory.createGizaLocation();             // Giza pyramids
```

---

## CI/CD Commands

```bash
# Run all tests (what CI runs)
flutter test --coverage

# Check coverage thresholds
flutter test --coverage && \
  lcov --summary coverage/lcov.info | grep "lines......:" | \
  awk '{if ($2 < 70.0) exit 1}'

# Generate HTML coverage report
genhtml coverage/lcov.info -o coverage/html

# Run golden tests separately
flutter test --tags=golden

# Run integration tests
flutter test integration_test/
```

---

## Debugging Tests

### Print Debug Info

```dart
test('debug example', () {
  final user = UserFactory.create();
  debugPrint('User: ${user.toMap()}');  // Print user data

  controller.doSomething();
  debugPrint('State: ${controller.state.value}');  // Print state
});
```

### Run Single Test

```bash
# Run specific test file
flutter test test/core/widgets/app_button_test.dart

# Run single test by name
flutter test --plain-name "button tap updates state"
```

### Watch Mode (Auto-run on file changes)

```bash
# Install flutter_test_watcher
flutter pub global activate flutter_test_watcher

# Run in watch mode
flutter_test_watcher
```

---

## Coverage Targets

| Component | Target | Priority |
|-----------|--------|----------|
| `lib/core/services/` | 85% | High |
| `lib/core/models/` | 90% | High |
| `lib/core/widgets/` | 80% | High |
| `lib/features/*/controllers/` | 75% | Medium |
| `lib/features/*/screens/` | 50% | Low |
| **Overall** | **70%** | **Required** |

---

## Troubleshooting

### Issue: "GetX controller not found"

**Solution**: Register controller in `setUp()`:

```dart
setUp(() {
  GetXTestHelper.setup();
  Get.lazyPut(() => MyController());
});
```

### Issue: "Golden test fails with font rendering error"

**Solution**: Add font loading in golden test:

```dart
setUpAll(() async {
  await loadAppFonts();
});
```

### Issue: "Test times out"

**Solution**: Use `pumpAndSettle()` to wait for animations:

```dart
await tester.pumpAndSettle();  // Wait for all animations
```

### Issue: "Mock service not resetting between tests"

**Solution**: Call `reset()` in `tearDown()`:

```dart
tearDown(() async {
  await mockService.reset();
  GetXTestHelper.cleanup();
});
```

---

## Best Practices

✅ **DO**:
- Use `GetXTestHelper.setup()` and `cleanup()` in every GetX test
- Use test factories for test data generation
- Test in both light/dark themes and RTL layout
- Write descriptive test names: `'login button shows loading state when tapped'`
- Group related tests: `group('AuthController', () { ... })`
- Use `pumpAndSettle()` to wait for animations
- Reset mocks in `tearDown()` to prevent state leakage

❌ **DON'T**:
- Use `Get.put()` in tests (use `Get.lazyPut()` instead)
- Hardcode test data (use factories)
- Skip golden tests for shared widgets
- Forget to call `Get.reset()` in `tearDown()`
- Use real Firebase in tests (always use mocks)
- Write tests without coverage in mind (aim for 70%+ overall)

---

## Next Steps

1. **Read comprehensive research**: See `research.md` for deep dive into testing patterns
2. **Understand data models**: See `data-model.md` for test entity structures
3. **Review contracts**: See `contracts/` for interface specifications
4. **Write tests**: Follow patterns in existing test files
5. **Run coverage**: Ensure you meet 70% overall target

---

## Additional Resources

- [Flutter Testing Documentation](https://flutter.dev/docs/testing)
- [GetX Testing Guide](https://github.com/jonataslaw/getx/wiki#testing)
- [BikeRide Research Doc](./research.md)
- [BikeRide Data Model Doc](./data-model.md)
- [BikeRide Contracts](./contracts/)

---

**Questions?** Check `research.md` or ask the team in #dev-testing Slack channel.
