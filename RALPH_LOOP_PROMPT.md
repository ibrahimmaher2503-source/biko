
## Project Context

**App:** BikeRide Customer (User) Flutter App
**Stack:** Flutter + Firebase (Firestore + Realtime DB + Auth) + GetX + Google Maps + Paymob
**State Management:** GetX (Rx variables, Obx widgets, GetxController)
**Architecture:** Feature-first (`lib/features/<feature>/`) with shared core (`lib/core/`)
**Design Reference:** Screens in `stitch/` folder — use as pixel-accurate design source
**Theme:** All colors from `AppTheme` — NO hardcoded colors
**Widgets:** Use shared widgets from `lib/core/widgets/` — NO duplicate widget code
**Constants:** Routes in `app_routes.dart`, strings in `lib/l10n/app_ar.dart` + `lib/l10n/app_en.dart`
**RTL:** Arabic is primary — all screens must pass RTL layout check
**Dark Mode:** Every screen must work in both light and dark theme

---

## Global Rules (Apply to EVERY Task)

```
RULE-01  Read stitch/ design file for the screen before writing any UI code
RULE-02  All colors → AppTheme.colorName (never Color(0xFF...))
RULE-03  All text strings → 'key'.tr (never hardcoded strings)
RULE-04  All spacing/radius → AppDimensions constants (never magic numbers)
RULE-05  Reuse existing shared widgets from lib/core/widgets/ before creating new ones
RULE-06  Controller must have no Firebase/Firestore imports — use services only
RULE-07  View must have no business logic — only Obx() reactive reads + user events
RULE-08  Service must have no UI imports (no BuildContext, no Navigator)
RULE-09  Every model needs fromMap(), toMap(), copyWith()
RULE-10  Every controller must cancel all stream subscriptions in onClose()
RULE-11  Every screen needs: loading state, error state, empty state
RULE-12  No print() — use debugPrint() or logger
RULE-13  Run flutter analyze after every file — fix all warnings before moving on
RULE-14  Screen width must work at 360px (small Android phone)
RULE-15  After each feature: run flutter test for the feature's widget tests
```

---

## Shared Widget Reference (Use Before Creating New Widgets)

```dart
// Check these exist before creating duplicates:
lib/core/widgets/
├── app_map_widget.dart          // Map with polyline, markers — extend for tracking
├── app_button.dart              // Primary/secondary buttons
├── app_text_field.dart          // Styled text input
├── app_loading.dart             // Loading indicator
├── app_error_widget.dart        // Error state display
├── app_empty_state.dart         // Empty state with icon + message
├── app_bottom_sheet.dart        // Modal bottom sheet wrapper
├── app_dialog.dart              // Confirmation dialog
└── app_snackbar.dart            // Success/error/warning snackbars
```

---

## Theme Reference

```dart
// Use AppTheme for ALL colors:
AppTheme.primaryColor          // Brand orange/primary
AppTheme.backgroundColor       // Screen background
AppTheme.cardColor             // Card/surface color
AppTheme.textPrimary           // Main text
AppTheme.textSecondary         // Subtitle/hint text
AppTheme.errorColor            // Error red
AppTheme.successColor          // Success green
AppTheme.warningColor          // Warning yellow
AppTheme.dividerColor          // Dividers/borders
AppTheme.shimmerBase           // Loading shimmer base
AppTheme.shimmerHighlight      // Loading shimmer highlight

// Typography:
AppTextStyles.heading1         // Large headings
AppTextStyles.heading2         // Section headings
AppTextStyles.body1            // Body text
AppTextStyles.body2            // Secondary body
AppTextStyles.caption          // Small labels
AppTextStyles.button           // Button text

// Dimensions:
AppDimensions.paddingS         // 8
AppDimensions.paddingM         // 16
AppDimensions.paddingL         // 24
AppDimensions.radiusS          // 8
AppDimensions.radiusM          // 12
AppDimensions.radiusL          // 20
```

---

## ═══════════════════════════════════════════
## FEATURE 1: Set Dropoff Location (P0 — CRITICAL)
## ═══════════════════════════════════════════

### TASK-1.1 — Add dropoffLocation to BiddingController
```
FILE: lib/features/bidding/controllers/bidding_controller.dart
ACTION: Add field
CODE:
  final Rx<PlaceModel?> dropoffLocation = Rx<PlaceModel?>(null);
TEST: Unit test — dropoffLocation starts null, updates correctly
```

### TASK-1.2 — Route constant for dropoff
```
FILE: lib/core/routes/app_routes.dart
ACTION: Add constant
CODE:
  static const String dropoff = '/customer/trip/dropoff';
```

### TASK-1.3 — DropoffBinding
```
FILE: lib/features/dropoff/bindings/dropoff_binding.dart
ACTION: Create file
CODE:
  class DropoffBinding extends Bindings {
    @override
    void dependencies() {
      Get.lazyPut<DropoffController>(() => DropoffController());
    }
  }
```

### TASK-1.4 — MapService: saveRecentDropoff()
```
FILE: lib/core/services/map_service.dart
ACTION: Add method
SIGNATURE: Future<void> saveRecentDropoff(PlaceModel place)
LOGIC: Save to SharedPreferences key 'recent_dropoffs' as JSON list, max 5 items
```

### TASK-1.5 — MapService: getRecentDropoffs()
```
FILE: lib/core/services/map_service.dart
ACTION: Add method
SIGNATURE: Future<List<PlaceModel>> getRecentDropoffs()
LOGIC: Read from SharedPreferences, parse JSON, return list
```

### TASK-1.6 — DropoffController
```
FILE: lib/features/dropoff/controllers/dropoff_controller.dart
ACTION: Create file
CLASS: DropoffController extends GetxController
FIELDS:
  final Rx<PlaceModel?> selectedDropoff = Rx<PlaceModel?>(null);
  final RxString searchQuery = ''.obs;
  final RxList<PlaceModel> searchResults = <PlaceModel>[].obs;
  final RxList<PlaceModel> recentDropoffs = <PlaceModel>[].obs;
  final RxBool isSearching = false.obs;
  StreamSubscription? _searchSub;
RULE: No Firebase imports — use MapService only
```

### TASK-1.7 — DropoffController: searchQuery with debounce
```
FILE: lib/features/dropoff/controllers/dropoff_controller.dart
ACTION: Add to onInit()
CODE:
  _searchSub = debounce(searchQuery, (_) => _performSearch(), 
    time: const Duration(milliseconds: 300));
```

### TASK-1.8 — DropoffController: selectDropoff()
```
FILE: lib/features/dropoff/controllers/dropoff_controller.dart
ACTION: Add method
SIGNATURE: void selectDropoff(PlaceModel place)
LOGIC:
  1. Set selectedDropoff = place
  2. Call mapService.saveRecentDropoff(place)
  3. Get.toNamed(AppRoutes.priceNegotiation, arguments: {
       'pickup': Get.arguments['pickup'],
       'dropoff': place
     })
```

