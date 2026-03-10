# GetX Architecture Rules

## State Management
- Use GetX exclusively. Never Provider, Bloc, or Riverpod.
- Reactive state: `.obs` properties + `Obx()` in widgets.
- Never use `GetBuilder` unless there's a specific performance reason.

## Dependency Injection
- Feature controllers: always `Get.lazyPut()` inside a `Binding` class.
- Never use `Get.put()` for feature controllers.
- Only `AuthController` and `LocationService` are registered globally (permanent) in `AppInitializer`.
- Always create a binding class for each feature screen.

## Navigation
- Use `Get.toNamed()` / `Get.offAllNamed()` with constants from `AppRoutes`.
- Never hardcode route strings — always reference `AppRoutes.routeName`.
- Pass data between screens via `Get.arguments` or `Get.parameters`.

## Controller Lifecycle
- Controllers are disposed automatically when their route is popped.
- Use `onInit()` for initialization, `onReady()` for post-frame logic, `onClose()` for cleanup.
- Cancel streams and timers in `onClose()`.

## Route Registration
- Customer routes: `lib/core/routes/customer_pages.dart`
- Driver routes: `lib/core/routes/driver_pages.dart`
- Admin routes: `lib/core/routes/admin_pages.dart`
- Route constants: `lib/core/routes/app_routes.dart`
- Admin pages use `AdminAuthGuard` middleware and wrap content in `AdminLayoutShell`.
