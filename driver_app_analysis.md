# Driver App Analysis

> Generated: 2026-03-09 | Branch: `015-admin-dashboard-fixes`

---

## Summary

| Category | Count |
|----------|-------|
| Specs covering driver app | 4 (012, 003, 010, 014) |
| Total driver-related spec tasks | ~30 |
| Completed tasks | ~22 |
| Pending tasks | ~8 |
| Routes declared in app_routes.dart | 19 |
| Routes implemented in driver_pages.dart | 7 |
| Screens implemented | 7 |
| Screens NOT implemented | 12 |
| Overall completion | ~35% of full driver experience |

---

## What's DONE

### Entry Point & Infrastructure
- [x] `lib/main_driver.dart` — fully implemented, Firebase + FCM init, Arabic default, RTL support
- [x] Route constants for 19 driver routes in `app_routes.dart`
- [x] `driver_pages.dart` with 7 registered GetPage routes

### Spec 003: Splash, Onboarding & Auth (Driver portions — ALL DONE)
- [x] **T025** Driver onboarding slides (Be Your Own Boss, Safe & Reliable, Earn More)
- [x] **T026** Driver onboarding translation keys (AR/EN)
- [x] **T042** PendingApprovalScreen with status timeline, contact support, back button

### Spec 012: Driver Auth & Onboarding
- [x] **T001** flutter_facebook_auth dependency added
- [x] **T002** `signingInWithFacebook` AuthState enum value
- [x] **T003** Facebook-specific translation keys (AR/EN)
- [x] **T004** `signInWithFacebook()` in AuthService
- [x] **T007** `signInWithFacebook()` in AuthController with state management
- [x] **T008** Facebook button wired in SocialLoginButtons widget
- [x] **T009** Android Facebook SDK config (AndroidManifest.xml)
- [x] **T010** iOS Facebook SDK config (Info.plist)
- [x] **T011** Contact Support button in PendingApprovalScreen (WhatsApp + email fallback)

### Spec 010: App Permissions (Driver portions — ALL DONE)
- [x] **T002** Background location translation keys
- [x] **T003** Android permissions: ACCESS_BACKGROUND_LOCATION, FOREGROUND_SERVICE, FOREGROUND_SERVICE_LOCATION

### Spec 014: Map Integration (Driver-shared portions)
- [x] **T006-T009** Real-time location on GoogleMap (blue dot, camera animation)
- [x] **T013, T015-T016** Trip route polylines + camera bounds
- [x] **T017-T019** Theme-aware map styling (light/dark JSON)

### Core Models (ALL COMPLETE)
- [x] `DriverProfileModel` — uid, nationalId, licenseNumber, vehicleType, plateNumber, vehicleModel, isOnline, isApproved, currentLat/Lng, ratingAvg, totalTrips, totalEarnings
- [x] `DocumentModel` — driverUid, type, fileUrl, status, adminNote, createdAt
- [x] `UserModel` — type (driver/customer), status (active/suspended/pendingApproval)
- [x] `TripModel` — driverUid field, full trip lifecycle
- [x] Enums: UserType.driver, VehicleType (motorcycle/scooter/ebike), DocumentType (4 types), DocumentStatus

### Core Services (Driver-relevant — ALL COMPLETE)
- [x] `AuthService` — Phone OTP, Google, Facebook sign-in
- [x] `FirestoreService` — getDriverProfile, createDriverProfile, updateDriverProfile, getDocumentsByDriver, createDocument
- [x] `StorageService` — uploadDocument (documents/{uid}/{type}_{timestamp}.jpg), uploadAvatar
- [x] `LocationService` — checkPermissions, getCurrentPosition, getLocationStream (10m filter)
- [x] `FcmService` — token management, notification channels (trip_updates, promotions)

### Shared Features (Driver-Aware — ALL COMPLETE)
- [x] `SplashController` — routes driver to /driver/pending (if pendingApproval) or /driver/home (if active)
- [x] `AuthController` — post-auth navigation checks user type + status for driver routing
- [x] `ProfileSetupController` — routes driver to /driver/register after profile completion
- [x] `OnboardingController` — shows driverSlides, app-type-specific completion persistence

