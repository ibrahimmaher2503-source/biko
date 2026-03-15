# Data Model: Test Controllers for GetX Validation

**Feature**: GetX Ecosystem Validation
**Date**: 2026-02-27
**Purpose**: Define test controller models used to validate GetX state management, routing, DI, and localization

---

## Overview

This document defines test-only controller classes used to validate GetX ecosystem integration. These controllers are **not** for production use - they exist solely to exercise GetX features in test scenarios.

---

## 1. TestCounterController (State Management)

**Purpose**: Validate reactive state management with Rx variables, Obx observers, and GetBuilder updates.

### Properties

| Property | Type | Initial Value | Description |
|----------|------|---------------|-------------|
| `count` | `RxInt` | `0` | Reactive integer for Obx tests |
| `message` | `RxString` | `''` | Reactive string for observer tests |
| `items` | `RxList<String>` | `[]` | Reactive list for collection tests |
| `config` | `RxMap<String, dynamic>` | `{}` | Reactive map for complex state |
| `isLoading` | `RxBool` | `false` | Reactive boolean for UI state |
| `normalCounter` | `int` | `0` | Non-reactive for GetBuilder comparison |

### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `increment()` | `void` | Increments `count.value++` |
| `decrement()` | `void` | Decrements `count.value--` |
| `setMessage(String msg)` | `void` | Sets `message.value = msg` |
| `addItem(String item)` | `void` | Appends to `items` list |
| `updateConfig(String key, dynamic value)` | `void` | Updates `config` map |
| `toggleLoading()` | `void` | Flips `isLoading.value` |
| `incrementNormal()` | `void` | Increments `normalCounter++` and calls `update()` |
| `reset()` | `void` | Resets all values to initial state |

### Lifecycle Hooks

| Hook | Purpose |
|------|---------|
| `onInit()` | Track initialization (set flag `_initialized = true`) |
| `onReady()` | Track ready state (set flag `_ready = true`) |
| `onClose()` | Track disposal (set flag `_disposed = true`) |

### Test Scenarios

- ✅ Rx variable changes trigger observer updates
- ✅ Multiple observers receive updates simultaneously
- ✅ RxList and RxMap changes trigger updates
- ✅ GetBuilder updates only when `update()` called
- ✅ Lifecycle hooks execute in correct order (onInit → onReady → onClose)

### Example Implementation

```dart
class TestCounterController extends GetxController {
  // Reactive variables
  final count = 0.obs;
  final message = ''.obs;
  final items = <String>[].obs;
  final config = <String, dynamic>{}.obs;
  final isLoading = false.obs;

  // Non-reactive for GetBuilder
  int normalCounter = 0;

  // Lifecycle flags (for testing)
  bool _initialized = false;
  bool _ready = false;
  bool _disposed = false;

  bool get initialized => _initialized;
  bool get ready => _ready;
  bool get disposed => _disposed;

  @override
  void onInit() {
    super.onInit();
    _initialized = true;
  }

  @override
  void onReady() {
    super.onReady();
    _ready = true;
  }

  @override
  void onClose() {
    _disposed = true;
    super.onClose();
  }

  void increment() => count.value++;
  void decrement() => count.value--;
  void setMessage(String msg) => message.value = msg;
  void addItem(String item) => items.add(item);
  void updateConfig(String key, dynamic value) => config[key] = value;
  void toggleLoading() => isLoading.value = !isLoading.value;

  void incrementNormal() {
    normalCounter++;
    update(); // Trigger GetBuilder rebuild
  }

  void reset() {
    count.value = 0;
    message.value = '';
    items.clear();
    config.clear();
    isLoading.value = false;
    normalCounter = 0;
  }
}
```

---

## 2. TestNavigationController (Routing)

**Purpose**: Validate GetX navigation methods, route parameters, and navigation stack management.

### Properties

| Property | Type | Initial Value | Description |
|----------|------|---------------|-------------|
| `currentRoute` | `RxString` | `'/'` | Tracks current route name |
| `navigationHistory` | `RxList<String>` | `[]` | History of visited routes |
| `lastArguments` | `Rx<dynamic>` | `null` | Last received route arguments |

### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `navigateTo(String route, {dynamic args})` | `Future<void>` | Calls `Get.toNamed(route, arguments: args)` |
| `navigateOff(String route)` | `Future<void>` | Calls `Get.offNamed(route)` (replaces current) |
| `navigateOffAll(String route)` | `Future<void>` | Calls `Get.offAllNamed(route)` (clears stack) |
| `goBack({dynamic result})` | `void` | Calls `Get.back(result: result)` |
| `recordRoute(String route)` | `void` | Adds route to `navigationHistory` |
| `clearHistory()` | `void` | Clears `navigationHistory` |

