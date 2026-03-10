<!--
Sync Impact Report
===================
Version change: (new) → 1.0.0
Modified principles: N/A (initial ratification)
Added sections:
  - Core Principles (7 principles)
  - Technology Constraints
  - Development Workflow
  - Governance
Removed sections: N/A
Templates requiring updates:
  - .specify/templates/plan-template.md — ✅ compatible
    (Constitution Check section uses [Gates determined based on
    constitution file] which will now resolve against these 7
    principles)
  - .specify/templates/spec-template.md — ✅ compatible
    (Independent testability aligns with Principle VII)
  - .specify/templates/tasks-template.md — ✅ compatible
    (Phase structure and parallel markers align with workflow)
  - .specify/templates/commands/ — N/A (directory empty)
Follow-up TODOs: None
-->

# BikeRide Constitution

## Core Principles

### I. Firebase-Only Architecture

All server-side logic MUST run on Firebase services. There MUST
be no traditional backend (no Laravel, no PHP, no custom REST
API servers). The approved service boundaries are:

- **Auth**: Firebase Auth (Phone OTP only)
- **Database**: Cloud Firestore (source of truth)
- **Real-time**: Firebase Realtime Database (temporary data only)
- **Business Logic**: Firebase Cloud Functions (Node.js 18)
- **Storage**: Firebase Storage
- **Push**: Firebase Cloud Messaging (FCM)
- **Hosting**: cPanel for Flutter Web static files only

**Rationale**: A single-vendor serverless stack eliminates
infrastructure management and keeps the project within a solo
developer's operational capacity.

### II. GetX Exclusive State Management

All state management, navigation, and dependency injection MUST
use GetX. Provider, Bloc, Riverpod, and other state management
solutions MUST NOT be used.

- Feature controllers MUST use `Get.lazyPut()` inside bindings.
- Only `AuthController` is registered globally in entry points.
- Navigation MUST use `Get.toNamed()` / `Get.offAllNamed()`.
- Reactive state MUST use `.obs` / `Obx()`.

**Rationale**: A single state management library prevents
conflicting patterns, reduces onboarding friction, and keeps
the codebase consistent across Customer, Driver, and Admin apps.

### III. Feature-First Architecture

Code MUST be organized in a feature-first folder structure under
`lib/features/`. Each feature module contains its own `screens/`,
`controllers/`, `bindings/`, `widgets/`, and `models/`
subdirectories. Shared code lives under `lib/core/`.

- Features MUST NOT import from other features' internal files.
- Cross-feature communication MUST go through `core/` services
  or GetX route arguments.
- Core widgets, models, and services are shared infrastructure.

**Rationale**: Feature isolation enables parallel development,
independent testing, and clean boundaries between product areas.

### IV. Bilingual RTL-First

Arabic (RTL) is the default language. English (LTR) is secondary.
All user-facing strings MUST be defined in localization files and
accessed via `.tr` GetX translation keys.

- Hardcoded Arabic or English text in widgets is FORBIDDEN.
- Every screen MUST be tested in Arabic RTL layout.
- Directional icons (arrows, chevrons, back buttons) MUST flip
  in RTL using `Directionality.of(context)` or
  `PositionedDirectional`.
- `EdgeInsetsDirectional` MUST be used when left/right padding
  differs.

**Rationale**: The target market is Egypt. RTL correctness is
not optional — it is the primary user experience.

### V. Config-Driven Business Logic

Prices, commission rates, bid timeouts, surge multipliers, and
all tunable business parameters MUST be read from the Firestore
`app_config` document at runtime. Hardcoding business values is
FORBIDDEN.

- Vehicle multipliers, base fares, and per-km/per-min rates
  come from `app_config`.
- Commission rates come from `app_config` (ride, C2C) or
  `merchants/{uid}` (B2B custom rates).
- Promo code logic reads from `promo_codes/` collection.

**Rationale**: Business parameters change frequently. Hardcoded
values require app releases to update. Remote config enables
instant tuning without deployment.

### VI. Server-Side Financial Security

Financial writes (wallets, transactions) MUST only occur in Cloud
Functions. Flutter clients MUST NOT write directly to `wallets/`
or `transactions/` collections.

- Paymob webhooks MUST verify HMAC signature before crediting.
- Admin Cloud Functions MUST verify `role: admin` custom claim.
- Multi-document financial operations MUST use Firestore batch
  writes for atomicity.