### TASK-1.9 — DropoffController: onClose()
```
FILE: lib/features/dropoff/controllers/dropoff_controller.dart
ACTION: Override onClose()
LOGIC: _searchSub?.cancel(); super.onClose();
```

### TASK-1.10 — SetDropoffScreen
```
FILE: lib/features/dropoff/screens/set_dropoff_screen.dart
ACTION: Create file
DESIGN: Mirror SetPickupScreen layout from stitch/ — same search bar, list, map tap
WIDGETS TO REUSE:
  - AppTextField for search (with location_on icon)
  - AppMapWidget for map selection
  - AppLoading for loading state
UNIQUE WIDGETS TO CREATE:
  - DropoffSearchBar (thin wrapper around AppTextField with dropoff styling)
  - DropoffResultsList (ListView of PlaceModel results)
  - SavedDropoffsList (Home / Work / Recent chips row)
RTL: Wrap in Directionality(textDirection: Get.locale?.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr)
THEME: Background → AppTheme.backgroundColor, Cards → AppTheme.cardColor
```

### TASK-1.11 — Wire Pickup → Dropoff navigation
```
FILE: lib/features/pickup/screens/set_pickup_screen.dart (or controller)
ACTION: In confirmPickup() or onPickupSelected()
CHANGE: Get.toNamed(AppRoutes.dropoff, arguments: {'pickup': selectedPlace})
```

### TASK-1.12 — Register dropoff route in app_pages.dart
```
FILE: lib/core/routes/app_pages.dart
ACTION: Add GetPage
CODE:
  GetPage(
    name: AppRoutes.dropoff,
    page: () => const SetDropoffScreen(),
    binding: DropoffBinding(),
    transition: Transition.rightToLeft,
  ),
```

### TASK-1.13 — Localization keys: Dropoff
```
FILES: lib/l10n/app_ar.dart + lib/l10n/app_en.dart
ACTION: Add keys
KEYS:
  'set_dropoff':        AR: 'حدد موقع الوصول'        EN: 'Set Dropoff Location'
  'where_to':           AR: 'إلى أين؟'               EN: 'Where to?'
  'recent_dropoffs':    AR: 'الوجهات الأخيرة'         EN: 'Recent Dropoffs'
  'saved_places':       AR: 'الأماكن المحفوظة'        EN: 'Saved Places'
  'home':               AR: 'المنزل'                  EN: 'Home'
  'work':               AR: 'العمل'                   EN: 'Work'
  'confirm_dropoff':    AR: 'تأكيد الوصول'            EN: 'Confirm Dropoff'
  'tap_map_dropoff':    AR: 'اضغط على الخريطة لتحديد الوصول'  EN: 'Tap map to set dropoff'
```

### TASK-1.14 — Widget tests: SetDropoffScreen
```
FILE: test/features/dropoff/set_dropoff_screen_test.dart
ACTION: Create test file
TESTS:
  - Search field displays and accepts input
  - Debounce fires after 300ms, not before
  - Recent dropoffs list renders with mock data
  - Selecting a result calls selectDropoff()
  - Map tap triggers location selection
  - RTL layout correct when locale is Arabic
  - Loading state shows AppLoading widget
  - Empty state shows when no results
```

---

## ═══════════════════════════════════════════
## FEATURE 2: View & Accept Driver Bids (P0 — CRITICAL)
## ═══════════════════════════════════════════

### TASK-2.1 — BidModel
```
FILE: lib/core/models/bid_model.dart
ACTION: Create file
CLASS: BidModel
FIELDS:
  final String bidId;
  final String driverUid;
  final String driverName;
  final String? driverPhotoUrl;
  final double driverRating;
  final VehicleType vehicleType;
  final double amount;
  final BidStatus status;
  final int etaMinutes;
  final DateTime createdAt;
METHODS: fromMap(), toMap(), copyWith()
```

### TASK-2.2 — BidStatus + VehicleType enums
```
FILE: lib/core/models/enums.dart
ACTION: Add enums
CODE:
  enum BidStatus { pending, accepted, rejected, expired }
  enum VehicleType { motorcycle, bicycle }
  // Add extension for display label + icon asset path
```

### TASK-2.3 — DriverBriefModel
```
FILE: lib/core/models/driver_brief_model.dart
ACTION: Create file
FIELDS:
  final String uid, name, photoUrl, vehicleType, plateNumber;
  final double rating;
  final double distanceKm;
METHODS: fromMap(), toMap()
```

### TASK-2.4 — FirestoreService: listenToLiveBids()
```
FILE: lib/core/services/firestore_service.dart
ACTION: Add method
SIGNATURE: Stream<List<BidModel>> listenToLiveBids(String tripId)
SOURCE: Realtime DB path → /live_bids/{tripId}/
LOGIC: Listen to onValue, map snapshots to List<BidModel>, sort by amount ASC
```

### TASK-2.5 — FirestoreService: acceptBid()
```
FILE: lib/core/services/firestore_service.dart
ACTION: Add method
SIGNATURE: Future<void> acceptBid(String tripId, String bidId, double finalPrice, String driverUid)
LOGIC:
  Firestore batch:
    trips/{tripId}: status=accepted, driverUid, finalPrice, acceptedAt
    trips/{tripId}/bids/{bidId}: status=accepted
  Realtime DB: remove /live_bids/{tripId} (cleanup)
```

### TASK-2.6 — FirestoreService: rejectBid()
```
FILE: lib/core/services/firestore_service.dart
ACTION: Add method
SIGNATURE: Future<void> rejectBid(String tripId, String bidId)
LOGIC: Update /live_bids/{tripId}/{bidId}/status to 'rejected'
```

### TASK-2.7 — FirestoreService: cancelTripSearch()
```
FILE: lib/core/services/firestore_service.dart
ACTION: Add method
SIGNATURE: Future<void> cancelTripSearch(String tripId)
LOGIC:
  - Update trips/{tripId}/status = 'cancelled'
  - Remove /live_bids/{tripId} from Realtime DB
```

### TASK-2.8 — FirestoreService: getDriverBrief()
```
FILE: lib/core/services/firestore_service.dart
ACTION: Add method
SIGNATURE: Future<DriverBriefModel> getDriverBrief(String driverUid)
SOURCE: drivers/{driverUid} Firestore document
```

