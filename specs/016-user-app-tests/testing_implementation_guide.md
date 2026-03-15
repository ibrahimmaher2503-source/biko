# Testing Implementation Guide for BikeRide

A practical guide for implementing the testing recommendations from research.md

---

## Quick Reference: Testing Decisions

### When to Use Each Approach

| Test Type | Tool | When | Example |
|-----------|------|------|---------|
| **Unit Tests** | fake_cloud_firestore + firebase_auth_mocks | Test services, controllers in isolation | `AuthService.login()` |
| **Widget Tests** | GetMaterialApp + native goldens | Test UI components | `AppButton` rendering in light/dark/RTL |
| **Integration Tests** | Firebase Emulator Suite | Test full user journeys | Auth → Trip Creation → Bidding |
| **Golden Tests** | Native `matchesGoldenFile()` | Catch visual regressions | Button appearance across themes |
| **Stream Tests** | `emitsInOrder()`, `expect()` matcher | Test reactive state | `.obs` property updates |

---

## Implementation Checklist

### Phase 1: Setup (Week 1)

- [ ] Add firebase mocking dependencies to pubspec.yaml
- [ ] Create test helpers (`firebase_test_helpers.dart`, `golden_test_helpers.dart`)
- [ ] Create test data factories (UserFactory, TripFactory, etc.)
- [ ] Update CI/CD configuration for coverage enforcement

### Phase 2: Core Services (Week 2-3)

- [ ] Write AuthService unit tests (85% target)
- [ ] Write FirestoreService unit tests (85% target)
- [ ] Write LocationService unit tests (80% target)
- [ ] Ensure all subscriptions canceled in `onClose()`

### Phase 3: Shared Widgets (Week 3-4)

- [ ] Update existing widget tests (AppButton, AppTextField, etc.)
- [ ] Add light/dark/RTL variants
- [ ] Generate golden images
- [ ] Verify 80% coverage

### Phase 4: Feature Controllers (Week 4-5)

- [ ] AuthController unit tests
- [ ] HomeController unit tests
- [ ] TripController unit tests
- [ ] BiddingController unit tests
- [ ] Target 75% coverage

### Phase 5: Integration Tests (Week 5-6)

- [ ] Setup Firebase Emulator
- [ ] Auth flow integration test
- [ ] Trip creation integration test
- [ ] Bidding flow integration test

### Phase 6: Coverage Enforcement (Week 6)

- [ ] Configure CI/CD thresholds
- [ ] Generate coverage reports
- [ ] Document testing guidelines

---

## Code Examples by Component

### 1. Service Unit Test Template

```dart
// test/core/services/my_service_test.dart
import 'package:biko/core/services/my_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MyService', () {
    late FakeFirebaseFirestore firestore;
    late MyService service;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      service = MyService(firestore);
    });

    test('method does X when given Y', () async {
      // Arrange: Set up test data
      await firestore.collection('collection').doc('doc1').set({
        'field': 'value',
      });

      // Act: Call the method
      final result = await service.someMethod('doc1');

      // Assert: Verify result
      expect(result.field, equals('value'));
    });

    test('streams emit updates correctly', () async {
      // Verify reactive streams
      expect(
        service.watchData('doc1'),
        emitsInOrder([
          isA<Data>(),
          isA<Data>(),
        ]),
      );

      // Trigger updates
      await firestore.collection('collection').doc('doc1').update({
        'field': 'updated1',
      });
    });

    test('batch operations work atomically', () async {
      await service.batchUpdate([
        {'id': 'doc1', 'value': 1},
        {'id': 'doc2', 'value': 2},
      ]);

      final doc1 = await firestore.collection('collection').doc('doc1').get();
      final doc2 = await firestore.collection('collection').doc('doc2').get();

      expect(doc1['value'], equals(1));
      expect(doc2['value'], equals(2));
    });
  });
}
```

### 2. Controller Unit Test Template

```dart
// test/features/auth/controllers/auth_controller_test.dart
import 'package:biko/features/auth/controllers/auth_controller.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(Get.reset);

  group('AuthController', () {
    test('initializes with correct state', () {
      final controller = AuthController(
        auth: MockFirebaseAuth(),
      );
      Get.put(controller);

      expect(controller.isAuthenticated.value, isFalse);
      expect(controller.currentUser, isNull);
    });

    test('updates state on login', () async {
      final auth = MockFirebaseAuth();
      final controller = AuthController(auth: auth);
      Get.put(controller);

      await controller.loginWithPhone('+201234567890');

      expect(controller.isAuthenticated.value, isTrue);
      expect(controller.currentUser, isNotNull);
    });

    test('reactive state triggers observers', () async {
      final controller = AuthController(
        auth: MockFirebaseAuth(),
      );
      Get.put(controller);

      var updateCount = 0;
      controller.isAuthenticated.listen((_) => updateCount++);

      await controller.loginWithPhone('+201234567890');

      expect(updateCount, greaterThan(0));
    });

    test('cleanup cancels subscriptions on close', () async {
      final controller = AuthController(
        auth: MockFirebaseAuth(),
      );
      Get.put(controller);

      expect(controller.isClosed, isFalse);

      Get.delete<AuthController>();

      expect(controller.isClosed, isTrue);
    });
  });
}
```