- Firestore security rules MUST enforce read/write boundaries
  per collection as defined in `firestore.rules`.

**Rationale**: Client-side financial writes are trivially
exploitable. Server-side enforcement is the only acceptable
trust boundary for money movement.

### VII. Theme-Aware Design System

All UI colors MUST come from `Theme.of(context)`, the
`AppColorsExtension` ThemeExtension, or `AppTheme` static
constants. Hardcoded `Colors.white` or `Colors.black` in widget
code is only permitted for:

- Shadows (low-opacity black)
- Text/icons on brand-colored backgrounds (white on primary)

All other surface, border, and text colors MUST use semantic
tokens (`surfaceElevated`, `surfaceContainer`, `borderSubtle`,
`textMuted`, etc.) that automatically adapt to light/dark mode.

**Rationale**: A semantic token system guarantees dark mode
support without per-widget audits and maintains visual
consistency across 50+ screens.

## Technology Constraints

The following technology boundaries are non-negotiable:

| Boundary | Allowed | Forbidden |
|----------|---------|-----------|
| Client language | Dart (Flutter) | Native Kotlin/Swift UI code |
| Server language | Node.js 18 (Cloud Functions only) | PHP, Laravel, Python, Go |
| State management | GetX | Provider, Bloc, Riverpod |
| Database | Firestore + Realtime DB | SQL databases, MongoDB |
| Auth method | Firebase Auth (Phone OTP) | Email/password, social-only |
| Maps | Google Maps SDK for Flutter | MapBox, Apple Maps |
| Payments | Paymob (cards, Vodafone Cash, Fawry) | Stripe, PayPal |
| Hosting | cPanel (static files) | Vercel, Netlify, AWS |
| Target region | Egypt (EGP currency, +20 phones) | Multi-country |

**Realtime DB usage rules**:
- Realtime DB is for sub-second temporary data ONLY.
- All Realtime DB data MUST be cleaned up by Cloud Functions
  after trip completion or cancellation.
- Firestore is ALWAYS the source of truth.

**GPS rules**:
- Driver location written to Realtime DB every 3 seconds (not
  through Cloud Functions).
- Ignore GPS updates with accuracy > 50m.
- Ignore GPS jumps > 100m in < 2 seconds.
- Stop location updates immediately when driver goes offline.

## Development Workflow

### Feature Development Process

1. Features are developed on named branches (`###-feature-name`).
2. Each feature has a specification in `specs/###-feature-name/`.
3. Implementation follows the SpecKit workflow:
   `/speckit.plan` → `/speckit.tasks` → `/speckit.implement`.
4. All Firestore queries MUST have deployed indexes before use
   (`firebase deploy --only firestore:indexes`).

### Localization Workflow

1. Add keys to `lib/core/translations/app_translations.dart`
   (both AR and EN) BEFORE building any widget that uses them.
2. Use `.tr` suffix for all user-visible text.
3. Verify both Arabic and English rendering before marking a
   feature complete.

### Asset Management

- Images: `assets/images/` with feature-specific subdirectories.
- Map styles: `assets/map_style.json`.
- Icons: `assets/icons/` for custom marker icons.
- All asset directories MUST be registered in `pubspec.yaml`.

### Environment & Secrets

- API keys and secrets MUST be stored in `.env` (never committed).
- `.env` MUST be listed in `.gitignore`.
- Production config uses Firebase Remote Config or environment
  variables at build time.

## Governance

This constitution defines the non-negotiable architectural and
process rules for the BikeRide project. All code contributions
MUST comply with these principles.

### Amendment Process

1. Propose the change with rationale and impact analysis.
2. Update this document via the `/speckit.constitution` command.
3. Propagate changes to dependent templates (plan, spec, tasks).
4. Version bump follows semantic versioning:
   - **MAJOR**: Principle removed, redefined, or made incompatible.
   - **MINOR**: New principle added or existing one materially
     expanded.
   - **PATCH**: Wording clarification, typo fix, non-semantic
     refinement.

### Compliance

- The plan template's "Constitution Check" section MUST gate
  implementation planning against these principles.
- Violations MUST be documented in the plan's "Complexity
  Tracking" table with justification.
- Runtime development guidance is maintained in `CLAUDE.md`.

**Version**: 1.0.0 | **Ratified**: 2026-03-02 | **Last Amended**: 2026-03-02