### Test Scenarios

- ✅ `Get.toNamed()` navigates to correct route
- ✅ Route arguments accessible via `Get.arguments`
- ✅ `Get.offNamed()` replaces current route (stack size unchanged)
- ✅ `Get.offAllNamed()` clears entire stack
- ✅ `Get.back()` returns to previous route
- ✅ `Get.back(result: data)` passes result to previous route

### Example Implementation

```dart
class TestNavigationController extends GetxController {
  final currentRoute = '/'.obs;
  final navigationHistory = <String>[].obs;
  final lastArguments = Rx<dynamic>(null);

  Future<void> navigateTo(String route, {dynamic args}) async {
    await Get.toNamed(route, arguments: args);
    recordRoute(route);
    currentRoute.value = route;
    lastArguments.value = args;
  }

  Future<void> navigateOff(String route) async {
    await Get.offNamed(route);
    recordRoute(route);
    currentRoute.value = route;
  }

  Future<void> navigateOffAll(String route) async {
    await Get.offAllNamed(route);
    navigationHistory.clear();
    recordRoute(route);
    currentRoute.value = route;
  }

  void goBack({dynamic result}) {
    Get.back(result: result);
    if (navigationHistory.isNotEmpty) {
      currentRoute.value = navigationHistory.last;
    }
  }

  void recordRoute(String route) {
    navigationHistory.add(route);
  }

  void clearHistory() {
    navigationHistory.clear();
  }
}
```

---

## 3. TestServiceController (Dependency Injection)

**Purpose**: Validate GetX dependency injection strategies (Get.put, Get.lazyPut, Get.find, Get.delete).

### Properties

| Property | Type | Initial Value | Description |
|----------|------|---------------|-------------|
| `instanceId` | `String` | `UUID` | Unique ID to verify singleton behavior |
| `instantiationTime` | `DateTime` | `DateTime.now()` | Timestamp of instantiation |
| `accessCount` | `RxInt` | `0` | Tracks how many times instance accessed |

### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `access()` | `void` | Increments `accessCount` (to track Get.find() calls) |
| `doWork()` | `String` | Returns "Work done by $instanceId" |

### Lifecycle Hooks

| Hook | Purpose |
|------|---------|
| `onClose()` | Track disposal (set `_disposed = true`) |

### Test Scenarios

- ✅ `Get.put()` creates immediate singleton instance
- ✅ `Get.find()` returns same instance (verify `instanceId` matches)
- ✅ `Get.lazyPut()` delays instantiation until first `Get.find()`
- ✅ `Get.putAsync()` completes async initialization before `Get.find()` returns
- ✅ Tagged instances (`Get.put(tag: 'A')`) are distinct
- ✅ `permanent: true` prevents disposal, `permanent: false` allows deletion
- ✅ `Get.delete()` triggers `onClose()` for non-permanent instances

### Example Implementation

```dart
class TestServiceController extends GetxController {
  final String instanceId = Uuid().v4();
  final DateTime instantiationTime = DateTime.now();
  final accessCount = 0.obs;
  bool _disposed = false;

  bool get disposed => _disposed;

  @override
  void onClose() {
    _disposed = true;
    super.onClose();
  }

  void access() {
    accessCount.value++;
  }

  String doWork() {
    return 'Work done by $instanceId';
  }
}
```

---

## 4. TestLocalizationController (Translations)

**Purpose**: Validate GetX localization, translation lookup, locale switching, and RTL/LTR behavior.

### Properties

| Property | Type | Initial Value | Description |
|----------|------|---------------|-------------|
| `currentLocale` | `Rx<Locale>` | `Get.locale` | Tracks current app locale |
| `isRTL` | `RxBool` | `false` | Tracks if current locale is RTL |

### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `switchToArabic()` | `void` | Calls `Get.updateLocale(Locale('ar'))` |
| `switchToEnglish()` | `void` | Calls `Get.updateLocale(Locale('en'))` |
| `getTranslation(String key)` | `String` | Returns `key.tr` (GetX translation lookup) |
| `updateRTLStatus(BuildContext context)` | `void` | Checks `Directionality.of(context)` and updates `isRTL` |

### Test Scenarios

- ✅ `'key'.tr` returns correct translation for current locale
- ✅ `Get.updateLocale()` switches translations immediately
- ✅ Arabic locale sets `Directionality.of(context) == TextDirection.rtl`
- ✅ English locale sets `Directionality.of(context) == TextDirection.ltr`
- ✅ Missing translation keys return the key string (fallback behavior)
- ✅ Translation parameters via `'key'.trParams({'name': 'John'})` work correctly

