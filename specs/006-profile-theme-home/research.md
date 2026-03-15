# Research: Profile Auto-Fill, Theme Chooser, Debug Logging & Home Page

**Feature**: `006-profile-theme-home`
**Date**: 2026-03-01

## R-001: How to access Google user data after sign-in

**Decision**: Use `FirebaseAuth.instance.currentUser` which exposes `displayName` and `photoURL` from the Google provider after sign-in.

**Rationale**: After `signInWithCredential()` completes, the Firebase `User` object automatically populates `displayName` and `photoURL` from the Google account. No need to keep a reference to the `GoogleSignIn` object — Firebase Auth already stores this.

**Alternatives considered**:
- Keep `GoogleSignInAccount` reference from sign-in flow — rejected because it requires passing data between controllers and Firebase Auth already has the data.
- Query Google People API separately — rejected as unnecessary complexity.

**Implementation**: In `ProfileSetupController.onInit()`, check `AuthService.currentUser?.displayName` and `AuthService.currentUser?.photoURL`.

---

## R-002: Theme persistence strategy

**Decision**: Dual persistence — SharedPreferences for immediate app-start theme, Firestore `theme` field on user document for cross-device sync.

**Rationale**: SharedPreferences loads synchronously before Firestore is available, preventing a "theme flash" on app start. Firestore provides cross-device consistency for returning users on new devices.

**Alternatives considered**:
- SharedPreferences only — rejected because theme wouldn't follow user to new device.
- Firestore only — rejected because Firestore requires async load, causing theme flash on startup.

**Implementation**:
1. On theme change: save to SharedPreferences immediately
2. On profile complete: persist to Firestore `theme` field
3. On app start: read from SharedPreferences in `AppInitializer` before `runApp()`

---

## R-003: GetX theme switching API

**Decision**: Use `Get.changeThemeMode(ThemeMode.dark | ThemeMode.light)` for immediate switching.

**Rationale**: GetX provides built-in theme mode switching that works with `GetMaterialApp`'s `themeMode` parameter. This is the idiomatic GetX approach.

**Alternatives considered**:
- Manual reactive Rx variable + `Obx` wrapper on `GetMaterialApp` — rejected as more complex than built-in API.
- `MediaQuery` override — rejected as not applicable (user preference, not system).

**Implementation**: `Get.changeThemeMode()` triggers immediate rebuild with the new theme. Persist the value and restore on next app launch.

---

## R-004: Debug snackbar logging approach

**Decision**: Create a centralized `AppSnackbar.show()` helper method that wraps `Get.snackbar()` and adds `debugPrint()` in debug mode using `kDebugMode`.

**Rationale**: A single entry point for all snackbars ensures consistent logging without modifying every call site. Using `kDebugMode` from `foundation.dart` is tree-shaken in release builds.

**Alternatives considered**:
- Override GetX's `SnackbarController` — rejected as fragile and version-dependent.
- Add `debugPrint()` at every `Get.snackbar()` call site — rejected as repetitive and easy to miss.
- Use `assert()` instead of `kDebugMode` — rejected because `assert` doesn't allow side effects reliably across all platforms.

**Implementation**: Replace all `Get.snackbar()` calls with `AppSnackbar.show()`. The helper prints `[Snackbar] title: message` to console in debug mode.

---

## R-005: Home page architecture

**Decision**: Create `lib/features/home/` with `HomeController`, `HomeBinding`, and `CustomerHomeScreen`. The controller fetches user data from Firestore, manages selected service type. The screen shows a greeting header, map placeholder (Container with map icon), and a service type toggle.

**Rationale**: Follows existing feature-first folder structure. Binding pattern matches existing onboarding/auth patterns. Map placeholder avoids Google Maps dependency until the trip feature is implemented.

**Alternatives considered**:
- Embed Google Maps immediately — rejected because map feature is in a later spec, and it adds configuration/API key complexity for a placeholder screen.
- Single file without controller — rejected as inconsistent with project architecture.

**Implementation**: `HomeController` registered via `HomeBinding` with `Get.lazyPut()` per CLAUDE.md rules.

---

## R-006: Theme selector UI pattern

**Decision**: Reuse the same pill-style toggle pattern as the existing language selector in `ProfileSetupScreen`. Two options: Light (sun icon) and Dark (moon icon), matching the visual style of the language toggle.

**Rationale**: Visual consistency with existing UI. The language selector pattern is proven in the codebase and works well for binary choices.

**Alternatives considered**:
- Dropdown menu — rejected as overkill for two options.
- Switch/toggle — rejected for visual inconsistency with the language selector.
- Three options (Light/Dark/System) — rejected for simplicity; system follow can be added later.

---

## R-007: Where to store theme mode value

**Decision**: Store as string `'light'` or `'dark'` in SharedPreferences key `'theme_mode'` and in Firestore user document field `theme`.

**Rationale**: String values are readable and easily mapped to `ThemeMode` enum. SharedPreferences for fast local access, Firestore for persistence across devices.

**Alternatives considered**:
- Integer values (0/1) — rejected for poor readability.
- Boolean `isDark` — rejected because it doesn't extend well if System mode is added later.

---

## R-008: Customer home page content scope

**Decision**: Minimal MVP home page with:
1. Greeting header ("Welcome, {name}" with avatar)
2. Map placeholder (gray container with map icon + "Your map will appear here" text)
3. Service type selector (Ride / Delivery toggle)

No real map, no trip creation, no wallet widget. These belong to future features.

**Rationale**: The spec asks to "start development" of the home page. A clean foundation screen is enough to demonstrate the flow and provide a landing point for authenticated users.

**Alternatives considered**:
- Full-featured home with map and search — rejected as out of scope for this feature.
- Completely empty screen with just text — rejected as insufficient to demonstrate functionality.
