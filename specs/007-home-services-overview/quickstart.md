# Quickstart: Customer Home Services Overview

**Feature Branch**: `007-home-services-overview`
**Date**: 2026-03-02

## Prerequisites

- Flutter SDK 3.x installed
- Project dependencies installed (`flutter pub get`)
- Firebase configured (existing setup)
- Android emulator or iOS simulator available

## Quick Setup

```bash
# 1. Switch to feature branch
git checkout 007-home-services-overview

# 2. Install dependencies
flutter pub get

# 3. Run the customer app
flutter run -t lib/main_customer.dart
```

## Key Files to Modify

| File | Action | Purpose |
|------|--------|---------|
| `lib/features/home/controllers/home_controller.dart` | MODIFY | Add wallet, location, recent locations state |
| `lib/features/home/screens/customer_home_screen.dart` | REPLACE | Full redesign matching reference |
| `lib/features/home/screens/customer_main_shell.dart` | CREATE | Bottom nav shell with IndexedStack |
| `lib/features/home/widgets/*.dart` | CREATE | 6 new extracted widgets |
| `lib/core/translations/app_translations.dart` | MODIFY | Add ~30 home translation keys |
| `lib/core/routes/customer_pages.dart` | MODIFY | Update route to use main shell |

## Design Reference

- Screenshot: `stitch/home_services_overview/screen.png`
- HTML/CSS: `stitch/home_services_overview/code.html`

## Architecture Overview

```
CustomerMainShell (persistent scaffold)
├── IndexedStack (tab pages)
│   ├── Tab 0: CustomerHomeScreen (this feature)
│   │   ├── HomeHeader (location + wallet badge)
│   │   ├── HomeSearchBar (floating search)
│   │   ├── RideServiceCard ("Take a Ride" prominent card)
│   │   ├── ServiceCardGrid (Delivery + Merchant 2-col)
│   │   └── RecentLocationsSection (recent locations list)
│   ├── Tab 1: Placeholder (Rides)
│   ├── Tab 2: — (center button navigates, not a tab)
│   ├── Tab 3: Placeholder (Wallet)
│   └── Tab 4: Placeholder (Profile)
└── CustomerBottomNav (persistent bottom navigation)
```

## Theme Colors Used

| Token | Light | Dark | Usage |
|-------|-------|------|-------|
| `AppTheme.primary` | #E0062E | #E0062E | Badges, buttons, active nav, merchant gradient |
| `AppTheme.primaryDark` | #B00423 | #B00423 | Merchant gradient end |
| `surfaceElevated` | white | #2D1316 | Card backgrounds |
| `surfaceContainer` | #F1F5F9 | #1E293B | Location icon bg, search bg |
| `border` | #E2E8F0 | #334155 | Card borders |
| `textMuted` | #64748B | #94A3B8 | Secondary text, descriptions |
| Orange accent | #F97316 | #F97316 | Package delivery icon bg |

## Testing

```bash
# Run all tests
flutter test

# Run only home feature tests
flutter test test/features/home/

# Run with coverage
flutter test --coverage
```