### 3. Widget Test with Goldens Template

```dart
// test/core/widgets/shared_widget_test.dart
import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/shared_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SharedWidget Tests', () {
    testWidgets('renders in light theme', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: SharedWidget(label: 'Test'),
          ),
        ),
      );

      expect(find.text('Test'), findsOneWidget);
      expect(find.byType(SharedWidget), findsOneWidget);
    });

    testWidgets('renders in dark theme', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          home: const Scaffold(
            body: SharedWidget(label: 'Test'),
          ),
        ),
      );

      expect(find.text('Test'), findsOneWidget);
    });

    testWidgets('renders in RTL layout', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('ar'),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: const Scaffold(
              body: SharedWidget(label: 'اختبار'),
            ),
          ),
        ),
      );

      expect(find.text('اختبار'), findsOneWidget);
    });

    testWidgets('golden test - light theme', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: Center(
              child: SharedWidget(label: 'Golden Test'),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(SharedWidget),
        matchesGoldenFile('goldens/light/shared_widget.png'),
      );
    });

    testWidgets('golden test - dark theme', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          home: const Scaffold(
            body: Center(
              child: SharedWidget(label: 'Golden Test'),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(SharedWidget),
        matchesGoldenFile('goldens/dark/shared_widget.png'),
      );
    });

    testWidgets('golden test - RTL layout', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('ar'),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: const Scaffold(
              body: Center(
                child: SharedWidget(label: 'اختبار'),
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(SharedWidget),
        matchesGoldenFile('goldens/rtl/shared_widget.png'),
      );
    });
  });
}
```

### 4. Integration Test Template

```dart
// integration_test/auth_integration_test.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:biko/main_customer.dart' as app;

void main() {
  group('Authentication Integration Tests', () {
    setUpAll(() async {
      // Initialize Firebase once for all tests
      await Firebase.initializeApp();
    });

    testWidgets('complete auth flow: phone → OTP → profile', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Expect to start at splash screen
      expect(find.byType(SplashScreen), findsOneWidget);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Navigate to login
      expect(find.byType(LoginScreen), findsOneWidget);

      // Enter phone number
      await tester.enterText(
        find.byType(TextField),
        '+201234567890',
      );
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Verify OTP screen shown
      expect(find.byType(OTPScreen), findsOneWidget);

      // Enter OTP
      await tester.enterText(find.byType(TextField), '123456');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Verify profile setup screen
      expect(find.byType(ProfileSetupScreen), findsOneWidget);

      // Complete profile
      await tester.enterText(find.byType(TextField), 'أحمد');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Verify home screen reached
      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });
}
```

### 5. Test Data Factory Template

```dart
// test/helpers/test_data/user_factory.dart
import 'package:biko/core/models/user_model.dart';

class UserFactory {
  static User createUser({
    String? id,
    String? phone,
    String? name,
    String? email,
    bool isDriver = false,
  }) {
    return User(
      id: id ?? 'user_${DateTime.now().millisecondsSinceEpoch}',
      phone: phone ?? '+201234567890',
      name: name ?? 'أحمد محمد',
      email: email ?? 'user@example.com',
      isDriver: isDriver,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  static User createDriver({
    String? id,
    String? phone,
    String? name,
  }) {
    return createUser(
      id: id,
      phone: phone ?? '+201111111111',
      name: name ?? 'سائق',
      isDriver: true,
    );
  }

  static User createCustomer({
    String? id,
    String? phone,
    String? name,
  }) {
    return createUser(
      id: id,
      phone: phone ?? '+202222222222',
      name: name ?? 'عميل',
      isDriver: false,
    );
  }

  static List<User> createUsers(int count) {
    return List.generate(
      count,
      (index) => createUser(
        phone: '+2010${1000000 + index}',
        name: 'User $index',
      ),
    );
  }
}

// Usage in tests:
void main() {
  test('auth flow with test user', () async {
    final testUser = UserFactory.createUser();
    // Use testUser in test...
  });
}
```

---

## CI/CD Configuration

### GitHub Actions Workflow

