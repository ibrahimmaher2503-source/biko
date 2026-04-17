# Admin Panel — Architectural Audit

**Audit date:** 2026-04-17
**Scope:** `lib/main_admin.dart`, `lib/core/routes/admin_pages.dart`, `lib/features/admin/` (all subfolders: bindings, controllers, models, screens, services, utils, widgets), and web deployment artifacts (`web/index.html`).

---

## 1. Executive Summary

**Phase: Beta / Phase 1.5.**

The admin panel is structurally sound — 30 screens, 22 bindings, 10 admin-specific services, responsive 3-breakpoint `AdminLayoutShell`, custom-claims verification on every protected route, and clean GetX patterns throughout. Dashboard metrics and the 30-day revenue chart work. Wallet balance adjustments and `app_config` updates correctly go through Cloud Functions. The recent branch (`015-admin-dashboard-fixes`, commits `b85f83c`/`5b5832f`) stabilized layout and error messaging.

However, **the panel is not production-ready** until several Cloud-Function violations are closed and an audit trail is introduced. Moderation actions (document rejections, driver suspensions, user status updates, promo CRUD) currently hit Firestore directly from the client, bypassing server-side validation and leaving no record of who did what. On top of that, there is no `firestore.rules` file in the repo — so the only thing keeping these direct writes from being exploitable is whatever rules are deployed out-of-band.

**Top 5 issues:**
1. **Direct Firestore writes for moderation** — `batchRejectDocumentsByIds`, `rejectDriverCompletely`, `updateUserStatus`, and promo CRUD all bypass Cloud Functions.
2. **No audit log** — no `admin_audit_log` collection, no "who rejected this driver at what time and why" history.
3. **Custom-claims never re-verified mid-session** — revoked admin access persists until a page refresh.
4. **Base href is unconfigured** (`web/index.html:15` is still the `$FLUTTER_BASE_HREF` placeholder). The deploy script must pass `--base-href=/admin/`.
5. **No dispute / appeals flow** — rejected drivers have no path to resubmit documents or challenge a decision.

---

## 2. Authentication & Authorization

### `AdminAuthGuard`
`lib/core/routes/admin_pages.dart:293–304`:
```dart
class AdminAuthGuard extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final auth = Get.find<AdminAuthController>();
    if (auth.isCheckingAuth.value) return null;          // async token verify in flight
    if (!auth.isAuthenticated.value) {
      return const RouteSettings(name: AppRoutes.adminLogin);
    }
    return null;
  }
}
```
**Verdict ✓:** Middleware correctly defers redirect while the token is being verified and enforces the redirect otherwise. Applied to every protected route.

### Custom-claims verification
`features/admin/controllers/admin_auth_controller.dart:34–61` and `:63–120`:
- `checkAdminAccess()` uses `AuthService.getIdTokenResult()` and accepts `role == 'admin' || 'super_admin'`.
- `signIn(email, password)` re-verifies the claim after sign-in and explicitly signs non-admins back out.

**Verdict ✓ for correctness, ✗ for robustness:**
- Role is only checked at controller init and at sign-in. No periodic re-verification.
- If an admin's claim is revoked server-side, they keep full access until the page is refreshed.
- No audit log entry when a non-admin attempts sign-in (missed signal for intrusion detection).

### Session persistence
Firebase Auth uses IndexedDB on web — session survives refresh. No 2FA. No session timeout. Long-lived tabs + stolen laptop = full access.

---

## 3. Dashboard Completeness

`features/admin/screens/admin_dashboard_screen.dart` + `features/admin/controllers/admin_dashboard_controller.dart`.

### Metrics loaded via `_loadStats()` (`:49–110`)
- Trips today (count)
- Revenue today (commission sum)
- Pending document reviews
- Total customers
- Total drivers
- Weekly trips
- Weekly revenue
- Cancellation rate
- Drivers online (RTDB stream)

### Revenue chart — `loadRevenueChart()` (`:122–174`)
Last 30 days, daily aggregation, completed trips only, commission-based.

### Recent trips — `loadRecentTrips()` (`:176–182`)
10 most recent.

### Refresh
Manual button only (added in commit `b85f83c`). **No auto-refresh**; no stale-data indicator ("updated 5 min ago"); no drill-down on metric cards.

---

## 4. CRUD Operations by Entity

