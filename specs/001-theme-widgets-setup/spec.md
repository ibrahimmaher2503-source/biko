# Feature Specification: Core Theme System and Shared Widgets

**Feature Branch**: `001-theme-widgets-setup`
**Created**: 2026-02-27
**Status**: Draft
**Input**: User description: "read claude.me and explore C:\Users\berog\StudioProjects\biko\stitch files to create app themes colors fonts shared widgets and main file structre project"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Consistent Visual Identity Across All Apps (Priority: P1)

Developers need a centralized theme system that ensures the Customer App, Driver App, and Admin Panel all share the same visual identity (colors, fonts, spacing) while supporting both light and dark modes and RTL/LTR directions.

**Why this priority**: This is the foundation for all UI development. Without it, no screens can be built consistently. Every feature depends on having access to standardized colors, fonts, and spacing.

**Independent Test**: Can be fully tested by creating a sample screen that uses all theme colors (primary, backgrounds, text colors), displays text in both Cairo and Plus Jakarta Sans fonts, and switches between light/dark modes and RTL/LTR directions. The theme values should match the design system exactly.

**Acceptance Scenarios**:

1. **Given** a developer creates a new screen, **When** they apply theme colors using the theme system, **Then** the colors automatically match the design specification (#e0062e for primary, #f8f5f6 for light background, etc.)
2. **Given** the app is in light mode, **When** the user switches to dark mode, **Then** all themed elements automatically update to dark mode colors (#230f13 for dark background, appropriate text colors)
3. **Given** text is displayed in the app, **When** the language is Arabic, **Then** text uses the Cairo font and flows right-to-left
4. **Given** text is displayed in the app, **When** the language is English, **Then** text uses Plus Jakarta Sans font and flows left-to-right

---

### User Story 2 - Reusable Widget Library for Rapid Development (Priority: P2)

Developers need pre-built, reusable widgets (buttons, text fields, cards, loading indicators, snackbars) that automatically follow the theme system and handle both RTL/LTR layouts, so they can build screens quickly without reinventing common UI patterns.

**Why this priority**: After the theme foundation (P1), developers need components to build with. This accelerates feature development and ensures UI consistency across all three apps.

**Independent Test**: Can be fully tested by creating a demo screen that displays all shared widgets (primary button, text field, card, loading spinner, snackbar) in both light/dark modes and RTL/LTR directions. Each widget should automatically adapt to theme changes and direction changes.

**Acceptance Scenarios**:

1. **Given** a developer needs a primary action button, **When** they use the AppButton widget, **Then** it displays with primary color (#e0062e), white text, rounded corners (xl), height 56dp, and proper hover/press states
2. **Given** a developer needs a text input, **When** they use the AppTextField widget, **Then** it displays with rounded corners, proper border colors, focus ring in primary color, and icon positioning that flips for RTL
3. **Given** a loading operation is in progress, **When** the developer shows the AppLoading widget, **Then** it displays a centered spinner in primary color with optional overlay
4. **Given** the app needs to show a success message, **When** the developer calls AppSnackbar.show(), **Then** a styled snackbar appears with appropriate icon, message, and auto-dismiss behavior
5. **Given** content is displayed in a card, **When** the developer uses AppCard, **Then** it displays with proper elevation, rounded corners, and padding

---

### User Story 3 - Proper Entry Points for Multi-App Architecture (Priority: P3)

The project needs separate entry point files (main_customer.dart, main_driver.dart, main_admin.dart) that initialize the app with correct configuration, Firebase setup, GetX bindings, and localization for each app type.

**Why this priority**: While important for the multi-app architecture, this can be implemented after the theme and widgets are ready. The entry points consume the theme system rather than define it.

**Independent Test**: Can be fully tested by running each app entry point (flutter run -t lib/main_customer.dart, etc.) and verifying that it launches successfully, shows the correct splash screen, initializes Firebase, registers global controllers (AuthController), and loads the correct language files.

**Acceptance Scenarios**:

1. **Given** a developer runs the customer app, **When** the app launches via main_customer.dart, **Then** Firebase initializes, GetX is configured, localization loads (default Arabic), AuthController is registered globally, and the splash screen displays
2. **Given** a developer runs the driver app, **When** the app launches via main_driver.dart, **Then** the same initialization occurs but with driver-specific routes and theme
3. **Given** a developer runs the admin panel, **When** the app launches via main_admin.dart, **Then** the web app initializes with admin routes and web-specific configurations
4. **Given** the app is starting up, **When** initialization completes, **Then** the app navigates to the language selection screen (if first launch) or splash screen based on user state

---

### Edge Cases

- What happens when a custom color is needed that's not in the theme palette? (Document in theme file how to add custom semantic colors)
- How do widgets handle extremely long text in RTL mode? (Text should truncate or wrap properly without breaking layout)
- What if a widget needs different styling in the admin panel vs mobile apps? (Widgets should accept optional style overrides while maintaining defaults)
- How do shared widgets behave on very small screens (< 320px width)? (Widgets should maintain minimum touch targets of 48dp and scale padding appropriately)
- What happens if Firebase initialization fails on app launch? (Show error screen with retry option instead of white screen)

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST define a centralized theme system in `lib/core/theme/app_theme.dart` containing all design tokens (colors, typography, spacing, border radius, shadows)
- **FR-002**: Theme MUST support both light mode and dark mode with separate color palettes
- **FR-003**: Theme MUST support RTL (Arabic) and LTR (English) text directions
- **FR-004**: System MUST provide primary color (#e0062e), primary dark (#b00423), background light (#f8f5f6), background dark (#230f13), and neutral tint (#fcecee)
- **FR-005**: System MUST configure Cairo font family for Arabic text and Plus Jakarta Sans for English text
- **FR-006**: System MUST define typography scales with font weights: 300, 400, 500, 600, 700, 800
- **FR-007**: System MUST define border radius values: default (4-8dp), large (8-16dp), xl (12-24dp), full (circular)
- **FR-008**: System MUST provide Material Icons integration via material_symbols_outlined
- **FR-009**: System MUST create AppButton widget in `lib/core/widgets/app_button.dart` with primary, secondary, and outline variants
- **FR-010**: AppButton MUST have height of 56dp, xl border radius, and support loading state
- **FR-011**: System MUST create AppTextField widget in `lib/core/widgets/app_text_field.dart` with label, hint, prefix/suffix icons, and validation error display
- **FR-012**: AppTextField MUST handle RTL text direction automatically and flip icon positions
- **FR-013**: System MUST create AppCard widget in `lib/core/widgets/app_card.dart` with elevation, padding, and tap handling
- **FR-014**: System MUST create AppLoading widget in `lib/core/widgets/app_loading.dart` with circular progress indicator and optional overlay
- **FR-015**: System MUST create AppSnackbar utility in `lib/core/widgets/app_snackbar.dart` for showing success, error, info, and warning messages
- **FR-016**: AppSnackbar MUST auto-dismiss after a configurable duration (default 3 seconds)
- **FR-017**: System MUST create AppMapWidget placeholder in `lib/core/widgets/app_map_widget.dart` for future Google Maps integration
- **FR-018**: System MUST create three entry point files: `lib/main_customer.dart`, `lib/main_driver.dart`, `lib/main_admin.dart`
- **FR-019**: Each entry point MUST initialize Firebase via `lib/core/services/firebase_service.dart`
- **FR-020**: Each entry point MUST configure GetX for state management, routing, and dependency injection
- **FR-021**: Each entry point MUST register AuthController as a global controller using Get.put()
- **FR-022**: Each entry point MUST configure localization with Arabic as default language
- **FR-023**: System MUST create language files at `assets/lang/ar.json` and `assets/lang/en.json` with initial keys for common UI strings
- **FR-024**: System MUST create `lib/core/constants/app_constants.dart` for app-wide constants (timeouts, limits, formats)
- **FR-025**: System MUST create `lib/core/routes/app_routes.dart` with route name constants for all apps
- **FR-026**: System MUST support switching between light and dark mode at runtime
- **FR-027**: System MUST support switching between Arabic and English at runtime
- **FR-028**: All shared widgets MUST automatically adapt to theme changes without requiring screen rebuilds

### Key Entities *(include if feature involves data)*

- **Theme Configuration**: Contains color schemes (light/dark), typography definitions, spacing scale, border radius values, shadow styles, and icon theme
- **Localization Asset**: JSON files containing key-value pairs for all UI strings in Arabic and English
- **App Route**: Named routes for navigation in GetX, organized by app type (customer, driver, admin)
- **Firebase Configuration**: Platform-specific Firebase options loaded from google-services.json (Android) and GoogleService-Info.plist (iOS)

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Developers can create a new screen using only theme values and shared widgets without writing custom styling code
- **SC-002**: All three apps (Customer, Driver, Admin) display identical visual components when using the same shared widgets
- **SC-003**: Switching between light and dark mode updates all UI elements instantly without lag or visual glitches
- **SC-004**: Switching between Arabic and English updates text direction and font family across the entire app
- **SC-005**: All shared widgets maintain proper layout and touch targets (minimum 48dp) in both RTL and LTR modes
- **SC-006**: Each app entry point successfully initializes and navigates to the first screen within 3 seconds on mid-range devices
- **SC-007**: Theme colors match the design specification exactly: primary (#e0062e), backgrounds (#f8f5f6 light, #230f13 dark)
- **SC-008**: All text uses Cairo font when language is Arabic and Plus Jakarta Sans when language is English

## Assumptions *(optional)*

1. The Material Symbols Outlined icon set provides sufficient icon coverage for the entire app without needing custom icon fonts
2. Firebase configuration files (google-services.json, GoogleService-Info.plist) will be added manually by the developer and are not part of this feature
3. The three apps share the same theme system but may use different routes and screens
4. Dark mode preference will be stored in shared preferences and persisted across app launches
5. Language preference will be stored in Firestore user document after authentication
6. The app will support Material Design 3 elevation and shadow styles
7. All colors in the design system provide sufficient contrast ratios for WCAG AA accessibility compliance
8. The app will use GetX's reactive state management (GetX/Obx) for theme and locale switching
9. Localization files will be expanded in future features; initial files only need common UI strings (buttons, errors, etc.)
10. The admin web panel will use the same theme system but may have desktop-specific breakpoints for responsive layout

## Dependencies *(optional)*

- Flutter SDK 3.9.2+
- GetX package (^4.6.6) for state management and routing
- Firebase Core package for app initialization
- flutter_localizations and intl packages for localization
- google_fonts package for loading Cairo and Plus Jakarta Sans fonts
- Material Symbols Outlined for icons (via Google Fonts or local assets)

## Out of Scope *(optional)*

- Firebase Authentication setup (will be handled in the auth feature)
- Actual screen implementations (splash, language selection, onboarding, etc.)
- Google Maps integration and custom map styling (placeholder widget only)
- Payment gateway integration
- Push notifications setup
- Image picker and Firebase Storage integration
- Analytics and crash reporting setup
- Specific business logic for trips, bids, wallets, etc.
- Firestore security rules
- Cloud Functions implementation
- Admin panel authentication and role-based access control
- Responsive breakpoints for different screen sizes (will be added as needed per feature)
