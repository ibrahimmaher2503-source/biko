# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

BikeRide (package name: `biko`) is an inDrive-style bike ride and delivery platform for Egypt with price-bidding. Three apps share one codebase: Customer, Driver, and Admin Web Panel. No traditional backend — all server logic runs on Firebase Cloud Functions.

## Build & Run Commands

```bash
# Run each app (separate entry points)
flutter run -t lib/main_customer.dart          # Customer app
flutter run -t lib/main_driver.dart            # Driver app
flutter run -d chrome -t lib/main_admin.dart   # Admin web panel

# Default entry point (main.dart) currently launches Admin app
flutter run

# Build admin panel for cPanel deployment
flutter build web --release --base-href /admin/

# Analyze & lint
flutter analyze

# Run all tests
flutter test

# Run a single test file
flutter test test/core/widgets/app_button_test.dart

# Get dependencies
flutter pub get

# Deploy Firestore indexes after adding new queries
firebase deploy --only firestore:indexes
```

**SDK**: Dart ^3.9.2, Flutter, uses Material 3.

## Architecture

### Multi-App Entry Points

Each app has its own entry point, page registry, and initial route:
- `lib/main_customer.dart` → `CustomerPages.pages` → starts at `/splash`
- `lib/main_driver.dart` → `DriverPages.pages` → starts at `/splash`
- `lib/main_admin.dart` → `AdminPages.pages` → starts at `/admin/login`

All three share `AppInitializer.init()` which handles: Flutter bindings → Firebase init → local notifications → theme restoration → global controller registration (`AuthController`, `LocationService`) → `runApp()`.

### State Management: GetX Only

- **Always** use GetX for state, navigation, DI. Never Provider/Bloc/Riverpod.
- Feature controllers use `Get.lazyPut()` inside bindings — never `Get.put()` for feature controllers.
- Only `AuthController` and `LocationService` are registered globally (permanent) in `AppInitializer`.
- Navigation uses `Get.toNamed()` / `Get.offAllNamed()` with route constants from `AppRoutes`.
- Reactive state uses `.obs` / `Obx()`.

### Feature-First Folder Structure

```
lib/core/          — Shared: theme, routes, services, widgets, models, translations, constants
lib/features/      — Feature modules, each with screens/, controllers/, bindings/, widgets/
```

- Features must NOT import from other features' internal files.
- Cross-feature communication goes through `core/` services or GetX route arguments.

### Route Registration Pattern

Each app has its own page registry file:
- `lib/core/routes/app_routes.dart` — All route name constants (shared)
- `lib/core/routes/customer_pages.dart` — Customer GetPage list
- `lib/core/routes/driver_pages.dart` — Driver GetPage list
- `lib/core/routes/admin_pages.dart` — Admin GetPage list with `AdminAuthGuard` middleware and `AdminLayoutShell` wrapping

Admin pages wrap content in `AdminLayoutShell` for sidebar navigation. All admin routes (except login and 404) use `AdminAuthGuard` middleware.

### Theme System

- `AppTheme.lightTheme` / `AppTheme.darkTheme` — Material 3 themes
- `AppColorsExtension` — semantic color tokens (`surfaceElevated`, `surfaceContainer`, `border`, `borderSubtle`, `textMuted`, `info`, `success`, `warning` + backgrounds)
- Access: `Theme.of(context).extension<AppColorsExtension>()!`
- Fonts: Plus Jakarta Sans (English), Cairo (Arabic) via `AppTheme.getThemeWithLocale(locale)`
- Primary brand color: `#E0062E` (BikeRide red)
- UI colors must come from theme tokens, not hardcoded `Colors.*` (except shadows and text-on-primary)

### Localization

- Translations are inline in `lib/core/translations/app_translations.dart` (GetX `Translations` class, not JSON files)
- Access via `'key'.tr` in widgets
- Default: Arabic (RTL). Admin defaults to English.
- Add both AR and EN keys BEFORE building widgets that use them
- Use `EdgeInsetsDirectional` when left/right padding differs

### Shared Widgets

Use widgets from `lib/core/widgets/` instead of raw Material widgets:
`AppButton`, `AppTextField`, `AppCard`, `AppLoading`, `AppSnackbar`, `AppMapWidget`

## Firebase Data Architecture

- **Firestore** = source of truth (users, trips, wallets, transactions, app_config, etc.)
- **Realtime Database** = temporary sub-second data only (driver locations, active trips, live bids, chats). Cleaned up by Cloud Functions after trip completion.
- **Flutter must NEVER write to `wallets/` or `transactions/`** — only Cloud Functions.
- Business config (prices, commissions, bid timeouts) read from `app_config` Firestore document — never hardcoded.
- Auth: Firebase Auth with Phone OTP, Google Sign-In, Facebook Sign-In.

## SpecKit Workflow

Features are developed using the SpecKit workflow with artifacts in `specs/###-feature-name/`:
- Each feature has: `spec.md`, `plan.md`, `tasks.md`, `research.md`, `data-model.md`, `quickstart.md`, `checklists/`, `contracts/`
- Flow: `/speckit.specify` → `/speckit.plan` → `/speckit.tasks` → `/speckit.implement`
- Project constitution at `.specify/memory/constitution.md` defines 7 non-negotiable principles

## Critical Rules

1. **No Laravel/PHP/REST API.** Everything is Firebase or Cloud Functions.
2. **GetX only** for state, navigation, DI.
3. **Never hardcode prices/commissions.** Read from `app_config`.
4. **Never write wallets/transactions from Flutter.** Cloud Functions only.
5. **Realtime DB is temporary.** Firestore is source of truth.
6. **All strings via `.tr` translations.** No hardcoded text in widgets.
7. **Test every screen in Arabic RTL.**
8. **Firestore batch writes** for multi-document atomic operations.
9. **Route names from `AppRoutes` constants only** — never hardcode route strings.

## Lint Configuration

Uses `flutter_lints` with strict rules: `prefer_single_quotes`, `require_trailing_commas`, `prefer_const_constructors`, `prefer_final_locals`, `avoid_print`, `sort_child_properties_last`, `sort_constructors_first`. See `analysis_options.yaml` for full config.

## Target Market

Egypt only. Currency: EGP. Phone format: +20 prefix, 11 digits. Arabic RTL is the primary UX.
