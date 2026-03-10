# BikeRide User App — TODO Update List
# Tracks completion status per Ralph Loop sprint
# Update checkboxes as tasks complete

---

## How to Use This File

- Ralph Loop updates this file after each task completes
- Check `[x]` when task is done, `[~]` when in-progress, `[!]` when blocked
- Each task references the RALPH_LOOP_PROMPT.md task ID

---

## SPRINT 1 — Critical Path (P0)

### Feature 1: Set Dropoff Location

| ID | Task | Status | Notes |
|----|------|--------|-------|
| TASK-1.1 | Add dropoffLocation to BiddingController | [ ] | |
| TASK-1.2 | Route constant /customer/trip/dropoff | [ ] | |
| TASK-1.3 | DropoffBinding | [ ] | |
| TASK-1.4 | MapService: saveRecentDropoff() | [ ] | |
| TASK-1.5 | MapService: getRecentDropoffs() | [ ] | |
| TASK-1.6 | DropoffController (base) | [ ] | |
| TASK-1.7 | searchQuery debounce 300ms | [ ] | |
| TASK-1.8 | selectDropoff() with navigation | [ ] | |
| TASK-1.9 | onClose() stream cleanup | [ ] | |
| TASK-1.10 | SetDropoffScreen UI | [ ] | |
| TASK-1.11 | Wire Pickup → Dropoff navigation | [ ] | |
| TASK-1.12 | Register route in app_pages.dart | [ ] | |
| TASK-1.13 | Localization keys (AR + EN) | [ ] | |
| TASK-1.14 | Widget tests (8 tests) | [ ] | |

**Feature 1 Progress: 0/14**

---

### Feature 2: View & Accept Driver Bids

| ID | Task | Status | Notes |
|----|------|--------|-------|
| TASK-2.1 | BidModel | [ ] | |
| TASK-2.2 | BidStatus + VehicleType enums | [ ] | |
| TASK-2.3 | DriverBriefModel | [ ] | |
| TASK-2.4 | FirestoreService: listenToLiveBids() | [ ] | |
| TASK-2.5 | FirestoreService: acceptBid() | [ ] | |
| TASK-2.6 | FirestoreService: rejectBid() | [ ] | |
| TASK-2.7 | FirestoreService: cancelTripSearch() | [ ] | |
| TASK-2.8 | FirestoreService: getDriverBrief() | [ ] | |
| TASK-2.9 | BidsController (base) | [ ] | |
| TASK-2.10 | BidsController: acceptBid() | [ ] | |
| TASK-2.11 | BidsController: cancelSearch() | [ ] | |
| TASK-2.12 | BidCard widget | [ ] | |
| TASK-2.13 | BidsList widget (animated) | [ ] | |
| TASK-2.14 | NoBidsYet widget | [ ] | |
| TASK-2.15 | SearchTimeoutWidget | [ ] | |
| TASK-2.16 | BidsScreen UI | [ ] | |
| TASK-2.17 | Route + Binding | [ ] | |
| TASK-2.18 | Wire price negotiation → bids | [ ] | |
| TASK-2.19 | Localization keys (AR + EN) | [ ] | |
| TASK-2.20 | Widget tests (8 tests) | [ ] | |

**Feature 2 Progress: 0/20**

---

### Feature 3: Trip Tracking

| ID | Task | Status | Notes |
|----|------|--------|-------|
| TASK-3.1 | TrackingStatus enum | [ ] | |
| TASK-3.2 | FirestoreService: listenToActiveTrip() | [ ] | |
| TASK-3.3 | FirestoreService: cancelTrip() | [ ] | |
| TASK-3.4 | TrackingController (base) | [ ] | |
| TASK-3.5 | Status transitions logic | [ ] | |
| TASK-3.6 | cancelTrip() with restriction | [ ] | |
| TASK-3.7 | TrackingMapWidget | [ ] | |
| TASK-3.8 | DriverInfoCard widget | [ ] | |
| TASK-3.9 | TrackingStatusBanner widget | [ ] | |
| TASK-3.10 | TripProgressBar widget | [ ] | |
| TASK-3.11 | TrackingScreen UI | [ ] | |
| TASK-3.12 | Route + Binding | [ ] | |
| TASK-3.13 | Driver marker asset | [ ] | |
| TASK-3.14 | Localization keys (AR + EN) | [ ] | |
| TASK-3.15 | Widget tests (8 tests) | [ ] | |