### Customers (`admin_customers_screen.dart`, `admin_customer_detail_screen.dart`)
| Operation | Path | Risk |
|---|---|---|
| List (paginated, 25/page) | `getPaginatedUsers(type: customer)` | Safe (read) |
| Detail | Firestore read of user doc + trips | Safe |
| Search by phone / name | `searchUsersByPhone`, `searchUsersByName` | Safe |
| Suspend / delete | **NOT IMPLEMENTED** | — |

### Drivers (`admin_drivers_screen.dart`, `admin_driver_detail_screen.dart`, `admin_approval_queue_screen.dart`)
| Operation | Path | Risk |
|---|---|---|
| List (paginated) | Read | Safe |
| Detail (user + profile + docs) | Read | Safe |
| Reject documents | `batchRejectDocumentsByIds` — **direct Firestore** | ✗ Violation |
| Reject driver (full) | `rejectDriverCompletely` — **direct Firestore** | ✗ Violation |
| Update status | `updateUserStatus` — **direct Firestore** | ✗ Violation |

### Trips (`admin_trips_screen.dart`, `admin_trip_detail_screen.dart`)
| Operation | Path | Risk |
|---|---|---|
| List (filterable by type/status/date) | Read | Safe |
| Detail (trip + bids) | Read | Safe |
| Cancel / refund / adjust price | **NOT IMPLEMENTED** | — |

### Wallets (`admin_wallet_monitoring_screen.dart`, `features/admin/services/wallet_service.dart`)
| Operation | Path | Risk |
|---|---|---|
| Summary | `getWalletSummary` (CF + Firestore fallback) | Safe |
| Activity (filtered) | Direct Firestore read | Safe |
| Adjust balance | `adjustWallet(userUid, amount, reason)` — **Cloud Function** at `:103–118` | ✓ Correct |

### App config (`admin_config_screen.dart`)
- Load: `getAppConfig()` — read.
- Save: `callCloudFunction('updateAppConfig', configData)` — **Cloud Function** ✓.
- Super-admin check enforced in controller at `:104–112` (not as middleware — see §9).

### Promos (`admin_promos_screen.dart`)
- List: direct read — safe.
- Create / update: `createPromoCode`, `updatePromoCode` — **direct Firestore writes** (`:815–845`). ✗ Violation.
- Delete: NOT IMPLEMENTED.

### Notifications (`admin_notifications_screen.dart`)
- List sent notifications.
- **Compose/send new:** NOT IMPLEMENTED.

### Referrals (`admin_referral_screen.dart`)
- View all / rewarded.
- Manual reward: NOT IMPLEMENTED.

---

## 5. Cloud Functions vs Direct Firestore

### Violations

| # | Method | File:Lines | Issue |
|---|---|---|---|
| 1 | `batchRejectDocumentsByIds` | `admin_firestore_service.dart:443–461` | Batch update on `documents/`; no server-side admin-role check, no audit, no FCM to driver. |
| 2 | `rejectDriverCompletely` | `admin_firestore_service.dart:558–587` | Batch write across `users/` + `documents/`; no atomic server logic, no log, no notification. |
| 3 | `updateUserStatus` | `admin_firestore_service.dart:463–468` | Direct `doc.update` on `users/`; used by multiple controllers for approve/suspend. |
| 4 | `createPromoCode` / `updatePromoCode` | `admin_firestore_service.dart:815–845` | Direct writes; no validation of discount range, expiry, or max uses. |

### Correct usage
- `adjustWallet` — Cloud Function ✓
- `updateAppConfig` — Cloud Function ✓
- All reads — direct Firestore is acceptable (rules enforce access).

**The fix pattern** for each violation: a Cloud Function that (a) verifies caller's `role` claim, (b) performs the atomic mutation, (c) writes an `admin_audit_log/{docId}` entry with `{admin_uid, action, target_uid, reason, timestamp}`, (d) fires an FCM to the affected user where relevant.

---

## 6. Admin Layout & Navigation

### `AdminLayoutShell` coverage
All 27 protected routes wrap their screen in `AdminLayoutShell`. Login and 404 are excluded (correct).

### Responsive breakpoints — `admin_layout_controller.dart:34–45`
```dart
static const double _mobileBreakpoint = 768;
static const double _tabletBreakpoint = 1200;
```
- Mobile (<768 px): drawer navigation.
- Tablet (768–1200 px): collapsed sidebar.
- Desktop (>1200 px): expanded sidebar.