### Driver Registration Feature (COMPLETE)
```
lib/features/driver_registration/
  controllers/driver_registration_controller.dart  ✅
  bindings/driver_registration_binding.dart         ✅
  screens/driver_registration_screen.dart           ✅
  screens/pending_approval_screen.dart              ✅
  widgets/document_upload_item.dart                 ✅
  widgets/step_progress_indicator.dart              ✅
```
- Multi-step form: vehicle info (model + plate) → 4 document uploads
- 4-step progress indicator
- Document upload with image picker, compression, Firebase Storage
- Validation: all fields + all 4 documents required
- Submit: creates DriverProfileModel + updates user status to pendingApproval
- Pending screen: status timeline, WhatsApp contact support, app_config-driven support info

---

## What's MISSING / PENDING

### Pending Spec Tasks (8 tasks)

| Task | Spec | Description | Priority |
|------|------|-------------|----------|
| **T005** | 012 | Update SharedPreferences key to `onboarding_completed_$appType` in OnboardingController | CRITICAL |
| **T006** | 012 | Update SplashController to read app-type-specific onboarding key | CRITICAL |
| **T012** | 014 | Convert driver locations from Realtime DB to map Marker objects | Medium |
| **T013** | 012 | End-to-end verification of full driver flow | QA |
| **T014** | 012 | Verify all modified screens render correctly in Arabic RTL | QA |
| **T015** | 012 | Verify Facebook auth error states and cancellation handling | QA |
| **T012** | 014 | Driver marker implementation on map | Medium |
| **T014** | 014 | Ensure MapService.getDirections parses polylines correctly | Medium |

### Critical Bug
**T005-T006**: Onboarding persistence is NOT app-type-specific. If a user completes customer onboarding, the driver app will also skip onboarding (and vice versa). The SharedPreferences key needs to be `onboarding_completed_driver` / `onboarding_completed_customer` instead of a single `onboarding_completed`.

---

## Screens NOT Implemented (12 missing)

These routes are declared in `app_routes.dart` but have **no screens, controllers, or bindings**:

| Route | Feature | Priority | Notes |
|-------|---------|----------|-------|
| `/driver/home` | Driver dashboard / go online | **CRITICAL** | The core driver experience — status toggle, stats, earnings summary |
| `/driver/requests` | Incoming trip requests | **CRITICAL** | Real-time list of nearby customer requests |
| `/driver/bid` | Submit bid for a trip | **CRITICAL** | Price offer screen for bidding on requests |
| `/driver/navigate/pickup` | Navigate to customer pickup | **HIGH** | Turn-by-turn or map view to reach customer |
| `/driver/trip/active` | Active trip tracking | **HIGH** | In-trip map, status updates (arrived, in-progress) |
| `/driver/trip/complete` | Trip completion | **HIGH** | Fare summary, payment confirmation |
| `/driver/earnings` | Earnings dashboard | **MEDIUM** | Daily/weekly/monthly earnings, trip history |
| `/driver/wallet` | Wallet management | **MEDIUM** | Balance, withdrawals, transaction history |
| `/driver/ratings` | Driver ratings/reviews | **MEDIUM** | Rating average, customer feedback |
| `/driver/documents` | Document management | **LOW** | View/re-upload expired documents |
| `/driver/profile` | Driver profile | **LOW** | Edit name, photo, vehicle info |
| `/driver/settings` | App settings | **LOW** | Language, theme, notifications preferences |
| `/driver/chat` | In-trip chat | **LOW** | Customer-driver messaging |

### Known UI Bug
- `PendingApprovalScreen` "Back to Home" button routes to `/driver/home` which doesn't exist — will crash if tapped by an approved driver.

---

## Current Driver Journey (What Works End-to-End)