**Feature 3 Progress: 0/15**

---

### Feature 8: Available Drivers on Map

| ID | Task | Status | Notes |
|----|------|--------|-------|
| TASK-8.1 | Driver marker asset (motorcycle PNG) | [ ] | |
| TASK-8.2 | AppMapWidget: markers parameter | [ ] | |
| TASK-8.3 | FirestoreService: getNearbyDrivers() | [ ] | |
| TASK-8.4 | HomeController: driverMarkers stream | [ ] | |

**Feature 8 Progress: 0/4**

**SPRINT 1 TOTAL: 0/53**

---

## SPRINT 2 — Revenue Path (P1)

### Feature 4: Trip Completion & Rating

| ID | Task | Status | Notes |
|----|------|--------|-------|
| TASK-4.1 | RatingModel | [ ] | |
| TASK-4.2 | TripSummaryModel | [ ] | |
| TASK-4.3 | FirestoreService: getTripSummary() | [ ] | |
| TASK-4.4 | FirestoreService: submitRating() | [ ] | |
| TASK-4.5 | FirestoreService: tipDriver() | [ ] | |
| TASK-4.6 | TripCompletionController | [ ] | |
| TASK-4.7 | TripSummaryCard widget | [ ] | |
| TASK-4.8 | StarRatingWidget | [ ] | |
| TASK-4.9 | CommentChips widget | [ ] | |
| TASK-4.10 | TipButtons widget | [ ] | |
| TASK-4.11 | TripCompletedScreen | [ ] | |
| TASK-4.12 | RateDriverScreen | [ ] | |
| TASK-4.13 | Localization keys (AR + EN) | [ ] | |
| TASK-4.14 | Widget tests (6 tests) | [ ] | |

**Feature 4 Progress: 0/14**

---

### Feature 5: Wallet

| ID | Task | Status | Notes |
|----|------|--------|-------|
| TASK-5.1 | WalletModel | [ ] | |
| TASK-5.2 | TransactionModel + enums | [ ] | |
| TASK-5.3 | FirestoreService: wallet methods (4) | [ ] | |
| TASK-5.4 | WalletController | [ ] | |
| TASK-5.5 | WalletBalanceCard widget | [ ] | |
| TASK-5.6 | TransactionListItem widget | [ ] | |
| TASK-5.7 | TopUpAmountSelector widget | [ ] | |
| TASK-5.8 | PaymentMethodSelector widget | [ ] | |
| TASK-5.9 | WalletScreen (replace placeholder) | [ ] | |
| TASK-5.10 | TopUpScreen | [ ] | |
| TASK-5.11 | PaymentWebViewScreen (Paymob) | [ ] | |
| TASK-5.12 | Localization keys (AR + EN) | [ ] | |
| TASK-5.13 | Widget tests (7 tests) | [ ] | |

**Feature 5 Progress: 0/13**

**SPRINT 2 TOTAL: 0/27**

---

## SPRINT 3 — Account Management (P2)

### Feature 6: Profile & Settings

| ID | Task | Status | Notes |
|----|------|--------|-------|
| TASK-6.1 | UserModel: language + themeMode fields | [ ] | |
| TASK-6.2 | FirestoreService: updateUserProfile() | [ ] | |
| TASK-6.3 | StorageService: uploadAvatar() | [ ] | |
| TASK-6.4 | ProfileController | [ ] | |
| TASK-6.5 | ProfileHeader widget | [ ] | |
| TASK-6.6 | ProfileMenuItem widget | [ ] | |
| TASK-6.7 | LanguageSelector widget | [ ] | |
| TASK-6.8 | ProfileScreen (replace placeholder) | [ ] | |
| TASK-6.9 | EditProfileScreen | [ ] | |
| TASK-6.10 | SettingsScreen | [ ] | |
| TASK-6.11 | Localization keys (AR + EN) | [ ] | |

**Feature 6 Progress: 0/11**

---

### Feature 7: Trip History

| ID | Task | Status | Notes |
|----|------|--------|-------|
| TASK-7.1 | FirestoreService: getTripHistory() | [ ] | |
| TASK-7.2 | FirestoreService: getTripDetails() | [ ] | |
| TASK-7.3 | TripHistoryController | [ ] | |
| TASK-7.4 | TripHistoryItem widget | [ ] | |
| TASK-7.5 | TripFilterChips widget | [ ] | |
| TASK-7.6 | TripDetailBottomSheet widget | [ ] | |
| TASK-7.7 | TripHistoryScreen (replace placeholder) | [ ] | |
| TASK-7.8 | Localization keys (AR + EN) | [ ] | |