Gaps: no landscape-mode detection; 768 is generous for tablets (a 5" Android phone in landscape crosses it).

### Sidebar
21 nav items in `admin_sidebar.dart` / `admin_layout_controller.dart:49–156` covering dashboard, approvals, customers, drivers, documents, trips, financial sub-module (6 sub-items), transactions, reports, settlement, analytics, promos, notifications, referrals, config (super-admin only at `:177–185`).

Missing: breadcrumbs; "back" affordance on detail screens.

### Topbar
Not deeply audited. Likely missing a locale switcher, which is needed if admins want to preview Arabic UI of customer-facing strings.

---

## 7. Controllers & Bindings Maturity

### Binding pattern — consistent
```dart
class AdminDashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AdminDashboardController>(AdminDashboardController.new);
  }
}
```
All 22 bindings follow the same lazy-put pattern. Memory-efficient.

### Controller pattern — consistent
```dart
final items = <T>[].obs;
final isLoading = false.obs;
final selectedItem = Rx<T?>(null);

@override void onInit() { super.onInit(); load(); }
@override void onClose() { _subscription?.cancel(); super.onClose(); }

try { ... } catch (e, stack) {
  debugPrint('error: $e\n$stack');
  AppSnackbar.error('key'.tr);
} finally { isLoading.value = false; }
```

**Strengths:** stream cleanup, pagination on all list screens, consistent error snackbars, dirty-tracking in `admin_config_controller.dart:29–44`.

**Gaps:** no search debouncing (keystroke-per-request on some screens), no offline cache, no numeric validation on config fields, no retry() method on error — user has to manually refresh.

---

## 8. Localization

`lib/main_admin.dart:46` → `locale: const Locale('en')`, `fallbackLocale: const Locale('ar')`. RTL wrapper at `:50–58` flips direction if locale is Arabic.

All user-facing strings use `.tr`. `web/index.html` is hard-coded `<html lang="en">` — not using the GetX locale, which is fine since admin is English-first.

---

## 9. Rule Violations (admin-specific)

| # | File | Line(s) | Violation |
|---|---|---|---|
| 1 | `features/admin/services/admin_firestore_service.dart` | 443–461 | Direct Firestore batch for document rejection. |
| 2 | same | 558–587 | Direct Firestore batch for full driver rejection. |
| 3 | same | 463–468 | Direct `doc.update` for user status. |
| 4 | same | 815–845 | Direct Firestore CRUD for promo codes. |
| 5 | `core/routes/admin_pages.dart` | 139–143 | Config screen's super-admin check is in the controller, not in a middleware — allowing a regular admin to reach the screen and see UI flashes before being kicked. |

---

## 10. Missing Tools (NOT IMPLEMENTED)

| Feature | Impact |
|---|---|
| **Admin audit log** | HIGH — no accountability; fails KYC compliance narrative. |
| **Dispute / appeals flow** | HIGH — rejected drivers cannot challenge. |
| **Driver verification queue** with prioritization & bulk actions | MEDIUM — manual iteration at scale. |
| **App config validator** (sanity checks on fares / commission ranges) | MEDIUM — misconfig can break pricing globally. |
| **Send notification** composer | MEDIUM — cannot push announcements. |
| **Trip cancel / refund / price adjust** | MEDIUM — no dispute resolution path. |
| **Analytics export (CSV / PDF)** | MEDIUM — no way to hand data to finance. |
| **Bulk operations** (multi-suspend, multi-promo) | MEDIUM — tedious at scale. |
| **2FA for admin sign-in** | MEDIUM — single-factor in a money-touching panel. |
| **Scheduled reports** | LOW — manual for now. |
| **Fine-grained permissions** (view-only vs approve-only) | LOW — currently just admin vs super-admin. |
| **Breadcrumbs / deep linking UX** | LOW. |

---

## 11. Web-Specific Concerns

### Base href — broken
`web/index.html:15` still reads `<base href="$FLUTTER_BASE_HREF">`. The cPanel deployment at `/admin/` requires either:
- A post-build `sed` step replacing the placeholder, or
- Passing `--base-href=/admin/` to `flutter build web` (already in `CLAUDE.md` Build commands, but not verified as part of a CI pipeline).

If the placeholder ships unreplaced, every route 404s.

### SEO / security headers
- `<meta name="description">` = "A new Flutter project." — generic.
- No `robots.txt` (admin panel should be `User-agent: * / Disallow: /`).
- No CSP header, no `X-Frame-Options`, no `X-Content-Type-Options`.
- No server-side configuration in this repo for cPanel hosting.

### Auth persistence
Firebase Auth uses IndexedDB on web by default — auth state should survive refreshes. Not explicitly tested in this codebase; no fallback if IndexedDB is disabled.

### Exports / downloads
No file-download flows exist in screens. `lib/core/services/web_download*.dart` stubs are present but unused by admin screens. Finance reports have no "Download CSV" action.

### Responsive
3 breakpoints via MediaQuery. No explicit font-size scaling tested. No landscape phone handling.

---

## 12. Current Phase & Next Steps

**Phase: Beta / Phase 1.5.**

Ordered action items:

### Tier 1 — Blockers
1. **[P0, 1–2 d]** Migrate `rejectDriverCompletely` + `batchRejectDocumentsByIds` to a `rejectDriver` / `rejectDocuments` Cloud Function. Require `role: admin`, write `admin_audit_log` entry, send FCM.
2. **[P0, 1 d]** Migrate `updateUserStatus` to a `setUserStatus` Cloud Function with the same audit pattern.
3. **[P0, 1 d]** Migrate `createPromoCode` / `updatePromoCode` to Cloud Functions. Validate: expiry > now, 0 < discount ≤ 100, `max_uses` > 0.
4. **[P0, 0.5 d]** Introduce `admin_audit_log` Firestore collection. Every moderation mutation writes `{admin_uid, action, target_uid, reason, timestamp}`.
5. **[P0, 0.5 d]** CI step or deploy script that guarantees `--base-href=/admin/` is passed. Verify with a smoke test against a staging cPanel.

### Tier 2 — High-value
6. **[P1, 2 d]** Build dispute/appeals UI: rejected drivers see a "Contest" screen; admin gets a queue; re-upload allowed.
7. **[P1, 1 d]** `admin_audit_log_screen.dart` — date/admin/action filters + CSV export.
8. **[P1, 1 d]** Send-notification composer: target=(all users | all drivers | all customers | uid list), invokes `sendNotification` CF.
9. **[P1, 0.5 d]** Prioritize approval queue by submission date; add bulk approve/reject with per-row reason.
10. **[P1, 0.5 d]** Periodic re-verification of admin claim — every 10 min call `getIdTokenResult(forceRefresh: true)` and sign out on role change.

### Tier 3 — Quality
11. **[P2, 1 d]** 2FA for admin sign-in (TOTP, stored per-admin).
12. **[P2, 0.5 d]** Real-time `app_config` form validation (min/max fare, commission range sanity).
13. **[P2, 1 d]** Analytics export (CSV/PDF) via signed-URL Cloud Function.
14. **[P2, 0.5 d]** Auto-refresh on dashboard (30 s tick with stale indicator).
15. **[P2, 0.5 d]** Move config-screen super-admin check into a `SuperAdminGuard` middleware.

### Tier 4 — Deploy hardening
16. **[Deploy, 0.5 d]** Add `robots.txt` to `web/` blocking indexing. Configure CSP + X-Frame-Options in cPanel `.htaccess`.
17. **[Deploy, 0.5 d]** Replace generic meta description; add app-specific favicons.

### Tier 5 — Testing
18. **[Testing, 3 d]** Unit tests for all admin controllers (GetX test pattern). Widget tests for `AdminLayoutShell` across breakpoints. Integration tests against Firebase Emulator for the migrated Cloud Functions.

---

## Key Metrics

| Metric | Status | Notes |
|---|---|---|
| Auth guard | ✓ | Custom claims verified on init + sign-in |
| Protected-route coverage | ✓ | 27 of 27 non-login routes |
| Layout shell coverage | ✓ | 100% |
| Responsive design | ⚠ Partial | 3 breakpoints; no landscape |
| CRUD coverage | ⚠ ~70% | Many entities read-only from client |
| Cloud Function usage | ⚠ 50% | Wallet + config only; docs/promos/user-status direct |
| Pagination | ✓ | All lists 25/page |
| Error handling | ✓ Standard | Consistent `AppSnackbar` pattern |
| Localization | ✓ English default | RTL wrapper present |
| Audit trail | ✗ | No `admin_audit_log` collection |
| Web deployment | ⚠ | Base href unconfigured |
| Offline support | ✗ | None |
| 2FA | ✗ | None |
| Test coverage | ✗ | Zero |

---

## Conclusion

The admin panel is **architecture-sound and feature-rich** (30 screens, responsive, clean bindings) but **operationally immature**. The four Cloud-Function violations plus the missing audit log are the compliance story. The missing dispute flow is the driver-experience story. The unconfigured base href is the "doesn't load when deployed" story. Close those five items and you have a production-ready admin panel; everything else is quality-of-life iteration.
