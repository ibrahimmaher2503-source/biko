# Quickstart: Admin Dashboard Web Panel

**Branch**: `013-admin-dashboard` | **Date**: 2026-03-02

## Prerequisites

1. Flutter SDK 3.x installed with web support enabled
2. Firebase project configured (same project as customer/driver apps)
3. At least one admin account created in Firebase Auth with custom claim `role: admin` or `role: super_admin`
4. Chrome browser for development

## Setup

```bash
# Switch to feature branch
git checkout 013-admin-dashboard

# Install dependencies (no new packages required — all deps already in pubspec.yaml)
flutter pub get

# Verify web support
flutter devices  # Should list Chrome and Edge
```

## Create Admin Account (One-Time)

Admin accounts are created manually. Use Firebase CLI or Cloud Shell:

```bash
# Create admin user via Firebase Auth (email/password)
# Then set custom claims via Node.js script or Firebase Admin SDK:
firebase functions:shell
> const admin = require('firebase-admin');
> admin.auth().setCustomUserClaims('ADMIN_UID', { role: 'super_admin' });
```

## Run Locally

```bash
# Run admin web panel in Chrome
flutter run -d chrome -t lib/main_admin.dart

# Run with specific port
flutter run -d chrome -t lib/main_admin.dart --web-port 8080
```

## Build for Production

```bash
# Build web release with base href for cPanel subdomain
flutter build web --release --base-href /admin/ -t lib/main_admin.dart

# Output: build/web/
```

## Deploy to cPanel

1. Build web release (see above)
2. Upload contents of `build/web/` to cPanel subdomain folder (e.g., `admin.bikeride.eg`)
3. Add admin domain to Firebase Auth authorized domains
4. Verify login works on deployed URL

## Deploy Firestore Indexes

After adding admin queries, deploy required indexes:

```bash
firebase deploy --only firestore:indexes
```

## Key Entry Points

| File | Purpose |
|------|---------|
| `lib/main_admin.dart` | App entry point |
| `lib/features/admin/screens/admin_login_screen.dart` | Login screen |
| `lib/features/admin/screens/admin_layout_shell.dart` | Layout wrapper (sidebar + topbar) |
| `lib/features/admin/controllers/admin_auth_controller.dart` | Auth logic |
| `lib/features/admin/controllers/admin_layout_controller.dart` | Sidebar state |
| `lib/core/routes/admin_pages.dart` | Route definitions |
| `lib/core/translations/app_translations.dart` | Add admin.* translation keys |

## Architecture Notes

- Admin features live under `lib/features/admin/` following the feature-first pattern
- Reuses shared core: theme, widgets, translations, models, services from `lib/core/`
- GetX for state management — all controllers use `GetxController` + `.obs`/`Obx()`
- Bindings use `Get.lazyPut()` per screen; `AdminAuthController` and `AdminLayoutController` are permanent
- Firebase Auth email/password for admin login (not phone OTP like customer/driver)
- Role check via custom claims in ID token: `admin` or `super_admin`
- Session timeout: 7 days of inactivity (tracked client-side via SharedPreferences)
- All financial writes go through Cloud Functions — never write directly to wallets/transactions from Flutter

## Testing

```bash
# Run admin-specific tests
flutter test test/features/admin/

# Run all tests
flutter test
```
