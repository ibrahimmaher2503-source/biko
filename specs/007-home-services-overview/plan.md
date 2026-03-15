# Implementation Plan: Customer Home Services Overview

**Branch**: `007-home-services-overview` | **Date**: 2026-03-02 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/007-home-services-overview/spec.md`

## Summary

Redesign the customer home screen from its current basic layout (greeting + ride/delivery toggle + map placeholder) into the full-featured services overview matching the reference design. The new screen includes a location header with wallet badge, floating search bar, three service cards (Ride, Delivery, Merchant), recent locations list, and a persistent bottom navigation bar with 5 tabs. The implementation leverages the existing AppTheme, AppColorsExtension, and shared widgets, extending the HomeController with wallet/location/recent-location state, and introducing a `CustomerMainShell` scaffold for bottom navigation persistence across tabs.

## Technical Context

**Language/Version**: Dart 3.x / Flutter 3.x
**Primary Dependencies**: GetX (state/routing/DI), google_fonts, cached_network_image, geolocator, geocoding
**Storage**: Cloud Firestore (user doc → wallet balance), SharedPreferences (cached location)
**Testing**: flutter_test (widget tests), integration_test
**Target Platform**: Android + iOS
**Project Type**: Mobile app (Flutter)
**Performance Goals**: 60fps scrolling, <500ms home screen render after auth
**Constraints**: RTL (Arabic default) + LTR (English), light + dark themes, offline-capable (show cached data)
**Scale/Scope**: Single screen redesign + bottom nav shell + ~15 new translation keys + 1 new asset

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

The project constitution is unpopulated (template only). No formal gates are defined. The implementation follows all rules from `CLAUDE.md`:

| Rule | Status | Notes |
|------|--------|-------|
| GetX mandatory | PASS | All state via GetxController, bindings use `Get.lazyPut()` |
| No hardcoded strings | PASS | All text via `.tr` localization keys |
| No hardcoded prices/config | PASS | Wallet balance read from Firestore `UserModel` |
| RTL + LTR support | PASS | Design uses `Directionality.of(context)` for chevron flipping |
| Light + Dark theme | PASS | All colors from `Theme.of(context)` and `AppColorsExtension` |
| Feature-first folders | PASS | All new code in `lib/features/home/` |
| Only AuthController global | PASS | HomeController via `Get.lazyPut()` in HomeBinding |

## Project Structure

### Documentation (this feature)

```text
specs/007-home-services-overview/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
└── tasks.md             # Phase 2 output (created by /speckit.tasks)
```

### Source Code (repository root)

```text
lib/
├── core/
│   ├── theme/app_theme.dart                    # [MODIFY] Add orange accent color
│   ├── translations/app_translations.dart      # [MODIFY] Add ~30 new home translation keys
│   ├── widgets/                                # [EXISTING] Reuse AppButton, AppCard, AppSnackbar
│   └── routes/
│       ├── app_routes.dart                     # [EXISTING] Routes already defined
│       └── customer_pages.dart                 # [MODIFY] Add CustomerMainShell route
│
├── features/home/
│   ├── controllers/
│   │   └── home_controller.dart                # [MODIFY] Add wallet, location, recent locations state
│   ├── bindings/
│   │   └── home_binding.dart                   # [MODIFY] Register any new dependencies
│   ├── screens/
│   │   ├── customer_home_screen.dart           # [REPLACE] Full redesign to match reference
│   │   └── customer_main_shell.dart            # [NEW] Bottom nav shell with IndexedStack
│   └── widgets/
│       ├── home_header.dart                    # [NEW] Location + wallet badge header
│       ├── home_search_bar.dart                # [NEW] Floating search bar
│       ├── ride_service_card.dart              # [NEW] "Take a Ride" prominent card
│       ├── service_card_grid.dart              # [NEW] Delivery + Merchant 2-col grid
│       ├── recent_locations_section.dart       # [NEW] Recent locations list
│       └── customer_bottom_nav.dart            # [NEW] Bottom navigation bar widget
│
└── assets/images/
    └── home/
        └── motorcycle.png                      # [NEW] Motorcycle illustration for ride card

test/
└── features/home/
    ├── home_controller_test.dart               # [NEW] Unit tests for controller
    └── widgets/
        ├── home_header_test.dart               # [NEW] Widget test
        ├── ride_service_card_test.dart          # [NEW] Widget test
        └── customer_bottom_nav_test.dart        # [NEW] Widget test
```

**Structure Decision**: Feature-first within the existing `lib/features/home/` directory. New widgets are extracted into `widgets/` subfolder for clarity. The `CustomerMainShell` acts as the persistent scaffold that wraps tab pages (Home, Rides, Wallet, Profile) with the bottom navigation bar.

## Complexity Tracking

No constitution violations to justify. The design is straightforward:
- No new packages required (all dependencies already in pubspec.yaml)
- No new services needed (reuses FirestoreService, AuthService)
- No new models needed (uses existing UserModel, extends with simple local data class for RecentLocation)
