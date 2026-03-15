# Research: Driver Authentication & Onboarding

**Branch**: `012-driver-auth-onboarding` | **Date**: 2026-03-02

## Existing Implementation Audit

### Decision: Most of the driver auth/onboarding flow is already built
**Rationale**: Deep code review reveals that the full onboarding → phone auth → OTP → profile setup → driver registration → pending approval flow is implemented and functional across 20+ files. The spec's user stories US1–US5 are 90%+ covered by existing code.

### Existing Code Coverage Matrix

| Spec Requirement | Existing File(s) | Status | Gap |
|-----------------|-------------------|--------|-----|
| Driver onboarding slides (US1) | `onboarding/data/onboarding_data.dart` | Complete | 3 driver slides defined with translation keys |
| Onboarding screen + widgets (US1) | `onboarding/screens/onboarding_screen.dart`, `widgets/` | Complete | Shared with customer, uses `Get.arguments` to select slides |
| Onboarding persistence (FR-003) | `splash/controllers/splash_controller.dart` | Partial | Uses single `onboarding_completed` key — not app-type-specific |
| Phone login screen (US2) | `auth/screens/phone_login_screen.dart` | Complete | +20 prefix, validation, map background |
| OTP verification (US2) | `auth/screens/otp_verification_screen.dart` | Complete | 4-digit input, 30s timer, resend, auto-advance |
| Google Sign-In (FR-009) | `auth/controllers/auth_controller.dart`, `auth_service.dart` | Complete | Full flow with profile pre-fill |
| Facebook Sign-In (FR-010) | `auth/widgets/social_login_buttons.dart` | Placeholder only | Button exists, shows "Coming Soon" snackbar |
| Profile setup screen (US3) | `auth/screens/profile_setup_screen.dart` | Complete | Avatar, name, language, theme |
| Profile → Driver Registration routing (US3) | `auth/controllers/profile_setup_controller.dart` | Complete | Routes to `/driver/register` for driver type |
| Driver registration screen (US4) | `driver_registration/screens/driver_registration_screen.dart` | Complete | Vehicle fields, 4 doc uploads, progress indicator |
| Document upload (FR-015) | `driver_registration/widgets/document_upload_item.dart` | Complete | Gallery picker, Firebase Storage upload, checkmark |
| Application submission (FR-018) | `driver_registration/controllers/driver_registration_controller.dart` | Complete | Creates driver profile, updates status |
| Pending approval screen (US5) | `driver_registration/screens/pending_approval_screen.dart` | Near-complete | Timeline, status message. "Contact Support" is TODO |
| Post-auth navigation (FR-020/021) | `splash/controllers/splash_controller.dart` | Complete | Full decision tree for all user states |
| Driver app routes | `core/routes/driver_pages.dart` | Complete | 7 routes for auth flow |
| Translations | `core/translations/app_translations.dart` | Complete | All keys for onboarding, auth, registration, pending in AR+EN |
| Models | `user_model.dart`, `driver_profile_model.dart`, `document_model.dart` | Complete | All fields, JSON serialization |
| Services | `auth_service.dart`, `firestore_service.dart`, `storage_service.dart` | Near-complete | Missing Facebook auth method |

## Research Items

### 1. Facebook Sign-In Implementation

**Decision**: Implement Facebook Sign-In using `flutter_facebook_auth` package following the existing Google Sign-In pattern.

**Rationale**: The spec (FR-010) requires Facebook as an alternative auth method. The stitch design for phone login shows both Google and Facebook buttons. The existing Google Sign-In implementation provides a clean pattern to follow.

**Alternatives considered**:
- Skip Facebook auth entirely → Rejected: explicitly required by spec and shown in designs
- Use Firebase UI Auth for both social providers → Rejected: doesn't match existing custom UI approach
- Defer to a future feature → Possible but the UI placeholder is already there with "Coming Soon"

**Implementation requirements**:
1. Add `flutter_facebook_auth` dependency to `pubspec.yaml`
2. Add `signInWithFacebook()` to `AuthService` (mirrors Google pattern)
3. Add `signInWithFacebook()` to `AuthController`
4. Add `AuthState.signingInWithFacebook` enum value
5. Update `SocialLoginButtons` widget to call real Facebook auth
6. Configure Android: Facebook App ID in `AndroidManifest.xml`, SDK dependency
7. Configure iOS: Facebook App ID in `Info.plist`, URL schemes
8. Enable Facebook provider in Firebase Console (manual step)
9. Create Facebook App in Meta Developer Console (manual step)

### 2. Onboarding Persistence Scope

**Decision**: Make onboarding "seen" flag app-type-specific by using separate SharedPreferences keys.

**Rationale**: Current implementation uses a single `onboarding_completed` key. If a user completes customer onboarding, then installs the driver app on the same device, they'd skip driver onboarding. Each app type should track independently.

**Alternatives considered**:
- Keep single key → Rejected: driver onboarding content is different from customer
- Store in Firestore → Rejected: over-engineering for a local-only preference

**Implementation**: Change key from `onboarding_completed` to `onboarding_completed_driver` / `onboarding_completed_customer` based on app type passed via `Get.arguments`.

### 3. Contact Support Button

**Decision**: Implement using `url_launcher` to open WhatsApp with a pre-filled support message.

**Rationale**: WhatsApp is the dominant messaging platform in Egypt. The `url_launcher` package is already in `pubspec.yaml`. This is the simplest approach that delivers immediate value.

**Alternatives considered**:
- In-app chat system → Rejected: over-engineering, not in scope
- Email support → Less common in Egypt's market
- Phone call → Possible secondary option

**Implementation**: Open `https://wa.me/+20XXXXXXXXXX?text=...` with pre-filled text including driver UID and "pending application" context.

### 4. UI Refinements from Stitch Designs

**Decision**: The existing screens closely match the stitch designs. Minor refinements may be needed during implementation.

**Key observations from stitch HTML analysis**:
- **Colors match**: Primary #e0062e, background #f8f5f6 (light) / #230f13 (dark)
- **Font**: Stitch uses Plus Jakarta Sans; Flutter uses the theme's configured font
- **Button style**: h-14 (56px), rounded-xl, shadow-lg — matches existing `AppButton`
- **Input fields**: h-14, rounded-xl, ring-1 — matches existing `AppTextField`
- **Page indicators**: Active w-8 / inactive w-2 — matches existing `PageIndicator`
- **Document upload items**: Match existing `DocumentUploadItem` widget pattern
- **Pending screen timeline**: Matches existing implementation

**No significant UI gaps identified** between stitch designs and existing code.

## Summary of Required Work

| Priority | Task | Effort | Files Affected |
|----------|------|--------|----------------|
| P1 | Facebook Sign-In (service + controller + widget) | Medium | 5 files + config |
| P1 | Facebook SDK Android/iOS configuration | Medium | 3 config files |
| P2 | App-type-specific onboarding persistence | Low | 2 files |
| P2 | Contact Support button implementation | Low | 1 file |
| P2 | AuthState enum update for Facebook | Low | 1 file |
| P3 | Integration testing of full driver flow | Medium | New test files |
| P3 | UI verification against stitch designs | Low | Review only |
