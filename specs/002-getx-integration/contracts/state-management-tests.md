# Test Contract: GetX State Management

**Test Suite**: `test/core/getx/state_management_test.dart`
**Controller**: `TestCounterController`
**Priority**: P1 (Critical)

---

## Test Coverage Requirements

### 1. Reactive Variables (Rx Types)

**Test**: `reactive int triggers observer updates`
- **Given**: A controller with `RxInt count = 0.obs`
- **When**: `count.value++` is called
- **Then**: Observer callback is triggered with new value

**Test**: `reactive string triggers observer updates`
- **Given**: A controller with `RxString message = ''.obs`
- **When**: `message.value = 'Hello'` is called
- **Then**: Observer callback receives 'Hello'

**Test**: `reactive list triggers observer updates on add`
- **Given**: A controller with `RxList items = [].obs`
- **When**: `items.add('item1')` is called
- **Then**: Observer callback is triggered

**Test**: `reactive map triggers observer updates on key change`
- **Given**: A controller with `RxMap config = {}.obs`
- **When**: `config['key'] = 'value'` is called
- **Then**: Observer callback is triggered

**Test**: `reactive bool toggles correctly`
- **Given**: A controller with `RxBool isLoading = false.obs`
- **When**: `isLoading.value = !isLoading.value` is called
- **Then**: Value changes from false to true

---

### 2. Observer Patterns

**Test**: `multiple observers receive updates`
- **Given**: A controller with `RxInt` and 2 listeners attached
- **When**: Value changes
- **Then**: Both listeners receive update

**Test**: `observer updates reflect correct new value`
- **Given**: A controller with `RxInt count = 0.obs`
- **When**: `count.value = 42` is called
- **Then**: Observer receives exactly 42 (not old value)

---

### 3. GetBuilder Pattern

**Test**: `GetBuilder updates only when update() called`
- **Given**: A controller with non-reactive `int normalCounter`
- **When**: `normalCounter++` without calling `update()`
- **Then**: GetBuilder does NOT rebuild

**Test**: `GetBuilder rebuilds after update() call`
- **Given**: A controller with non-reactive `int normalCounter`
- **When**: `normalCounter++` followed by `update()`
- **Then**: GetBuilder widget rebuilds with new value

**Test**: `GetBuilder with ID updates selectively`
- **Given**: A controller with `update(['counter1'])`
- **When**: Update is called with specific ID
- **Then**: Only GetBuilder with matching ID rebuilds

---

### 4. Controller Lifecycle

**Test**: `onInit executes before controller usage`
- **Given**: A new controller is created via Get.put()
- **When**: Controller is registered
- **Then**: `onInit()` has been called (verify `_initialized == true`)

**Test**: `onReady executes after onInit`
- **Given**: A new controller is registered
- **When**: Controller initialization completes
- **Then**: `onReady()` is called after `onInit()` (verify `_ready == true`)

**Test**: `onClose executes on disposal`
- **Given**: A non-permanent controller is registered
- **When**: `Get.delete<TestCounterController>()` is called
- **Then**: `onClose()` is called (verify `_disposed == true`)

**Test**: `lifecycle hooks execute in correct order`
- **Given**: A new controller lifecycle
- **When**: Register → Use → Dispose
- **Then**: Order is: onInit → onReady → onClose

---

### 5. Permanent vs Non-Permanent Controllers

**Test**: `permanent controller survives Get.delete()`
- **Given**: Controller registered with `permanent: true`
- **When**: `Get.delete<TestCounterController>()` is called
- **Then**: Controller still accessible via `Get.find()`

**Test**: `non-permanent controller is deleted`
- **Given**: Controller registered with `permanent: false`
- **When**: `Get.delete<TestCounterController>()` is called
- **Then**: Subsequent `Get.find()` throws error

**Test**: `permanent controller persists across route changes`
- **Given**: Permanent controller registered at app startup
- **When**: Navigate between multiple routes
- **Then**: Same controller instance accessible on all routes

---

### 6. Singleton Behavior

**Test**: `Get.find() returns same instance`
- **Given**: Controller registered via `Get.put()`
- **When**: `Get.find()` called multiple times
- **Then**: Same instance returned (verify reference equality)

**Test**: `state persists across Get.find() calls`
- **Given**: Controller with `count.value = 5`
- **When**: Access via `Get.find()` from different context
- **Then**: `count.value` still equals 5

---

## Expected Test Count

**Total**: 18 tests
- Reactive variables: 5 tests
- Observer patterns: 2 tests
- GetBuilder: 3 tests
- Lifecycle: 4 tests
- Permanent/Non-permanent: 3 tests
- Singleton: 2 tests

---

## Success Criteria

- ✅ All tests pass with zero failures
- ✅ No memory leaks (verified with DevTools)
- ✅ Test execution time < 5 seconds
- ✅ Code coverage for state management paths > 95%

---

## Edge Cases to Test

- **Rapid state changes**: Verify observer handles multiple quick updates
- **Null values**: Test Rx<dynamic> with null values
- **Empty collections**: Test RxList and RxMap when empty
- **Controller reuse**: Verify Get.put() with same controller type after Get.delete()
