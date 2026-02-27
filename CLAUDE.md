# 🏍️ BikeRide — CLAUDE.md

> This file gives Claude full context about the BikeRide project.
> Read this entire file before writing any code, suggesting any solution, or answering any question.

---

## 🧠 Project Overview

BikeRide is an **inDrive-style bike ride and delivery platform** built for Egypt. It has a price-bidding system where the system suggests a price and both the customer and driver negotiate. There are three apps: Customer App, Driver App, and Admin Web Panel — all built in Flutter. There is no traditional backend. All logic runs on Firebase Cloud Functions.

---

## 🗂️ Project Type

- **Platform:** Mobile (Android + iOS) + Web (Admin)
- **Language:** Dart (Flutter) only — no Laravel, no PHP, no Node except Cloud Functions
- **State Management:** GetX — always use GetX, never use Provider, Bloc, or Riverpod
- **Architecture:** Feature-first folder structure
- **Region:** Egypt 🇪🇬
- **Languages:** Arabic (RTL, default) + English (LTR)

---

## 🧱 Tech Stack

| Layer | Technology |
|---|---|
| Mobile Apps | Flutter (Android + iOS) |
| Web Admin | Flutter Web → hosted as static files on cPanel |
| Auth | Firebase Auth (Phone OTP only) |
| Main Database | Cloud Firestore |
| Real-time | Firebase Realtime Database |
| Business Logic | Firebase Cloud Functions (Node.js 18) |
| File Storage | Firebase Storage |
| Push Notifications | Firebase Cloud Messaging (FCM) |
| Maps | Google Maps SDK for Flutter |
| Address Search | Google Places API |
| Payments | Paymob (cards, Vodafone Cash, Fawry) |
| Hosting | cPanel — static Flutter Web files only |

---

## 📁 Folder Structure

```
bikeride/
├── lib/
│   ├── main_customer.dart        # Entry point — customer app
│   ├── main_driver.dart          # Entry point — driver app
│   ├── main_admin.dart           # Entry point — admin web app
│   │
│   ├── core/
│   │   ├── constants/
│   │   │   ├── firebase_keys.dart
│   │   │   ├── api_keys.dart
│   │   │   └── app_constants.dart
│   │   ├── models/
│   │   │   ├── user_model.dart
│   │   │   ├── driver_profile_model.dart
│   │   │   ├── trip_model.dart
│   │   │   ├── bid_model.dart
│   │   │   ├── transaction_model.dart
│   │   │   ├── wallet_model.dart
│   │   │   ├── rating_model.dart
│   │   │   ├── promo_code_model.dart
│   │   │   └── notification_model.dart
│   │   ├── services/
│   │   │   ├── firebase_service.dart
│   │   │   ├── auth_service.dart
│   │   │   ├── fcm_service.dart
│   │   │   ├── location_service.dart
│   │   │   └── payment_service.dart
│   │   ├── widgets/
│   │   │   ├── app_button.dart
│   │   │   ├── app_text_field.dart
│   │   │   ├── app_card.dart
│   │   │   ├── app_loading.dart
│   │   │   ├── app_snackbar.dart
│   │   │   └── app_map_widget.dart
│   │   ├── utils/
│   │   │   ├── price_calculator.dart
│   │   │   ├── location_utils.dart
│   │   │   ├── date_formatter.dart
│   │   │   └── validators.dart
│   │   ├── theme/
│   │   │   └── app_theme.dart
│   │   └── routes/
│   │       └── app_routes.dart
│   │
│   └── features/
│       ├── auth/
│       │   ├── screens/
│       │   ├── controllers/auth_controller.dart
│       │   └── bindings/auth_binding.dart
│       ├── home/
│       │   ├── screens/
│       │   ├── controllers/home_controller.dart
│       │   └── bindings/home_binding.dart
│       ├── trip/
│       │   ├── screens/
│       │   ├── controllers/trip_controller.dart
│       │   └── bindings/trip_binding.dart
│       ├── tracking/
│       │   ├── screens/
│       │   └── controllers/tracking_controller.dart
│       ├── chat/
│       │   ├── screens/
│       │   └── controllers/chat_controller.dart
│       ├── wallet/
│       │   ├── screens/
│       │   └── controllers/wallet_controller.dart
│       ├── delivery/
│       │   ├── screens/
│       │   └── controllers/delivery_controller.dart
│       ├── promo/
│       │   ├── screens/
│       │   └── controllers/promo_controller.dart
│       ├── referral/
│       │   ├── screens/
│       │   └── controllers/referral_controller.dart
│       ├── notifications/
│       │   ├── screens/
│       │   └── controllers/notification_controller.dart
│       ├── profile/
│       │   ├── screens/
│       │   └── controllers/profile_controller.dart
│       ├── earnings/
│       │   ├── screens/
│       │   └── controllers/earnings_controller.dart
│       └── admin/
│           ├── dashboard/
│           ├── users/
│           ├── trips/
│           ├── financial/
│           ├── config/
│           ├── promos/
│           ├── notifications/
│           └── analytics/
│
├── functions/                    # Firebase Cloud Functions (Node.js)
│   ├── index.js
│   └── src/
│       ├── auth/
│       │   └── on_user_created.js
│       ├── trips/
│       │   ├── on_trip_created.js
│       │   ├── on_bid_accepted.js
│       │   ├── on_trip_completed.js
│       │   └── on_trip_cancelled.js
│       ├── payments/
│       │   ├── initiate_top_up.js
│       │   ├── paymob_webhook.js
│       │   └── process_commission.js
│       ├── notifications/
│       │   ├── send_to_user.js
│       │   └── send_to_segment.js
│       ├── scheduled/
│       │   ├── expire_stale_bids.js
│       │   ├── sync_driver_stats.js
│       │   └── cleanup_realtime_db.js
│       └── admin/
│           ├── approve_driver.js
│           ├── suspend_user.js
│           ├── adjust_wallet.js
│           └── update_app_config.js
│
├── pubspec.yaml
├── firebase.json
├── firestore.rules
├── database.rules.json
└── CLAUDE.md
```