### TASK-2.9 — BidsController
```
FILE: lib/features/bidding/controllers/bids_controller.dart
ACTION: Create file
CLASS: BidsController extends GetxController
FIELDS:
  final RxList<BidModel> bids = <BidModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isAcceptingBid = false.obs;
  final RxString tripId = ''.obs;
  StreamSubscription? _bidsSub;
onInit(): tripId = Get.arguments['tripId']; _listenToBids();
RULE: No Firebase imports
```

### TASK-2.10 — BidsController: acceptBid()
```
FILE: lib/features/bidding/controllers/bids_controller.dart
ACTION: Add method
SIGNATURE: Future<void> acceptBid(BidModel bid)
LOGIC:
  1. isAcceptingBid = true
  2. Call firestoreService.acceptBid(...)
  3. Get.offNamed(AppRoutes.tracking, arguments: {'tripId': tripId.value})
  4. On error: AppSnackbar.error('accept_bid_error'.tr)
  5. Finally: isAcceptingBid = false
```

### TASK-2.11 — BidsController: cancelSearch()
```
FILE: lib/features/bidding/controllers/bids_controller.dart
ACTION: Add method
LOGIC:
  Show AppDialog confirm → on confirm:
    firestoreService.cancelTripSearch(tripId.value)
    Get.offAllNamed(AppRoutes.customerHome)
```

### TASK-2.12 — BidCard widget
```
FILE: lib/features/bidding/widgets/bid_card.dart
ACTION: Create file
DESIGN: Reference stitch/ bid card design
LAYOUT:
  Row:
    Left: CircleAvatar (driver photo, fallback icon)
    Center column:
      Text(driverName) — AppTextStyles.body1
      RatingStars row (filled/empty stars)
      Row(vehicleIcon, vehicleLabel, '·', etaText)
    Right column:
      Text(amount in EGP) — AppTextStyles.heading2, AppTheme.primaryColor
      AppButton('accept_bid'.tr, onTap: onAccept)
CARD: AppTheme.cardColor background, AppDimensions.radiusM, elevation shadow
```

### TASK-2.13 — BidsList widget (animated)
```
FILE: lib/features/bidding/widgets/bids_list.dart
ACTION: Create file
WIDGET: AnimatedList with slide-in from right (LTR) / left (RTL)
Empty state: NoBidsYet widget
```

### TASK-2.14 — NoBidsYet widget
```
FILE: lib/features/bidding/widgets/no_bids_yet.dart
ACTION: Create file
DESIGN: Centered lottie/gif animation OR pulsing icon, text 'no_bids_yet'.tr
COLOR: AppTheme.textSecondary
```

### TASK-2.15 — SearchTimeoutWidget
```
FILE: lib/features/bidding/widgets/search_timeout_widget.dart
ACTION: Create file
TRIGGER: Show after 60 seconds with no bids
CONTENT: 'raise_offer'.tr suggestion + RaisedButton to increase offer amount
```

### TASK-2.16 — BidsScreen
```
FILE: lib/features/bidding/screens/bids_screen.dart
ACTION: Create file
DESIGN: Reference stitch/ bids screen
STRUCTURE:
  Scaffold(
    appBar: AppBar(title: 'incoming_bids'.tr, actions: [CancelSearchButton]),
    body: Column(
      TripSummaryHeader (pickup → dropoff, offered price),
      SearchTimeoutWidget (if timer expired),
      Expanded(BidsList),
    )
  )
CONTROLLER: BidsController via GetX
```

### TASK-2.17 — Route + Binding: Bids
```
FILE: lib/core/routes/app_pages.dart + app_routes.dart
ACTION: Add
  AppRoutes.bids = '/customer/trip/bids'
  GetPage(name: AppRoutes.bids, page: BidsScreen, binding: BidsBinding)
  BidsBinding: lazyPut BidsController
```

### TASK-2.18 — Wire: price negotiation → bids screen
```
FILE: lib/features/bidding/controllers/bidding_controller.dart
ACTION: In submitOffer() or confirmPrice()
CHANGE: Get.toNamed(AppRoutes.bids, arguments: {'tripId': createdTripId})
```

### TASK-2.19 — Localization keys: Bids
```
KEYS:
  'incoming_bids':     AR: 'العروض الواردة'           EN: 'Incoming Bids'
  'no_bids_yet':       AR: 'في انتظار عروض السائقين...'  EN: 'Waiting for driver bids...'
  'accept_bid':        AR: 'قبول'                     EN: 'Accept'
  'reject_bid':        AR: 'رفض'                      EN: 'Reject'
  'raise_offer':       AR: 'رفع عرضك'                 EN: 'Raise Your Offer'
  'bid_expired':       AR: 'انتهت صلاحية هذا العرض'   EN: 'This bid has expired'
  'cancel_search':     AR: 'إلغاء البحث'              EN: 'Cancel Search'
  'cancel_search_confirm': AR: 'هل تريد إلغاء البحث عن سائق؟'  EN: 'Cancel driver search?'
  'eta_minutes':       AR: '{} دقائق'                 EN: '{} min away'
  'per_km':            AR: 'جنيه'                     EN: 'EGP'
```

### TASK-2.20 — Widget tests: BidsScreen
```
FILE: test/features/bidding/bids_screen_test.dart
TESTS:
  - NoBidsYet shown on empty bids list
  - BidCard renders driver name, rating, amount correctly
  - Accept button calls acceptBid() on controller
  - Cancel search shows confirmation dialog
  - SearchTimeoutWidget appears after 60s (mock timer)
  - BidsList animates in new bids
  - RTL layout correct for Arabic
  - Dark mode colors are AppTheme values (no hardcoded)
```

---

## ═══════════════════════════════════════════
## FEATURE 3: Trip Tracking (P0 — CRITICAL)
## ═══════════════════════════════════════════

### TASK-3.1 — TrackingStatus enum
```
FILE: lib/core/models/enums.dart
ACTION: Add enum
CODE:
  enum TrackingStatus { driverEnRoute, driverArrived, tripInProgress, arrivingSoon, completed }
  // Extension: display string key + icon
```

### TASK-3.2 — FirestoreService: listenToActiveTrip()
```
FILE: lib/core/services/firestore_service.dart
ACTION: Add method
SIGNATURE: Stream<Map<String, dynamic>> listenToActiveTrip(String tripId)
SOURCE: Realtime DB /active_trips/{tripId}
FIELDS EXPECTED: status, driverLat, driverLng, driverHeading, etaMinutes
```

### TASK-3.3 — FirestoreService: cancelTrip()
```
FILE: lib/core/services/firestore_service.dart
ACTION: Add method
SIGNATURE: Future<void> cancelTrip(String tripId, String reason)
LOGIC:
  - trips/{tripId}/status = 'cancelled', cancellationReason, cancelledAt
  - Remove /active_trips/{tripId}
RESTRICTION: Throw exception if status is 'trip_in_progress' (cannot cancel mid-trip)
```

