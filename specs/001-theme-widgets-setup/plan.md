# Implementation Plan: Core Theme System and Shared Widgets

**Branch**: `001-theme-widgets-setup` | **Date**: 2026-02-27 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-theme-widgets-setup/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

Create a centralized theme system and reusable widget library for the BikeRide platform. The theme system provides consistent colors, typography, spacing, and styling across three Flutter apps (Customer, Driver, Admin Panel) with support for light/dark modes and RTL/LTR directions. Shared widgets (buttons, text fields, cards, loading indicators, snackbars) built on this theme accelerate feature development and ensure visual consistency. Three entry point files initialize each app with proper Firebase, GetX, and localization configuration.

## Technical Context

**Language/Version**: Dart 3.9.2+ with Flutter SDK 3.9.2+
**Primary Dependencies**:
- GetX (^4.6.6) for state management, routing, and dependency injection
- Firebase Core (^3.x) for multi-platform initialization
- google_fonts for Cairo and Plus Jakarta Sans typography
- flutter_localizations and intl for Arabic/English localization

**Storage**:
- SharedPreferences for local theme/language preferences
- Firestore for user language preference (post-authentication)

**Testing**:
- flutter_test for widget tests
- golden tests for visual regression testing of widgets and themes

**Target Platform**:
- Android (minSdk from Flutter config)
- iOS (deployment target from Flutter config)
- Web (Flutter Web for admin panel)

**Project Type**: Mobile + Web application (multi-app architecture with shared codebase)

**Performance Goals**:
- Theme switching: <16ms (single frame) to prevent visual lag
- App initialization: <3 seconds to first screen on mid-range devices
- Widget rebuild: <16ms when theme/locale changes

**Constraints**:
- Must support RTL (Arabic) as default language
- Must work offline (theme/widgets don't require network)
- Must maintain 48dp minimum touch targets for accessibility
- Colors must meet WCAG AA contrast ratios

**Scale/Scope**:
- 3 apps sharing same theme system
- 6 shared widgets initially (expandable)
- 2 languages (Arabic, English)
- 2 theme modes (light, dark)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

**Status**: ⚠️ Constitution not yet ratified

The project constitution file exists as a template but has not been customized with project-specific principles. Based on the CLAUDE.md critical rules, the following principles are inferred:

### Inferred Principles from CLAUDE.md

1. **GetX-Only State Management** (NON-NEGOTIABLE)
   - ✅ **Compliant**: Plan uses GetX exclusively for theme/locale reactivity
   - All widgets use GetX reactive patterns (GetBuilder/Obx) for theme updates

2. **Firebase-First Architecture** (NON-NEGOTIABLE)
   - ✅ **Compliant**: Firebase initialization is core to all three entry points
   - No alternative backend; Firebase Cloud Functions handle business logic

3. **Localization Mandatory** (NON-NEGOTIABLE)
   - ✅ **Compliant**: All strings externalized to ar.json/en.json
   - No hardcoded text in widgets; RTL/LTR support built into theme

4. **Multi-App Architecture**
   - ✅ **Compliant**: Three separate entry points (main_customer, main_driver, main_admin)
   - Shared core code (theme, widgets, models, services)

5. **No Hardcoded Configuration**
   - ✅ **Compliant**: Theme values centralized in app_theme.dart
   - Config constants in app_constants.dart, not scattered across files

**Recommendation**: Run `/speckit.constitution` to formalize project principles before implementation phase.

---

### Post-Phase 1 Re-evaluation

**Status**: ✅ **PASSED** - Design maintains compliance

After completing Phase 1 (research, data model, contracts):

1. **GetX-Only State Management**: ✅ Maintained
   - Theme switching uses `Get.changeThemeMode()`
   - Locale switching uses `Get.updateLocale()`
   - Widget library uses GetX reactive patterns (`.obs`, `Obx()`)

2. **Firebase-First Architecture**: ✅ Maintained
   - All three entry points initialize Firebase via `FirebaseService.initialize()`
   - No alternative backend dependencies introduced

3. **Localization Mandatory**: ✅ Maintained
   - Widget API contracts require `.tr` for all text
   - Quickstart guide enforces localization best practices
   - Data model defines ar.json/en.json structure

4. **No New Violations Introduced**: ✅ Confirmed
   - No additional libraries beyond project standards
   - No complexity added beyond requirements
   - All design decisions align with CLAUDE.md rules

**Gate Status**: ✅ **APPROVED** - Ready to proceed to implementation

## Project Structure

### Documentation (this feature)

```text
specs/001-theme-widgets-setup/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
│   └── widget-api.md    # Public widget contracts
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
lib/
├── main_customer.dart           # Customer app entry point
├── main_driver.dart             # Driver app entry point
├── main_admin.dart              # Admin panel entry point
│
├── core/
│   ├── theme/
│   │   └── app_theme.dart       # Theme system (colors, typography, spacing)
│   │
│   ├── widgets/
│   │   ├── app_button.dart      # Reusable button widget
│   │   ├── app_text_field.dart  # Reusable text input widget
│   │   ├── app_card.dart        # Reusable card widget
│   │   ├── app_loading.dart     # Loading indicator widget
│   │   ├── app_snackbar.dart    # Snackbar utility
│   │   └── app_map_widget.dart  # Map placeholder widget
│   │
│   ├── constants/
│   │   └── app_constants.dart   # App-wide constants
│   │
│   ├── routes/
│   │   └── app_routes.dart      # Route name constants
│   │
│   └── services/
│       └── firebase_service.dart # Firebase initialization
│
└── features/
    └── auth/
        └── controllers/
            └── auth_controller.dart # Global auth controller

assets/
└── lang/
    ├── ar.json                  # Arabic translations
    └── en.json                  # English translations

test/
└── core/
    ├── theme/
    │   └── app_theme_test.dart  # Theme tests
    └── widgets/
        ├── app_button_test.dart
        ├── app_text_field_test.dart
        ├── app_card_test.dart
        ├── app_loading_test.dart
        └── app_snackbar_test.dart
```

**Structure Decision**: Using Flutter feature-first architecture as defined in CLAUDE.md. The `core/` directory contains cross-cutting concerns (theme, widgets, services) shared across all three apps. Each app entry point (`main_*.dart`) initializes the same core but with app-specific routes and configurations. This structure supports the multi-app architecture while maximizing code reuse.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

**Status**: N/A - No violations detected

All design decisions align with inferred principles from CLAUDE.md:
- GetX for state management (mandated)
- Firebase for initialization (mandated)
- Multi-app structure with shared core (mandated)
- Localization-first approach (mandated)

No additional complexity introduced beyond project requirements.
