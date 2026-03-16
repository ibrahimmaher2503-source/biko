# GetX Mock Patterns for BikeRide

## Test Mode Setup

Always enable GetX test mode in `setUp`:

```dart
setUp(() {
  Get.testMode = true;
});

tearDown(Get.reset);
```

## Controller Registration in Tests

### Direct Registration (Unit Tests)
```dart
final controller = Get.put(MyController());
// Use controller...
Get.delete<MyController>();
```

### Permanent Controllers
```dart
Get.put(MyController(), permanent: true);
// Survives Get.delete() unless force: true
Get.delete<MyController>(force: true); // Cleanup
```

### With Tags
```dart
Get.put(MyController(), tag: 'profile');
final c = Get.find<MyController>(tag: 'profile');
Get.delete<MyController>(tag: 'profile');
```

## Widget Test Pattern

### Basic GetMaterialApp Setup
```dart
testWidgets('screen renders correctly', (tester) async {
  await tester.pumpWidget(
    GetMaterialApp(
      translations: AppTranslations(),
      locale: const Locale('ar'),
      fallbackLocale: const Locale('en'),
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: const MyScreen(),
    ),
  );
  // assertions...
});
```

### Avoiding Common GetX Test Pitfalls

#### 1. Never use `pumpAndSettle()` with GetX
GetX animations cause `pumpAndSettle()` to hang indefinitely. Use `pump()` instead:
```dart
// BAD - will hang
await tester.pumpAndSettle();

// GOOD
await tester.pump();
await tester.pump(const Duration(milliseconds: 500));
```

#### 2. Never use `Get.updateLocale()` in widget tests
The future hangs in test mode. Instead, create separate test instances:
```dart
// BAD - hangs
await Get.updateLocale(const Locale('ar'));

// GOOD - separate test per locale
testWidgets('AR locale', (tester) async {
  await tester.pumpWidget(
    GetMaterialApp(locale: const Locale('ar'), ...),
  );
});
```

#### 3. GetX Snackbar Overlay Lifecycle
`Get.snackbar()` requires an active widget tree with overlay. In unit tests without widgets, never call `AppSnackbar.*()` methods. Only one testWidgets per file should show snackbars, and must pump past the auto-dismiss timer:
```dart
// Show snackbar
await tester.tap(find.text('Show'));
await tester.pump();
await tester.pump(const Duration(milliseconds: 500));

// Verify content
expect(find.text('Success'), findsOneWidget);

// Pump past 3-second auto-dismiss timer
await tester.pump(const Duration(seconds: 4));
await tester.pump(const Duration(seconds: 1));
```

## Reactive Variable Testing

```dart
test('reactive int triggers observers', () {
  final controller = TestController();
  var updateCount = 0;

  controller.count.listen((_) => updateCount++);
  controller.increment();

  expect(updateCount, equals(1));
  expect(controller.count.value, equals(1));
});
```

## Lifecycle Testing

```dart
test('onInit/onClose execute correctly', () {
  final controller = Get.put(MyController());
  expect(controller.initialized, isTrue);
  expect(controller.disposed, isFalse);

  Get.delete<MyController>();
  expect(controller.disposed, isTrue);
});
```

## Translation Testing

### Key Parity Check
```dart
test('every EN key has a corresponding AR key', () {
  final translations = AppTranslations();
  final arKeys = translations.keys['ar']!;
  final enKeys = translations.keys['en']!;

  final missing = <String>[];
  for (final key in enKeys.keys) {
    if (!arKeys.containsKey(key)) missing.add(key);
  }
  expect(missing, isEmpty, reason: 'Missing AR keys: ${missing.join(', ')}');
});
```

### .tr in Widget Tests
```dart
testWidgets('.tr resolves in widget context', (tester) async {
  await tester.pumpWidget(
    GetMaterialApp(
      translations: AppTranslations(),
      locale: const Locale('en'),
      fallbackLocale: const Locale('en'),
      home: const SizedBox.shrink(),
    ),
  );
  expect('common.ok'.tr, equals('OK'));
});
```

### Parameter Interpolation
```dart
final result = 'bids.eta_minutes'.trParams({'minutes': '3'});
expect(result, contains('3'));
```

## Route Testing

### Verify Route Exists in Registry
```dart
test('route exists in CustomerPages', () {
  final pages = CustomerPages.pages;
  final route = pages.where((p) => p.name == AppRoutes.customerWallet);
  expect(route, isNotEmpty);
});
```

### Route Constants Validation
```dart
test('AppRoutes.splash is non-empty', () {
  expect(AppRoutes.splash, isNotEmpty);
  expect(AppRoutes.splash, startsWith('/'));
});
```