**Feature 7 Progress: 0/8**

**SPRINT 3 TOTAL: 0/19**

---

## SPRINT 4 — Scaffolds + Tests (P3 + Testing)

### Feature 9: Promo Codes (Scaffold)

| ID | Task | Status | Notes |
|----|------|--------|-------|
| TASK-9.1 | PromoCodeModel | [ ] | |
| TASK-9.2 | PromoScreen scaffold | [ ] | |
| TASK-9.3 | PromoController stub | [ ] | |
| TASK-9.4 | Route registered | [ ] | |

**Feature 9 Progress: 0/4**

---

### Feature 10: Referral System (Scaffold)

| ID | Task | Status | Notes |
|----|------|--------|-------|
| TASK-10.1 | ReferralModel | [ ] | |
| TASK-10.2 | ReferralScreen scaffold | [ ] | |
| TASK-10.3 | ReferralController stub | [ ] | |
| TASK-10.4 | Route registered | [ ] | |

**Feature 10 Progress: 0/4**

---

### Feature 11: In-Trip Chat (Scaffold)

| ID | Task | Status | Notes |
|----|------|--------|-------|
| TASK-11.1 | ChatMessageModel | [ ] | |
| TASK-11.2 | ChatScreen scaffold | [ ] | |
| TASK-11.3 | ChatController stub | [ ] | |
| TASK-11.4 | ChatBubble widget | [ ] | |
| TASK-11.5 | ChatInput widget | [ ] | |
| TASK-11.6 | Chat button wired in TrackingScreen | [ ] | |
| TASK-11.7 | Route registered | [ ] | |

**Feature 11 Progress: 0/7**

---

### Feature 12: Notifications Center (Scaffold)

| ID | Task | Status | Notes |
|----|------|--------|-------|
| TASK-12.1 | NotificationModel | [ ] | |
| TASK-12.2 | NotificationsScreen scaffold | [ ] | |
| TASK-12.3 | NotificationsController stub | [ ] | |
| TASK-12.4 | NotificationListItem widget | [ ] | |
| TASK-12.5 | Route registered | [ ] | |

**Feature 12 Progress: 0/5**

---

### GetX Tests — Localization (21 tests)

| ID | Test | Status | Notes |
|----|------|--------|-------|
| T-L10N-01 | AR keys all present | [ ] | |
| T-L10N-02 | EN keys all present | [ ] | |
| T-L10N-03 | Missing key fallback | [ ] | |
| T-L10N-04 | Locale switching works | [ ] | |
| T-L10N-05 | RTL layout Arabic | [ ] | |
| T-L10N-06 | LTR layout English | [ ] | |
| T-L10N-07 | Date format per locale | [ ] | |
| T-L10N-08 | Number format per locale | [ ] | |
| T-L10N-09 | EGP currency format | [ ] | |
| T-L10N-10 | Pluralization AR | [ ] | |
| T-L10N-11 | Pluralization EN | [ ] | |
| T-L10N-12 | Gender-based translation | [ ] | |
| T-L10N-13 | Dynamic locale change | [ ] | |
| T-L10N-14 | Parameter interpolation | [ ] | |
| T-L10N-15 | Nested translation key | [ ] | |
| T-L10N-16 | Bulk locale change | [ ] | |
| T-L10N-17 | Locale persistence | [ ] | |
| T-L10N-18 | Translations loading | [ ] | |
| T-L10N-19 | Fallback locale | [ ] | |
| T-L10N-20 | GetMaterialApp locale config | [ ] | |
| T-L10N-21 | Localization service integration | [ ] | |

**L10N Tests Progress: 0/21**

---

### GetX Tests — Snackbar (17 tests)

| ID | Test | Status | Notes |
|----|------|--------|-------|
| T-SB-01 | Success snackbar green | [ ] | |
| T-SB-02 | Error snackbar red | [ ] | |
| T-SB-03 | Warning snackbar orange | [ ] | |
| T-SB-04 | Info snackbar blue | [ ] | |
| T-SB-05 | Duration test | [ ] | |
| T-SB-06 | Action button test | [ ] | |
| T-SB-07 | Dismiss test | [ ] | |
| T-SB-08 | Queue test | [ ] | |
| T-SB-09 | Position top | [ ] | |
| T-SB-10 | Position bottom | [ ] | |
| T-SB-11 | With icon | [ ] | |
| T-SB-12 | Without icon | [ ] | |
| T-SB-13 | Dark mode theme | [ ] | |
| T-SB-14 | Light mode theme | [ ] | |
| T-SB-15 | RTL test | [ ] | |
| T-SB-16 | Margin test | [ ] | |
| T-SB-17 | Integration test | [ ] | |