---

## 🔥 Firestore Collections

### `users/{uid}`
```
uid, name, phone, type (customer | driver | merchant),
status (active | suspended | pending_approval),
wallet_balance, referral_code, referred_by,
lang (ar | en), avatar_url, fcm_token, created_at
```

### `driver_profiles/{uid}`
```
uid, national_id, license_number,
vehicle_type (motorcycle | scooter | ebike),
plate_number, vehicle_model,
is_online, is_approved,
current_lat, current_lng,
rating_avg, total_trips, total_earnings
```

### `documents/{doc_id}`
```
driver_uid, type (national_id | license | vehicle_registration),
file_url, status (pending | approved | rejected), admin_note
```

### `trips/{trip_id}`
```
trip_id, customer_uid, driver_uid,
type (ride | c2c_delivery | b2b_delivery),
status (searching | bidding | accepted | on_the_way | arrived | in_progress | completed | cancelled),
pickup_address, pickup_lat, pickup_lng,
dropoff_address, dropoff_lat, dropoff_lng,
suggested_price, final_price, commission_amount,
payment_method (cash | wallet | card | vodafone_cash | fawry),
distance_km, duration_mins, notes,
promo_code_used, discount_amount,
created_at, accepted_at, completed_at
```

### `trips/{trip_id}/bids/{bid_id}` (subcollection)
```
bid_id, driver_uid, driver_name, driver_rating,
vehicle_type, amount,
status (pending | accepted | rejected), created_at
```

### `wallets/{uid}`
```
uid, balance, currency (EGP)
```

### `transactions/{txn_id}`
```
txn_id, uid, type (credit | debit),
amount, method (cash | wallet | card | vodafone_cash | fawry),
reference, trip_id,
status (pending | completed | failed), created_at
```

### `ratings/{rating_id}`
```
rating_id, trip_id, rater_uid, ratee_uid,
score (1-5), comment, created_at
```

### `promo_codes/{code}`
```
code, type (percentage | fixed), value,
max_uses, used_count, min_trip_value,
expiry_date, is_active
```

### `promo_usages/{id}`
```
promo_id, user_uid, trip_id, created_at
```

### `referrals/{id}`
```
referrer_uid, referee_uid, reward_amount,
status (pending | rewarded), created_at
```

