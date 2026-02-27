# Data Model: Core Theme System and Shared Widgets

**Feature**: 001-theme-widgets-setup
**Date**: 2026-02-27

## Overview

This document defines the data structures, configurations, and entities for the theme system and shared widget library. These are conceptual models that inform implementation without prescribing specific code structure.

## Core Entities

### 1. Theme Configuration

**Purpose**: Centralized design token system providing colors, typography, spacing, and styling rules for all apps.

**Key Attributes**:
- Color palette (light mode): primary, primary dark, background, surface, text colors, neutral tint
- Color palette (dark mode): same semantic colors with dark-appropriate values
- Typography definitions: font families (Cairo, Plus Jakarta Sans), weights (300-800), sizes, line heights
- Spacing scale: consistent padding/margin values (4dp, 8dp, 12dp, 16dp, 24dp, 32dp)
- Border radius values: default (4-8dp), large (8-16dp), xl (12-24dp), full (9999)
- Shadow/elevation styles: elevation levels 0-24
- Icon theme: color, size, opacity

**Relationships**:
- Used by all widgets in the widget library
- Referenced by all screens across three apps
- Controlled by user preferences (theme mode, locale)

**State Transitions**:
```
Light Mode <--> Dark Mode (via user preference or system setting)
```

**Validation Rules**:
- All colors must have both light and dark variants
- Font families must be available (either bundled or from google_fonts)
- Spacing values must be multiples of 4dp for pixel-perfect rendering
- Color contrast ratios must meet WCAG AA standards (4.5:1 for text, 3:1 for UI)

---

### 2. Localization Asset

**Purpose**: Externalized strings for all UI text supporting Arabic (RTL) and English (LTR).

**Key Attributes**:
- Language code: 'ar' or 'en'
- Text direction: RTL or LTR
- String key-value pairs (flat JSON structure)
- Fallback behavior (use English if Arabic key missing)

**File Structure**:
```json
{
  "common": {
    "app_name": "BikeRide",
    "ok": "موافق / OK",
    "cancel": "إلغاء / Cancel",
    "save": "حفظ / Save",
    "loading": "جاري التحميل / Loading"
  },
  "buttons": {
    "get_started": "ابدأ الآن / Get Started",
    "verify": "تحقق / Verify",
    "complete_profile": "إكمال الملف الشخصي / Complete Profile"
  },
  "validation": {
    "required_field": "هذا الحقل مطلوب / This field is required",
    "invalid_phone": "رقم الهاتف غير صالح / Invalid phone number"
  }
}
```

**Relationships**:
- Loaded by app initialization based on user locale preference
- Used by all widgets that display text
- Updated when user changes language in settings

**State Transitions**:
```
Arabic (RTL, Cairo font) <--> English (LTR, Plus Jakarta Sans)
```

**Validation Rules**:
- All keys in ar.json must exist in en.json (and vice versa)
- String values must not contain hardcoded directionality (no embedded LTR/RTL marks)
- Placeholder syntax consistent: {variable_name}

---

### 3. Widget Variant Configuration

**Purpose**: Defines visual variants for shared widgets (primary, secondary, outline, etc.).

**Key Attributes**:
- Variant name: enum (primary, secondary, outline, text, danger)
- Background color: from theme color scheme
- Text color: from theme color scheme
- Border style: none, solid, or theme-defined
- Elevation: 0-24dp
- State styles: default, hovered, pressed, disabled, loading

**Example Variants (AppButton)**:
```
Primary:
  - Background: theme.colorScheme.primary (#e0062e)
  - Text: white
  - Elevation: 2dp
  - Border: none

Secondary:
  - Background: theme.colorScheme.surface
  - Text: theme.colorScheme.primary
  - Elevation: 0dp
  - Border: 1dp solid primary

Outline:
  - Background: transparent
  - Text: theme.colorScheme.primary
  - Elevation: 0dp
  - Border: 1dp solid primary

Text:
  - Background: transparent
  - Text: theme.colorScheme.primary
  - Elevation: 0dp
  - Border: none
```

**Relationships**:
- Each widget (AppButton, AppCard) has its own variant definitions
- Variants automatically adapt to theme mode (light/dark)
- Disabled state overlays 50% opacity on all variants

**Validation Rules**:
- All variants must be visually distinct
- Disabled state must be visually distinguishable from enabled
- Loading state must show progress indicator without layout shift

