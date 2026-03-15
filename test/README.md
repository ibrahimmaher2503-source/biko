# BikeRide Test Suite

Comprehensive test suite for the BikeRide customer app. Tests are organized by type and feature, following Flutter best practices and the project's SpecKit workflow.

---

## Quick Start

### Run All Tests

```bash
# From the repository root:
flutter test
```

### Run Tests with Coverage

```bash
flutter test --coverage
```

### Run a Specific Test File

```bash
flutter test test/core/widgets/app_button_test.dart
```

### Run Tests by Directory

```bash
# Widget tests only
flutter test test/core/widgets/

# Feature controller tests only
flutter test test/features/

# Integration tests only
flutter test test/integration/

# Accessibility tests
flutter test test/accessibility/

# Translation tests
flutter test test/l10n/

# Performance tests
flutter test test/performance/
```

### Run Tests with Verbose Output

```bash
flutter test --reporter=expanded
```

---

## Test Directory Structure

```
test/
├── README.md                          # This file
├── core/
│   ├── models/                        # Model tests (US2)
│   │   ├── user_model_test.dart
│   │   ├── trip_model_test.dart
│   │   ├── bid_model_test.dart
│   │   └── place_model_test.dart
│   ├── services/                      # Service tests (US2)
│   │   ├── auth_service_test.dart
│   │   ├── firestore_service_test.dart
│   │   └── location_service_test.dart
│   ├── theme/                         # Theme tests
│   └── widgets/                       # Shared widget tests (US1)
│       ├── app_button_test.dart
│       ├── app_text_field_test.dart
│       ├── app_card_test.dart
│       ├── app_loading_test.dart
│       ├── app_snackbar_test.dart
│       ├── app_dialog_test.dart
│       ├── app_bottom_sheet_test.dart
│       ├── app_error_widget_test.dart
│       └── app_empty_state_test.dart
├── features/                          # Feature controller tests (US2)
│   ├── auth/controllers/
│   ├── home/controllers/
│   ├── profile/controllers/
│   ├── trip/controllers/
│   ├── bidding/controllers/
│   └── wallet/controllers/
├── integration/                       # Integration tests (US3)
│   ├── auth_flow_test.dart
│   ├── trip_creation_flow_test.dart
│   ├── bidding_flow_test.dart
│   ├── error_scenarios_test.dart
│   └── navigation_guards_test.dart
├── accessibility/                     # Accessibility & RTL tests (US4)
│   ├── accessibility_test.dart
│   └── rtl_layout_test.dart
├── performance/                       # Performance tests (US4)
│   └── performance_test.dart
├── l10n/                              # Translation tests (US4)
│   ├── localization_test.dart
│   └── translation_test.dart
├── helpers/                           # Shared test utilities
│   ├── getx_test_helpers.dart
│   ├── golden_test_helpers.dart
│   ├── firebase_test_helpers.dart
│   ├── mock_services.dart
│   ├── test_factories.dart
│   └── test_fixtures.dart
└── goldens/                           # Golden reference images
```

---

## How to Write Tests

### Unit Tests (Controllers & Services)

Unit tests verify pure functions and observable state without Firebase:

```dart
import 'package:biko/features/auth/controllers/auth_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  test('isValidEgyptianPhone returns true for valid Vodafone number', () {
    final controller = AuthController();
    // Note: instantiate directly — does NOT call onInit()
    expect(controller.isValidEgyptianPhone('1012345678'), isTrue);
  });
}
```

**Key rules:**
- Use `Get.testMode = true` in `setUp()` and `Get.reset()` in `tearDown()`
- Instantiate controllers directly (`Controller()`) — this does NOT trigger `onInit()`
- Only test pure functions and `.obs` state — Firebase calls are in integration tests
- Never call `Get.put()` in unit tests (use direct instantiation)

### Widget Tests

Widget tests verify UI rendering, interactions, and state:

```dart
import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AppButton renders text and responds to tap', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: AppButton(
            text: 'Book Ride',
            onPressed: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('Book Ride'), findsOneWidget);

    await tester.tap(find.byType(AppButton));
    await tester.pump();

    expect(tapped, isTrue);
  });
}
```

**Key rules:**
- Always use `AppTheme.lightTheme` (or `darkTheme`) in widget tests
- Wrap widgets in `MaterialApp(home: Scaffold(...))` for proper context
- Use `await tester.pump()` after interactions (not `pumpAndSettle()` unless animations)
- Test both light and dark themes for all shared widgets

### Integration Tests

Integration tests verify component interactions and data flows:

```dart
import 'package:biko/core/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Auth flow data contracts', () {
    test('UserModel.fromJson produces expected output for auth flow', () {
      final json = {
        'uid': 'user_001',
        'name': 'محمد أحمد',
        'phone': '+201012345678',
        'type': 'customer',
      };

      final user = UserModel.fromJson(json);

      expect(user.uid, equals('user_001'));
      expect(user.type.toJson(), equals('customer'));
    });
  });
}
```

### RTL / Arabic Tests