```
1. App Launch → Splash (2s min)                          ✅
2. First time? → Driver Onboarding (3 slides)            ✅
3. → Phone Login (+20 Egyptian format)                   ✅
4. → OTP Verification (or skip in dev)                   ✅
5. OR: Google Sign-In / Facebook Sign-In                 ✅
6. New user? → Profile Setup (name, avatar, theme)       ✅
7. Driver type? → Driver Registration                    ✅
   - Enter vehicle model + plate number                  ✅
   - Upload 4 documents (national ID, license, vehicle   ✅
     registration, criminal record)
   - Submit application                                  ✅
8. → Pending Approval Screen                             ✅
   - Status timeline (submitted → pending)               ✅
   - Contact Support (WhatsApp)                          ✅
9. Admin approves → Next app launch routes to...
10. → /driver/home                                       ❌ DOES NOT EXIST
11. → [ENTIRE POST-APPROVAL EXPERIENCE MISSING]          ❌
```

**The flow breaks at step 10.** Once a driver is approved by admin, there is nowhere to go.

---

## File Inventory

### Implemented Files
```
lib/main_driver.dart                                           ✅ Entry point

lib/core/routes/driver_pages.dart                              ⚠️ 7/19 routes
lib/core/routes/app_routes.dart                                ✅ All constants

lib/features/driver_registration/
  controllers/driver_registration_controller.dart              ✅
  bindings/driver_registration_binding.dart                    ✅
  screens/driver_registration_screen.dart                      ✅
  screens/pending_approval_screen.dart                         ✅
  widgets/document_upload_item.dart                            ✅
  widgets/step_progress_indicator.dart                         ✅

lib/features/splash/          (shared, driver-aware)           ✅
lib/features/onboarding/      (shared, driver-aware)           ✅
lib/features/auth/            (shared, driver-aware)           ✅

lib/core/models/driver_profile_model.dart                      ✅
lib/core/models/document_model.dart                            ✅
lib/core/models/enums.dart    (driver enums)                   ✅
lib/core/services/            (all 7 services)                 ✅
```

### Missing Feature Folders (need to be created)
```
lib/features/driver_home/          — Dashboard, online toggle, stats
lib/features/driver_trips/         — Requests, bidding, active trip, completion
lib/features/driver_earnings/      — Earnings dashboard, history
lib/features/driver_wallet/        — Wallet balance, withdrawals
lib/features/driver_ratings/       — Rating overview, reviews
lib/features/driver_profile/       — Profile view/edit
lib/features/driver_settings/      — App settings
lib/features/driver_chat/          — In-trip messaging
```

---

## Missing Backend Dependencies

The following features need **Cloud Functions** or **Realtime Database** integrations that don't exist yet:

| Feature | Backend Needed |
|---------|---------------|
| Go Online/Offline toggle | Write driver location to Realtime DB, clean up on offline |
| Incoming trip requests | Realtime DB listener for nearby requests (geo-query) |
| Submit bid | Write bid to Realtime DB trips/{tripId}/bids/ |
| Bid accepted notification | FCM push when customer accepts driver's bid |
| Trip status updates | Write status changes to Firestore + Realtime DB |
| Earnings calculation | Cloud Function to calculate commission + net earnings |
| Wallet management | Cloud Function for withdrawals (Flutter must NOT write to wallets/) |
| Background location tracking | Foreground service sending location every 3s to Realtime DB |

---

## Verdict

The driver app is **~35% complete**. The onboarding-through-registration flow is solid and production-ready, but the **entire post-approval driver experience is unbuilt**. There are no screens for the core driver workflow: going online, receiving requests, bidding, navigating to pickups, managing trips, or viewing earnings.

### Recommended Next Steps (Priority Order)

1. **Fix onboarding persistence bug** (T005-T006) — app-type-specific SharedPreferences keys
2. **Build Driver Home Screen** — online/offline toggle, today's stats, earnings summary
3. **Build Trip Request Screen** — real-time incoming requests from Realtime DB
4. **Build Bid Submission Screen** — price offer UI with suggested fare
5. **Build Active Trip Screen** — map-based tracking, status progression (on the way → arrived → in progress → completed)
6. **Build Trip Completion Screen** — fare breakdown, payment confirmation
7. **Integrate background location** — foreground service for continuous GPS updates
8. **Build Earnings Dashboard** — daily/weekly/monthly breakdown
9. **Build Wallet Screen** — balance, transaction history
10. **Build Profile & Settings** — edit info, manage preferences