### TASK-3.4 — TrackingController
```
FILE: lib/features/tracking/controllers/tracking_controller.dart
ACTION: Create file
CLASS: TrackingController extends GetxController
FIELDS:
  final Rx<TripModel?> trip = Rx(null);
  final Rx<LatLng?> driverLocation = Rx(null);
  final Rx<TrackingStatus> trackingStatus = TrackingStatus.driverEnRoute.obs;
  final RxString eta = ''.obs;
  final RxDouble driverHeading = 0.0.obs;
  StreamSubscription? _tripSub;
onInit(): tripId from arguments; _listenToTrip();
```

### TASK-3.5 — TrackingController: status transitions
```
FILE: lib/features/tracking/controllers/tracking_controller.dart
ACTION: Add _handleStatusUpdate(Map data)
LOGIC:
  'driver_en_route'  → trackingStatus = driverEnRoute
  'driver_arrived'   → trackingStatus = driverArrived; show "Driver arrived" snackbar
  'in_progress'      → trackingStatus = tripInProgress
  'arriving_soon'    → trackingStatus = arrivingSoon
  'completed'        → navigate to TripCompletedScreen
```

### TASK-3.6 — TrackingController: cancelTrip()
```
SIGNATURE: Future<void> cancelTrip()
LOGIC:
  if (trackingStatus == tripInProgress) show "cannot_cancel_in_progress".tr snackbar; return;
  Show AppDialog confirm → call firestoreService.cancelTrip(tripId, reason) → Go home
```

### TASK-3.7 — TrackingMapWidget
```
FILE: lib/features/tracking/widgets/tracking_map_widget.dart
ACTION: Create file (extends / wraps AppMapWidget)
FEATURES:
  - Animated driver marker (rotate by driverHeading)
  - Pickup marker (green pin)
  - Dropoff marker (red pin)
  - Route polyline (AppTheme.primaryColor)
  - Camera auto-follows driver with padding
MARKER ASSET: assets/images/driver_marker.png (motorcycle icon)
```

### TASK-3.8 — DriverInfoCard widget
```
FILE: lib/features/tracking/widgets/driver_info_card.dart
ACTION: Create file
DESIGN: Reference stitch/ tracking screen bottom card
LAYOUT:
  Card (AppTheme.cardColor, top rounded corners):
    Row:
      CircleAvatar(driverPhoto)
      Column(driverName, vehicleType · plateNumber, StarRating)
      Spacer
      Column(CallButton, ChatButton)
BUTTONS: Use AppButton (outline style) with phone_icon / chat_icon
```

### TASK-3.9 — TrackingStatusBanner widget
```
FILE: lib/features/tracking/widgets/tracking_status_banner.dart
ACTION: Create file
DESIGN: Animated banner at top of screen
STATES:
  driverEnRoute  → orange bg, "driver_en_route".tr, car icon moving
  driverArrived  → green bg, "driver_arrived".tr, checkmark icon
  tripInProgress → primary bg, "trip_in_progress".tr, route icon
  arrivingSoon   → yellow bg, "arriving_soon".tr
ANIMATION: CrossFade between status changes
```

### TASK-3.10 — TripProgressBar widget
```
FILE: lib/features/tracking/widgets/trip_progress_bar.dart
ACTION: Create file
DESIGN: Linear step indicator: Pickup ──── Driver ──── Dropoff
USES: CustomPainter or LinearProgressIndicator styled with AppTheme colors
```

### TASK-3.11 — TrackingScreen
```
FILE: lib/features/tracking/screens/tracking_screen.dart
ACTION: Create file
DESIGN: Reference stitch/ tracking screen — full-screen map with overlaid cards
STRUCTURE:
  Stack(
    TrackingMapWidget (full screen),
    Positioned top: TrackingStatusBanner,
    Positioned bottom: Column(
      TripProgressBar,
      DriverInfoCard,
      ETA chip,
      CancelButton (only if driverEnRoute or driverArrived),
    )
  )
```

### TASK-3.12 — Route + Binding: Tracking
```
AppRoutes.tracking = '/customer/trip/track'
GetPage + TrackingBinding (lazyPut TrackingController)
```

### TASK-3.13 — Driver marker asset
```
FILE: assets/images/driver_marker.png
ACTION: Use motorcycle SVG/PNG icon — convert to BitmapDescriptor in TrackingMapWidget
pubspec.yaml: add assets/images/driver_marker.png
```

### TASK-3.14 — Localization keys: Tracking
```
KEYS:
  'driver_en_route':        AR: 'السائق في الطريق إليك'    EN: 'Driver is on the way'
  'driver_arrived':         AR: 'السائق وصل'               EN: 'Driver has arrived'
  'trip_in_progress':       AR: 'الرحلة جارية'             EN: 'Trip in progress'
  'arriving_soon':          AR: 'وصلنا قريباً'             EN: 'Arriving soon'
  'eta_label':              AR: 'الوصول خلال'              EN: 'ETA'
  'call_driver':            AR: 'اتصل بالسائق'            EN: 'Call Driver'
  'chat_driver':            AR: 'محادثة'                   EN: 'Chat'
  'cancel_trip':            AR: 'إلغاء الرحلة'            EN: 'Cancel Trip'
  'cannot_cancel_in_progress': AR: 'لا يمكن الإلغاء أثناء الرحلة'  EN: 'Cannot cancel mid-trip'
```

### TASK-3.15 — Widget tests: TrackingScreen
```
FILE: test/features/tracking/tracking_screen_test.dart
TESTS:
  - TrackingStatusBanner shows correct text per status
  - DriverInfoCard renders driver name, vehicle, rating
  - Call button triggers launch URL with tel: prefix
  - CancelButton hidden during trip_in_progress
  - CancelButton visible during driver_en_route
  - Cancel shows confirmation dialog
  - ETA string updates when controller eta changes
  - RTL layout correct
```

---

## ═══════════════════════════════════════════
## FEATURE 4: Trip Completion & Rating (P1 — HIGH)
## ═══════════════════════════════════════════

### TASK-4.1 — RatingModel
```
FILE: lib/core/models/rating_model.dart
FIELDS: ratingId, tripId, raterUid, rateeUid, score (1-5), comment?, createdAt
METHODS: fromMap(), toMap(), copyWith()
```

### TASK-4.2 — TripSummaryModel
```
FILE: lib/core/models/trip_summary_model.dart
FIELDS:
  String tripId, pickupAddress, dropoffAddress;
  double distanceKm, baseFare, distanceFare, timeFare, discount, totalFare;
  String paymentMethod;
  int durationMinutes;
  DriverBriefModel driver;
METHODS: fromMap(), toMap()
COMPUTED: String get formattedTotal => '${totalFare.toStringAsFixed(2)} EGP'
```

