# Implementation Plan: Admin Dashboard Web Panel

**Branch**: `013-admin-dashboard` | **Date**: 2026-03-02 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/013-admin-dashboard/spec.md`

## Summary

Build a Flutter Web admin dashboard for the BikeRide platform with 18 screens covering authentication (email/password with custom claims), responsive layout shell, document review queue, live dashboard stats, customer/driver/trip management, financial ledger, app configuration, promo codes, notifications with sent history, referral settings, and analytics. The admin panel reuses the existing shared core module (theme, widgets, translations, models, services) and follows the established GetX + feature-first architecture. Two roles are supported: `admin` (all operational features) and `super_admin` (adds config, maintenance mode, and admin management). Deployed as static files on cPanel.

## Technical Context

**Language/Version**: Dart (Flutter 3.x)
**Primary Dependencies**: GetX 4.6.6, Firebase Core/Auth/Firestore/Storage/Messaging, fl_chart 0.69.x, google_maps_flutter 2.10.0, cached_network_image 3.3.1, google_fonts 6.1.0
**Storage**: Cloud Firestore (source of truth) + Firebase Realtime Database (live driver locations, active trips) + Firebase Storage (document images)
**Testing**: Flutter test framework (widget tests exist in `test/`)
**Target Platform**: Flutter Web — Chrome, Firefox, Safari, Edge
**Project Type**: Web application (admin panel within multi-app Flutter monorepo)
**Performance Goals**: Login <5s, real-time updates <5s, CSV export <15s for 10K rows, search results <10s
**Constraints**: Static file deployment on cPanel (no server-side processing), 1-5 concurrent admin users, Firebase quotas, 7-day session timeout
**Scale/Scope**: 18 screens, 11 feature sections + dashboard home, 15 user stories, 39 functional requirements

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| # | Principle | Status | Notes |
|---|-----------|--------|-------|
| I | Firebase-Only Architecture | PASS | All data from Firestore/RTDB, auth via Firebase Auth email/password with custom claims, no traditional backend |
| II | GetX Exclusive State Management | PASS | All admin controllers use GetxController, bindings use Get.lazyPut(), reactive state via .obs/Obx() |
| III | Feature-First Architecture | PASS | Admin features under `lib/features/admin/` with screens/, controllers/, bindings/, widgets/ subdirectories |
| IV | Bilingual RTL-First | PASS | Reuses existing localization system. Admin defaults to English but Arabic RTL fully supported. All strings via .tr keys |
| V | Config-Driven Business Logic | PASS | Config screen reads/writes `app_config` document. No hardcoded business values |
| VI | Server-Side Financial Security | PASS | Wallet adjustments via existing `adjustWalletBalance` Cloud Function. No direct Flutter writes to wallets/transactions |
| VII | Theme-Aware Design System | PASS | Reuses AppTheme + AppColorsExtension. All colors from semantic tokens |

**Gate result: ALL PASS** — No violations. Proceed to Phase 0.

### Post-Phase 1 Re-check

| # | Principle | Status | Notes |
|---|-----------|--------|-------|
| I | Firebase-Only Architecture | PASS | New `admin_notifications` collection in Firestore. All admin actions via existing Cloud Functions. No backend added. |
| II | GetX Exclusive State Management | PASS | 14 admin controllers, all extend GetxController. AdminAuthController + AdminLayoutController registered as permanent. All others via Get.lazyPut() in bindings. |
| III | Feature-First Architecture | PASS | All admin code under `lib/features/admin/` with screens/, controllers/, bindings/, widgets/, models/, services/ subdirs. Admin-specific models co-located (not shared). |
| IV | Bilingual RTL-First | PASS | Admin translation keys added to existing app_translations.dart. .tr used for all strings. RTL layout tested via Directionality builder in main_admin.dart. |
| V | Config-Driven Business Logic | PASS | Config screen reads/writes `app_config/config` via Cloud Function. Dashboard reads config for display. No hardcoded values. |
| VI | Server-Side Financial Security | PASS | Wallet adjustments call `adjustWalletBalance` CF. Credit issuance calls CF. No direct Firestore writes to wallets/transactions. |
| VII | Theme-Aware Design System | PASS | All admin screens use AppTheme + AppColorsExtension. Custom admin widgets (stat_card, status_badge, etc.) use semantic tokens. |

**Post-design gate: ALL PASS**

## Project Structure

### Documentation (this feature)

```text
specs/013-admin-dashboard/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output (internal admin — minimal)
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
lib/
├── main_admin.dart                          # Entry point — admin web app (exists, needs update)
├── core/                                    # Shared infrastructure (exists, extend with admin translations)
│   ├── models/                              # Existing: UserModel, DriverProfileModel, TripModel, DocumentModel, enums
│   ├── services/                            # Existing: FirestoreService, AuthService, StorageService, FcmService
│   ├── widgets/                             # Existing: AppButton, AppTextField, AppCard, AppLoading, AppSnackbar, AppMapWidget
│   ├── theme/app_theme.dart                 # Existing: AppTheme, AppColorsExtension
│   ├── translations/app_translations.dart   # Existing: extend with admin.* keys
│   └── routes/
│       ├── app_routes.dart                  # Existing: admin route constants already defined
│       └── admin_pages.dart                 # NEW: GetPage list for admin routes
│
└── features/admin/                          # NEW: All admin feature code
    ├── bindings/
    │   ├── admin_auth_binding.dart
    │   ├── admin_dashboard_binding.dart
    │   ├── admin_users_binding.dart
    │   ├── admin_documents_binding.dart
    │   ├── admin_trips_binding.dart
    │   ├── admin_financial_binding.dart
    │   ├── admin_config_binding.dart
    │   ├── admin_promos_binding.dart
    │   ├── admin_referral_binding.dart
    │   ├── admin_notifications_binding.dart
    │   └── admin_analytics_binding.dart
    ├── controllers/
    │   ├── admin_auth_controller.dart        # Email/password auth, role check, session management
    │   ├── admin_layout_controller.dart      # Sidebar state, responsive breakpoints, pending badge
    │   ├── admin_dashboard_controller.dart   # Live stats, charts, recent trips
    │   ├── admin_users_controller.dart       # Customer list, search, filter, suspend/activate, wallet adjust
    │   ├── admin_drivers_controller.dart     # Driver list, approval filter, online filter
    │   ├── admin_documents_controller.dart   # Pending queue, approve/reject with notification
    │   ├── admin_trips_controller.dart       # Trip list, filters, detail view, issue credit
    │   ├── admin_financial_controller.dart   # Summary cards, transaction ledger, CSV export, commission breakdown
    │   ├── admin_config_controller.dart      # Read/write app_config, validation, maintenance mode
    │   ├── admin_promos_controller.dart      # CRUD promo codes
    │   ├── admin_referral_controller.dart    # Referral config, stats, history
    │   ├── admin_notifications_controller.dart # Send to segment/user, sent history
    │   ├── admin_analytics_controller.dart   # Charts data, period selector, CSV export
    │   └── admin_search_controller.dart      # Global topbar search
    ├── screens/
    │   ├── admin_login_screen.dart
    │   ├── admin_layout_shell.dart           # Sidebar + topbar + content area
    │   ├── admin_dashboard_screen.dart
    │   ├── admin_customers_screen.dart
    │   ├── admin_customer_detail_screen.dart
    │   ├── admin_drivers_screen.dart
    │   ├── admin_driver_detail_screen.dart
    │   ├── admin_documents_screen.dart
    │   ├── admin_trips_screen.dart
    │   ├── admin_trip_detail_screen.dart
    │   ├── admin_financial_screen.dart
    │   ├── admin_config_screen.dart
    │   ├── admin_promos_screen.dart
    │   ├── admin_referral_screen.dart
    │   ├── admin_notifications_screen.dart
    │   ├── admin_analytics_screen.dart
    │   └── admin_not_found_screen.dart
    ├── widgets/
    │   ├── admin_sidebar.dart               # Responsive sidebar with nav items + badge
    │   ├── admin_topbar.dart                # Title, global search, admin info
    │   ├── stat_card.dart                   # Dashboard metric card
    │   ├── admin_data_table.dart            # Reusable paginated data table with search/filter
    │   ├── document_image_viewer.dart       # Image preview + full-size dialog
    │   ├── status_badge.dart                # Colored badge for statuses
    │   ├── date_range_picker.dart           # Date range filter widget
    │   ├── confirm_dialog.dart              # Reusable confirmation dialog
    │   └── notification_preview_card.dart   # Notification preview before sending
    ├── models/
    │   ├── admin_user_model.dart            # Admin-specific fields (role, lastLoginAt)
    │   ├── dashboard_stats_model.dart       # Aggregated dashboard metrics
    │   ├── financial_summary_model.dart     # Revenue, commission, top-ups, refunds
    │   ├── notification_record_model.dart   # Sent notification history record
    │   └── referral_stats_model.dart        # Referral aggregate stats
    └── services/
        └── admin_firestore_service.dart     # Admin-specific Firestore queries (aggregations, paginated lists, search)

test/
├── features/admin/
│   ├── controllers/                         # Unit tests for admin controllers
│   └── widgets/                             # Widget tests for admin-specific widgets
└── [existing test files]
```

**Structure Decision**: Admin features follow the established feature-first pattern under `lib/features/admin/`. Admin-specific models and services are co-located within the feature module since they are not shared with customer/driver apps. Shared models (UserModel, TripModel, etc.) from `lib/core/models/` are reused directly. The admin layout shell wraps all authenticated screens with sidebar + topbar.

## Complexity Tracking

> No constitution violations detected. No entries needed.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| — | — | — |
