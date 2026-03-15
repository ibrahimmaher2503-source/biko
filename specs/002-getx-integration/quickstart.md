# Quick Start: Running GetX Validation Tests

**Feature**: GetX Ecosystem Validation
**Date**: 2026-02-27
**Purpose**: Guide for running and interpreting GetX integration validation tests

---

## Prerequisites

- Flutter SDK 3.9.2+ installed
- Dart 3.9.2+ installed
- BikeRide project cloned and dependencies installed (`flutter pub get`)
- No Firebase connection required (tests use mock/test mode)

---

## Quick Commands

### Run All GetX Validation Tests

```bash
# From project root
flutter test test/core/getx/
```

**Expected Output**: All tests pass (18-21 tests per suite, ~94 tests total)

---

### Run Individual Test Suites

**State Management Tests** (P1 - Critical):
```bash
flutter test test/core/getx/state_management_test.dart
```
- Tests: 18 tests
- Duration: ~2-3 seconds
- Coverage: Rx variables, controllers, GetBuilder, lifecycle

**Navigation Tests** (P2 - High):
```bash
flutter test test/core/getx/navigation_test.dart
```
- Tests: 18 tests
- Duration: ~8-10 seconds (widget tests, slower)
- Coverage: Named routes, parameters, stack management

**Dependency Injection Tests** (P3 - Medium):
```bash
flutter test test/core/getx/dependency_injection_test.dart
```
- Tests: 21 tests
- Duration: ~2-3 seconds
- Coverage: Get.put, Get.lazyPut, Get.find, Get.delete

**Localization Tests** (P4 - Medium-Low):
```bash
flutter test test/core/getx/localization_test.dart
```
- Tests: 20 tests
- Duration: ~5-7 seconds (mix of unit and widget tests)
- Coverage: Translation lookup, locale switching, RTL/LTR

**Snackbar Tests** (P5 - Low):
```bash
flutter test test/core/getx/snackbar_test.dart
```
- Tests: 11 tests (unit tests only, limited by animation lifecycle)
- Duration: ~1-2 seconds
- Coverage: Color mapping, enum validation

---

### Run Integration Tests

**Full multi-app integration tests** (validates all 3 entry points):
```bash
flutter test test/integration/
```

Tests include:
- Customer app initialization
- Driver app initialization
- Admin app initialization
- Full navigation flows
- Snackbar rendering (full lifecycle)

---

## Test Output Interpretation

### ✅ Success Output

```text
00:02 +18: All tests passed!
```

**What this means**:
- All 18 tests in the suite passed
- No memory leaks detected
- All GetX features validated
- Ready for production use

---

### ❌ Failure Output

```text
00:03 +15 -1: test/core/getx/state_management_test.dart: reactive int triggers observer updates [E]
  Expected: <1>
  Actual: <0>
```

**What this means**:
- 15 tests passed, 1 test failed
- The failing test: "reactive int triggers observer updates"
- Expected 1 observer update, but got 0
- **Likely cause**: Rx variable not triggering observer (GetX integration issue)

**How to debug**:
1. Check if `Get.testMode = true` is set in test setup
2. Verify observer is properly attached before value change
3. Run test with `--verbose` flag for more details

---

### ⚠️ Warning Output

```text
Warning: Using deprecated Get.to() method. Use Get.toNamed() instead.
```

**What this means**:
- Tests may pass, but code uses deprecated GetX APIs
- Update code to use current GetX best practices

---

## Code Coverage

### Generate Coverage Report

```bash
# Run tests with coverage
flutter test --coverage

# Generate HTML report (requires lcov)
genhtml coverage/lcov.info -o coverage/html

# Open report in browser
open coverage/html/index.html  # macOS
start coverage/html/index.html # Windows
xdg-open coverage/html/index.html # Linux
```

### Coverage Goals

| Category | Target | Status |
|----------|--------|--------|
| State Management | >95% | TBD |
| Navigation | >90% | TBD |
| Dependency Injection | >95% | TBD |
| Localization | >90% | TBD |
| Snackbar | >60% | TBD (limited) |
| **Overall GetX** | >90% | TBD |

---

## Performance Profiling

### Check for Memory Leaks

**Using Flutter DevTools**:

1. Start app in debug mode:
   ```bash
   flutter run -t lib/main_customer.dart
   ```

2. Open DevTools:
   ```bash
   flutter pub global activate devtools
   flutter pub global run devtools
   ```

3. Navigate through app (trigger controller lifecycle)

