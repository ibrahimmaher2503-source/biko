# Test Contract: GetX Navigation & Routing

**Test Suite**: `test/core/getx/navigation_test.dart`
**Controller**: `TestNavigationController`
**Priority**: P2 (High)

---

## Test Coverage Requirements

### 1. Named Route Navigation

**Test**: `Get.toNamed navigates to correct route`
- **Given**: GetMaterialApp with defined routes
- **When**: `Get.toNamed('/profile')` is called
- **Then**: App navigates to profile route

**Test**: `Get.toNamed passes route arguments`
- **Given**: Navigation to route with arguments
- **When**: `Get.toNamed('/profile', arguments: {'userId': 123})` is called
- **Then**: `Get.arguments` contains `{'userId': 123}` on destination route

**Test**: `Get.toNamed adds route to navigation stack`
- **Given**: App on home route
- **When**: `Get.toNamed('/profile')` is called
- **Then**: Navigation stack size increases by 1

---

### 2. Replace Navigation

**Test**: `Get.offNamed replaces current route`
- **Given**: App on route A, navigation stack size = 2
- **When**: `Get.offNamed('/routeB')` is called
- **Then**: Now on route B, stack size still = 2 (A replaced by B)

**Test**: `Get.offNamed with arguments`
- **Given**: Replacing current route with new route
- **When**: `Get.offNamed('/login', arguments: {'redirect': '/home'})` is called
- **Then**: Arguments accessible on login route

---

### 3. Clear Navigation Stack

**Test**: `Get.offAllNamed clears entire stack`
- **Given**: Navigation stack with 3 routes
- **When**: `Get.offAllNamed('/login')` is called
- **Then**: Stack size = 1 (only login route remains)

**Test**: `Get.offAllNamed with predicate`
- **Given**: Navigation stack with multiple routes
- **When**: `Get.offAllNamed('/home', predicate: (route) => false)` is called
- **Then**: All previous routes removed, only home remains

---

### 4. Back Navigation

**Test**: `Get.back returns to previous route`
- **Given**: Navigation stack: home → profile
- **When**: `Get.back()` is called
- **Then**: Returns to home route

**Test**: `Get.back with result passes data`
- **Given**: Route A navigates to Route B with await
- **When**: Route B calls `Get.back(result: {'status': 'success'})`
- **Then**: Route A receives `{'status': 'success'}`

**Test**: `Get.back on root route does nothing`
- **Given**: App on root route (stack size = 1)
- **When**: `Get.back()` is called
- **Then**: No navigation occurs, still on root

---

### 5. Route Parameters

**Test**: `route parameters accessible via Get.arguments`
- **Given**: Navigation with arguments
- **When**: Destination route accesses `Get.arguments`
- **Then**: Correct arguments object returned

**Test**: `route parameters persist during route lifetime`
- **Given**: Route received arguments
- **When**: Access `Get.arguments` multiple times
- **Then**: Same arguments returned each time

**Test**: `route parameters cleared on new navigation`
- **Given**: Previous route had arguments
- **When**: Navigate to new route without arguments
- **Then**: `Get.arguments` is null

---

### 6. Route Bindings

**Test**: `bindings instantiate controller on route access`
- **Given**: Route with binding class that registers TestController
- **When**: Navigate to route
- **Then**: TestController is automatically instantiated and registered

**Test**: `bindings dispose controller on route exit`
- **Given**: Route with binding and non-permanent controller
- **When**: Navigate away from route
- **Then**: Controller is disposed (onClose called)

---

### 7. Multi-App Entry Points

**Test**: `customer app routes work correctly`
- **Given**: Customer app entry point (main_customer.dart)
- **When**: Navigate using AppRoutes constants
- **Then**: Navigation succeeds, no route not found errors

**Test**: `driver app routes work correctly`
- **Given**: Driver app entry point (main_driver.dart)
- **When**: Navigate using AppRoutes constants
- **Then**: Navigation succeeds, no route not found errors

**Test**: `admin app routes work correctly`
- **Given**: Admin app entry point (main_admin.dart)
- **When**: Navigate using AppRoutes constants
- **Then**: Navigation succeeds, no route not found errors

---

### 8. Route Guards & Middleware

**Test**: `GetMiddleware executes before route access`
- **Given**: Route with middleware that checks authentication
- **When**: Navigate to protected route
- **Then**: Middleware executes, can redirect if needed

**Test**: `GetMiddleware can prevent navigation`
- **Given**: Middleware that returns redirect
- **When**: Attempt to access protected route
- **Then**: Navigation redirects to specified route

---

## Expected Test Count

**Total**: 18 tests
- Named routes: 3 tests
- Replace navigation: 2 tests
- Clear stack: 2 tests
- Back navigation: 3 tests
- Route parameters: 3 tests
- Route bindings: 2 tests
- Multi-app: 3 tests
- Middleware: 2 tests (optional, if implemented)

---

## Success Criteria

- ✅ All tests pass with zero failures
- ✅ No route not found errors
- ✅ Navigation stack managed correctly
- ✅ All three app entry points validated
- ✅ Test execution time < 10 seconds (widget tests are slower)

---

## Edge Cases to Test

- **Rapid navigation**: Multiple Get.toNamed() calls in quick succession
- **Deep linking**: Navigate directly to nested route (if implemented)
- **Invalid routes**: Attempt to navigate to non-existent route
- **Circular navigation**: Route A → B → A → B (verify stack doesn't overflow)
- **Large argument payloads**: Pass large objects as route arguments

---

## Implementation Notes

- **Use GetMaterialApp**: Required for GetX routing to work
- **Define routes**: Use `getPages` parameter with `GetPage` objects
- **Test mode**: May need `Get.testMode = true` for some unit tests
- **Widget tests**: Most navigation tests require full widget tests with `pumpAndSettle()`