**Snackbar Tests Progress: 0/17**

---

### Integration + Polish Tests

| ID | Task | Status | Notes |
|----|------|--------|-------|
| T-INT-01 | Customer app entry test | [ ] | |
| T-INT-02 | Driver app entry test | [ ] | |
| T-INT-03 | Admin app entry test | [ ] | |
| T-INT-04 | Shared core module test | [ ] | |
| T-POL-01 | Coverage report (≥60%) | [ ] | |
| T-POL-02 | flutter analyze (zero errors) | [ ] | |
| T-POL-03 | dart format compliance | [ ] | |
| T-POL-04 | test/README.md | [ ] | |
| T-POL-05 | docs/mock_setup.md | [ ] | |
| T-POL-06 | CI/CD test config | [ ] | |
| T-POL-07 | Performance benchmark tests | [ ] | |
| T-POL-08 | Memory leak tests | [ ] | |
| T-POL-09 | Widget test helpers doc | [ ] | |
| T-POL-10 | Integration test guide | [ ] | |
| T-POL-11 | Test maintenance guide | [ ] | |

**Polish Progress: 0/15**

**SPRINT 4 TOTAL: 0/73**

---

## Overall Progress Summary

| Sprint | Feature | Total Tasks | Done | % |
|--------|---------|-------------|------|---|
| S1 | Dropoff Location | 14 | 0 | 0% |
| S1 | View & Accept Bids | 20 | 0 | 0% |
| S1 | Trip Tracking | 15 | 0 | 0% |
| S1 | Driver Markers (Map) | 4 | 0 | 0% |
| S2 | Trip Completion + Rating | 14 | 0 | 0% |
| S2 | Wallet | 13 | 0 | 0% |
| S3 | Profile & Settings | 11 | 0 | 0% |
| S3 | Trip History | 8 | 0 | 0% |
| S4 | Promo (scaffold) | 4 | 0 | 0% |
| S4 | Referral (scaffold) | 4 | 0 | 0% |
| S4 | Chat (scaffold) | 7 | 0 | 0% |
| S4 | Notifications (scaffold) | 5 | 0 | 0% |
| S4 | L10N Tests | 21 | 0 | 0% |
| S4 | Snackbar Tests | 17 | 0 | 0% |
| S4 | Integration + Polish | 15 | 0 | 0% |
| | **GRAND TOTAL** | **172** | **0** | **0%** |

---

## Placeholder Screens to Replace

Track which placeholder screens have been replaced with real implementations:

| Placeholder File | Replacement | Status |
|-----------------|-------------|--------|
| placeholder_wallet_screen.dart | wallet_screen.dart | [ ] |
| placeholder_profile_screen.dart | profile_screen.dart | [ ] |
| placeholder_rides_screen.dart | trip_history_screen.dart | [ ] |

---

## Blocked Tasks Log

Use this section to track tasks blocked by dependencies:

| Task ID | Blocked By | Resolution |
|---------|-----------|------------|
| TASK-2.4 | Realtime DB /live_bids/{tripId} structure must exist | Create DB structure first |
| TASK-3.2 | Realtime DB /active_trips/{tripId} structure must exist | Create DB structure first |
| TASK-5.11 | Cloud Function 'createPaymobOrder' must be deployed | Deploy function first |
| TASK-8.3 | Realtime DB /driver_locations structure must exist | Driver app writes this |

---

## New Files Created Log

Track all new files created by Ralph Loop (for PR review):

### Models
- [ ] lib/core/models/bid_model.dart
- [ ] lib/core/models/driver_brief_model.dart
- [ ] lib/core/models/rating_model.dart
- [ ] lib/core/models/trip_summary_model.dart
- [ ] lib/core/models/wallet_model.dart
- [ ] lib/core/models/transaction_model.dart
- [ ] lib/core/models/promo_code_model.dart
- [ ] lib/core/models/referral_model.dart
- [ ] lib/core/models/chat_message_model.dart
- [ ] lib/core/models/notification_model.dart

