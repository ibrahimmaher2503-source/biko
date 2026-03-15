# Research: Customer Home Services Overview

**Feature Branch**: `007-home-services-overview`
**Date**: 2026-03-02

## Research Tasks & Findings

### 1. Bottom Navigation Architecture in Flutter + GetX

**Decision**: Use `CustomerMainShell` widget with `IndexedStack` + `Obx` for tab switching

**Rationale**:
- `IndexedStack` preserves state of all tab pages (no rebuild when switching tabs)
- GetX `Obx` reactive wrapper for the selected tab index
- The center elevated "+" button requires custom positioning (`Stack` + `Positioned`)
- Each tab page gets its own controller via GetX bindings
- The shell is registered as the `customerHome` route, replacing the direct `CustomerHomeScreen`

**Alternatives considered**:
- `GetX nested navigation` (Navigator 2.0 per tab): Overkill for this feature, adds complexity. Rejected because tabs share no deep linking requirements.
- `BottomNavigationBar` with `PageView`: Allows swipe between tabs but design doesn't call for horizontal swiping. Rejected.
- `Scaffold.bottomNavigationBar`: Material default doesn't support the elevated center button easily. Custom widget preferred.

### 2. Map Background Implementation

**Decision**: Use the existing `assets/images/backgrounds/cairo_map.png` as a static grayscale background with gradient overlay

**Rationale**:
- The spec explicitly states: "The map background uses a static map image or grayscale placeholder initially. Live interactive maps are a separate feature."
- The `cairo_map.png` asset already exists in `assets/images/backgrounds/`
- Apply `ColorFiltered` with grayscale matrix + opacity, then overlay a `LinearGradient` from white/60% → transparent → white/90% (matching the stitch HTML)
- In dark mode: gradient from `backgroundDark/60%` → transparent → `backgroundDark/90%`

**Alternatives considered**:
- Google Maps SDK static map: Requires API key, network call, adds latency. Rejected for initial implementation.
- Generated vector map: Too complex for marginal visual benefit. Rejected.

### 3. Motorcycle Illustration Asset

**Decision**: Add a motorcycle PNG illustration to `assets/images/home/motorcycle.png`

**Rationale**:
- The reference design shows a 3D-style red motorcycle illustration on the ride card
- The spec states: "The motorcycle illustration on the ride card uses a local asset image. If no asset is available, a motorcycle icon placeholder is used."
- Implementation: Try to load the asset, fallback to `Icons.two_wheeler` icon if asset is missing
- The image is displayed at ~112x112dp with a subtle drop shadow

**Alternatives considered**:
- Icon-only: Doesn't match reference design. Used as fallback only.
- SVG illustration: PNG is simpler for 3D-style illustrations. Rejected.

### 4. Wallet Balance Data Source

**Decision**: Read from `UserModel.walletBalance` loaded in `HomeController.onInit()`

**Rationale**:
- `UserModel` already has a `walletBalance` field (type `double`)
- The existing `_loadUserData()` method in `HomeController` already fetches the user model
- Simply expose `walletBalance` as an observable `RxDouble`
- The spec states: "The wallet balance is read from the user's wallet document. Real-time wallet updates are not required on this screen (balance refreshes on screen load)."
- Error state: Show "---" if fetch fails (per edge case spec)

**Alternatives considered**:
- Separate wallet stream listener: Over-engineering for a screen-load refresh. Rejected.
- Read from `wallets/{uid}` directly: UserModel already mirrors the balance. Rejected.

### 5. Location Display Strategy

**Decision**: Use `geolocator` for coordinates + `geocoding` for reverse geocoding to city name. Cache the result.

**Rationale**:
- The header shows "Current Location" label + city/area name (e.g., "Banha, Al-Qalyubia")
- `geolocator` package (already in pubspec) provides GPS coordinates
- `geocoding` package (already in pubspec) converts lat/lng to place name
- Cache the last known location in `SharedPreferences` for offline/quick display
- If location services disabled: Show "Location unavailable" per edge case spec
- Permission request handled at this screen (if not already granted)

**Alternatives considered**:
- Google Places API: Overkill for reverse geocoding a single point. Rejected.
- Fixed "Cairo, Egypt": Doesn't match the dynamic location display in design. Rejected.

### 6. Recent Locations Data Source

**Decision**: Initially use placeholder data. When trip history is implemented, read from Firestore trip history.

**Rationale**:
- The spec states: "Recent locations are read from trip history. The initial implementation may show hardcoded placeholder items if the trip history feature is not yet built, with the section hidden when no data exists."
- Create a simple `RecentLocation` data class (name, address, lat, lng, icon type)
- In `HomeController`: expose `RxList<RecentLocation>` — populated with placeholders for demo, empty in production (section hidden)
- The demo data matches the reference: "Benha University" and "Office"

**Alternatives considered**:
- SharedPreferences local storage: Good for future, but trip history will be the real source. Keep simple for now. Rejected for initial implementation.

### 7. RTL Layout Strategy

**Decision**: Use `Directionality.of(context)` for directional elements. Flutter handles most RTL automatically.

**Rationale**:
- The app already wraps with `Directionality` widget in `main_customer.dart`
- `Row`, `Padding`, `Align` etc. automatically flip in RTL
- Chevron icons on recent locations need manual flipping: use `Transform.flip` when `textDirection == TextDirection.rtl`
- The "POPULAR" badge, card layouts, and search bar are inherently direction-agnostic
- Bottom nav icons don't need flipping (symmetric)

**Alternatives considered**:
- Separate RTL/LTR widget variants: Duplication, unnecessary. Rejected.

### 8. Dark Mode Color Mapping

**Decision**: Use existing `AppColorsExtension` semantic colors + theme `ColorScheme` for all adaptations

**Rationale**:
- The stitch HTML defines dark mode variants (e.g., `dark:bg-slate-800`, `dark:text-white`)
- Map to Flutter:
  - Card backgrounds: `AppColorsExtension.surfaceElevated` (white / dark surface)
  - Borders: `AppColorsExtension.border` and `borderSubtle`
  - Muted text: `AppColorsExtension.textMuted`
  - Primary text: `Theme.of(context).colorScheme.onSurface`
  - Search bar bg: `AppColorsExtension.surfaceElevated`
  - Header bg: `surfaceElevated` with 95% opacity
- Gradient overlay on map: adapts from/to based on `Theme.of(context).scaffoldBackgroundColor`

**Alternatives considered**:
- Hardcoded dark colors: Violates theme system. Rejected.

### 9. Navigation Targets (Placeholder Handling)

**Decision**: Navigate to existing routes where available, show snackbar/placeholder for unbuilt features

**Rationale**:
- Routes already defined in `AppRoutes` but many screens don't exist yet
- "Book Now" / Ride card → Navigate to `AppRoutes.customerTripCreate` (placeholder if not built)
- Delivery card → Navigate to `AppRoutes.customerTripCreate` with delivery type
- Merchant card → Show "Coming Soon" via `AppSnackbar.info()`
- Wallet badge → Navigate to `AppRoutes.customerWallet` (placeholder)
- Search bar → Navigate to `AppRoutes.customerTripPickup` (placeholder)
- Recent location tap → Navigate to ride flow with pre-filled destination
- Bottom nav tabs: Home (current), Rides (placeholder), Wallet (placeholder), Profile (placeholder)
- For unbuilt screens: Show a simple placeholder widget with "Coming Soon" text

**Alternatives considered**:
- Block navigation entirely: Poor UX, user can't see the flow. Rejected.
