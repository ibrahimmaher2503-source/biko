# Research: Admin Dashboard Web Panel

**Branch**: `013-admin-dashboard` | **Date**: 2026-03-02
**Phase**: 0 — Outline & Research

## Research Summary

No NEEDS CLARIFICATION markers remained in the Technical Context. All technology choices are established in the existing codebase. Research focused on best practices for the specific admin dashboard patterns within the existing BikeRide architecture.

---

## R1: Admin Authentication via Email/Password with Custom Claims

**Decision**: Use Firebase Auth `signInWithEmailAndPassword()` combined with `getIdTokenResult()` to verify custom claims (`role: admin` or `role: super_admin`) after sign-in. Redirect non-admin users to login with error message.

**Rationale**: The existing codebase uses Firebase Auth for phone OTP (customer/driver). Admin uses email/password — a separate auth method on the same Firebase Auth project. Custom claims are the standard Firebase approach for role-based access, already referenced in CLAUDE.md's Cloud Functions reference (`role: admin` custom claim).

**Alternatives considered**:
- Firestore-based role check (read user doc for role field) — Rejected: custom claims are more secure, cannot be spoofed client-side, and are checked before any Firestore read.
- Separate Firebase project for admin — Rejected: adds unnecessary complexity; same project allows admin to query all user data directly.

**Implementation notes**:
- Admin accounts created manually via Firebase Console or CLI (per spec assumption)
- Custom claims set via Firebase Admin SDK (`setCustomUserClaims`)
- Session persistence: Firebase Auth `browserLocalPersistence` (survives browser restart)
- 7-day timeout: Track last activity timestamp in SharedPreferences; check on app init; force re-auth if >7 days

---

## R2: Responsive Layout Shell Pattern for Flutter Web

**Decision**: Build a `AdminLayoutShell` widget that wraps all authenticated screens. Uses `LayoutBuilder` to detect breakpoints: desktop (>1200px) shows expanded 240px sidebar, tablet (768-1200px) shows 72px icon-only sidebar, mobile (<768px) hides sidebar behind a `Drawer`. Topbar is always visible with title, global search, and admin info.

**Rationale**: Flutter Web's `LayoutBuilder` is the standard approach for responsive layouts. The shell pattern ensures consistent navigation across all screens without repeating layout code.

**Alternatives considered**:
- MediaQuery-based approach — Rejected: `LayoutBuilder` responds to the content area, which is more accurate when sidebar width changes.
- `NavigationRail` widget — Rejected: too limited for the expanded/collapsed/drawer trio needed here. Custom sidebar gives full control over badge display and active state.

**Implementation notes**:
- `AdminLayoutController` (registered as permanent in main_admin.dart) manages sidebar state
- Sidebar items defined as a list of `SidebarItem` objects with icon, label, route, and optional badge stream
- Active route detection via `Get.currentRoute`
- Pending document count badge: real-time Firestore query on `documents` collection where `status == 'pending'`

---

## R3: Real-time Dashboard Stats (Drivers Online Count)

**Decision**: Use Firebase Realtime Database listener on `/driver_locations/` to count online drivers (where `is_online == true`). Firestore snapshots for trips today, revenue today, and pending reviews. Combine into a reactive `DashboardStats` observable.

**Rationale**: Driver online status lives in Realtime DB (per CLAUDE.md architecture). Other stats (trips, revenue) are in Firestore. The hybrid approach matches the established data architecture.

**Alternatives considered**:
- Poll Firestore for driver count — Rejected: driver online status is in Realtime DB, not Firestore. Querying Firestore `driver_profiles` where `is_online == true` would work but adds latency vs Realtime DB.
- Server-sent aggregation via Cloud Function — Rejected: unnecessary for 1-5 admins; client-side aggregation is sufficient.

**Implementation notes**:
- Realtime DB: `FirebaseDatabase.instance.ref('driver_locations').onValue` stream filtered for `is_online == true`
- Firestore trips today: query `trips` where `created_at >= startOfDay` with snapshot listener
- Revenue: sum `commission_amount` from completed trips today
- Pending reviews: count `documents` where `status == 'pending'`
- Chart data: query last 30 days of completed trips, aggregate daily commission

---

## R4: Paginated Data Tables with Search and Filters

**Decision**: Build a reusable `AdminDataTable` widget that accepts column definitions, a data source callback, and filter widgets. Uses Firestore cursor-based pagination (`.startAfterDocument()`) with configurable page size (default 25). Search is implemented client-side for small datasets (<1000 docs) or via Firestore text-prefix query for name/phone fields.

**Rationale**: Firestore doesn't support full-text search. For the admin panel with small user base, client-side filtering after fetching a page is acceptable. Phone number searches use exact prefix match which Firestore handles well.

**Alternatives considered**:
- Offset-based pagination — Rejected: Firestore doesn't support skip/offset efficiently; cursor-based is the recommended approach.
- Algolia/Typesense for search — Rejected: adds external dependency for a 1-5 admin use case. Firestore prefix queries + client-side filtering is sufficient.

**Implementation notes**:
- Cursor pagination: store last document snapshot, use `.startAfterDocument()` for next page
- Search by phone: Firestore `.where('phone', isGreaterThanOrEqualTo: query).where('phone', isLessThan: query + '\uf8ff')`
- Search by name: Same prefix approach on `name` field
- Status filters: `.where('status', isEqualTo: filterValue)` compound with pagination
- Composite indexes needed for compound queries (status + orderBy created_at)

---

## R5: Document Image Preview and Full-Size Viewer