### TASK-4.3 — FirestoreService: getTripSummary()
```
SIGNATURE: Future<TripSummaryModel> getTripSummary(String tripId)
SOURCE: trips/{tripId} + drivers/{driverUid}
```

### TASK-4.4 — FirestoreService: submitRating()
```
SIGNATURE: Future<void> submitRating(RatingModel rating)
LOGIC:
  - Add to ratings/{ratingId}
  - Update driver's average rating (batch: read current, recalculate, write)
```

### TASK-4.5 — FirestoreService: tipDriver()
```
SIGNATURE: Future<void> tipDriver(String tripId, double amount)
LOGIC: Deduct from user wallet, credit driver wallet, add transaction records
```

### TASK-4.6 — TripCompletionController
```
FILE: lib/features/trip/controllers/trip_completion_controller.dart
FIELDS:
  Rx<TripSummaryModel?> summary;
  RxInt rating = 3.obs;
  RxString comment = ''.obs;
  RxList<String> selectedChips = <String>[].obs;
  RxBool isSubmitting = false.obs;
METHOD submitRating(): validate → firestoreService.submitRating() → navigate home
```

### TASK-4.7 — TripSummaryCard widget
```
FILE: lib/features/trip/widgets/trip_summary_card.dart
DESIGN: Reference stitch/ trip complete screen
LAYOUT:
  Card:
    Route row (pickup icon → line → dropoff icon)
    Metrics row (distance, duration, payment method)
    ExpansionTile 'fare_breakdown'.tr:
      baseFare row
      distanceFare row
      timeFare row
      discount row (if any, green color)
      Divider
      totalFare row (bold, large)
```

### TASK-4.8 — StarRatingWidget
```
FILE: lib/features/trip/widgets/star_rating_widget.dart
DESIGN: 5 tappable star icons, filled = AppTheme.primaryColor, empty = AppTheme.dividerColor
SIZE: 36px stars with 8px gap
INTERACTIVE: onRatingChanged(int) callback
```

### TASK-4.9 — CommentChips widget
```
FILE: lib/features/trip/widgets/comment_chips.dart
CHIPS: 'Great ride', 'Clean vehicle', 'Punctual', 'Friendly driver', 'Safe driving'
STYLE: FilterChip with AppTheme.primaryColor selected state
MULTI-SELECT: yes
```

### TASK-4.10 — TipButtons widget
```
FILE: lib/features/trip/widgets/tip_buttons.dart
PRESETS: [5, 10, 15, 20] EGP buttons + custom input
STYLE: Outlined button grid 2x2, selected = filled AppTheme.primaryColor
```

### TASK-4.11 — TripCompletedScreen
```
FILE: lib/features/trip/screens/trip_completed_screen.dart
DESIGN: Reference stitch/ trip_complete screen
STRUCTURE:
  Scaffold:
    Success animation (lottie or icon) at top
    'trip_completed'.tr heading
    TripSummaryCard
    'rate_your_trip'.tr section
    StarRatingWidget
    CommentChips
    TipButtons
    AppButton('submit_rating'.tr)
```

### TASK-4.12 — RateDriverScreen
```
FILE: lib/features/trip/screens/rate_driver_screen.dart
NOTE: Can be separate screen or integrated in TripCompletedScreen
CONTENT: DriverInfo header + StarRatingWidget + CommentInput + Submit
```

### TASK-4.13 — Localization keys: Completion
```
KEYS:
  'trip_completed':    AR: 'اكتملت الرحلة'         EN: 'Trip Completed'
  'rate_your_trip':   AR: 'قيّم رحلتك'             EN: 'Rate Your Trip'
  'fare_breakdown':   AR: 'تفاصيل الأجرة'           EN: 'Fare Breakdown'
  'base_fare':        AR: 'الأجرة الأساسية'         EN: 'Base Fare'
  'distance_fare':    AR: 'أجرة المسافة'            EN: 'Distance'
  'time_fare':        AR: 'أجرة الوقت'              EN: 'Time'
  'discount':         AR: 'خصم'                    EN: 'Discount'
  'total_fare':       AR: 'الإجمالي'               EN: 'Total'
  'tip_driver':       AR: 'إكرامية للسائق'          EN: 'Tip Driver'
  'submit_rating':    AR: 'إرسال التقييم'           EN: 'Submit Rating'
  'great_ride':       AR: 'رحلة ممتازة'            EN: 'Great ride'
  'clean_vehicle':    AR: 'مركبة نظيفة'            EN: 'Clean vehicle'
  'punctual':         AR: 'في الموعد'              EN: 'Punctual'
  'friendly_driver':  AR: 'سائق ودود'              EN: 'Friendly driver'
  'safe_driving':     AR: 'قيادة آمنة'             EN: 'Safe driving'
```

### TASK-4.14 — Widget tests: TripCompletedScreen
```
FILE: test/features/trip/trip_completed_screen_test.dart
TESTS:
  - TripSummaryCard shows correct fare breakdown
  - StarRatingWidget updates rating on tap
  - CommentChips multi-select works
  - TipButtons selection state updates
  - Submit button calls submitRating()
  - Fare breakdown expandable opens/closes
```

---

## ═══════════════════════════════════════════
## FEATURE 5: Wallet (P1 — HIGH)
## ═══════════════════════════════════════════

### TASK-5.1 — WalletModel
```
FILE: lib/core/models/wallet_model.dart
FIELDS: uid, balance (double), currency ('EGP'), lastUpdated
METHODS: fromMap(), toMap(), copyWith()
COMPUTED: String get formattedBalance => '${balance.toStringAsFixed(2)} EGP'
```

### TASK-5.2 — TransactionModel
```
FILE: lib/core/models/transaction_model.dart
FIELDS: txnId, uid, type (TransactionType), amount, method, reference?, tripId?, status (TransactionStatus), createdAt
METHODS: fromMap(), toMap(), copyWith()
ENUMS: TransactionType {credit, debit}, TransactionStatus {pending, completed, failed}
```

### TASK-5.3 — FirestoreService: wallet methods
```
METHODS TO ADD:
  Stream<WalletModel> listenToWallet(String uid)
    → Stream from wallets/{uid}
  Future<List<TransactionModel>> getTransactions(String uid, {int limit = 20, DateTime? after})
    → Query transactions collection, orderBy createdAt DESC
  Future<String> initiateTopUp(double amount, String method)
    → Call Cloud Function 'createPaymobOrder' → returns Paymob payment URL
  Stream<TransactionModel> listenToTransaction(String txnId)
    → Listen for payment confirmation
```