4. In DevTools:
   - Go to **Memory** tab
   - Click **"Take Snapshot"**
   - Look for leaked GetX controllers (should be 0 after disposal)

**Expected Result**: No GetX controllers in memory after `Get.delete()` or route exit

---

### Check Frame Rate

**Using Flutter DevTools**:

1. Run app in profile mode:
   ```bash
   flutter run --profile -t lib/main_customer.dart
   ```

2. In DevTools, go to **Performance** tab

3. Perform state updates (increment counter, change Rx values)

4. Check frame rate: Should stay at 60 fps (16ms per frame)

**Expected Result**: No frame drops during GetX state updates

---

## Troubleshooting

### Issue: "Get.find() throws dependency not found"

**Symptoms**:
```text
Error: Instance of 'TestController' not found.
```

**Solutions**:
1. Ensure controller registered with `Get.put()` before accessing
2. Check if `Get.reset()` was called (clears all dependencies)
3. Verify controller type matches (use `Get.find<TestController>()`, not `Get.find<BaseController>()`)

---

### Issue: "Tests fail with ticker disposal errors"

**Symptoms**:
```text
Error: The following assertion was thrown:
A ticker was disposed while still active.
```

**Solutions**:
1. For GetX snackbars: Use color/enum tests only (unit tests), use integration tests for rendering
2. For GetX animations: Ensure `Get.testMode = true` is set
3. For controllers with timers: Override `onClose()` to cancel timers

**Reference**: See `test/core/widgets/app_snackbar_test.dart` for workaround pattern

---

### Issue: "Navigation tests fail with 'context not found'"

**Symptoms**:
```text
Error: No MaterialLocalizations found.
```

**Solutions**:
1. Wrap test widget with `GetMaterialApp` (not `MaterialApp`)
2. Ensure `await tester.pumpAndSettle()` after navigation
3. Use `Get.testMode = true` for unit tests, full widget tests for integration

---

### Issue: "Locale not switching in tests"

**Symptoms**:
```text
Expected: Locale('ar')
Actual: Locale('en')
```

**Solutions**:
1. Use `GetMaterialApp` with `translations: AppTranslations()`
2. Call `Get.updateLocale()` and then `await tester.pump()` to rebuild
3. Verify `AppTranslations` class implements `Translations` from GetX

---

## Continuous Integration (CI)

### GitHub Actions Example

```yaml
name: GetX Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.9.2'

      - name: Install dependencies
        run: flutter pub get

      - name: Run GetX validation tests
        run: flutter test test/core/getx/

      - name: Run integration tests
        run: flutter test test/integration/

      - name: Generate coverage
        run: flutter test --coverage

      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          files: coverage/lcov.info
```

---

## Next Steps

### After All Tests Pass

1. ✅ **Validate multi-app**: Run integration tests for customer, driver, admin apps
2. ✅ **Profile performance**: Use DevTools to check memory and frame rate
3. ✅ **Review coverage**: Ensure >90% coverage for GetX code paths
4. ✅ **Run flutter analyze**: Check for any GetX-related warnings
5. ✅ **Document findings**: Update project README with GetX validation results

### If Tests Fail

1. ❌ **Review error messages**: Identify which GetX feature is broken
2. ❌ **Check GetX version**: Verify `pubspec.yaml` has `get: ^4.6.5`
3. ❌ **Review production code**: Check for GetX anti-patterns or misuse
4. ❌ **Fix issues**: Update production code to match GetX best practices
5. ❌ **Re-run tests**: Verify fixes resolve failures

---

## Additional Resources

- **GetX Documentation**: https://pub.dev/packages/get
- **Flutter Testing Guide**: https://flutter.dev/docs/testing
- **BikeRide README**: `README.md` (GetX usage patterns)
- **Test Contracts**: `specs/002-getx-integration/contracts/` (detailed test specifications)
- **Research Document**: `specs/002-getx-integration/research.md` (GetX testing patterns)

---

## Summary

| Command | Purpose | Duration |
|---------|---------|----------|
| `flutter test test/core/getx/` | Run all GetX tests | ~20-25 sec |
| `flutter test test/integration/` | Run integration tests | ~30-40 sec |
| `flutter test --coverage` | Generate coverage report | ~30-35 sec |
| `flutter analyze` | Check code quality | ~5-10 sec |

**Total validation time**: ~60-90 seconds for complete GetX ecosystem validation

---

**Ready to implement?** Run `/speckit.tasks` to generate actionable task breakdown.