### `merchants/{uid}`
```
uid, business_name, business_type,
contract_type, custom_commission_rate
```

### `users/{uid}/notifications/{notif_id}` (subcollection)
```
type, title, body, data, is_read, created_at
```

### `app_config` (single document — all apps listen to this)
```
base_fare, price_per_km, price_per_min,
surge_multiplier,
commission_ride, commission_c2c, commission_b2b,
min_bid_radius_km, bid_timeout_seconds,
referrer_reward, referee_reward,
maintenance_mode
```

---

## ⚡ Realtime Database Structure

Used ONLY for sub-second real-time data. Not for persistence.

```
/driver_locations/{driver_uid}/
    lat, lng, heading, is_online, updated_at

/active_trips/{trip_id}/
    status, driver_lat, driver_lng, driver_heading

/live_bids/{trip_id}/{bid_id}/
    driver_uid, driver_name, driver_rating, vehicle_type, amount

/chats/{trip_id}/messages/{msg_id}/
    sender_uid, type (text | call_request),
    content, timestamp, is_read
```

> **Rule:** All Realtime DB data is temporary. Cloud Functions clean it up after trip completion or cancellation. Firestore is the source of truth.

---

## ☁️ Cloud Functions Reference

All functions are in `functions/src/`. Export all from `functions/index.js`.

| Function | Trigger | What it does |
|---|---|---|
| `onUserCreated` | Auth onCreate | Creates Firestore user doc + wallet doc |
| `onTripCreated` | Firestore onCreate | Broadcasts trip to nearby drivers via FCM |
| `onBidAccepted` | Firestore onUpdate | Locks trip, rejects other bids, notifies driver |
| `onTripCompleted` | Firestore onUpdate | Calculates commission, updates wallets, cleans Realtime DB |
| `onTripCancelled` | Firestore onUpdate | Handles cancellation, restores state |
| `processCommission` | Internal helper | Calculates and records commission |
| `initiateTopUp` | HTTP POST | Creates Paymob payment order, returns URL |
| `paymobWebhook` | HTTP POST | Verifies HMAC, credits wallet |
| `validatePromoCode` | HTTP POST | Checks promo validity |
| `onFirstTripCompleted` | Internal helper | Triggers referral reward |
| `sendToUser` | Internal helper | Sends FCM to a single user |
| `sendToSegment` | HTTP POST (admin) | Sends FCM to all/drivers/customers |
| `approveDriver` | HTTP POST (admin) | Approves driver documents |
| `suspendUser` | HTTP POST (admin) | Disables Firebase Auth account |
| `adjustWalletBalance` | HTTP POST (admin) | Admin manually edits wallet |
| `updateAppConfig` | HTTP POST (admin) | Updates app_config document |
| `expireStaleBids` | Scheduled every 5min | Cancels timed-out trips |
| `syncDriverStats` | Scheduled nightly | Updates rating averages |
| `cleanupRealtimeDB` | Scheduled hourly | Removes offline driver locations |

---

## 🎮 GetX Controllers Reference

Always use `Get.lazyPut()` in bindings. Never use `Get.put()` for feature controllers.
Only `AuthController` is registered globally in `main_*.dart`.

| Controller | App | Responsibility |
|---|---|---|
| `AuthController` | All | OTP, session, FCM token save |
| `HomeController` | Customer | Map, service selector, nearby drivers |
| `TripController` | Customer | Create trip, watch bids, accept bid |
| `TrackingController` | Customer | Listen to driver location stream |
| `BidController` | Driver | Incoming requests, submit bids |
| `LocationController` | Driver | GPS stream → Realtime DB every 3s |
| `ChatController` | Both | Realtime DB messages |
| `WalletController` | Both | Balance, transactions, top-up |
| `PaymentController` | Customer | Paymob WebView flow |
| `DeliveryController` | Both | C2C and B2B delivery states |
| `DriverHomeController` | Driver | Incoming requests, online toggle |
| `EarningsController` | Driver | Earnings by day/week/month |
| `PromoController` | Customer | Validate and apply promo codes |
| `ReferralController` | Customer | Referral code sharing and earnings |
| `NotificationController` | Both | FCM, in-app notification list |
| `AdminDashController` | Admin | Stats, charts, live map |
| `AdminUsersController` | Admin | User list, document approvals |
| `AdminTripsController` | Admin | Trips table, disputes |
| `AdminConfigController` | Admin | Pricing, commission, bid config |