### TASK-5.4 — WalletController
```
FILE: lib/features/wallet/controllers/wallet_controller.dart
FIELDS:
  Rx<WalletModel?> wallet;
  RxList<TransactionModel> transactions;
  RxBool isLoading = true.obs;
  RxBool isPaginating = false.obs;
  StreamSubscription? _walletSub;
METHODS:
  loadMore() — pagination for transactions
  topUp(double amount, String method) → calls service → opens PaymentWebViewScreen
  refresh() — manual refresh
onClose(): cancel _walletSub
```

### TASK-5.5 — WalletBalanceCard widget
```
FILE: lib/features/wallet/widgets/wallet_balance_card.dart
DESIGN: Reference stitch/ wallet screen
LAYOUT:
  Gradient card (AppTheme.primaryColor gradient):
    Label: 'wallet_balance'.tr (small, white)
    Balance: wallet.formattedBalance (XL white bold)
    TopUp button (white filled, primaryColor text)
```

### TASK-5.6 — TransactionListItem widget
```
FILE: lib/features/wallet/widgets/transaction_list_item.dart
LAYOUT:
  ListTile:
    Leading: Icon (arrow_up=debit red, arrow_down=credit green) in colored circle
    Title: method or tripId reference
    Subtitle: formatted date
    Trailing: amount with +/- prefix, color coded
```

### TASK-5.7 — TopUpAmountSelector widget
```
FILE: lib/features/wallet/widgets/top_up_amount_selector.dart
PRESETS: [50, 100, 200, 500] EGP grid
CUSTOM: TextField for custom amount
STYLE: Same as TipButtons pattern
```

### TASK-5.8 — PaymentMethodSelector widget
```
FILE: lib/features/wallet/widgets/payment_method_selector.dart
OPTIONS: Credit Card, Vodafone Cash, Fawry
STYLE: Radio-style cards with logo icons
```

### TASK-5.9 — WalletScreen
```
FILE: lib/features/wallet/screens/wallet_screen.dart
DESIGN: Reference stitch/ wallet screen
STRUCTURE:
  Column:
    WalletBalanceCard
    'transaction_history'.tr header
    Expanded ListView (TransactionListItem) with pagination
    Pull-to-refresh
REPLACE: lib/features/wallet/screens/placeholder_wallet_screen.dart
```

### TASK-5.10 — TopUpScreen
```
FILE: lib/features/wallet/screens/top_up_screen.dart
STRUCTURE:
  Column:
    TopUpAmountSelector
    PaymentMethodSelector
    AppButton('proceed'.tr)
```

### TASK-5.11 — PaymentWebViewScreen
```
FILE: lib/features/wallet/screens/payment_web_view_screen.dart
PACKAGE: webview_flutter (add to pubspec.yaml if not present)
LOGIC:
  Load Paymob URL in WebView
  Listen for redirect to success/failure URL
  On success: show success snackbar, pop to wallet
  On failure: show error, allow retry
```

### TASK-5.12 — Localization keys: Wallet
```
KEYS:
  'wallet_balance':        AR: 'رصيد المحفظة'           EN: 'Wallet Balance'
  'top_up':               AR: 'إضافة رصيد'              EN: 'Top Up'
  'transaction_history':  AR: 'سجل المعاملات'           EN: 'Transaction History'
  'payment_method':       AR: 'طريقة الدفع'             EN: 'Payment Method'
  'credit_card':          AR: 'بطاقة ائتمانية'          EN: 'Credit/Debit Card'
  'vodafone_cash':        AR: 'فودافون كاش'             EN: 'Vodafone Cash'
  'fawry':               AR: 'فوري'                    EN: 'Fawry'
  'transaction_credit':   AR: 'إيداع'                  EN: 'Credit'
  'transaction_debit':    AR: 'خصم'                    EN: 'Debit'
  'payment_success':      AR: 'تم الدفع بنجاح'          EN: 'Payment Successful'
  'payment_failed':       AR: 'فشل الدفع'              EN: 'Payment Failed'
  'proceed':             AR: 'متابعة'                  EN: 'Proceed'
```

### TASK-5.13 — Widget tests: WalletScreen
```
FILE: test/features/wallet/wallet_screen_test.dart
TESTS:
  - WalletBalanceCard shows formatted balance
  - TransactionListItem credit shows green, debit shows red
  - TopUpAmountSelector preset selection updates amount
  - Custom amount input accepted
  - PaymentMethodSelector radio selection works
  - Paginate loads more on scroll end
  - Pull to refresh triggers reload
```

---

## ═══════════════════════════════════════════
## FEATURE 6: Profile & Settings (P2 — MEDIUM)
## ═══════════════════════════════════════════

### TASK-6.1 — UserModel: add language + themeMode
```
FILE: lib/core/models/user_model.dart
ACTION: Add if not present
  final String language; // 'ar' or 'en'
  final String themeMode; // 'light', 'dark', 'system'
```

### TASK-6.2 — FirestoreService: updateUserProfile()
```
SIGNATURE: Future<void> updateUserProfile(UserModel user)
LOGIC: Update users/{uid} document (only changed fields)
```

### TASK-6.3 — StorageService: uploadAvatar()
```
SIGNATURE: Future<String> uploadAvatar(File image)
LOGIC: Upload to Firebase Storage avatars/{uid}.jpg → return download URL
```

### TASK-6.4 — ProfileController
```
FILE: lib/features/profile/controllers/profile_controller.dart
FIELDS: Rx<UserModel?> user; RxBool isEditing, isSaving;
METHODS:
  loadUser() → from AuthService.currentUser
  saveProfile(String newName) → update in Firestore
  changeAvatar() → ImagePicker → uploadAvatar → update photoUrl
  changeLanguage(String lang) → Get.updateLocale(); save to Firestore
  changeTheme(String mode) → Get.changeTheme(); save to Firestore
  logout() → AuthService.logout() → Get.offAllNamed(AppRoutes.login)
  deleteAccount() → AuthService.deleteAccount() → navigate to onboarding
```

### TASK-6.5 — ProfileHeader widget
```
FILE: lib/features/profile/widgets/profile_header.dart
LAYOUT:
  Column:
    Stack(CircleAvatar(120), edit_icon button bottom-right)
    Text(userName) — AppTextStyles.heading2
    Text(phoneNumber) — AppTextStyles.body2, AppTheme.textSecondary
```

### TASK-6.6 — ProfileMenuItem widget
```
FILE: lib/features/profile/widgets/profile_menu_item.dart
PARAMS: IconData icon, String label, Widget? trailing, VoidCallback onTap
STYLE: ListTile with AppTheme colors, divider between items
```

### TASK-6.7 — LanguageSelector widget
```
FILE: lib/features/profile/widgets/language_selector.dart
STYLE: Segmented control AR | EN, AppTheme.primaryColor selected
```

