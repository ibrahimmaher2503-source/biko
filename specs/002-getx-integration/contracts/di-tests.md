# Test Contract: GetX Dependency Injection

**Test Suite**: `test/core/getx/dependency_injection_test.dart`
**Controller**: `TestServiceController`
**Priority**: P3 (Medium)

---

## Test Coverage Requirements

### 1. Get.put() - Immediate Instantiation

**Test**: `Get.put creates controller immediately`
- **Given**: Controller not yet registered
- **When**: `Get.put(TestServiceController())` is called
- **Then**: Controller is instantiated immediately (verify `instantiationTime` set)

**Test**: `Get.put returns singleton instance`
- **Given**: Controller registered via `Get.put()`
- **When**: `Get.find<TestServiceController>()` called multiple times
- **Then**: Same instance returned each time (verify `instanceId` matches)

**Test**: `Get.put with permanent flag persists`
- **Given**: Controller registered with `permanent: true`
- **When**: `Get.delete<TestServiceController>()` is called
- **Then**: Controller NOT deleted, still accessible via Get.find()

**Test**: `Get.put without permanent flag can be deleted`
- **Given**: Controller registered with `permanent: false`
- **When**: `Get.delete<TestServiceController>()` is called
- **Then**: Controller deleted, subsequent Get.find() throws error

---

### 2. Get.lazyPut() - Lazy Instantiation

**Test**: `Get.lazyPut delays instantiation`
- **Given**: `Get.lazyPut(() => TestServiceController())` called
- **When**: Immediately after registration
- **Then**: Controller NOT yet instantiated (no instance exists)

**Test**: `Get.lazyPut instantiates on first Get.find()`
- **Given**: Controller registered via Get.lazyPut()
- **When**: `Get.find<TestServiceController>()` called for first time
- **Then**: Controller instantiated at that moment (verify `instantiationTime`)

**Test**: `Get.lazyPut returns same instance on subsequent finds`
- **Given**: Controller instantiated via first Get.find()
- **When**: `Get.find<TestServiceController>()` called again
- **Then**: Same instance returned (verify `instanceId` matches)

**Test**: `Get.lazyPut with fenix recreates after delete`
- **Given**: Controller registered with `Get.lazyPut(fenix: true)`
- **When**: Deleted, then accessed again via Get.find()
- **Then**: New instance created (different `instanceId`)

---

### 3. Get.find() - Dependency Resolution

**Test**: `Get.find throws error if not registered`
- **Given**: Controller never registered
- **When**: `Get.find<TestServiceController>()` is called
- **Then**: Throws dependency not found error

**Test**: `Get.find returns correct type`
- **Given**: Multiple controllers registered (A, B, C)
- **When**: `Get.find<TestServiceController>()` is called
- **Then**: Returns TestServiceController (not A, B, or C)

**Test**: `Get.find with tag returns tagged instance`
- **Given**: Two instances with tags: `Get.put(Controller(), tag: 'A')` and `Get.put(Controller(), tag: 'B')`
- **When**: `Get.find<TestServiceController>(tag: 'A')` is called
- **Then**: Returns instance tagged 'A' (not 'B')

---

### 4. Get.delete() - Disposal

**Test**: `Get.delete removes controller`
- **Given**: Non-permanent controller registered
- **When**: `Get.delete<TestServiceController>()` is called
- **Then**: Controller removed, Get.find() throws error

**Test**: `Get.delete triggers onClose lifecycle`
- **Given**: Non-permanent controller registered
- **When**: `Get.delete<TestServiceController>()` is called
- **Then**: `onClose()` is called (verify `_disposed == true`)

**Test**: `Get.delete with tag removes only tagged instance`
- **Given**: Two tagged instances ('A' and 'B')
- **When**: `Get.delete<TestServiceController>(tag: 'A')` is called
- **Then**: Tag 'A' deleted, tag 'B' still accessible

**Test**: `Get.delete on permanent controller does nothing`
- **Given**: Controller registered with `permanent: true`
- **When**: `Get.delete<TestServiceController>()` is called
- **Then**: Controller still accessible, NOT deleted

---

### 5. Get.putAsync() - Async Initialization

**Test**: `Get.putAsync waits for async initialization`
- **Given**: Controller with async constructor: `Get.putAsync(() async { await delay(); return Controller(); })`
- **When**: `Get.find<TestServiceController>()` is called before completion
- **Then**: Get.find() waits until async initialization completes

**Test**: `Get.putAsync completes before returning instance`
- **Given**: Async controller with 1-second delay
- **When**: `await Get.putAsync(...)` completes
- **Then**: Controller is fully initialized (verify initialization flag)

---

### 6. Get.reset() - Clear All Dependencies

**Test**: `Get.reset clears all controllers`
- **Given**: Multiple controllers registered (A, B, C)
- **When**: `Get.reset()` is called
- **Then**: All controllers deleted, subsequent Get.find() throws error

**Test**: `Get.reset disposes non-permanent controllers`
- **Given**: Mix of permanent and non-permanent controllers
- **When**: `Get.reset()` is called
- **Then**: Non-permanent controllers have `onClose()` called

**Test**: `Get.reset clears permanent controllers too`
- **Given**: Permanent controller registered
- **When**: `Get.reset()` is called
- **Then**: Even permanent controllers are cleared (hard reset)

---

### 7. Real-World DI Scenario

**Test**: `FirebaseService singleton accessible globally`
- **Given**: FirebaseService registered at app startup via Get.put()
- **When**: Access from different widgets/controllers via Get.find()
- **Then**: Same FirebaseService instance returned everywhere

**Test**: `AuthController registered as permanent`
- **Given**: AuthController registered with `permanent: true` in AppInitializer
- **When**: Navigate between routes
- **Then**: AuthController persists, maintains authentication state

---

## Expected Test Count

**Total**: 21 tests
- Get.put: 4 tests
- Get.lazyPut: 4 tests
- Get.find: 3 tests
- Get.delete: 4 tests
- Get.putAsync: 2 tests
- Get.reset: 3 tests
- Real-world: 2 tests

---

## Success Criteria

- ✅ All tests pass with zero failures
- ✅ No memory leaks from undisposed controllers
- ✅ All DI strategies (put, lazyPut, putAsync) validated
- ✅ Singleton behavior verified
- ✅ Test execution time < 3 seconds (pure unit tests)

---

## Edge Cases to Test

- **Circular dependencies**: Controller A depends on B, B depends on A
- **Missing dependencies**: Controller constructor requires another controller not registered
- **Duplicate registration**: Register same controller type twice without delete
- **Tagged vs untagged**: Register both tagged and untagged instances of same type
- **Delete during async**: Delete controller while async initialization in progress

---

## Implementation Notes

- **Use Get.reset() in tearDown**: Ensures clean state between tests
- **Test mode**: Use `Get.testMode = true` for unit tests
- **Access tracking**: Use `accessCount` property to verify Get.find() calls
- **Instance ID**: Use `instanceId` to verify singleton vs new instances