**Decision**: Use `cached_network_image` (already in pubspec) for document thumbnails. Full-size viewing uses a `Dialog` with an `InteractiveViewer` for zoom/pan capability. Images loaded directly from Firebase Storage download URLs stored in the `documents` collection.

**Rationale**: `cached_network_image` is already a project dependency. `InteractiveViewer` is a built-in Flutter widget ideal for pinch-to-zoom on document images in a web browser.

**Alternatives considered**:
- Native browser image viewer (open in new tab) — Rejected: breaks admin workflow flow, forces context switching.
- Custom image gallery package — Rejected: overkill for 3 document images per driver.

---

## R6: CSV Export from Flutter Web

**Decision**: Generate CSV content as a string in Dart, then trigger browser download using `dart:html` `AnchorElement` with `Url.createObjectUrlFromBlob()`. For large exports (>10K rows), paginate Firestore reads in chunks of 500 documents and stream into the CSV buffer.

**Rationale**: Flutter Web can generate files client-side without a backend. The `dart:html` approach is the standard Flutter Web file download pattern.

**Alternatives considered**:
- Cloud Function endpoint to generate CSV server-side — Rejected: adds unnecessary function, and admin count is 1-5 users. Client-side generation is fast enough.
- Excel format (xlsx) — Rejected: adds a package dependency. CSV is sufficient for the admin use case and opens in Excel anyway.

**Implementation notes**:
- Financial export: query transactions with active filters, build CSV rows
- Analytics export: aggregate chart data into CSV format
- Max 10K rows per spec requirement (SC-008: <15 seconds)
- Use `universal_html` package for web-compatible dart:html access if needed

---

## R7: Admin Role-Based UI Restrictions

**Decision**: Store the admin's role (`admin` or `super_admin`) in the `AdminAuthController` as a reactive observable. Sidebar items check role to show/hide config and admin management sections. Config screen checks role on init and redirects regular admins with a snackbar message. Button-level restrictions use `Obx()` to disable/hide actions.

**Rationale**: Client-side UI restrictions are for UX only. The real security gate is the Cloud Function verifying `role: admin` or `role: super_admin` custom claims before executing privileged operations.

**Alternatives considered**:
- Middleware/route guard per screen — Rejected for config screens: too heavy. A simple role check in the controller `onInit()` is sufficient since security is enforced server-side.
- Separate app builds for admin vs super_admin — Rejected: same app, different UI visibility.

---

## R8: Push Notification Sending via Cloud Function

**Decision**: Admin dashboard calls the existing `sendToSegment` HTTP Cloud Function for segment-based notifications and `sendToUser` for individual notifications. The dashboard stores a notification record in a new Firestore collection `admin_notifications/{id}` after successful send.

**Rationale**: Cloud Functions for sending notifications already exist (per CLAUDE.md). The admin dashboard is a client that calls these existing endpoints. Sent history is stored in a new collection since the existing `users/{uid}/notifications/` subcollection is per-recipient.

**Alternatives considered**:
- Direct FCM send from Flutter — Rejected: requires server key in client, violates security principle.
- Store sent history in the same `users/{uid}/notifications/` subcollection — Rejected: that's per-recipient. Admin needs a global sent history log.

---

## R9: Chart Library for Analytics

**Decision**: Use `fl_chart` (already in pubspec at ^0.69.x) for all chart types: `LineChart` for revenue and cancellation trends, `BarChart` (stacked) for trip volume by type, `PieChart` for payment method breakdown.

**Rationale**: `fl_chart` is already a project dependency, supports all required chart types, works on Flutter Web, and is highly customizable.

**Alternatives considered**:
- syncfusion_flutter_charts — Rejected: commercial license, adds dependency.
- charts_flutter — Rejected: discontinued by Google.

---

## R10: Session Timeout Implementation

**Decision**: Store `lastActivityTimestamp` in SharedPreferences on each meaningful user action (navigation, data mutation). On app init, check if `DateTime.now() - lastActivity > 7 days`. If expired, call `FirebaseAuth.signOut()` and redirect to login with "Session expired" message. Also check on periodic timer (every 30 minutes) while app is active.

**Rationale**: Firebase Auth's built-in token refresh keeps the session alive indefinitely. The 7-day inactivity timeout is a business requirement that must be implemented client-side.

**Alternatives considered**:
- Firebase Auth session cookie with server-side expiry — Rejected: requires a backend endpoint, violates Firebase-only architecture.
- Custom claims with expiry timestamp — Rejected: custom claims don't auto-expire and require Cloud Function to update.

---

## Firestore Index Requirements

The following composite indexes will be needed:

| Collection | Fields | Order |
|------------|--------|-------|
| `users` | `type` ASC, `status` ASC, `createdAt` DESC | For filtered user lists |
| `users` | `type` ASC, `name` ASC | For name search within user type |
| `users` | `type` ASC, `phone` ASC | For phone search within user type |
| `trips` | `type` ASC, `status` ASC, `createdAt` DESC | For filtered trip lists |
| `trips` | `status` ASC, `createdAt` DESC | For status-filtered trips |
| `transactions` | `uid` ASC, `createdAt` DESC | For user transaction history |
| `transactions` | `method` ASC, `createdAt` DESC | For payment method filter |
| `documents` | `status` ASC, `createdAt` ASC | For pending document queue |
| `promo_codes` | `is_active` ASC, `expiry_date` DESC | For promo code filtering |

These must be deployed via `firebase deploy --only firestore:indexes` before the admin panel queries are functional.