### TASK-6.8 — ProfileScreen
```
FILE: lib/features/profile/screens/profile_screen.dart
DESIGN: Reference stitch/ profile screen
STRUCTURE:
  Column:
    ProfileHeader
    Divider
    ProfileMenuItem(language, LanguageSelector)
    ProfileMenuItem(theme, ThemeToggle)
    ProfileMenuItem(trip_history, navigate)
    ProfileMenuItem(wallet, navigate)
    ProfileMenuItem(help, navigate)
    ProfileMenuItem(logout, red color)
    ProfileMenuItem(delete_account, error color)
REPLACE: placeholder_profile_screen.dart
```

### TASK-6.9 — EditProfileScreen
```
FILE: lib/features/profile/screens/edit_profile_screen.dart
FIELDS: Name (AppTextField), Avatar tap → change
AppBar action: Save button (AppButton)
```

### TASK-6.10 — SettingsScreen
```
FILE: lib/features/settings/screens/settings_screen.dart
ITEMS: Language, Theme, Notifications toggle, Privacy Policy link, Terms link, App Version
```

### TASK-6.11 — Localization keys: Profile
```
KEYS:
  'profile':              AR: 'الملف الشخصي'    EN: 'Profile'
  'edit_profile':         AR: 'تعديل الملف'     EN: 'Edit Profile'
  'language':             AR: 'اللغة'           EN: 'Language'
  'theme':               AR: 'المظهر'           EN: 'Theme'
  'light_theme':          AR: 'فاتح'            EN: 'Light'
  'dark_theme':           AR: 'داكن'            EN: 'Dark'
  'system_theme':         AR: 'تلقائي'          EN: 'System'
  'logout':              AR: 'تسجيل الخروج'    EN: 'Logout'
  'delete_account':       AR: 'حذف الحساب'      EN: 'Delete Account'
  'delete_account_confirm': AR: 'هل تريد حذف حسابك نهائياً؟'  EN: 'Delete your account permanently?'
  'save_changes':         AR: 'حفظ التغييرات'   EN: 'Save Changes'
  'change_avatar':        AR: 'تغيير الصورة'    EN: 'Change Photo'
```

---

## ═══════════════════════════════════════════
## FEATURE 7: Trip History (P2 — MEDIUM)
## ═══════════════════════════════════════════

### TASK-7.1 — FirestoreService: getTripHistory()
```
SIGNATURE: Future<List<TripModel>> getTripHistory(String uid, {int limit=20, DateTime? after, TripStatus? statusFilter})
QUERY: trips where customerUid==uid, orderBy createdAt DESC, startAfter for pagination
```

### TASK-7.2 — FirestoreService: getTripDetails()
```
SIGNATURE: Future<TripModel> getTripDetails(String tripId)
SOURCE: trips/{tripId} + populate driver info
```

### TASK-7.3 — TripHistoryController
```
FILE: lib/features/history/controllers/trip_history_controller.dart
FIELDS: RxList<TripModel> trips; RxBool isLoading, isPaginating; RxString filter ('all','completed','cancelled')
METHODS: loadTrips(), loadMore(), refresh(), setFilter(String)
```

### TASK-7.4 — TripHistoryItem widget
```
FILE: lib/features/history/widgets/trip_history_item.dart
LAYOUT:
  Card:
    Row(date, status badge)
    Row(pickup_icon, pickup address)
    Row(dropoff_icon, dropoff address)
    Row(distance, duration, Spacer, fare bold)
  onTap: show TripDetailBottomSheet
```

### TASK-7.5 — TripFilterChips widget
```
FILE: lib/features/history/widgets/trip_filter_chips.dart
CHIPS: All, Completed, Cancelled
STYLE: ChoiceChip with AppTheme.primaryColor
```

### TASK-7.6 — TripDetailBottomSheet
```
FILE: lib/features/history/widgets/trip_detail_bottom_sheet.dart
CONTENT: Full TripSummaryCard + Driver mini card + Rebook button
```

### TASK-7.7 — TripHistoryScreen
```
FILE: lib/features/history/screens/trip_history_screen.dart
DESIGN: Reference stitch/ rides/history screen
STRUCTURE:
  Column:
    TripFilterChips
    Expanded ListView(TripHistoryItem) with pagination
    Pull to refresh
REPLACE: placeholder_rides_screen.dart
```

### TASK-7.8 — Localization keys: History
```
KEYS:
  'trip_history':      AR: 'سجل الرحلات'     EN: 'Trip History'
  'all_trips':         AR: 'الكل'            EN: 'All'
  'completed_trips':   AR: 'المكتملة'        EN: 'Completed'
  'cancelled_trips':   AR: 'الملغاة'         EN: 'Cancelled'
  'rebook':           AR: 'إعادة الحجز'      EN: 'Rebook'
  'no_trips':         AR: 'لا توجد رحلات'    EN: 'No trips yet'
```

---

## ═══════════════════════════════════════════
## FEATURE 8: Available Drivers on Map (Spec 014)
## ═══════════════════════════════════════════

### TASK-8.1 — Driver marker asset
```
FILE: assets/images/driver_marker.png
ACTION: Add motorcycle icon asset (36x36 px, AppTheme.primaryColor tint)
pubspec.yaml: ensure assets/images/ is listed
```

### TASK-8.2 — AppMapWidget: accept markers parameter
```
FILE: lib/core/widgets/app_map_widget.dart
ACTION: Add parameter
  final Set<Marker> markers;
UPDATE: Pass markers to GoogleMap widget's markers property
DEFAULT: const <Marker>{}
```

### TASK-8.3 — FirestoreService: getNearbyDrivers()
```
SIGNATURE: Stream<List<DriverLocationModel>> getNearbyDrivers(LatLng center, double radiusKm)
SOURCE: Realtime DB /driver_locations where isOnline == true
FILTER: Use Haversine formula to filter by radiusKm (default 5km)
MAX: Return max 50 results
CONVERT: Each to Marker with driver_marker.png BitmapDescriptor
```

### TASK-8.4 — HomeController: show driver markers
```
FILE: lib/features/home/controllers/home_controller.dart
ACTION: Add RxSet<Marker> driverMarkers; subscribe to getNearbyDrivers() on map ready
UPDATE: AppMapWidget receives driverMarkers in home screen
```

---

## ═══════════════════════════════════════════
## FEATURE 9–12: P3 Low Priority (Scaffold Only)
## ═══════════════════════════════════════════
## Build models + services + empty screen scaffolds only.
## Full implementation deferred to next sprint.

### TASK-9 — Promo Codes (scaffold)
```
CREATE: lib/core/models/promo_code_model.dart (fromMap, toMap, copyWith)
CREATE: lib/features/promo/screens/promo_screen.dart (AppBar + empty state)
CREATE: lib/features/promo/controllers/promo_controller.dart (stub)
ADD ROUTE: AppRoutes.promo = '/customer/promo'
```

