# BikeRide Project Rules

You are an expert Flutter and Firebase developer working on the **BikeRide** project, an inDrive-style platform for Egypt.

Follow these strict rules when writing code or suggesting solutions:

## Core Stack & Architecture
- **Language & Framework:** Dart and Flutter ONLY. No PHP, no Laravel, no REST APIs. Everything is Flutter + Firebase.
- **State Management & Routing:** STRICTLY use **GetX**. Never use `Provider`, `Bloc`, or `Riverpod`.
  - Always use `Get.lazyPut()` in bindings. Never use `Get.put()` for feature controllers, except for global controllers like `AuthController`.
  - **Routing Constants:** ALL routes MUST be referenced from `lib/core/routes/app_routes.dart`. Never hardcode route strings. Pages are registered in `customer_pages.dart` or `driver_pages.dart`.
- **Architecture:** Feature-first folder structure (`lib/features/`, `lib/core/`). Keep screens, controllers, and bindings compartmentalized within each feature.

## UI, Localization, Theming & Shared Widgets
- **Direction & Language:** Default language is **Arabic (RTL)**. Test every screen in RTL. Never assume LTR layout works for both directions.
- **Localization (`intl`):** All strings must be in `assets/lang/ar.json` and `assets/lang/en.json`. Never hardcode Arabic or English texts directly in widgets.
- **Directionality Widget:** Use `Directionality.of(context)` at the app root and detect orientation. Icons that imply direction (arrows, etc.) must flip in RTL naturally or via `Directionality`.
- **Theming & Colors (`AppTheme`):** Use `AppTheme.lightTheme` and `AppTheme.darkTheme`.
  - **Fonts**: `GoogleFonts.plusJakartaSans` for English and `GoogleFonts.cairo` for Arabic (controlled by `AppTheme.getThemeWithLocale`).
  - **Semantic Colors**: Access custom variants via `Theme.of(context).extension<AppColorsExtension>()!`.
- **Shared Widgets:** STRICTLY prioritize widgets from `lib/core/widgets/` over raw Material components. Utilize `AppButton`, `AppTextField`, `AppCard`, `AppLoading`, `AppMapWidget`, and `AppSnackbar` which natively support RTL flipping, states, and the App's theme constraints.

## Firebase & Data Flow Constraints
- **Configurations:** Never hardcode prices, commission rates, or configuration values. Always retrieve them from the `app_config` Firestore document.
- **Wallets & Transactions:** NEVER write directly to `wallets/` or `transactions/` from the Flutter app. These nodes are strictly written to by Firebase Cloud Functions.
- **Realtime Database:** RTDB is for temporary, sub-second real-time data ONLY (like driver locations and chat messages). Do not use for persistence. Source of truth is Firestore.
- **Firestore Writes:** Use Firestore batch writes for operations that update multiple documents atomically (e.g., deducting customer wallet + crediting driver wallet).
- **Queries:** All Firestore queries must be covered by indexes.

## Maps & Location Logic
- **Driver GPS:** Use `google_maps_flutter`. Driver locations are written to the Realtime database every **3 seconds** strictly when online. Stop updates immediately upon going offline.
- **GPS Filtering:** Ignore location updates if `accuracy > 50m` or if the driver allegedly jumped `> 100m` in `< 2 seconds`.

## Security & Cloud Functions
- **Admin Roles:** Any admin-related Cloud Functions must verify the `role: admin` custom claim before executing.
- **Webhooks:** Paymob webhooks must verify the HMAC signature before crediting any wallet balances.
- **Subcollections & Auth:** Ensure data reads and writes strictly follow the firestore security rules where users/drivers can only mutate their own assets unless explicitly allowed.