---

## 💰 Pricing Formula

```
suggested_price = base_fare
               + (price_per_km × distance_km)
               + (price_per_min × estimated_duration_min)
               × vehicle_type_multiplier
```

Vehicle multipliers (stored in `app_config`):
- `motorcycle` → 1.0
- `scooter` → 1.1
- `ebike` → 1.15

All values are read from Firestore `app_config` document. Never hardcode prices.

---

## 💳 Payment Logic

### Commission Calculation
``` 
commission = final_price × commission_rate
driver_earning = final_price - commission
```

Rates from `app_config`:
- `commission_ride` — default 0.15 (15%)
- `commission_c2c` — default 0.12 (12%)
- `commission_b2b` — from `merchants/{uid}/custom_commission_rate`

### Cash Trip Commission
- Driver collects cash from customer
- Commission is deducted from driver's Firestore wallet balance
- If wallet goes negative → set `can_go_online: false` on driver profile
- Driver must top up wallet before going online again

### Wallet Payment
- Hold amount during trip (do not deduct yet)
- On completion: deduct from customer wallet, credit to driver wallet minus commission
- Both happen atomically in a Firestore batch write

---

## 🌍 Localization Rules

- Default language is **Arabic (RTL)**
- Use `flutter_localizations` and `intl` package
- All strings must be in `assets/lang/ar.json` and `assets/lang/en.json`
- Never hardcode Arabic or English strings in widget code
- Use `Get.locale` to get current language
- Use `Directionality` widget at app root — never hardcode `TextDirection`
- Icons that imply direction (arrows, back buttons) must flip in RTL — use `Directionality.of(context)` to detect

---

## 🗺️ Maps Rules

- Use `google_maps_flutter` package
- Custom map style JSON stored in `assets/map_style.json`
- Driver markers use custom icons per vehicle type — stored in `assets/icons/`
- Filter GPS updates: ignore if `accuracy > 50m`
- Filter GPS jumps: ignore if moved `> 100m` in `< 2 seconds`
- Driver location written to Realtime DB every **3 seconds** when online
- Stop location updates immediately when driver goes offline

---

## 🔒 Security Rules Summary

### Firestore
- `users/{uid}` — read/write by owner only
- `driver_profiles/{uid}` — read by any logged-in user, write by owner only
- `trips/{id}` — read by customer or assigned driver only
- `trips/{id}/bids/{bid}` — read by trip customer and bid owner, write by drivers only
- `wallets/{uid}` — read by owner, write by Cloud Functions only
- `transactions/{id}` — read by owner, write by Cloud Functions only
- `promo_codes/{id}` — read by any logged-in user, write by admin Cloud Function only
- `app_config` — read by any logged-in user, write by admin Cloud Function only

### Realtime DB
- `/driver_locations/{uid}` — write by owner only, read by any logged-in user
- `/active_trips/{trip_id}` — write by Cloud Functions only, read by trip participants
- `/live_bids/{trip_id}` — write by Cloud Functions only, read by trip customer
- `/chats/{trip_id}` — read/write by trip customer and driver only

---

## 📱 App Screens Quick Reference

### Customer App
```
SplashScreen → LanguageScreen → OnboardingScreen
→ PhoneScreen → OtpScreen → ProfileSetupScreen
→ HomeScreen → SetPickupScreen → SetDropoffScreen
→ TripOptionsScreen → PriceScreen → WaitingBidsScreen
→ TrackingScreen → TripCompletedScreen → RatingScreen
→ WalletScreen → TopUpScreen → PromoScreen
→ ReferralScreen → HistoryScreen → NotificationsScreen
→ ProfileScreen → DeliveryRequestScreen → B2bTrackingScreen
```

### Driver App
```
SplashScreen → PhoneScreen → OtpScreen
→ DriverRegisterScreen → DocumentUploadScreen → PendingScreen
→ DriverHomeScreen → IncomingRequestScreen → SubmitBidScreen
→ NavigateToPickupScreen → ActiveTripScreen → TripCompleteScreen
→ EarningsScreen → WalletScreen → RatingsScreen
→ DocumentsScreen → ProfileScreen
```