---

### 4. App Route Configuration

**Purpose**: Centralized route name constants for navigation in all three apps.

**Key Attributes**:
- Route name: string constant (e.g., '/splash', '/home', '/auth/otp')
- Route path: hierarchical path structure
- App scope: customer, driver, admin, or shared
- Parameters: typed route parameters (optional)

**Route Organization**:
```
Shared Routes:
  /splash
  /language-selection
  /onboarding

Customer Routes:
  /customer/home
  /customer/trip/create
  /customer/trip/tracking
  /customer/wallet
  /customer/profile

Driver Routes:
  /driver/home
  /driver/trip/active
  /driver/earnings
  /driver/documents

Admin Routes:
  /admin/dashboard
  /admin/users
  /admin/trips
  /admin/config
```

**Relationships**:
- Used by GetX navigation (Get.toNamed())
- Maps to screen widgets in each app
- Route guards check authentication state

**Validation Rules**:
- No duplicate route names across apps
- All routes must start with '/'
- Hierarchical routes use '/' separator

---

### 5. Firebase Configuration

**Purpose**: Platform-specific Firebase initialization options.

**Key Attributes**:
- API key: platform-specific
- Project ID: bikeride-eg (example)
- App ID: platform-specific (Android, iOS, Web)
- Messaging sender ID: for FCM
- Storage bucket: for Firebase Storage

**Platform Variants**:
- Android: from google-services.json
- iOS: from GoogleService-Info.plist
- Web: from Firebase console config object

**Relationships**:
- Loaded during app initialization before runApp()
- Used by Firebase services (Auth, Firestore, Realtime DB, Storage, Messaging)
- Same Firebase project across all three apps

**State Transitions**:
```
Uninitialized --> Initializing --> Ready --> Error (retry flow)
```

**Validation Rules**:
- All required fields must be present
- Firebase project must exist and be accessible
- Network connection required for initialization (cached after first success)

---

### 6. User Preference State

**Purpose**: Persisted user settings for theme mode and language.

**Key Attributes**:
- Theme mode: system, light, or dark
- Language: 'ar' or 'en'
- Is first launch: boolean
- Last updated: timestamp

**Storage**:
- Local: SharedPreferences (immediate access on app start)
- Remote: Firestore users/{uid} document (synced after authentication)

**Relationships**:
- Controls Theme Configuration selection (light/dark)
- Controls Localization Asset selection (ar/en)
- Synchronized across devices after authentication

**State Transitions**:
```
Initial (system defaults) --> User changed --> Persisted locally --> Synced to Firestore
```

**Validation Rules**:
- Theme mode must be one of: system, light, dark
- Language must be one of: ar, en
- Defaults: theme = system, language = ar (Arabic default per CLAUDE.md)

---

## Entity Relationships Diagram

```
┌─────────────────────┐
│  User Preference    │
│  - theme_mode       │
│  - language         │
└──────────┬──────────┘
           │ controls
           ↓
┌─────────────────────┐         ┌──────────────────────┐
│ Theme Configuration │────────→│   Widget Variants    │
│ - colors            │  uses   │ - primary            │
│ - typography        │         │ - secondary          │
│ - spacing           │         │ - outline            │
└──────────┬──────────┘         └──────────────────────┘
           │ applies to
           ↓
┌─────────────────────┐
│   Shared Widgets    │
│ - AppButton         │
│ - AppTextField      │
│ - AppCard           │
│ - AppLoading        │
│ - AppSnackbar       │
└─────────────────────┘
           │ used by
           ↓
┌─────────────────────┐         ┌──────────────────────┐
│   App Screens       │────────→│  Localization Asset  │
│ - Customer app      │  uses   │ - ar.json            │
│ - Driver app        │         │ - en.json            │
│ - Admin panel       │         └──────────────────────┘
└─────────────────────┘
           │ navigates via
           ↓
┌─────────────────────┐
│ App Route Config    │
│ - /customer/*       │
│ - /driver/*         │
│ - /admin/*          │
└─────────────────────┘
```

## Validation Summary

All entities have:
- ✅ Clear purpose and attributes defined
- ✅ Relationships to other entities documented
- ✅ State transitions identified (where applicable)
- ✅ Validation rules specified
- ✅ Storage/persistence strategy defined

Ready to proceed to contracts definition.
