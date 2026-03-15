# Test Helper Contract

**Version**: 1.0.0
**Last Updated**: 2026-03-11
**Applies To**: All test helper utilities in `test/helpers/`

## Purpose

Test helpers provide common setup, teardown, and utility functions shared across all test files. Helpers MUST follow consistent patterns to ensure predictable test behavior and reduce duplication.

## Contract

### Helper Categories

BikeRide test infrastructure has three helper categories, each with specific contracts:

1. **GetX Test Helper** (`getx_test_helpers.dart`)
2. **Golden Test Helper** (`golden_test_helpers.dart`)
3. **Firebase Test Helper** (`firebase_test_helpers.dart`)

---

## GetX Test Helper Contract

Manages GetX state management setup/teardown for all tests.

### Required Static Methods

```dart
class GetXTestHelper {
  /// Enables GetX test mode (disables logging, makes behavior deterministic)
  static void setup();

  /// Resets all GetX instances and bindings
  static void cleanup();

  /// Pumps a widget wrapped in GetMaterialApp with BikeRide theme and translations
  static Future<void> pumpApp(
    WidgetTester tester,
    Widget child, {
    ThemeMode? themeMode,
    Locale? locale,
    List<GetPage>? pages,
  });

  /// Registers all mock services (Auth, Firestore, Location)
  static void registerMockServices();
}
```

### Behavior Constraints

- `setup()` MUST be called in `setUp()` of every GetX test
- `cleanup()` MUST be called in `tearDown()` of every GetX test
- `registerMockServices()` MUST replace real services with mocks
- `pumpApp()` MUST use `GetMaterialApp` (not plain `MaterialApp`)

### Example Implementation

```dart
class GetXTestHelper {
  static void setup() {
    Get.testMode = true;
  }

  static void cleanup() {
    Get.reset();
  }

  static Future<void> pumpApp(
    WidgetTester tester,
    Widget child, {
    ThemeMode? themeMode,
    Locale? locale,
    List<GetPage>? pages,
  }) async {
    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.getThemeWithLocale(locale ?? const Locale('ar')),
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode ?? ThemeMode.light,
        locale: locale ?? const Locale('ar'),
        translations: AppTranslations(),
        getPages: pages,
        home: Scaffold(body: child),
      ),
    );
  }

  static void registerMockServices() {
    Get.lazyPut<AuthService>(() => MockAuthService());
    Get.lazyPut<FirestoreService>(() => MockFirestoreService());
    Get.lazyPut<LocationService>(() => MockLocationService());
  }
}
```

### Usage Pattern

```dart
void main() {
  setUp(() {
    GetXTestHelper.setup();
    GetXTestHelper.registerMockServices();
  });

  tearDown(() {
    GetXTestHelper.cleanup();
  });

  testWidgets('home screen renders', (tester) async {
    await GetXTestHelper.pumpApp(tester, HomeScreen());
    expect(find.text('home_title'.tr), findsOneWidget);
  });
}
```

---

## Golden Test Helper Contract

Simplifies visual regression testing across light/dark themes and RTL layouts.

### Required Static Methods

```dart
class GoldenTestHelper {
  /// Test widget in light theme
  static Future<void> testLightTheme(
    WidgetTester tester,
    Widget widget,
    String filename,
  );

  /// Test widget in dark theme
  static Future<void> testDarkTheme(
    WidgetTester tester,
    Widget widget,
    String filename,
  );

  /// Test widget in RTL (Arabic) layout
  static Future<void> testRTL(
    WidgetTester tester,
    Widget widget,
    String filename,
  );

  /// Test widget at multiple screen sizes
  static Future<void> testResponsive(
    WidgetTester tester,
    Widget widget,
    String filename,
    List<Size> sizes,
  );
}
```

### File Path Conventions

Golden files MUST follow this directory structure:

```
test/
└── core/
    └── widgets/
        ├── app_button_test.dart
        └── goldens/
            ├── light/
            │   └── app_button_primary.png
            ├── dark/
            │   └── app_button_primary.png
            └── rtl/
                └── app_button_primary_rtl.png
```

### Behavior Constraints

- All golden tests MUST pump widget wrapped in `MaterialApp`
- Light theme golden path: `goldens/light/{filename}.png`
- Dark theme golden path: `goldens/dark/{filename}.png`
- RTL golden path: `goldens/rtl/{filename}.png`
- Responsive golden path: `goldens/responsive/{filename}_{width}x{height}.png`

### Example Implementation

```dart
class GoldenTestHelper {
  static Future<void> testLightTheme(
    WidgetTester tester,
    Widget widget,
    String filename,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(body: widget),
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
        theme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        home: Scaffold(body: widget),
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
          child: Scaffold(body: widget),
        ),
      ),
    );

    await expectLater(
      find.byWidget(widget),
      matchesGoldenFile('goldens/rtl/$filename.png'),
    );
  }

  static Future<void> testResponsive(
    WidgetTester tester,
    Widget widget,
    String filename,
    List<Size> sizes,
  ) async {
    for (final size in sizes) {
      tester.binding.window.physicalSizeTestValue = size;
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(body: widget),
        ),
      );

      await expectLater(
        find.byWidget(widget),
        matchesGoldenFile(
          'goldens/responsive/${filename}_${size.width.toInt()}x${size.height.toInt()}.png',
        ),
      );
    }
  }
}
```