### Admin Panel (Flutter Web)
```
AdminLoginScreen → DashboardScreen
→ UsersScreen → DriverDocumentsScreen → UserDetailScreen
→ TripsScreen → TripDetailScreen
→ FinancialScreen → TransactionLedgerScreen
→ ConfigScreen → CommissionScreen
→ PromosScreen → ReferralConfigScreen
→ NotificationsScreen → AnalyticsScreen
```

---

## 🚀 cPanel Deployment (Admin Panel)

```bash
# Build
flutter build web --release --base-href /admin/

# Upload build/web/ contents to cPanel subdomain folder
# Subdomain: admin.bikeride.eg
```

cPanel serves only static files. No PHP. No server processing.
All data is fetched by Flutter Web directly from Firebase in the browser.

To redeploy: delete old files in cPanel, upload new build. Takes under 2 minutes.

---

## ⚠️ Critical Rules — Read Before Writing Any Code

1. **No Laravel. No PHP. No REST API.** Everything is Firebase or Cloud Functions.
2. **Always use GetX** for state, navigation, and dependency injection. No exceptions.
3. **Never hardcode prices, commission rates, or config values.** Always read from `app_config` in Firestore.
4. **Never write to `wallets/` or `transactions/` from Flutter.** Only Cloud Functions write to these.
5. **Realtime DB is temporary.** Never store anything permanently there. Always sync to Firestore.
6. **All strings go through localization files.** No hardcoded Arabic or English text in widgets.
7. **Test every screen in Arabic RTL** — never assume LTR layout works for both directions.
8. **GPS location is written to Realtime DB from the Driver app directly** — do not route through Cloud Functions to avoid server load.
9. **Admin Cloud Functions must verify `role: admin` custom claim** before executing any admin action.
10. **Paymob webhook must verify HMAC signature** before crediting any wallet.
11. **All Firestore queries must use indexes.** Run `firebase deploy --only firestore:indexes` after adding new queries.
12. **Use Firestore batch writes** for any operation that updates multiple documents atomically (e.g., debit customer + credit driver + create 2 transactions).

---

## 📦 Key Dependencies (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter
  get: ^4.6.6
  firebase_core: ^3.x.x
  cloud_firestore: ^5.x.x
  firebase_auth: ^5.x.x
  firebase_database: ^11.x.x
  firebase_storage: ^12.x.x
  firebase_messaging: ^15.x.x
  google_maps_flutter: ^2.x.x
  geolocator: ^12.x.x
  geocoding: ^3.x.x
  flutter_polyline_points: ^2.x.x
  webview_flutter: ^4.x.x
  image_picker: ^1.x.x
  cached_network_image: ^3.x.x
  flutter_local_notifications: ^18.x.x
  intl: ^0.19.x
  fl_chart: ^0.69.x
  shared_preferences: ^2.x.x
  connectivity_plus: ^6.x.x
  permission_handler: ^11.x.x
  url_launcher: ^6.x.x
  flutter_localizations:
    sdk: flutter
```

---

## 🔑 Environment Variables (Never commit to Git)

Store in `.env` file — use `flutter_dotenv` or Firebase Remote Config:

```
GOOGLE_MAPS_API_KEY=
PAYMOB_API_KEY=
PAYMOB_INTEGRATION_ID_CARD=
PAYMOB_INTEGRATION_ID_WALLET=
PAYMOB_INTEGRATION_ID_FAWRY=
PAYMOB_HMAC_SECRET=
FIREBASE_PROJECT_ID=
```

---

## 👤 Developer Context

- **Developer:** Ibrahim
- **Location:** Egypt
- **Stack expertise:** Flutter, Firebase, Laravel (not used here), GetX
- **Admin panel:** Flutter Web on cPanel (not Filament — decision changed to simplify stack)
- **Project type:** Graduation / commercial project
- **Target market:** Egypt only
- **Currency:** EGP (Egyptian Pound)
- **Phone format:** +20 prefix, 11 digits total