### Controllers
- [ ] lib/features/dropoff/controllers/dropoff_controller.dart
- [ ] lib/features/bidding/controllers/bids_controller.dart
- [ ] lib/features/tracking/controllers/tracking_controller.dart
- [ ] lib/features/trip/controllers/trip_completion_controller.dart
- [ ] lib/features/wallet/controllers/wallet_controller.dart
- [ ] lib/features/profile/controllers/profile_controller.dart
- [ ] lib/features/history/controllers/trip_history_controller.dart
- [ ] lib/features/promo/controllers/promo_controller.dart
- [ ] lib/features/referral/controllers/referral_controller.dart
- [ ] lib/features/chat/controllers/chat_controller.dart
- [ ] lib/features/notifications/controllers/notifications_controller.dart

### Screens
- [ ] lib/features/dropoff/screens/set_dropoff_screen.dart
- [ ] lib/features/bidding/screens/bids_screen.dart
- [ ] lib/features/tracking/screens/tracking_screen.dart
- [ ] lib/features/trip/screens/trip_completed_screen.dart
- [ ] lib/features/trip/screens/rate_driver_screen.dart
- [ ] lib/features/wallet/screens/wallet_screen.dart
- [ ] lib/features/wallet/screens/top_up_screen.dart
- [ ] lib/features/wallet/screens/payment_web_view_screen.dart
- [ ] lib/features/profile/screens/profile_screen.dart
- [ ] lib/features/profile/screens/edit_profile_screen.dart
- [ ] lib/features/settings/screens/settings_screen.dart
- [ ] lib/features/history/screens/trip_history_screen.dart
- [ ] lib/features/promo/screens/promo_screen.dart
- [ ] lib/features/referral/screens/referral_screen.dart
- [ ] lib/features/chat/screens/chat_screen.dart
- [ ] lib/features/notifications/screens/notifications_screen.dart

### Widgets
- [ ] lib/features/dropoff/widgets/dropoff_search_bar.dart
- [ ] lib/features/dropoff/widgets/dropoff_results_list.dart
- [ ] lib/features/dropoff/widgets/saved_dropoffs_list.dart
- [ ] lib/features/bidding/widgets/bid_card.dart
- [ ] lib/features/bidding/widgets/bids_list.dart
- [ ] lib/features/bidding/widgets/no_bids_yet.dart
- [ ] lib/features/bidding/widgets/search_timeout_widget.dart
- [ ] lib/features/tracking/widgets/tracking_map_widget.dart
- [ ] lib/features/tracking/widgets/driver_info_card.dart
- [ ] lib/features/tracking/widgets/tracking_status_banner.dart
- [ ] lib/features/tracking/widgets/trip_progress_bar.dart
- [ ] lib/features/trip/widgets/trip_summary_card.dart
- [ ] lib/features/trip/widgets/star_rating_widget.dart
- [ ] lib/features/trip/widgets/comment_chips.dart
- [ ] lib/features/trip/widgets/tip_buttons.dart
- [ ] lib/features/wallet/widgets/wallet_balance_card.dart
- [ ] lib/features/wallet/widgets/transaction_list_item.dart
- [ ] lib/features/wallet/widgets/top_up_amount_selector.dart
- [ ] lib/features/wallet/widgets/payment_method_selector.dart
- [ ] lib/features/profile/widgets/profile_header.dart
- [ ] lib/features/profile/widgets/profile_menu_item.dart
- [ ] lib/features/profile/widgets/language_selector.dart
- [ ] lib/features/history/widgets/trip_history_item.dart
- [ ] lib/features/history/widgets/trip_filter_chips.dart
- [ ] lib/features/history/widgets/trip_detail_bottom_sheet.dart
- [ ] lib/features/chat/widgets/chat_bubble.dart
- [ ] lib/features/chat/widgets/chat_input.dart
- [ ] lib/features/notifications/widgets/notification_list_item.dart

### Test Files
- [ ] test/features/dropoff/set_dropoff_screen_test.dart
- [ ] test/features/bidding/bids_screen_test.dart
- [ ] test/features/tracking/tracking_screen_test.dart
- [ ] test/features/trip/trip_completed_screen_test.dart
- [ ] test/features/wallet/wallet_screen_test.dart
- [ ] test/l10n/localization_test.dart
- [ ] test/widgets/snackbar_test.dart
- [ ] test/integration/app_entry_test.dart

---

*Last Updated: 2026-03-10 | Next Review: After Sprint 1 completion*
