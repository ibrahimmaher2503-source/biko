# BikeRide Testing Guide

## Table of Contents
1. [Benchmark Testing](#benchmark-testing)
2. [Memory Leak Prevention](#memory-leak-prevention)
3. [Widget Test Helpers](#widget-test-helpers)
4. [Integration Testing](#integration-testing)
5. [Test Maintenance](#test-maintenance)

---

## Benchmark Testing

### Performance Testing Approach
BikeRide uses Flutter's built-in test framework for performance verification.

#### Key Metrics to Monitor
- Widget build time under 16ms (60fps target)
- Controller initialization time
- Translation lookup speed (1300+ keys)
- Route resolution time

#### Running Performance Checks
```bash
# Run tests with timing output
flutter test --reporter expanded

# Profile mode for realistic performance
flutter run --profile -t lib/main_customer.dart
```

#### Translation Benchmark
```dart
test('translation lookup is fast for 1300+ keys', () {
  final translations = AppTranslations();
  final arKeys = translations.keys['ar']!;
  final stopwatch = Stopwatch()..start();

  for (var i = 0; i < 1000; i++) {
    arKeys['common.ok'];
  }

  stopwatch.stop();
  // 1000 lookups should complete in under 10ms
  expect(stopwatch.elapsedMilliseconds, lessThan(10));
});
```

---

## Memory Leak Prevention

### GetX Controller Cleanup Rules

1. **Always cancel stream subscriptions in `onClose()`**:
```dart
class MyController extends GetxController {
  StreamSubscription? _sub;

  @override
  void onInit() {
    super.onInit();
    _sub = someStream.listen((data) { /* ... */ });
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }
}
```

2. **Always call `Get.delete()` in test tearDown**:
```dart
tearDown(Get.reset); // Cleans up all registered controllers
```

3. **Verify disposal in tests**:
```dart
test('controller disposes correctly', () {
  final controller = Get.put(MyController());
  expect(controller.disposed, isFalse);
  Get.delete<MyController>();
  expect(controller.disposed, isTrue);
});
```

### Common Memory Leak Patterns to Avoid
- Forgetting to cancel `Timer` instances in `onClose()`
- Not disposing `TextEditingController` or `ScrollController`
- Holding references to `BuildContext` in controllers
- Using `permanent: true` when not needed

### Testing for Leaks
```dart
test('no lingering controllers after deletion', () {
  Get.put(MyController());
  Get.delete<MyController>();
  expect(() => Get.find<MyController>(), throwsA(anything));
});
```

---

## Widget Test Helpers

### Standard Test Wrapper
Located in `test/helpers/test_helpers.dart`:

```dart
Widget buildTestApp({
  required Widget home,
  Locale locale = const Locale('ar'),
}) {
  return GetMaterialApp(
    translations: AppTranslations(),
    locale: locale,
    fallbackLocale: const Locale('en'),
    theme: AppTheme.lightTheme,
    darkTheme: AppTheme.darkTheme,
    home: home,
  );
}
```

### Common Test Patterns

#### Testing with Arabic RTL
```dart
testWidgets('screen renders in RTL', (tester) async {
  await tester.pumpWidget(buildTestApp(
    home: const MyScreen(),
    locale: const Locale('ar'),
  ));
  // Verify RTL layout...
});
```

#### Testing Translations Exist
```dart
test('screen keys exist in both locales', () {
  final translations = AppTranslations();
  final ar = translations.keys['ar']!;
  final en = translations.keys['en']!;

  for (final key in ['screen.title', 'screen.subtitle']) {
    expect(ar.containsKey(key), isTrue, reason: 'Missing AR: $key');
    expect(en.containsKey(key), isTrue, reason: 'Missing EN: $key');
  }
});
```

#### Testing Button Tap
```dart
testWidgets('button triggers action', (tester) async {
  var tapped = false;
  await tester.pumpWidget(buildTestApp(
    home: AppButton(
      text: 'Tap me',
      onPressed: () => tapped = true,
    ),
  ));
  await tester.tap(find.text('Tap me'));
  expect(tapped, isTrue);
});
```

---

## Integration Testing

### App Entry Testing
Each app entry point (Customer, Driver, Admin) is tested to verify:
1. Page registry is non-empty
2. Essential routes exist
3. GetMaterialApp builds without error

### Multi-App Route Isolation
```dart
test('admin routes are distinct from customer routes', () {
  final customerRoutes = CustomerPages.pages.map((p) => p.name).toSet();
  final adminRoutes = AdminPages.pages.map((p) => p.name).toSet();
  final adminOnly = adminRoutes.difference(customerRoutes);
  expect(adminOnly, isNotEmpty);
});
```

### Shared Core Module Verification
Tests verify that `AppRoutes`, `AppTheme`, and `AppTranslations` work across all three apps without conflicts.

### Running Integration Tests
```bash
flutter test test/integration/
```

---

## Test Maintenance

### Adding Tests for New Features

1. **Create test file** mirroring source structure:
   - Source: `lib/features/wallet/controllers/wallet_controller.dart`
   - Test: `test/features/wallet/controllers/wallet_controller_test.dart`

2. **Import the GetX test setup pattern**:
```dart
setUp(() => Get.testMode = true);
tearDown(Get.reset);
```

3. **Test all three states** for every screen:
   - Loading state
   - Error state
   - Empty state
   - Populated state

4. **Add translation keys first**, then test they exist in both locales.

### Test Naming Convention
- Test IDs follow the pattern: `T-{CATEGORY}-{NUMBER}`
- Categories: L10N (localization), SB (snackbar), INT (integration), POL (polish)
- Feature tests: `T{feature-number}` (e.g., T005 for state management)

### When to Update Tests
- Adding new translation keys: update T-L10N-01/02 key parity tests
- Adding new routes: update T-INT route existence tests
- Adding new SnackbarType values: update T-SB-08 enum count
- Adding new feature modules: update T-L10N-21 feature prefix list

### CI/CD Integration
Tests run automatically on push to `main` and `develop` via GitHub Actions:
```bash
flutter analyze   # Lint check
dart format       # Format check
flutter test      # All tests
flutter test --coverage  # Coverage report
```

### Coverage Target
- Minimum: 60% line coverage
- Goal: 80% for core modules, 70% for features
- Run: `flutter test --coverage` then check `coverage/lcov.info`
