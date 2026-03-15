# Testing & CI/CD Research

This document captures research on Flutter performance testing, accessibility testing, and CI/CD best practices for the BikeRide project.

## 1. Performance Testing in Flutter

### DevTools Profiling

**Key Tools:**
- **Performance View**: Frame-by-frame UI performance analysis via Flutter DevTools Timeline view
- **Memory Profiler**: Heap examination and memory leak detection
- **CPU Profiler**: Frame rendering time and CPU usage analysis
- **Network Profiler**: Network latency and request analysis

**Best Practices:**
- Always profile on physical devices in **profile mode**, not debug mode
- Use `flutter run --profile` or `flutter build apk --profile`
- Profile mode keeps timeline events and service ports open for DevTools inspection
- Most flagship phones now ship with 90Hz or 120Hz displays (8-11ms per frame budget)
- Measure on real hardware, not emulators (they have different performance characteristics)

**References:**
- [Flutter performance profiling](https://docs.flutter.dev/perf/ui-performance)
- [Use the Performance view](https://docs.flutter.dev/tools/devtools/performance)
- [Measure performance with an integration test](https://docs.flutter.dev/cookbook/testing/integration/profiling)

### Benchmark Testing

**Metrics:**
- Widget build times
- Jank measurement (skipped frames)
- Frame rates (60 FPS / 120 FPS)
- Startup time
- Battery consumption
- Download size

**Tools & Approach:**
- Use `IntegrationTestWidgetsFlutterBinding.traceAction()` to record performance metrics
- `TimelineSummary` writes JSON summaries including skipped frames and slowest build times
- Benchmark tests via integration test framework with Flutter Driver

**Regression Testing:**
- Configure benchmarks to run on every commit
- Automated benchmark helpers benchmark on multiple devices
- Generate reports to detect performance regressions
- Calculate running averages across test runs

**References:**
- [How to Test the Performance of Flutter Apps](https://www.velotio.com/engineering-blog/performance-testing-of-flutter-apps)
- [Performance testing of Flutter apps](https://blog.flutter.dev/performance-testing-of-flutter-apps-df7669bb7df7)
- [Dart benchmark package](https://pub.dev/packages/benchmark)

---

## 2. Accessibility Testing in Flutter

### Semantics & Screen Readers

**Key Concepts:**
- Use `Semantics` widget to assign labels, roles, hints, and flags for screen readers
- Screen readers (TalkBack on Android, VoiceOver on iOS) enable spoken feedback
- Test that screen readers can describe all controls when tapped with intelligible descriptions

**Testing Framework:**
- Use `tester.ensureSemantics()` in widget tests
- Flutter's testing framework provides `meetsGuideline` matcher with `AccessibilityGuideline` enum
- Tests verify semantics conform to WCAG requirements

**References:**
- [Accessibility testing](https://docs.flutter.dev/ui/accessibility/accessibility-testing)
- [Flutter Accessibility: Making Apps Screen-Reader Friendly and WCAG 2.2 Compliant](https://vibe-studio.ai/insights/flutter-accessibility-making-apps-screen-reader-friendly-and-wcag-2-2-compliant)
- [Improving Accessibility in Flutter Apps](https://dev.to/adepto/improving-accessibility-in-flutter-apps-a-comprehensive-guide-1jod)

### WCAG Compliance

**Minimum Requirements:**
- Tappable nodes: 48x48 pixels (Android), 44x44 (iOS)
- Touch targets must be labeled
- Text contrast ratio: 4.5:1 for regular text, 3:1 for larger text
- All controls must be keyboard navigable (especially for web/desktop)

**Testing Approach:**
- Test with actual screen readers: TalkBack (Android), VoiceOver (iOS)
- Verify contrast ratios using color analysis tools
- Check focus order and keyboard navigation
- Test with text scaling enabled

**References:**
- [Accessibility technologies](https://docs.flutter.dev/ui/accessibility/assistive-technologies)
- [Practical Accessibility in Flutter](https://dcm.dev/blog/2025/06/30/accessibility-flutter-practical-tips-tools-code-youll-actually-use/)

---

## 3. RTL & Localization Testing

### Directionality & RTL Support

**Key Widgets:**
- `Directionality` widget controls text direction (LTR or RTL)
- Property: `textDirection: TextDirection.rtl` or `TextDirection.ltr`
- Default for Directionality children is the specified direction

**Testing Multi-Language Support:**
- Use `Localizations` widget to wrap widget tree during testing
- Set app locale and verify UI, text strings, and content are correctly translated
- Test language switching at runtime

**RTL-Specific Considerations:**
- Text and layouts flip automatically (material widgets handle this)
- Navigation drawers slide in from right in RTL
- Progress indicators animate in opposite direction
- Iconography and animations must account for direction
- Numeric formatting may differ by locale

**Best Practices:**
- Configure MaterialApp with RTL support
- Wrap custom widgets with Directionality
- Use RTL-ready fonts (especially for Arabic: Cairo font)
- Thoroughly test across platforms in both LTR and RTL

**References:**
- [App Localization: RTL Support and Fonts in Flutter](https://vibe-studio.ai/insights/app-localization-rtl-(right-to-left)-support-and-fonts-in-flutter)
- [Right to Left in Flutter Apps: The Developer's Guide](https://leancode.co/blog/right-to-left-in-flutter-app)
- [Text Directionality](https://engineering.verygood.ventures/internationalization/text_directionality/)

### Golden Tests for RTL

**Overview:**
- Golden tests capture visual output of widgets and compare against stored "golden" reference images
- Ideal for detecting visual regressions in RTL layouts
- Can be run with different Directionality settings to validate both LTR and RTL rendering

**Tools:**
- `flutter_test` package includes Golden test functionality
- `golden_toolkit` package provides advanced screenshot test utilities
- Can test at different screen resolutions, text scales, and device configurations

**Key Challenges:**
- Platform variability (different renderings on different devices)
- Text scaling and screen resolution differences
- Environment-dependent rendering
- Golden files must be captured consistently across CI environments

**References:**
- [Flutter Widget Testing Best Practices: Golden Tests and Screenshot Diffs](https://vibe-studio.ai/insights/flutter-widget-testing-best-practices-golden-tests-and-screenshot-diffs)
- [Flutter: screenshot testing as a solid UI regression tool](https://medium.com/flutter-community/flutter-screenshot-testing-as-a-solid-ui-regression-tool-630221a621e4)
- [Understanding Golden Image Tests in Flutter](https://medium.com/@johnacolani_22987/understanding-golden-image-tests-in-flutter-a-step-by-step-guide-3838287c44ce)

---

## 4. CI/CD Integration with GitHub Actions

### Test Coverage Reporting

**Coverage Generation:**
- Run `flutter test --coverage` to write LCOV data to `coverage/lcov.info`
- Coverage reports can be generated as HTML using tools like `genhtml`

**Integration Options:**
- **Codecov**: Use `codecov/codecov-action@v1` to upload coverage results
- **GitHub Pages**: Deploy HTML coverage reports using Flutter Coverage Action
- **GitHub Actions Native**: Use `zgosalvez/github-actions-report-lcov` to generate reports and enforce thresholds

**Coverage Enforcement:**
- Extract coverage percentage and fail builds if below threshold (e.g., 90%)
- Prevent uncovered code from reaching production
- Set minimum coverage requirements in CI pipeline

**References:**
- [Flutter CI/CD with GitHub Actions: Build, Test & Enforce Code Coverage](https://medium.com/@akashvyasce/automate-your-flutter-builds-with-ci-cd-using-github-actions-55a7790c3f74)
- [Run Flutter tests using GitHub Actions and Codecov](https://damienaicheh.github.io/flutter/github/actions/2021/05/06/flutter-tests-github-actions-codecov-en.html)
- [How to Generate Code Coverage Reports with GitHub Actions](https://oneuptime.com/blog/post/2026-01-27-code-coverage-reports-github-actions/view)

### Parallel Test Execution

**Concurrency Option:**
- Use `--concurrency` flag to run test suites in parallel
- Default: half the number of CPU cores
- Control parallelism level with concurrency parameter
- Significantly reduces total test execution time

**Test Sharding:**
- Split test suite into smaller segments (shards)
- Run each shard on different machines/executors in CI
- Beneficial when CI supports unlimited parallel jobs
- Can reduce test cycle from hours to minutes

**Integration Test Parallelization:**
- Flutter doesn't provide built-in parallel integration test support
- Divide integration tests into logical groups
- Run groups on separate devices or in separate jobs
- Cloud-based solutions (Firebase Test Lab) support device parallelization

**Cloud-Based Testing:**
- Firebase Test Lab enables parallel test execution across multiple devices
- Eliminates need for extensive local device infrastructure
- Consistent environments reduce flakiness

**References:**
- [Flutter Testing: Harness the Power of Parallel Test Execution](https://akanksha98.medium.com/flutter-testing-harness-the-power-of-parallel-test-execution-on-test-lab-without-relying-on-github-5146973eae44)
- [Improve test execution speed with concurrency option](https://deku.posstree.com/en/flutter/test/concurrency/)
- [How to build Flutter apps 44% faster with parallel workflows](https://blog.codemagic.io/how-to-build-44-faster-with-parallel-workflows/)

### Handling Flaky Tests

**Problem Definition:**
- Tests that sometimes pass and sometimes fail without code changes
- Common in Flutter: Android timing issues, Firebase Test Lab timeouts
- Particularly prevalent in integration tests and WebView tests

**Retry Policies:**
- Implement automatic retries for failed tests
- Important: don't retry immediately (may fail again due to concurrent interference)
- Better approach: retry after entire test suite completes, possibly on clean test machine
- Use retry helpers in test code to manage retry logic

**Quarantine Strategy:**
- Detect flaky tests and exclude them from pass/fail decisions
- Don't count quarantined tests when deciding whether to accept code change
- Track quarantined tests for future fixing
- Automatic quarantine systems can re-quarantine tests that were "fixed" but remain flaky

**Implementation:**
- Maintain database of test results to identify flakiness patterns
- Adjust CI system to handle quarantined tests appropriately
- Track retry counts and success/failure patterns
- Use flaky test management dashboards for visibility

**Flutter-Specific Notes:**
- Some flakiness is intrinsic to test frameworks (e.g., XCUITests)
- Integration tests particularly prone to timing-based flakiness
- WebView tests have known flakiness issues

**References:**
- [Reducing Test Flakiness](https://github.com/flutter/flutter/wiki/Reducing-Test-Flakiness)
- [How to Fix 'Flaky Tests' in CI/CD](https://oneuptime.com/blog/post/2026-01-24-fix-flaky-tests-cicd/view)
- [Flaky Tests in CI: How to Detect, Manage, and Eliminate](https://triotechsystems.com/flaky-tests-in-ci-how-to-detect-manage-and-eliminate-them/)

### Golden Test Management in CI

**Challenge:**
- Golden image files must be captured in consistent environment
- Different platforms, text scaling, and screen resolutions cause failures
- Golden files need to be versioned and managed across CI agents

**Best Practices:**
- Use single, standardized agent configuration for golden test capture
- Version control golden image files
- Document baseline environment (Flutter version, device config, text scale)
- Use CI/CD tooling to manage golden file updates across agents
- Review visual diffs carefully before accepting new golden files

**Integration:**
- Run golden tests as part of regular test suite
- Compare against checked-in golden files
- Require manual review and approval when golden files change
- Store golden diffs as CI artifacts for review

---

## 5. Performance & Accessibility in BikeRide Context

### Admin Dashboard Specific

**Performance Priorities:**
- Admin dashboard tables/lists with many items: use virtual scrolling
- Real-time data updates: optimize Firestore listeners
- Map rendering: lazy load and optimize polylines for tracking
- Profile mode testing on devices similar to target admin users

**Accessibility Priorities for Admin:**
- Admin panels used by staff: ensure keyboard navigation for efficiency
- TalkBack/VoiceOver support for accessibility compliance
- High contrast modes for readability in bright outdoor environments
- Semantic labels for all dashboard controls and data cells

### RTL Testing for Arabic-First Design

**Critical for BikeRide (Egypt-focused):**
- Default language: Arabic (RTL)
- Test all screens in Arabic RTL mode
- Verify directional icons flip correctly
- Check map markers and polylines in RTL context
- Validate numeric formatting for phone numbers, prices in EGP

---

## 6. Recommended Workflow Summary

1. **Development Phase:**
   - Write unit and widget tests with accessibility in mind
   - Use golden tests for UI regression detection
   - Profile critical paths in profile mode on real device

2. **Pre-Commit:**
   - Run `flutter analyze` to catch lint issues
   - Run `flutter test` locally with coverage
   - Run golden tests and review visual diffs

3. **CI/CD Pipeline:**
   - Parallel test execution (unit, widget, integration)
   - Coverage reporting with minimum threshold enforcement
   - Flaky test quarantine and retry logic
   - Golden test comparison with visual diffs as artifacts
   - Performance benchmark comparison

4. **Testing Across Languages:**
   - Run all widget tests in both Arabic (RTL) and English
   - Golden tests for both LTR and RTL layouts
   - Accessibility tests in both languages

5. **Deployment Gates:**
   - Coverage must meet minimum threshold
   - No unquarantined test failures
   - Golden test approvals reviewed
   - Performance benchmarks within acceptable range

---

## 7. Integration Testing Framework: integration_test vs flutter_driver

### Framework Selection

The **official Flutter recommendation for 2024+** is to use `integration_test` instead of the deprecated `flutter_driver`.

| Aspect | `integration_test` | `flutter_driver` |
|--------|-------------------|------------------|
| **Status** | ✅ Recommended & Actively Maintained | ⚠️ Deprecated / Minimal Support |
| **API Foundation** | Built on `flutter_test` (similar to widget tests) | Custom driver protocol |
| **Learning Curve** | Lower - familiar if you know widget tests | Steeper - requires driver knowledge |
| **Packaging** | App + tests bundled together in ipa/apk | Separate driver executable needed |
| **Firebase Test Lab** | First-class support | Legacy support only |
| **Test Independence** | Tests are independent (no state coupling) | Tests can have dependencies |
| **CI/CD Integration** | Seamless with modern CI systems | Requires driver setup |
| **Future-Proofing** | Long-term support guaranteed | Maintenance mode only |

### Key Advantages of integration_test

1. **Consistency**: Tests resemble widget tests, reducing learning curve
2. **Packaging**: Single ipa/apk contains both app and tests—ideal for device farms
3. **Independence**: Each test runs in isolation; no state carryover between tests
4. **Device Farm Ready**: Firebase Test Lab and cloud testing services prefer this
5. **Maintenance**: Active development with regular updates and community support

### Setup for integration_test

```dart
// Add to pubspec.yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
```

**Test Structure** (`test_driver/integration_test/app_test.dart`):

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:biko/main_customer.dart' as app;

void main() {
  // Initialize integration test binding
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Customer App Integration Tests', () {
    testWidgets('complete booking flow', (WidgetTester tester) async {
      // Launch app
      app.main();

      // Wait for animations to complete
      await tester.pumpAndSettle();

      // Test interactions
      expect(find.byType(SplashScreen), findsOneWidget);

      // Tap to proceed
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Verify navigation
      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });
}
```

**Running integration tests**:

```bash
# On connected device
flutter test integration_test/app_test.dart

# On specific emulator
flutter test -d emulator-5554 integration_test/app_test.dart

# With verbose output
flutter test --verbose integration_test/app_test.dart

# Update golden files if needed
flutter test --update-goldens integration_test/app_test.dart
```

### References

- [Migrating from flutter_driver - Flutter Official Docs](https://docs.flutter.dev/release/breaking-changes/flutter-driver-migration)
- [Integration testing concepts - Flutter Docs](https://docs.flutter.dev/cookbook/testing/integration/introduction)
- [New Flutter Integration Tests - Medium Article](https://tomek-polanski.medium.com/the-new-flutter-integration-tests-are-they-any-good-a7c0fc506d6b)
- [Firebase Test Lab - Integration Testing Guide](https://firebase.google.com/docs/test-lab/flutter/integration-testing-with-flutter)

---

## 8. Test Data Factories & Generators

### Factory Pattern (Recommended for BikeRide)

Create simple, focused factory classes for each model:

```dart
// lib/test/factories/user_factory.dart
import 'package:faker/faker.dart';
import 'package:biko/core/models/user_model.dart';

class UserFactory {
  /// Creates a test customer user
  static UserModel createCustomer({
    String? uid,
    String? name,
    String? phone,
    String? email,
  }) {
    final faker = Faker();
    return UserModel(
      uid: uid ?? faker.guid.guid(),
      name: name ?? faker.person.name(),
      phone: phone ?? _generateEgyptianPhone(),
      email: email ?? faker.internet.email(),
      type: UserType.customer,
      status: UserStatus.active,
      lang: 'ar',
      theme: 'light',
      createdAt: DateTime.now(),
    );
  }

  /// Creates a test driver user
  static UserModel createDriver({
    String? uid,
    String? name,
    String? phone,
  }) {
    final faker = Faker();
    return UserModel(
      uid: uid ?? faker.guid.guid(),
      name: name ?? faker.person.name(),
      phone: phone ?? _generateEgyptianPhone(),
      type: UserType.driver,
      status: UserStatus.active,
      createdAt: DateTime.now(),
    );
  }

  /// Creates admin user
  static UserModel createAdmin({
    String? uid,
    String? email,
  }) {
    return UserModel(
      uid: uid ?? 'admin-uid-${DateTime.now().millisecondsSinceEpoch}',
      name: 'Admin User',
      phone: '+201001234567',
      email: email ?? 'admin@biko.com',
      type: UserType.admin,
      status: UserStatus.active,
      createdAt: DateTime.now(),
    );
  }

  /// Generate valid Egyptian phone number (+201XX format)
  static String _generateEgyptianPhone() {
    final faker = Faker();
    final operators = ['01', '02', '05']; // Vodafone, Etisalat, Telecom
    final operator = operators[faker.randomGenerator.integer(operators.length)];
    final remainder = faker.randomGenerator.integer(999999999, min: 100000000);
    return '+20$operator${remainder.toString().padLeft(8, '0')}';
  }
}
```

### Builder Pattern (For Complex Objects)

Use when models have many optional parameters:

```dart
// lib/test/factories/trip_builder.dart
class TripBuilder {
  String? _id;
  String? _customerId;
  String? _driverId;
  LatLng? _pickupLocation;
  LatLng? _dropoffLocation;
  TripStatus? _status;
  double? _estimatedFare;
  DateTime? _createdAt;

  TripBuilder setId(String id) {
    _id = id;
    return this;
  }

  TripBuilder setCustomerId(String customerId) {
    _customerId = customerId;
    return this;
  }

  TripBuilder setPickupLocation(LatLng location) {
    _pickupLocation = location;
    return this;
  }

  TripBuilder setEstimatedFare(double fare) {
    _estimatedFare = fare;
    return this;
  }

  Trip build() {
    final faker = Faker();
    return Trip(
      id: _id ?? faker.guid.guid(),
      customerId: _customerId ?? faker.guid.guid(),
      driverId: _driverId,
      pickupLocation: _pickupLocation ?? _defaultCairoLocation(),
      dropoffLocation: _dropoffLocation ?? _defaultCairoLocation(),
      status: _status ?? TripStatus.pending,
      estimatedFare: _estimatedFare ?? 45.0,
      createdAt: _createdAt ?? DateTime.now(),
    );
  }

  static LatLng _defaultCairoLocation() {
    final faker = Faker();
    return LatLng(
      30.0444 + faker.randomGenerator.decimal(min: -0.5, max: 0.5),
      31.2357 + faker.randomGenerator.decimal(min: -0.5, max: 0.5),
    );
  }
}

// Usage
final trip = TripBuilder()
  .setCustomerId('cust123')
  .setEstimatedFare(55.0)
  .build();
```

### Faker Package Setup

```dart
// Add to pubspec.yaml
dev_dependencies:
  faker: ^2.1.0
  uuid: ^4.0.0
```

**Common Faker Usage**:

```dart
final faker = Faker();

// Names & People
faker.person.name();          // "Abdullah Mohammed"
faker.person.firstName();     // "Ahmed"
faker.person.lastName();      // "Hassan"

// Contact Info
faker.internet.email();       // "user@example.com"
faker.internet.safeEmail();   // "safe.user@example.com"
faker.phoneNumber.us();       // "+1 (555) 123-4567"

// Dates & Times
faker.date.dateTime();        // Random DateTime
faker.date.dateTimeUtc();     // UTC DateTime
faker.date.future();          // Future date

// Numbers
faker.randomGenerator.integer(1000);      // 0-1000
faker.randomGenerator.decimal();          // 0.0-1.0
faker.randomGenerator.integer(100, min: 50);  // 50-100

// Text
faker.lorem.word();           // Single word
faker.lorem.sentence();       // Full sentence
faker.lorem.paragraph();      // Multiple sentences

// For Egyptian-specific data
class EgyptianDataFactory {
  static String generatePhoneNumber() {
    final faker = Faker();
    final operators = ['01', '02', '05']; // Vodafone, Etisalat, Telecom
    final operator = operators[faker.randomGenerator.integer(operators.length)];
    final number = faker.randomGenerator.integer(999999999, min: 100000000);
    return '+20$operator${number.toString().padLeft(8, '0')}';
  }

  static String generateValidNationalId() {
    final faker = Faker();
    // Egyptian national ID: 14 digits
    final yearOfBirth = faker.randomGenerator.integer(99).toString().padLeft(2, '0');
    final monthOfBirth = faker.randomGenerator.integer(1, max: 12).toString().padLeft(2, '0');
    final dayOfBirth = faker.randomGenerator.integer(1, max: 28).toString().padLeft(2, '0');
    final governorate = faker.randomGenerator.integer(29).toString().padLeft(2, '0');
    final remainder = faker.randomGenerator.integer(99999999).toString().padLeft(8, '0');
    return '2$yearOfBirth$monthOfBirth$dayOfBirth$governorate$remainder';
  }

  static String generateArabicName() {
    final arabicNames = [
      'محمد علي',
      'فاطمة أحمد',
      'عمر محمود',
      'هند يوسف',
      'علي حسن',
      'نور محمد',
      'سارة أحمد',
    ];
    return arabicNames[Random().nextInt(arabicNames.length)];
  }
}
```

### App Configuration Factory

For testing with business parameters:

```dart
// lib/test/factories/app_config_factory.dart
class AppConfigFactory {
  /// Creates test app configuration with default BikeRide pricing
  static AppConfig createTestConfig({
    double? baseFareEgp,
    double? perKmRateEgp,
    double? minFareEgp,
    double? commissionPercentage,
    int? bidTimeoutSeconds,
  }) {
    return AppConfig(
      baseFareEgp: baseFareEgp ?? 5.0,
      perKmRateEgp: perKmRateEgp ?? 2.5,
      minFareEgp: minFareEgp ?? 10.0,
      commissionPercentage: commissionPercentage ?? 0.15,  // 15%
      bidTimeoutSeconds: bidTimeoutSeconds ?? 30,
      maxConcurrentBids: 5,
      currency: 'EGP',
      activeCities: ['cairo', 'giza', 'alex'],
      maintenanceMode: false,
      updatedAt: DateTime.now(),
    );
  }

  /// Creates configuration with high commission (test edge case)
  static AppConfig createHighCommissionConfig() {
    return createTestConfig(commissionPercentage: 0.25);
  }

  /// Creates configuration with long bid timeout
  static AppConfig createLongBidTimeoutConfig() {
    return createTestConfig(bidTimeoutSeconds: 60);
  }
}
```

### References

- [Generating Fake Data with Factory Pattern - DEV Community](https://dev.to/carlomigueldy/generating-fake-data-in-flutter-using-the-factory-pattern-for-unit-testing-3i8k)
- [faker - Flutter Gems Package Directory](https://fluttergems.dev/packages/faker/)
- [SmartFaker - Intelligent Test Data Generation](https://github.com/tienenwu/smart_faker)
- [Quick Fake Data Generation for Flutter UIs](https://codewithandrea.com/tips/faker-package/)

---

## 9. Firebase Realtime Database Mocking

### Using firebase_database_mocks

```dart
// Add to pubspec.yaml
dev_dependencies:
  firebase_database_mocks: ^0.2.0
```

### Setup & Seeding

```dart
// lib/test/mocks/firebase_mocks.dart
import 'package:firebase_database_mocks/firebase_database_mocks.dart';

class FirebaseMockSetup {
  static MockFirebaseDatabase setupMockDatabase() {
    final mock = MockFirebaseDatabase.instance;
    // Keep data in memory for test duration
    MockFirebaseDatabase.setDataPersistenceEnabled(enabled: true);
    return mock;
  }

  /// Seed driver location data for testing
  static void seedDriverLocationData(MockFirebaseDatabase mock) {
    mock.child('drivers_locations').set({
      'driver123': {
        'latitude': 30.0444,
        'longitude': 31.2357,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'accuracy': 10.0,
      },
      'driver456': {
        'latitude': 30.0500,
        'longitude': 31.2400,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'accuracy': 15.0,
      },
    });
  }

  /// Seed active bids for testing
  static void seedActiveBidsData(MockFirebaseDatabase mock) {
    mock.child('active_bids').set({
      'trip123': {
        'driver123': {
          'amount': 50.0,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
        'driver456': {
          'amount': 48.0,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      },
    });
  }
}
```

### Testing Stream Subscriptions

**Critical Pattern** (per RULE-10): All stream subscriptions must be cancelled in `onClose()`:

```dart
// test/services/location_service_test.dart
void main() {
  group('LocationService - Stream Cleanup', () {
    late MockFirebaseDatabase mockDb;
    late LocationService locationService;

    setUp(() {
      Get.testMode = true;
      mockDb = FirebaseMockSetup.setupMockDatabase();
      FirebaseMockSetup.seedDriverLocationData(mockDb);

      locationService = LocationService(database: mockDb);
    });

    tearDown(() {
      // Clean up subscriptions
      locationService.dispose();
      Get.reset();
    });

    test('subscribes to driver location stream', () async {
      // Act
      locationService.subscribeToDriverLocation('driver123');
      await Future.delayed(const Duration(milliseconds: 50));

      // Assert
      expect(locationService.currentLocation, isNotNull);
      expect(locationService.currentLocation?.latitude, equals(30.0444));
    });

    test('handles stream updates', () async {
      // Arrange
      var updateCount = 0;
      locationService.subscribeToDriverLocation('driver123');
      locationService.locationUpdates.listen((_) => updateCount++);

      // Act: Update data
      await mockDb.child('drivers_locations/driver123').update({
        'latitude': 30.0500,
        'longitude': 31.2400,
      });

      await Future.delayed(const Duration(milliseconds: 100));

      // Assert
      expect(updateCount, greaterThan(0));
    });

    test('cancels all subscriptions on dispose', () async {
      // Arrange
      locationService.subscribeToDriverLocation('driver123');
      expect(locationService.isDisposed, isFalse);

      // Act
      locationService.dispose();

      // Assert
      expect(locationService.isDisposed, isTrue);
      // Verify no active subscriptions remain
    });
  });
}
```

### Stream Cleanup in Controllers

**Required Pattern**:

```dart
class LocationService extends GetxService {
  final _subscriptions = <StreamSubscription>[];

  bool _isDisposed = false;
  bool get isDisposed => _isDisposed;

  void subscribeToDriverLocation(String driverId) {
    final subscription = FirebaseDatabase.instance
      .ref('drivers_locations/$driverId')
      .onValue
      .listen(
        (event) {
          // Handle update
        },
        onError: (error) {
          // Handle error
        },
      );

    _subscriptions.add(subscription);
  }

  @override
  void onClose() {
    // CRITICAL: Cancel all subscriptions (RULE-10)
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
    _isDisposed = true;
    super.onClose();
  }
}
```

### References

- [firebase_database_mocks - Pub.dev](https://pub.dev/packages/firebase_database_mocks)
- [FlutterFire Testing Documentation](https://firebase.flutter.dev/docs/testing/testing/)
- [Stream Testing with Matchers - Code with Andrea](https://codewithandrea.com/articles/async-tests-streams-flutter/)

---

## 10. Firestore Mocking for app_config & Data

### Using fake_cloud_firestore

```dart
// Add to pubspec.yaml
dev_dependencies:
  fake_cloud_firestore: ^2.5.0
```

### Setup with Test Data

```dart
// lib/test/mocks/firestore_mocks.dart
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreMockSetup {
  static FakeFirebaseFirestore setupMockFirestore() {
    return FakeFirebaseFirestore();
  }

  /// Seed app_config document with business parameters
  static Future<void> seedAppConfig(FakeFirebaseFirestore db) async {
    await db.collection('app_config').doc('live').set({
      'base_fare_egp': 5.0,
      'per_km_rate_egp': 2.5,
      'min_fare_egp': 10.0,
      'commission_percentage': 0.15,
      'bid_timeout_seconds': 30,
      'max_concurrent_bids': 5,
      'driver_document_requirements': [
        'national_id',
        'driving_license',
        'vehicle_registration',
      ],
      'active_cities': ['cairo', 'giza', 'alex'],
      'currency': 'EGP',
      'maintenance_mode': false,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  /// Seed users for testing
  static Future<void> seedUsers(FakeFirebaseFirestore db) async {
    await db.collection('users').doc('customer123').set(
      UserFactory.createCustomer(uid: 'customer123').toMap(),
    );

    await db.collection('users').doc('driver456').set(
      UserFactory.createDriver(uid: 'driver456').toMap(),
    );

    await db.collection('users').doc('admin789').set(
      UserFactory.createAdmin(uid: 'admin789').toMap(),
    );
  }

  /// Seed trips for testing queries
  static Future<void> seedTrips(FakeFirebaseFirestore db) async {
    for (int i = 0; i < 5; i++) {
      final trip = TripBuilder()
        .setCustomerId('customer123')
        .build()
        .copyWith(status: TripStatus.completed);

      await db.collection('trips').doc(trip.id).set(trip.toMap());
    }
  }
}
```

### Service Testing with Mocks

```dart
// test/services/firestore_service_test.dart
void main() {
  group('FirestoreService - App Config', () {
    late FakeFirebaseFirestore mockDb;
    late FirestoreService firestoreService;

    setUp(() async {
      mockDb = FirestoreMockSetup.setupMockFirestore();
      await FirestoreMockSetup.seedAppConfig(mockDb);
      firestoreService = FirestoreService(firestore: mockDb);
    });

    test('reads app config with business parameters', () async {
      // Act
      final config = await firestoreService.getAppConfig();

      // Assert
      expect(config.baseFareEgp, equals(5.0));
      expect(config.perKmRateEgp, equals(2.5));
      expect(config.commissionPercentage, equals(0.15));
      expect(config.bidTimeoutSeconds, equals(30));
      expect(config.currency, equals('EGP'));
    });

    test('caches config after first read', () async {
      // Act - First read
      final config1 = await firestoreService.getAppConfig();

      // Modify underlying data
      await mockDb.collection('app_config').doc('live').update({
        'base_fare_egp': 10.0,
      });

      // Second read returns cached value
      final config2 = await firestoreService.getAppConfig();

      // Assert
      expect(config1.baseFareEgp, equals(5.0));
      expect(config2.baseFareEgp, equals(5.0)); // Still cached
    });

    test('handles missing config gracefully', () async {
      // Use empty database
      final emptyDb = FirestoreMockSetup.setupMockFirestore();
      final service = FirestoreService(firestore: emptyDb);

      // Assert
      expect(
        () => service.getAppConfig(),
        throwsA(isA<DocumentNotFoundException>()),
      );
    });
  });

  group('FirestoreService - Trip Queries', () {
    late FakeFirebaseFirestore mockDb;
    late FirestoreService firestoreService;

    setUp(() async {
      mockDb = FirestoreMockSetup.setupMockFirestore();
      await FirestoreMockSetup.seedTrips(mockDb);
      firestoreService = FirestoreService(firestore: mockDb);
    });

    test('queries trips for specific customer', () async {
      // Act
      final trips = await firestoreService.getCustomerTrips('customer123');

      // Assert
      expect(trips, isNotEmpty);
      expect(trips.every((t) => t.customerId == 'customer123'), isTrue);
    });

    test('filters completed trips only', () async {
      // Act
      final trips = await firestoreService.getCompletedTrips(
        customerId: 'customer123',
      );

      // Assert
      expect(trips.every((t) => t.status == TripStatus.completed), isTrue);
    });
  });
}
```

### Batch Write Testing

```dart
test('batch writes atomic updates', () async {
  final mockDb = FirestoreMockSetup.setupMockFirestore();
  await FirestoreMockSetup.seedUsers(mockDb);

  // Arrange
  final batch = mockDb.batch();

  // Act: Update wallet and write transaction atomically
  batch.update(
    mockDb.collection('users').doc('customer123'),
    {'wallet_balance': FieldValue.increment(-45.0)},
  );

  batch.set(
    mockDb.collection('transactions').doc('txn001'),
    {
      'user_id': 'customer123',
      'amount': -45.0,
      'type': 'trip_payment',
      'status': 'completed',
      'timestamp': DateTime.now(),
    },
  );

  await batch.commit();

  // Assert
  final user = await mockDb.collection('users').doc('customer123').get();
  expect(user['wallet_balance'], equals(-45.0));
});
```

### References

- [Firestore Mocking Guide - Blog](https://blog.victoreronmosele.com/mocking-firestore-flutter)
- [Firebase Security Rules Unit Tests](https://firebase.google.com/docs/rules/unit-tests)
- [Mocking Firebase Services - Medium](https://medium.com/fludev/mocking-firebase-services-the-smart-way-in-flutter-c9df5fc7abe8)

---

## 11. Testing GetX Navigation

### Important Limitation

Direct unit testing of `Get.toNamed()` and `Get.offAllNamed()` is not possible because GetX uses static context internally. **Navigation testing requires widget tests**.

### Widget Test Approach (Recommended)

```dart
// test/integration/navigation_test.dart
void main() {
  group('GetX Navigation - Widget Tests', () {
    testWidgets('navigates to admin login from splash', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        GetMaterialApp(
          home: const SplashScreen(),
          getPages: AdminPages.pages,
          theme: AppTheme.lightTheme,
          translations: AppTranslations(),
        ),
      );

      // Act
      Get.offAllNamed(AppRoutes.adminLogin);
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(AdminLoginScreen), findsOneWidget);
      expect(find.byType(SplashScreen), findsNothing);
    });

    testWidgets('passes route arguments correctly', (WidgetTester tester) async {
      // Arrange
      final testUser = UserFactory.createCustomer();

      await tester.pumpWidget(
        GetMaterialApp(
          home: const HomePage(),
          getPages: CustomerPages.pages,
        ),
      );

      // Act
      Get.toNamed(
        AppRoutes.profileDetail,
        arguments: {'user': testUser},
      );
      await tester.pumpAndSettle();

      // Assert
      final state = Get.find<ProfileController>();
      expect(state.user?.uid, equals(testUser.uid));
    });

    testWidgets('back navigation works correctly', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        GetMaterialApp(
          home: const HomePage(),
          getPages: CustomerPages.pages,
        ),
      );

      // Act
      Get.toNamed(AppRoutes.tripDetail, arguments: {'tripId': 'trip123'});
      await tester.pumpAndSettle();

      Get.back();
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(HomePage), findsOneWidget);
    });
  });

  group('GetX Navigation - Controller Lifecycle', () {
    testWidgets('controllers initialize on route enter', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        GetMaterialApp(
          home: const HomePage(),
          getPages: CustomerPages.pages,
        ),
      );

      // Act
      Get.toNamed(AppRoutes.pickupLocation);
      await tester.pumpAndSettle();

      // Assert
      final controller = Get.find<PickupLocationController>();
      expect(controller.initialized, isTrue);
    });

    testWidgets('controllers dispose on route exit', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        GetMaterialApp(
          home: const HomePage(),
          getPages: CustomerPages.pages,
        ),
      );

      // Act
      Get.toNamed(AppRoutes.pickupLocation);
      await tester.pumpAndSettle();

      final controller = Get.find<PickupLocationController>();
      Get.back();
      await tester.pumpAndSettle();

      // Assert
      expect(controller.disposed, isTrue);
    });
  });

  group('AdminAuthGuard Middleware', () {
    testWidgets('redirects to login if not authenticated', (WidgetTester tester) async {
      // Arrange
      Get.testMode = true;

      await tester.pumpWidget(
        GetMaterialApp(
          home: const SplashScreen(),
          getPages: AdminPages.pages,
        ),
      );

      // Act: Try to navigate to protected route
      Get.offAllNamed(AppRoutes.adminDashboard);
      await tester.pumpAndSettle();

      // Assert: Should redirect to login
      expect(find.byType(AdminLoginScreen), findsOneWidget);
    });
  });
}
```

### References

- [GetX Navigation Testing - GitHub Issue](https://github.com/jonataslaw/getx/issues/42)
- [Mock GetX Controllers - Hashnode](https://psuedopolymath.hashnode.dev/getx-and-flutter-widget-testing-how-to-use-mock-getx-controller)
- [Mocking Navigator in testWidgets](https://developermemos.com/posts/mock-navigator-test-widgets/)

---

## 12. Golden Tests for UI Consistency

### Setup

```dart
// Add to pubspec.yaml
dev_dependencies:
  golden_toolkit: ^0.14.0
```

### Basic Golden Test Structure

```dart
// test/core/widgets/app_button_golden_test.dart
void main() {
  group('AppButton - Golden Tests', () {
    testGoldens('primary button in light theme', (WidgetTester tester) async {
      await tester.pumpWidgetBuilder(
        const AppButton(
          label: 'Book Ride',
          onPressed: () {},
        ),
        surfaceSize: const Size(400, 100),
        wrapper: materialAppWrapper(
          theme: AppTheme.lightTheme,
        ),
      );

      await expectLater(
        find.byType(AppButton),
        matchesGoldenFile('goldens/app_button_primary_light.png'),
      );
    });

    testGoldens('disabled button state', (WidgetTester tester) async {
      await tester.pumpWidgetBuilder(
        const AppButton(
          label: 'Disabled',
          onPressed: null,
        ),
        surfaceSize: const Size(400, 100),
      );

      await expectLater(
        find.byType(AppButton),
        matchesGoldenFile('goldens/app_button_disabled.png'),
      );
    });

    // CRITICAL: Test Arabic RTL
    testGoldens('button in Arabic RTL', (WidgetTester tester) async {
      await tester.pumpWidgetBuilder(
        const Directionality(
          textDirection: TextDirection.rtl,
          child: AppButton(
            label: 'احجز الآن',
            onPressed: () {},
          ),
        ),
        surfaceSize: const Size(400, 100),
      );

      await expectLater(
        find.byType(AppButton),
        matchesGoldenFile('goldens/app_button_rtl.png'),
      );
    });
  });
}
```

### Configuration File

```yaml
# dart_test.yaml (project root)
tags:
  golden:
    timeout: 2m

exclude_tags:
  - slow
```

### Running Golden Tests

```bash
# Generate golden files on first run
flutter test --update-goldens test/core/widgets/

# Run tests (compare against golden files)
flutter test test/core/widgets/

# Run with pixel tolerance (useful in CI)
flutter test --golden-tolerance=0.5 test/
```

### Best Practices

1. **Test at Multiple Sizes**: 360px (mobile), 600px (tablet), 1024px (web)
2. **Test Both Languages**: English (LTR) and Arabic (RTL)
3. **Test Dark Mode**: Separate goldens for light/dark themes
4. **Test States**: Loading, error, success, empty states
5. **Descriptive Names**: Include widget, state, and theme in filename

### References

- [Golden Tests Best Practices - Vibe Studio](https://vibe-studio.ai/insights/flutter-widget-testing-best-practices-golden-tests-and-screenshot-diffs)
- [Comprehensive Golden Tests Guide - Medium](https://medium.com/profusion-engineering/golden-tests-in-flutter-a-comprehensive-guide-b4b50a932fd5)
- [Golden Testing with Tolerance](https://tomasrepcik.dev/blog/2024/2024-09-19-flutter-golden-test-with-tolerance/)

---

## 13. Complete Testing Stack for BikeRide

### Recommended Dependencies

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter

  # Integration Testing
  integration_test:
    sdk: flutter

  # Test Data Generation
  faker: ^2.1.0
  uuid: ^4.0.0

  # Firebase Mocking
  firebase_database_mocks: ^0.2.0
  fake_cloud_firestore: ^2.5.0

  # Mocking & Stubbing
  mockito: ^5.4.0

  # Golden Tests
  golden_toolkit: ^0.14.0

  # Linting
  flutter_lints: ^5.0.0
```

### Directory Structure Template

```
test/
├── factories/
│   ├── user_factory.dart
│   ├── trip_factory.dart
│   ├── app_config_factory.dart
│   └── phone_factory.dart
├── mocks/
│   ├── firebase_mocks.dart
│   ├── firestore_mocks.dart
│   └── getx_test_helpers.dart
├── unit/
│   ├── services/
│   │   ├── firestore_service_test.dart
│   │   └── location_service_test.dart
│   └── controllers/
│       └── admin_auth_controller_test.dart
├── widget/
│   ├── screens/
│   │   └── admin_login_screen_test.dart
│   └── widgets/
│       └── app_button_test.dart
├── integration/
│   ├── customer_booking_flow_test.dart
│   └── admin_dashboard_test.dart
├── goldens/
│   ├── screens/
│   │   └── admin_login_screen.png
│   └── widgets/
│       └── app_button_primary_light.png
└── integration_test/
    ├── admin_dashboard_test.dart
    └── customer_booking_test.dart
```

### Testing Pyramid

```
         Integration Tests (5-10)
    Widget Tests (30-50)
Unit Tests (100-150+)
```

---

## 14. Implementation Checklist

### Phase 1: Foundation (Week 1)
- [ ] Add testing dependencies
- [ ] Create factory classes for core models
- [ ] Setup Firebase mocks
- [ ] Write 5+ unit tests

### Phase 2: Coverage (Week 2-3)
- [ ] Write unit tests for all controllers
- [ ] Add widget tests for critical screens
- [ ] Create golden tests for shared widgets
- [ ] Test Arabic RTL in screens

### Phase 3: Integration (Week 4)
- [ ] Write 5-10 integration tests
- [ ] Setup CI/CD with flutter test
- [ ] Add code coverage reporting
- [ ] Document testing procedures

### Phase 4: Maintenance
- [ ] Run tests in CI on every commit
- [ ] Update tests when features change
- [ ] Add tests before fixing bugs (TDD)
- [ ] Review coverage quarterly

---

## 15. Conclusion

**Key Recommendations for BikeRide (2024-2025)**:

1. **Integration Testing**: Use `integration_test` (not deprecated `flutter_driver`)
2. **Test Data**: Factory pattern with `faker` for realistic Egyptian data
3. **Firebase Mocking**: `firebase_database_mocks` + `fake_cloud_firestore`
4. **Navigation Testing**: Widget tests required; unit tests insufficient for GetX
5. **UI Consistency**: Golden tests critical for RTL/Arabic primary experience
6. **Stream Cleanup**: Strict cancellation in `onClose()` to prevent memory leaks

These patterns align with Flutter 2024-2025 best practices and BikeRide's specific architecture (Firebase-only backend, GetX state management, Egyptian market focus with Arabic RTL).