### TASK-10 — Referral System (scaffold)
```
CREATE: lib/core/models/referral_model.dart
CREATE: lib/features/referral/screens/referral_screen.dart (share button stub)
CREATE: lib/features/referral/controllers/referral_controller.dart
ADD ROUTE: AppRoutes.referral = '/customer/referral'
```

### TASK-11 — In-Trip Chat (scaffold)
```
CREATE: lib/core/models/chat_message_model.dart (messageId, tripId, senderUid, content, timestamp, isRead)
CREATE: lib/features/chat/screens/chat_screen.dart (bubble list + input field layout)
CREATE: lib/features/chat/controllers/chat_controller.dart
CREATE: lib/features/chat/widgets/chat_bubble.dart
CREATE: lib/features/chat/widgets/chat_input.dart
ADD ROUTE: AppRoutes.chat = '/customer/chat'
NOTE: Wire chat button in TrackingScreen DriverInfoCard
```

### TASK-12 — Notifications Center (scaffold)
```
CREATE: lib/core/models/notification_model.dart (notifId, uid, title, body, type, isRead, createdAt)
CREATE: lib/features/notifications/screens/notifications_screen.dart
CREATE: lib/features/notifications/controllers/notifications_controller.dart
CREATE: lib/features/notifications/widgets/notification_list_item.dart
ADD ROUTE: AppRoutes.notifications = '/customer/notifications'
```

---

## ═══════════════════════════════════════════
## GETX TESTS — Spec 002 Completion
## ═══════════════════════════════════════════

### TASK-TEST-L10N — Localization Tests
```
FILE: test/l10n/localization_test.dart
FRAMEWORK: flutter_test + get_test
TESTS (21 tests):
  T-L10N-01: All AR keys present — verify app_ar.dart has every key in app_en.dart
  T-L10N-02: All EN keys present — reverse check
  T-L10N-03: Missing key returns key string (not throw)
  T-L10N-04: Get.updateLocale(Locale('ar')) changes .tr output
  T-L10N-05: RTL confirmed — testWidgets: Directionality.of = RTL in Arabic
  T-L10N-06: LTR confirmed — testWidgets: Directionality.of = LTR in English
  T-L10N-07: Date formatted per locale (intl package)
  T-L10N-08: Number formatted per locale (1,000 vs ١٬٠٠٠)
  T-L10N-09: EGP currency symbol appears correctly
  T-L10N-10-11: Pluralization (manual test — GetX uses simple .tr)
  T-L10N-12: Parameter interpolation: 'eta_minutes'.trParams({'minutes':'3'}) = '3 min away'
  T-L10N-13-21: Locale switching, persistence, fallback tests
```

### TASK-TEST-SB — Snackbar Tests
```
FILE: test/widgets/snackbar_test.dart
FRAMEWORK: flutter_test, pumpWidget with GetMaterialApp
TESTS (17 tests):
  T-SB-01: AppSnackbar.success() shows green snackbar
  T-SB-02: AppSnackbar.error() shows red snackbar
  T-SB-03: AppSnackbar.warning() shows orange snackbar
  T-SB-04: AppSnackbar.info() shows blue snackbar
  T-SB-05: Default duration = 3 seconds, custom works
  T-SB-06: Action button renders and fires callback
  T-SB-07: Dismiss by swipe works
  T-SB-08: Queue — second snackbar waits for first
  T-SB-09-10: Position top/bottom
  T-SB-11-12: Icon vs no-icon variants
  T-SB-13-14: Theme color correct in dark/light mode
  T-SB-15: RTL Arabic — text aligns right
  T-SB-16: Margin applies correctly
  T-SB-17: Integration — snackbar triggered from controller action
```

### TASK-TEST-INT — Multi-App Integration Tests
```
FILE: test/integration/app_entry_test.dart
TESTS:
  T-INT-01: Customer app main.dart runs without error
  T-INT-02: Driver app main.dart runs without error
  T-INT-03: Admin web app entry runs without error
  T-INT-04: lib/core/ imports cleanly in all three apps
```

### TASK-TEST-POL — Polish Tests
```
ACTIONS:
  T-POL-01: Run flutter test --coverage; fail if coverage < 60%
  T-POL-02: Run flutter analyze; zero errors required
  T-POL-03: Confirm all files pass dart format --output none
  T-POL-04: Create test/README.md with test descriptions
  T-POL-05: Create docs/mock_setup.md with GetX mock patterns
  T-POL-06: Add test: section to .github/workflows/ci.yml (or equivalent)
  T-POL-07-11: Document benchmark, memory, helper, integration, maintenance guides
```

---

## Ralph Loop Execution Order

```
SPRINT 1 (Critical Path):
  TASK-1.1 → 1.14  (Dropoff)
  TASK-2.1 → 2.20  (Bids)
  TASK-3.1 → 3.15  (Tracking)
  TASK-8.1 → 8.4   (Driver Markers — parallel with tracking map work)

SPRINT 2 (Revenue Path):
  TASK-4.1 → 4.14  (Trip Completion + Rating)
  TASK-5.1 → 5.13  (Wallet)

SPRINT 3 (Account Management):
  TASK-6.1 → 6.11  (Profile & Settings)
  TASK-7.1 → 7.8   (Trip History)

SPRINT 4 (Scaffolding + Tests):
  TASK-9  (Promo scaffold)
  TASK-10 (Referral scaffold)
  TASK-11 (Chat scaffold)
  TASK-12 (Notifications scaffold)
  TASK-TEST-L10N (21 l10n tests)
  TASK-TEST-SB   (17 snackbar tests)
  TASK-TEST-INT  (4 integration tests)
  TASK-TEST-POL  (11 polish tasks)
```

---

## Definition of Done (Per Task)

Every task must pass BEFORE Ralph marks it complete:

- [ ] File created at exact path specified
- [ ] No hardcoded colors (use AppTheme)
- [ ] No hardcoded strings (use .tr keys)
- [ ] No hardcoded spacing (use AppDimensions)
- [ ] Existing shared widgets reused where applicable
- [ ] Controller: no Firebase imports
- [ ] View: no business logic
- [ ] Model: fromMap + toMap + copyWith present
- [ ] onClose() cancels all subscriptions
- [ ] Loading / error / empty states implemented
- [ ] RTL verified (Arabic layout)
- [ ] Dark mode verified
- [ ] 360px width renders without overflow
- [ ] flutter analyze passes (zero errors)
- [ ] Widget test file exists and passes
- [ ] No print() statements

---

*End of Ralph Loop Prompt — BikeRide User App*
