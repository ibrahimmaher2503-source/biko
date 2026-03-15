# Test Contract: GetX Snackbar & Dialogs

**Test Suite**: `test/core/getx/snackbar_test.dart`
**Controller**: `TestSnackbarController`
**Priority**: P5 (Low - Limited Testing Due to Animation Lifecycle)

---

## ⚠️ Testing Limitations

**Known Issue**: GetX snackbars use `AnimationController` which fails in unit tests due to ticker lifecycle management. This is a known limitation documented in existing test: `test/core/widgets/app_snackbar_test.dart`.

**Testing Strategy**:
- ✅ **Unit Tests**: Test color constants, enum values, type mappings (no rendering)
- ❌ **Unit Tests**: Cannot test snackbar rendering, appearance, dismissal
- ✅ **Integration Tests**: Test full snackbar lifecycle with `pumpAndSettle()`

---

## Test Coverage Requirements

### 1. SnackbarType Enum Validation

**Test**: `SnackbarType enum has all expected values`
- **Given**: SnackbarType enum definition
- **When**: Check enum values
- **Then**: Has exactly 4 values: success, error, info, warning

**Test**: `SnackbarType values accessible by name`
- **Given**: SnackbarType enum
- **When**: Access `SnackbarType.success`, etc.
- **Then**: All 4 types accessible without errors

---

### 2. Color Mapping (Unit Tests)

**Test**: `success type maps to green color`
- **Given**: SnackbarType.success
- **When**: Get color for type
- **Then**: Returns green shade (e.g., `Colors.green[600]` or `#4CAF50`)

**Test**: `error type maps to red color`
- **Given**: SnackbarType.error
- **When**: Get color for type
- **Then**: Returns red shade (e.g., `Colors.red[600]` or `#F44336`)

**Test**: `info type maps to blue color`
- **Given**: SnackbarType.info
- **When**: Get color for type
- **Then**: Returns blue shade (e.g., `Colors.blue[600]` or `#2196F3`)

**Test**: `warning type maps to orange color`
- **Given**: SnackbarType.warning
- **When**: Get color for type
- **Then**: Returns orange shade (e.g., `Colors.orange[600]` or `#FF9800`)

---

### 3. AppSnackbar Helper Methods (Limited)

**Test**: `AppSnackbar.success method exists`
- **Given**: AppSnackbar class
- **When**: Check for `success(String message)` method
- **Then**: Method signature exists and is callable

**Test**: `AppSnackbar.error method exists`
- **Given**: AppSnackbar class
- **When**: Check for `error(String message)` method
- **Then**: Method signature exists and is callable

**Test**: `AppSnackbar.info method exists`
- **Given**: AppSnackbar class
- **When**: Check for `info(String message)` method
- **Then**: Method signature exists and is callable

**Test**: `AppSnackbar.warning method exists`
- **Given**: AppSnackbar class
- **When**: Check for `warning(String message)` method
- **Then**: Method signature exists and is callable

---

### 4. Integration Tests (Full Rendering)

**Test**: `snackbar appears after AppSnackbar.success call`
- **Given**: GetMaterialApp with button that calls AppSnackbar.success()
- **When**: Tap button and `pumpAndSettle()`
- **Then**: Snackbar widget appears on screen

**Test**: `snackbar shows correct message text`
- **Given**: Call `AppSnackbar.success('Test Message')`
- **When**: Snackbar renders
- **Then**: Find text 'Test Message' in widget tree

**Test**: `snackbar auto-dismisses after duration`
- **Given**: Snackbar displayed with default duration (3 seconds)
- **When**: Wait for duration and `pumpAndSettle()`
- **Then**: Snackbar no longer visible

**Test**: `snackbar dismisses on tap`
- **Given**: Snackbar displayed with onTap callback
- **When**: Tap on snackbar
- **Then**: Snackbar dismisses and callback executed

**Test**: `multiple snackbars queue correctly`
- **Given**: Two snackbars triggered in quick succession
- **When**: First snackbar appears
- **Then**: Second snackbar waits until first dismisses

---

### 5. No BuildContext Requirement

**Test**: `AppSnackbar.show works without BuildContext`
- **Given**: Controller method calls AppSnackbar.success()
- **When**: Method executes (no context passed)
- **Then**: No BuildContext required error (GetX handles overlay)

---

### 6. Dialog Tests (If Implemented)

**Test**: `Get.dialog shows dialog overlay`
- **Given**: Call `Get.dialog(widget)`
- **When**: Dialog renders
- **Then**: Dialog appears as overlay over app content

**Test**: `Get.back dismisses dialog`
- **Given**: Dialog is open
- **When**: `Get.back()` is called
- **Then**: Dialog dismisses, underlying route remains

---

## Expected Test Count

**Total**: 17 tests
- Enum validation: 2 tests (unit)
- Color mapping: 4 tests (unit)
- Helper methods: 4 tests (unit - existence only)
- Integration tests: 5 tests (full rendering)
- No context: 1 test (unit)
- Dialog: 2 tests (if implemented)

**Note**: Only 11 tests can run in unit test suite. Remaining 5-6 require integration tests.

---

## Success Criteria

- ✅ All unit tests pass (color/enum validation)
- ✅ Integration tests validate full snackbar lifecycle
- ✅ No BuildContext requirement verified
- ⚠️ Limited coverage acceptable due to animation lifecycle limitation
- ✅ Existing pattern from `test/core/widgets/app_snackbar_test.dart` followed

---

## Edge Cases to Test (Integration Only)

- **Rapid snackbar triggers**: Call AppSnackbar.success() 5 times quickly
- **Long messages**: Snackbar with very long text (verify wrapping/truncation)
- **Custom duration**: Snackbar with custom `Duration(seconds: 10)`
- **Snackbar during navigation**: Show snackbar while navigating between routes
- **Multiple snackbar types**: Show success, then error, verify color changes

---

## Implementation Notes

### Unit Tests (Core Tests)

```dart
void main() {
  group('SnackbarType enum', () {
    test('has all expected values', () {
      expect(SnackbarType.values.length, equals(4));
      expect(SnackbarType.values, contains(SnackbarType.success));
      expect(SnackbarType.values, contains(SnackbarType.error));
      expect(SnackbarType.values, contains(SnackbarType.info));
      expect(SnackbarType.values, contains(SnackbarType.warning));
    });
  });

  group('Color mapping', () {
    test('success maps to green', () {
      final color = _getColorForType(SnackbarType.success);
      expect(color, equals(Colors.green[600]));
    });
    // ... other color tests
  });
}
```

### Integration Tests (Separate File)

```dart
// test/integration/snackbar_integration_test.dart
void main() {
  testWidgets('snackbar appears and shows message', (tester) async {
    await tester.pumpWidget(GetMaterialApp(
      home: Builder(builder: (context) {
        return ElevatedButton(
          onPressed: () => AppSnackbar.success('Test'),
          child: Text('Show'),
        );
      }),
    ));

    await tester.tap(find.text('Show'));
    await tester.pumpAndSettle();

    expect(find.text('Test'), findsOneWidget);
  });
}
```

---

## Reference

- **Existing Test**: `test/core/widgets/app_snackbar_test.dart` (5 tests, color/enum only)
- **Known Limitation**: Animation ticker disposal errors in unit tests
- **Workaround**: Separate unit tests (colors) from integration tests (rendering)