```yaml
# .github/workflows/ci.yml
name: BikeRide CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

jobs:
  analyze:
    name: Analyze & Lint
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
      - run: flutter pub get
      - run: flutter analyze
      - run: dart format --output none --set-exit-if-changed lib/ test/

  test:
    name: Run Tests
    runs-on: ubuntu-latest
    needs: analyze
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
      - run: flutter pub get
      - run: flutter test
      - run: flutter test --coverage

      # Check coverage thresholds
      - name: Check coverage
        run: |
          if [ -f coverage/lcov.info ]; then
            TOTAL=$(grep -c "DA:" coverage/lcov.info)
            HIT=$(grep "DA:" coverage/lcov.info | grep -v ",0$" | wc -l)
            COVERAGE=$((HIT * 100 / TOTAL))
            echo "Coverage: ${COVERAGE}%"
            if [ "$COVERAGE" -lt 70 ]; then
              echo "::error::Coverage ${COVERAGE}% below 70% threshold"
              exit 1
            fi
          fi

      # Upload to codecov
      - uses: codecov/codecov-action@v3
        with:
          files: ./coverage/lcov.info
          flags: flutter
          fail_ci_if_error: false

  goldens:
    name: Golden Tests
    runs-on: ubuntu-latest
    needs: analyze
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
      - run: flutter pub get
      - run: flutter test test/core/widgets/

      # Fail if golden images changed unexpectedly
      - name: Check golden files
        run: |
          if git diff --exit-code test/**/goldens/; then
            echo "Golden files match baseline"
          else
            echo "::error::Golden files changed. Review visual changes."
            exit 1
          fi

  build-web:
    name: Build Admin Web
    runs-on: ubuntu-latest
    needs: [test, goldens]
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
      - run: flutter pub get
      - run: flutter build web --release --base-href /admin/ -t lib/main_admin.dart
```

---

## Command Reference

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Update golden files
flutter test --update-goldens test/core/widgets/

# Run specific test file
flutter test test/core/services/auth_service_test.dart

# Run with verbose output
flutter test --verbose

# Run with watch mode (re-run on file changes)
flutter test --watch

# Generate HTML coverage report
genhtml coverage/lcov.info -o coverage/html && open coverage/html/index.html

# Check coverage percentage
lcov --summary coverage/lcov.info
```

---

## Common Pitfalls & Solutions

### Problem: GetX controller not found in widget test

**Cause**: Using `MaterialApp` instead of `GetMaterialApp`

**Solution**:
```dart
// ❌ Wrong
testWidgets('test', (tester) async {
  await tester.pumpWidget(MaterialApp(...));
});

// ✅ Correct
testWidgets('test', (tester) async {
  await tester.pumpWidget(GetMaterialApp(...));
});
```

### Problem: Golden test fails in CI/CD

**Cause**: Different font rendering between CI environment and local

**Solution**: Generate goldens in CI/CD environment
```bash
# In .github/workflows/ci.yml, update goldens on stable channel
- run: flutter test --update-goldens
- run: git add test/**/goldens/
- run: git commit -m "Update golden files"
```

### Problem: Firebase mock data not persisting between tests

**Cause**: Each test gets fresh `FakeFirebaseFirestore()` instance

**Solution**: Create firestore in `setUp()`, not globally
```dart
// ❌ Wrong
final firestore = FakeFirebaseFirestore();

void main() {
  test('test 1', ...) // Uses same firestore
  test('test 2', ...) // Also same firestore - data persists!
}

// ✅ Correct
void main() {
  late FakeFirebaseFirestore firestore;

  setUp(() {
    firestore = FakeFirebaseFirestore(); // Fresh instance per test
  });

  test('test 1', ...);
  test('test 2', ...);
}
```

### Problem: Stream subscriptions cause "memory leaks"

**Cause**: Not canceling subscriptions in `onClose()`

**Solution**:
```dart
class MyController extends GetxController {
  late StreamSubscription _subscription;

  @override
  void onInit() {
    super.onInit();
    _subscription = firestore.watch().listen((_) {});
  }

  @override
  void onClose() {
    _subscription.cancel(); // Cancel before dispose
    super.onClose();
  }
}

// Test cleanup
test('cancels subscriptions on close', () {
  final controller = MyController();
  Get.put(controller);

  Get.delete<MyController>();

  expect(controller.isClosed, isTrue);
});
```

---

## Next Steps

1. Start with Phase 1 setup (this week)
2. Use templates above for writing new tests
3. Refer to research.md for detailed explanations
4. Update CI/CD configuration once comfortable with tests
5. Gradually increase coverage targets

Good luck! 🚀