### Example Implementation

```dart
class TestLocalizationController extends GetxController {
  final currentLocale = Rx<Locale>(Get.locale ?? Locale('en'));
  final isRTL = false.obs;

  void switchToArabic() {
    Get.updateLocale(Locale('ar'));
    currentLocale.value = Locale('ar');
    isRTL.value = true;
  }

  void switchToEnglish() {
    Get.updateLocale(Locale('en'));
    currentLocale.value = Locale('en');
    isRTL.value = false;
  }

  String getTranslation(String key) {
    return key.tr;
  }

  void updateRTLStatus(BuildContext context) {
    isRTL.value = Directionality.of(context) == TextDirection.rtl;
  }
}
```

---

## 5. TestSnackbarController (UI Feedback)

**Purpose**: Validate GetX snackbar functionality (limited to color/enum tests due to animation lifecycle).

### Properties

| Property | Type | Initial Value | Description |
|----------|------|---------------|-------------|
| `lastSnackbarType` | `Rx<SnackbarType?>` | `null` | Tracks last shown snackbar type |
| `snackbarHistory` | `RxList<SnackbarType>` | `[]` | History of shown snackbars |

### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `showSuccess(String msg)` | `void` | Calls `AppSnackbar.success(msg)` and records type |
| `showError(String msg)` | `void` | Calls `AppSnackbar.error(msg)` and records type |
| `showInfo(String msg)` | `void` | Calls `AppSnackbar.info(msg)` and records type |
| `showWarning(String msg)` | `void` | Calls `AppSnackbar.warning(msg)` and records type |
| `clearHistory()` | `void` | Clears `snackbarHistory` |

### Test Scenarios (Limited)

- ✅ `SnackbarType` enum has all 4 values (success, error, info, warning)
- ✅ Color mapping: success→green, error→red, info→blue, warning→orange
- ❌ Snackbar rendering (animation lifecycle limitation)
- ❌ Snackbar interaction (requires integration tests)

### Example Implementation

```dart
class TestSnackbarController extends GetxController {
  final lastSnackbarType = Rx<SnackbarType?>(null);
  final snackbarHistory = <SnackbarType>[].obs;

  void showSuccess(String msg) {
    AppSnackbar.success(msg);
    _recordSnackbar(SnackbarType.success);
  }

  void showError(String msg) {
    AppSnackbar.error(msg);
    _recordSnackbar(SnackbarType.error);
  }

  void showInfo(String msg) {
    AppSnackbar.info(msg);
    _recordSnackbar(SnackbarType.info);
  }

  void showWarning(String msg) {
    AppSnackbar.warning(msg);
    _recordSnackbar(SnackbarType.warning);
  }

  void _recordSnackbar(SnackbarType type) {
    lastSnackbarType.value = type;
    snackbarHistory.add(type);
  }

  void clearHistory() {
    snackbarHistory.clear();
    lastSnackbarType.value = null;
  }
}
```

---

## Entity Relationships

```text
┌─────────────────────────┐
│ TestCounterController   │ (State Management)
│ - Rx variables          │
│ - GetBuilder state      │
│ - Lifecycle hooks       │
└─────────────────────────┘

┌─────────────────────────┐
│ TestNavigationController│ (Routing)
│ - Route history         │
│ - Navigation methods    │
│ - Arguments tracking    │
└─────────────────────────┘

┌─────────────────────────┐
│ TestServiceController   │ (Dependency Injection)
│ - Instance ID           │
│ - Access tracking       │
│ - Disposal detection    │
└─────────────────────────┘

┌─────────────────────────┐
│ TestLocalizationController│ (Translations)
│ - Locale switching      │
│ - RTL/LTR detection     │
│ - Translation lookup    │
└─────────────────────────┘

┌─────────────────────────┐
│ TestSnackbarController  │ (UI Feedback)
│ - Snackbar types        │
│ - History tracking      │
│ - (Limited testing)     │
└─────────────────────────┘
```

**No direct relationships** - Each controller tests a specific GetX feature in isolation.

---

## Storage & Persistence

**None** - All test controllers are in-memory only. No database, SharedPreferences, or file I/O.

---

## Validation Rules

All test controllers must:
1. ✅ Extend `GetxController` base class
2. ✅ Implement lifecycle hooks (`onInit`, `onReady`, `onClose`) with tracking
3. ✅ Use `Get.reset()` in test tearDown to prevent test pollution
4. ✅ Be disposable without side effects (no static state)
5. ✅ Have unique instance IDs to verify singleton behavior

---

**Next**: Proceed to [contracts/](./contracts/) for test specifications.