Always test screens in Arabic RTL mode (Egypt's primary locale):

```dart
testWidgets('widget renders in Arabic RTL', (tester) async {
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.rtl,
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: YourWidget(),
        ),
      ),
    ),
  );

  expect(tester.takeException(), isNull);
});
```

Or use `GetMaterialApp` for full translation support:

```dart
await tester.pumpWidget(
  GetMaterialApp(
    translations: AppTranslations(),
    locale: const Locale('ar'),
    fallbackLocale: const Locale('en'),
    theme: AppTheme.lightTheme,
    home: Scaffold(body: YourWidget()),
  ),
);
```

---

## Coverage Report Generation

### Generate Coverage Data

```bash
flutter test --coverage
```

This creates `coverage/lcov.info`.

### Generate HTML Report

```bash
# Install lcov (macOS)
brew install lcov

# Install lcov (Linux/Ubuntu)
sudo apt-get install -y lcov

# Generate HTML report
genhtml coverage/lcov.info -o coverage/html

# Open report in browser (macOS)
open coverage/html/index.html

# Open report in browser (Linux)
xdg-open coverage/html/index.html
```

### View Coverage Summary in Terminal

```bash
lcov --summary coverage/lcov.info
```

### Expected Coverage Targets

| Component | Target | Description |
|-----------|--------|-------------|
| `core/widgets/` | >= 80% | All shared widgets |
| `core/services/` | >= 70% | Firebase service wrappers |
| `core/models/` | >= 90% | Pure data models |
| `features/*/controllers/` | >= 70% | Controller business logic |
| Overall | >= 70% | Minimum enforced by CI |

---

## Troubleshooting

### Tests Fail with Firebase Initialization Error

**Problem:** `FirebaseApp named "[DEFAULT]" already exists`

**Solution:** Unit tests should never call Firebase. Check that:
1. You're instantiating controllers directly (not via `Get.put()`)
2. No `onInit()` is being triggered (direct instantiation skips it)
3. `Get.reset()` is in `tearDown()`

```dart
// Correct — does NOT trigger onInit()
final controller = HomeController();

// Wrong — triggers onInit() which calls Firebase
Get.put(HomeController());
```

### Widget Tests Fail with "No Directionality widget"

**Problem:** Widget requires `Directionality` but isn't wrapped in `MaterialApp`

**Solution:** Always wrap test widgets in `MaterialApp`:

```dart
// Correct
await tester.pumpWidget(MaterialApp(home: YourWidget()));

// Wrong
await tester.pumpWidget(YourWidget());
```

### GetX Tests Fail Between Test Cases

**Problem:** GetX state leaks between tests

**Solution:** Ensure proper setUp/tearDown:

```dart
setUp(() => Get.testMode = true);
tearDown(Get.reset);
```

### Golden Tests Fail After UI Changes

**Problem:** Visual regression detected — golden images are outdated

**Solution:** Regenerate golden reference images:

```bash
# Regenerate all widget goldens
flutter test --update-goldens test/core/widgets/

# Regenerate specific test file
flutter test --update-goldens test/core/widgets/app_button_test.dart
```

Then commit the updated golden files:

```bash
git add test/core/widgets/goldens/
git commit -m "chore: update golden reference images"
```

### Translation Tests Fail with "Missing Key" Error

**Problem:** `AR keys missing EN translation` or vice versa

**Solution:** Add the missing key to **both** maps in `app_translations.dart`:

```dart
'ar': {
  'feature.new_key': 'النص العربي',  // Add here
},
'en': {
  'feature.new_key': 'English Text',  // And here
},
```

---

## Test Writing Guide

### Naming Conventions

- Test files: `<source_file>_test.dart` (mirrors source structure)
- Test groups: Match task IDs where possible (`T097: phone validation`)
- Test names: Describe the expected behavior, not the implementation

```dart
// Good test names
test('isValidEgyptianPhone returns false for 9-digit number', () { ... });
test('changeTab(2) does not update currentTabIndex (center FAB button)', () { ... });

// Bad test names
test('phone validation test', () { ... });
test('test tab change', () { ... });
```

### Test Structure (AAA Pattern)

```dart
test('widget shows error message when network fails', () {
  // Arrange
  const errorMessage = 'Network connection failed';

  // Act
  final widget = AppErrorWidget(message: errorMessage);

  // Assert
  expect(widget.message, equals(errorMessage));
});
```

### What to Test vs. Not Test

| Layer | Test | What to verify |
|-------|------|----------------|
| Models | Unit | `fromJson`, `toMap`, `copyWith`, computed properties |
| Services | Unit | Method signatures exist, error handling patterns |
| Controllers | Unit | Initial state, pure functions, `.obs` updates, `onClose` |
| Widgets | Widget | Render, interaction, theming, RTL, accessibility |
| Integration | Widget | Data flow, navigation, state synchronization |

Do **not** test:
- Firebase calls directly (mock or test indirectly)
- Platform-specific APIs (GPS, camera, notifications) in unit tests
- Auto-generated code (`*.g.dart`)
- Framework internals

---

## CI/CD Integration

Tests run automatically via GitHub Actions (`.github/workflows/test.yml`):

| Job | Trigger | What it does |
|-----|---------|--------------|
| `test` | Every push/PR | Runs all tests with coverage |
| `coverage` | After `test` | Enforces >= 70% coverage threshold |
| `golden-tests` | Every push/PR | Verifies golden images unchanged |
| `codecov` | Push to main/develop | Uploads coverage to Codecov |
| `matrix-test` | Every push/PR | Tests on Flutter stable + beta |
| `format` | Every push/PR | Enforces `dart format` compliance |