### Usage Pattern

```dart
void main() {
  group('AppButton Golden Tests', () {
    testWidgets('primary button light theme', (tester) async {
      const button = AppButton(text: 'Press Me', onPressed: null);
      await GoldenTestHelper.testLightTheme(tester, button, 'app_button_primary');
    });

    testWidgets('primary button dark theme', (tester) async {
      const button = AppButton(text: 'Press Me', onPressed: null);
      await GoldenTestHelper.testDarkTheme(tester, button, 'app_button_primary');
    });

    testWidgets('primary button RTL layout', (tester) async {
      const button = AppButton(
        text: 'اضغط عليّ',
        onPressed: null,
        leadingIcon: Icons.arrow_forward,
      );
      await GoldenTestHelper.testRTL(tester, button, 'app_button_primary_rtl');
    });

    testWidgets('button responsive sizes', (tester) async {
      const button = AppButton(text: 'Press Me', onPressed: null);
      await GoldenTestHelper.testResponsive(
        tester,
        button,
        'app_button_primary',
        [
          const Size(360, 800),  // Small phone
          const Size(768, 1024), // Tablet
        ],
      );
    });
  });
}
```

---

## Firebase Test Helper Contract

Provides factory methods for creating mock Firebase services.

### Required Static Methods

```dart
class FirebaseTestHelper {
  /// Creates a fake Firestore instance (in-memory)
  static FakeFirebaseFirestore createFakeFirestore();

  /// Creates a mock Firebase Auth instance
  static MockFirebaseAuth createMockAuth({User? initialUser});

  /// Seeds Firestore with test data
  static Future<void> seedFirestore(
    FakeFirebaseFirestore firestore,
    Map<String, List<Map<String, dynamic>>> data,
  );

  /// Clears all data from fake Firestore
  static Future<void> clearFirestore(FakeFirebaseFirestore firestore);
}
```

### Behavior Constraints

- All Firebase instances MUST be in-memory (no network calls)
- `seedFirestore()` MUST accept data in format `{collection: [docs]}`
- `clearFirestore()` MUST delete all documents from all collections

### Example Implementation

```dart
class FirebaseTestHelper {
  static FakeFirebaseFirestore createFakeFirestore() {
    return FakeFirebaseFirestore();
  }

  static MockFirebaseAuth createMockAuth({User? initialUser}) {
    return MockFirebaseAuth(signedIn: initialUser != null, user: initialUser);
  }

  static Future<void> seedFirestore(
    FakeFirebaseFirestore firestore,
    Map<String, List<Map<String, dynamic>>> data,
  ) async {
    for (final entry in data.entries) {
      final collection = entry.key;
      final docs = entry.value;

      for (final doc in docs) {
        await firestore.collection(collection).add(doc);
      }
    }
  }

  static Future<void> clearFirestore(FakeFirebaseFirestore firestore) async {
    final collections = ['users', 'trips', 'bids', 'wallets', 'transactions'];
    for (final collection in collections) {
      final docs = await firestore.collection(collection).get();
      for (final doc in docs.docs) {
        await doc.reference.delete();
      }
    }
  }
}
```

### Usage Pattern

```dart
void main() {
  late FakeFirebaseFirestore firestore;
  late MockFirebaseAuth auth;
  late FirestoreService service;

  setUp(() async {
    firestore = FirebaseTestHelper.createFakeFirestore();
    auth = FirebaseTestHelper.createMockAuth();
    service = FirestoreService(firestore);

    // Seed with test data
    await FirebaseTestHelper.seedFirestore(firestore, {
      'users': [
        UserFactory.create().toMap(),
        UserFactory.createDriver().toMap(),
      ],
      'trips': [
        TripFactory.create().toMap(),
      ],
    });
  });

  tearDown(() async {
    await FirebaseTestHelper.clearFirestore(firestore);
  });

  test('getUser retrieves seeded user', () async {
    final user = await service.getUser('test_user_123');
    expect(user, isNotNull);
  });
}
```

---

## Validation

All test helpers MUST pass these validation checks:
- ✅ Static methods only (no instance state)
- ✅ No side effects beyond test setup/teardown
- ✅ Idempotent (multiple calls produce same result)
- ✅ Fast execution (<50ms per call)
- ✅ Clear method names that describe purpose
- ✅ Consistent parameter ordering across helpers

## Non-Goals

Test helpers MUST NOT:
- ❌ Contain test assertions (helpers set up, tests assert)
- ❌ Have complex business logic (keep helpers simple)
- ❌ Depend on specific test files (helpers are reusable)
- ❌ Modify global state (except GetX registration which is reset in tearDown)
