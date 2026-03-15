# Tasks: Admin Dashboard Web Panel

**Input**: Design documents from `/specs/013-admin-dashboard/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: Not explicitly requested. Test tasks are omitted.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Create admin feature directory structure and configure project

- [x] T001 Create admin feature directory structure: `lib/features/admin/` with subdirectories `bindings/`, `controllers/`, `screens/`, `widgets/`, `models/`, `services/`
- [x] T002 [P] Add admin-specific translation keys (admin.login.*, admin.sidebar.*, admin.dashboard.*, admin.users.*, admin.documents.*, admin.trips.*, admin.financial.*, admin.config.*, admin.promos.*, admin.notifications.*, admin.analytics.*, admin.referrals.*, admin.search.*, admin.common.*) to `lib/core/translations/app_translations.dart`
- [x] T003 [P] Add AdminRole enum (admin, superAdmin) with toJson/fromJson to `lib/core/models/enums.dart`
- [x] T004 [P] Add new admin route constants (adminLogin, adminNotificationHistory, adminCustomers, adminDrivers, adminDriverDetail, adminCustomerDetail) to `lib/core/routes/app_routes.dart` if not already present

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**CRITICAL**: No user story work can begin until this phase is complete

- [x] T005 Create AdminUserModel with uid, email, displayName, role (AdminRole), lastLoginAt; constructor from FirebaseAuth currentUser + IdTokenResult claims in `lib/features/admin/models/admin_user_model.dart`
- [x] T006 [P] Create ChartDataPoint model with date, value, label fields and factory constructors in `lib/features/admin/models/chart_data_point.dart`
- [x] T007 [P] Create reusable StatusBadge widget that renders colored badges for UserStatus, DocumentStatus, TripStatus, and custom strings in `lib/features/admin/widgets/status_badge.dart`
- [x] T008 [P] Create reusable ConfirmDialog widget with title, message, confirmLabel, cancelLabel, isDestructive flag using AppButton and AppCard in `lib/features/admin/widgets/confirm_dialog.dart`
- [x] T009 [P] Create reusable DateRangePicker widget with preset ranges (today, 7d, 30d, 90d, custom) returning DateTimeRange in `lib/features/admin/widgets/date_range_picker.dart`
- [x] T010 Create reusable AdminDataTable widget with column definitions, cursor-based pagination (page size 25), search field, filter dropdowns, loading/empty states, and row tap callback in `lib/features/admin/widgets/admin_data_table.dart`
- [x] T011 Create AdminFirestoreService with static methods: getPaginatedUsers, getPaginatedTrips, getPaginatedTransactions, getPendingDocuments, searchUsersByPhone, searchUsersByName, getAppConfig, getDailyStats using cursor-based Firestore pagination in `lib/features/admin/services/admin_firestore_service.dart`
- [x] T012 Create admin_not_found_screen.dart with "Page not found" message and back navigation button in `lib/features/admin/screens/admin_not_found_screen.dart`

**Checkpoint**: Foundation ready — user story implementation can now begin

---

## Phase 3: User Story 1 — Admin Login & Session Persistence (Priority: P1) MVP

**Goal**: Admin can log in with email/password, system verifies admin role via custom claims, session persists for 7 days of inactivity

**Independent Test**: Attempt login with admin credentials, non-admin credentials, and invalid credentials. Verify session persists across browser restart. Verify 7-day timeout redirects to login.

### Implementation for User Story 1

- [x] T013 [US1] Create AdminAuthController extending GetxController with: signIn(email, password), signOut(), checkSession(), _verifyAdminRole() using FirebaseAuth signInWithEmailAndPassword + getIdTokenResult for custom claims check, 7-day inactivity timeout via SharedPreferences lastActivityTimestamp, isAuthenticated/isLoading/errorMessage observables, AdminUserModel observable in `lib/features/admin/controllers/admin_auth_controller.dart`
- [x] T014 [US1] Create AdminAuthBinding that registers AdminAuthController via Get.lazyPut in `lib/features/admin/bindings/admin_auth_binding.dart`
- [x] T015 [US1] Create AdminLoginScreen with email/password AppTextFields, login AppButton, error message display, loading state, BikeRide branding, centered card layout for web in `lib/features/admin/screens/admin_login_screen.dart`
- [x] T016 [US1] Create admin auth guard middleware extending GetMiddleware that checks AdminAuthController.isAuthenticated and redirects to adminLogin if false, also checking 7-day session expiry in `lib/features/admin/controllers/admin_auth_controller.dart` (add GetMiddleware class at bottom of file)

**Checkpoint**: Admin can log in, non-admins are blocked, session persists across browser restart

---

## Phase 4: User Story 2 — Layout Shell with Responsive Navigation (Priority: P1)

**Goal**: Authenticated admin sees responsive sidebar + topbar layout on every screen. Sidebar adapts: desktop expanded (240px), tablet icons-only (72px), mobile drawer.

**Independent Test**: Navigate between sidebar items at different browser widths. Verify responsive behavior, active highlighting, and pending document badge.

**Dependencies**: US1 (auth must work for layout to show)

### Implementation for User Story 2

- [x] T017 [US2] Create AdminLayoutController extending GetxController (permanent) with: currentRoute observable, isSidebarExpanded, screenWidth tracking via LayoutBuilder, pendingReviewCount stream from Firestore documents where status==pending, sidebar items list with icons/labels/routes/badges, toggleSidebar(), navigateTo(route), updateActivityTimestamp() in `lib/features/admin/controllers/admin_layout_controller.dart`
- [x] T018 [US2] Create AdminSidebar widget with SidebarItem list rendering, active route highlighting via Obx, pending review badge on Document Review item, expanded mode (240px with icons+labels), collapsed mode (72px icons-only), responsive behavior, admin role check to show/hide config items in `lib/features/admin/widgets/admin_sidebar.dart`
- [x] T019 [US2] Create AdminTopbar widget with current section title, global search placeholder (wired in US12), admin name/email display, logout button, language toggle, hamburger menu for mobile in `lib/features/admin/widgets/admin_topbar.dart`
- [x] T020 [US2] Create AdminLayoutShell screen that wraps content with AdminSidebar + AdminTopbar using LayoutBuilder for responsive breakpoints (>1200px expanded, 768-1200px collapsed, <768px drawer), accepts child widget via GetX nested navigation in `lib/features/admin/screens/admin_layout_shell.dart`
- [x] T021 [US2] Create admin_pages.dart with GetPage list for all admin routes (login, dashboard, customers, customer detail, drivers, driver detail, documents, trips, trip detail, financial, config, promos, referrals, notifications, analytics) each with their binding and wrapped in AdminLayoutShell where appropriate in `lib/core/routes/admin_pages.dart`
- [x] T022 [US2] Update main_admin.dart to register AdminAuthController + AdminLayoutController as permanent, set initialRoute to adminLogin, use adminPages from admin_pages.dart, add auth guard middleware to all protected routes in `lib/main_admin.dart`

**Checkpoint**: Admin sees responsive layout shell with working sidebar navigation and topbar on all screens

---

## Phase 5: User Story 3 — Document Review Queue (Priority: P1)

**Goal**: Admin sees two-panel layout with pending drivers list (left) and document image previews (right). Can approve all or reject with reason. Driver gets notified.

**Independent Test**: Select a pending driver, review document images, approve them, verify driver activated and notified.

**Dependencies**: US2 (layout shell)

### Implementation for User Story 3

- [x] T023 [US3] Create DocumentImageViewer widget with CachedNetworkImage thumbnail, onTap opens Dialog with InteractiveViewer for full-size zoom/pan, loading/error states, placeholder for broken URLs in `lib/features/admin/widgets/document_image_viewer.dart`
- [x] T024 [US3] Create AdminDocumentsController extending GetxController with: pendingDrivers list (grouped by driver_uid from Firestore documents where status==pending), selectedDriver observable, loadDocumentsForDriver(uid), approveAll(driverUid) calling approveDriver Cloud Function, reject(driverUid, reason) calling Firestore update + FCM, real-time stream subscription for pending documents in `lib/features/admin/controllers/admin_documents_controller.dart`
- [x] T025 [US3] Create AdminDocumentsBinding that registers AdminDocumentsController via Get.lazyPut in `lib/features/admin/bindings/admin_documents_binding.dart`
- [x] T026 [US3] Create AdminDocumentsScreen with two-panel responsive layout: left panel shows scrollable list of pending drivers (name, phone, time since submission), right panel shows selected driver's 3 document image cards (National ID, License, Vehicle Registration) using DocumentImageViewer, "Approve All" and "Reject" buttons with ConfirmDialog, empty state when no pending reviews in `lib/features/admin/screens/admin_documents_screen.dart`

**Checkpoint**: Admin can review and approve/reject driver documents with notifications sent

---

## Phase 6: User Story 4 — Dashboard with Live Stats and Charts (Priority: P2)

**Goal**: Dashboard shows 4 stat cards (trips today, revenue, drivers online, pending reviews), 30-day revenue chart, live driver map, and recent trips table.

**Independent Test**: Load dashboard, verify stats match data. Observe real-time driver online count update. Check chart data points.

**Dependencies**: US2 (layout shell)

### Implementation for User Story 4

- [x] T027 [P] [US4] Create DashboardStatsModel with tripsToday, revenueToday, driversOnline, pendingReviews, totalCustomers, totalDrivers, weeklyTrips, weeklyRevenue, cancellationRate fields and default constructor in `lib/features/admin/models/dashboard_stats_model.dart`
- [x] T028 [P] [US4] Create StatCard widget with icon, title, value (animated counter), subtitle, optional trend indicator, responsive sizing, using AppCard and AppColorsExtension colors in `lib/features/admin/widgets/stat_card.dart`
- [x] T029 [US4] Create AdminDashboardController extending GetxController with: stats observable (DashboardStatsModel), revenueChartData (List<ChartDataPoint>), recentTrips (List<TripModel>), real-time Realtime DB listener for driversOnline, Firestore snapshot listeners for tripsToday/revenueToday/pendingReviews, loadRevenueChart() querying last 30 days of completed trips aggregated by day, loadRecentTrips() fetching 10 most recent in `lib/features/admin/controllers/admin_dashboard_controller.dart`
- [x] T030 [US4] Create AdminDashboardBinding that registers AdminDashboardController via Get.lazyPut in `lib/features/admin/bindings/admin_dashboard_binding.dart`
- [x] T031 [US4] Create AdminDashboardScreen with: 4 StatCards in responsive grid (4-col desktop, 2x2 tablet, stacked mobile), 30-day LineChart for revenue using fl_chart, AppMapWidget showing live driver locations from Realtime DB, recent trips table (10 rows) with trip type badge, status badge, fare, date, and row tap navigating to trip detail in `lib/features/admin/screens/admin_dashboard_screen.dart`

**Checkpoint**: Dashboard displays live stats, revenue chart, driver map, and recent trips

---

## Phase 7: User Story 5 — Customer Management (Priority: P2)

**Goal**: Paginated customer table with search/filter. View customer detail with profile, wallet, trips. Suspend/activate and adjust wallet.

**Independent Test**: Search customer, view profile, suspend/reactivate, adjust wallet balance.

**Dependencies**: US2 (layout shell)

### Implementation for User Story 5

- [x] T032 [US5] Create AdminUsersController extending GetxController with: customers list with cursor pagination, searchQuery observable, statusFilter observable, loadCustomers() using AdminFirestoreService.getPaginatedUsers(type: customer), searchCustomers(query), filterByStatus(status), selectedUser observable, loadUserDetail(uid) fetching user + wallet + recent trips, suspendUser(uid, reason) calling suspendUser CF, activateUser(uid), adjustWallet(uid, amount, reason) calling adjustWalletBalance CF in `lib/features/admin/controllers/admin_users_controller.dart`
- [x] T033 [US5] Create AdminUsersBinding that registers AdminUsersController via Get.lazyPut in `lib/features/admin/bindings/admin_users_binding.dart`
- [x] T034 [US5] Create AdminCustomersScreen with AdminDataTable showing customer columns (name, phone, status, wallet balance, created date), search field, status filter dropdown, "View" action per row navigating to customer detail in `lib/features/admin/screens/admin_customers_screen.dart`
- [x] T035 [US5] Create AdminCustomerDetailScreen with: profile card (avatar, name, phone, email, status badge, created date), wallet card (balance, adjust button opening amount+reason dialog calling adjustWallet CF), recent trips table (last 10), suspend/activate toggle button with ConfirmDialog, back navigation in `lib/features/admin/screens/admin_customer_detail_screen.dart`

**Checkpoint**: Admin can browse, search, view, suspend/activate customers and adjust wallets

---

## Phase 8: User Story 6 — Driver Management (Priority: P2)

**Goal**: Paginated driver table with search, approval status filter, online status filter. View driver detail with vehicle info, stats, documents.

**Independent Test**: Filter drivers by approval and online status, view profile, perform approve/reject/suspend.

**Dependencies**: US2 (layout shell)

### Implementation for User Story 6

- [x] T036 [US6] Create AdminDriversController extending GetxController with: drivers list with cursor pagination, approvalFilter (all/approved/pending/rejected), onlineFilter (all/online/offline), searchQuery, loadDrivers() joining users (type:driver) with driver_profiles, filterByApproval(status), filterByOnline(status), selectedDriver observable, loadDriverDetail(uid) fetching user + driverProfile + documents, approveDriver(uid) calling approveDriver CF, rejectDriver(uid, reason), suspendDriver(uid, reason) calling suspendUser CF, activateDriver(uid) in `lib/features/admin/controllers/admin_drivers_controller.dart`
- [x] T037 [US6] Create AdminDriversBinding that registers AdminDriversController via Get.lazyPut in `lib/features/admin/bindings/admin_drivers_binding.dart`
- [x] T038 [US6] Create AdminDriversScreen with AdminDataTable showing driver columns (name, phone, vehicle type, approval status badge, online status indicator, rating, total trips), search field, approval status filter, online status filter, "View" action per row in `lib/features/admin/screens/admin_drivers_screen.dart`
- [x] T039 [US6] Create AdminDriverDetailScreen with: profile card (name, phone, status), vehicle info card (type, plate, model), performance card (total trips, avg rating, total earnings, online status), documents card (3 DocumentImageViewer cards for National ID, License, Vehicle Registration), action buttons (approve/reject/suspend/activate with ConfirmDialog), back navigation in `lib/features/admin/screens/admin_driver_detail_screen.dart`

**Checkpoint**: Admin can browse, filter, view, and manage drivers with full profile and document visibility

---

## Phase 9: User Story 7 — Trips Management (Priority: P3)

**Goal**: Filterable paginated trips table. Trip detail with route map, payment info, bids, status timeline. Issue credit for dispute resolution.

**Independent Test**: Filter trips, view detail, issue credit to customer.

**Dependencies**: US2 (layout shell)

### Implementation for User Story 7

- [x] T040 [US7] Create AdminTripsController extending GetxController with: trips list with cursor pagination, typeFilter (all/ride/c2c/b2b), statusFilter, dateRange, loadTrips() using AdminFirestoreService.getPaginatedTrips with compound filters, selectedTrip observable, loadTripDetail(tripId) fetching trip + bids subcollection + customer user + driver user, issueCredit(tripId, customerUid, amount, reason) calling adjustWalletBalance CF in `lib/features/admin/controllers/admin_trips_controller.dart`
- [x] T041 [US7] Create AdminTripsBinding that registers AdminTripsController via Get.lazyPut in `lib/features/admin/bindings/admin_trips_binding.dart`
- [x] T042 [US7] Create AdminTripsScreen with AdminDataTable showing trip columns (trip ID, type badge, status badge, customer name, driver name, fare, payment method, date), type filter, status filter, DateRangePicker, row tap to detail in `lib/features/admin/screens/admin_trips_screen.dart`
- [x] T043 [US7] Create AdminTripDetailScreen with: trip info card (type, status timeline, timestamps), route map section using AppMapWidget with pickup/dropoff markers and polyline, payment card (suggested price, final price, commission, payment method, promo discount), customer mini-card (name, phone, link to detail), driver mini-card (name, phone, vehicle, link to detail), bids table (all bids with driver name, amount, status), "Issue Credit" button (for completed trips) opening amount+reason dialog in `lib/features/admin/screens/admin_trip_detail_screen.dart`

**Checkpoint**: Admin can browse, filter, inspect trip details with map, and issue credits

---

## Phase 10: User Story 8 — Financial & Transaction Ledger (Priority: P3)

**Goal**: Financial summary cards, filterable transaction table with CSV export, commission breakdown by service type.

**Independent Test**: View summary cards, filter transactions, export CSV, verify commission breakdown.

**Dependencies**: US2 (layout shell)

### Implementation for User Story 8

- [x] T044 [P] [US8] Create FinancialSummaryModel with totalRevenue, totalCommission, totalTopUps, totalRefunds, dateFrom, dateTo fields in `lib/features/admin/models/financial_summary_model.dart`
- [x] T045 [US8] Create AdminFinancialController extending GetxController with: summary observable (FinancialSummaryModel), transactions list with cursor pagination, commissionBreakdown (List per TripType with tripCount, totalFare, commissionRate, commissionEarned), dateRange filter, paymentMethodFilter, transactionTypeFilter, loadSummary(dateRange), loadTransactions() with compound filters, loadCommissionBreakdown(dateRange), exportCsv() generating CSV string and triggering browser download via dart:html AnchorElement in `lib/features/admin/controllers/admin_financial_controller.dart`
- [x] T046 [US8] Create AdminFinancialBinding that registers AdminFinancialController via Get.lazyPut in `lib/features/admin/bindings/admin_financial_binding.dart`
- [x] T047 [US8] Create AdminFinancialScreen with: 4 summary StatCards (total revenue, commission, top-ups, refunds), DateRangePicker for period selection, transaction AdminDataTable (columns: ID, user, type badge, amount, method, status, date) with payment method filter and type filter, "Export CSV" AppButton, commission breakdown table (service type, trip count, total fare, rate, commission earned) in `lib/features/admin/screens/admin_financial_screen.dart`

**Checkpoint**: Admin can view financial summaries, filter transactions, export CSV, and see commission breakdown

---

## Phase 11: User Story 9 — App Configuration (Priority: P3)

**Goal**: Editable fields for pricing, multipliers, commissions, bidding, referral rewards. Unsaved changes banner. Maintenance mode toggle. Super_admin only.

**Independent Test**: Change a pricing value, save, verify customer app reflects new price.

**Dependencies**: US2 (layout shell). Super_admin role required (FR-035).

### Implementation for User Story 9

- [x] T048 [US9] Create AdminConfigController extending GetxController with: configFields map (base_fare, price_per_km, price_per_min, surge_multiplier, motorcycle/scooter/ebike multipliers, commission_ride, commission_c2c, commission_b2b, min_bid_radius_km, bid_timeout_seconds, referrer_reward, referee_reward, maintenance_mode), originalValues for dirty tracking, hasUnsavedChanges computed, loadConfig() from Firestore app_config/config, saveConfig() calling updateAppConfig CF (super_admin check), resetToSaved(), toggleMaintenanceMode() with ConfirmDialog, validateInputs() (no negatives, no zero fares) in `lib/features/admin/controllers/admin_config_controller.dart`
- [x] T049 [US9] Create AdminConfigBinding that registers AdminConfigController via Get.lazyPut in `lib/features/admin/bindings/admin_config_binding.dart`
- [x] T050 [US9] Create AdminConfigScreen with: role check (redirect regular admin with snackbar per FR-038), grouped form sections (Pricing, Vehicle Multipliers, Commission Rates, Bidding Settings, Referral Rewards) each with AppTextFields and labels, orange "Unsaved changes" banner when dirty, "Save" and "Reset" AppButtons, Maintenance Mode toggle with red warning ConfirmDialog, input validation error messages in `lib/features/admin/screens/admin_config_screen.dart`

**Checkpoint**: Super admin can view, edit, save, and reset platform configuration with validation

---

## Phase 12: User Story 10 — Promo Code Management (Priority: P3)

**Goal**: Table of promo codes with filters. Create, edit, deactivate promos. Usage counts visible.

**Independent Test**: Create promo code, use it in customer app, verify usage count increments.

**Dependencies**: US2 (layout shell)

### Implementation for User Story 10

- [x] T051 [US10] Create AdminPromosController extending GetxController with: promos list from Firestore promo_codes collection, statusFilter (all/active/expired/inactive/exhausted), loadPromos(), createPromo(code, type, value, maxUses, minTripValue, expiryDate) writing to Firestore, editPromo(code, updates), deactivatePromo(code) setting is_active=false, isExhausted(promo) checking used_count>=max_uses in `lib/features/admin/controllers/admin_promos_controller.dart`
- [x] T052 [US10] Create AdminPromosBinding that registers AdminPromosController via Get.lazyPut in `lib/features/admin/bindings/admin_promos_binding.dart`
- [x] T053 [US10] Create AdminPromosScreen with: AdminDataTable showing promo columns (code, type badge, value, max uses, used count, min trip value, expiry date, status badge), status filter, "Create New" AppButton opening form dialog (code, type dropdown, value, max uses, min trip, expiry DatePicker), row actions (edit, deactivate with ConfirmDialog) in `lib/features/admin/screens/admin_promos_screen.dart`

**Checkpoint**: Admin can manage promo codes with full CRUD and usage tracking

---

## Phase 13: User Story 11 — Push Notification Sender (Priority: P3)

**Goal**: Select target segment or specific user. Enter bilingual title/body. Preview card. Confirmation before send. Sent history table.

**Independent Test**: Send notification to specific user, verify received on device.

**Dependencies**: US2 (layout shell)

### Implementation for User Story 11

- [x] T054 [P] [US11] Create NotificationRecordModel with id, targetSegment, titleAr, titleEn, bodyAr, bodyEn, senderUid, senderName, sentAt fields, fromJson/toJson methods in `lib/features/admin/models/notification_record_model.dart`
- [x] T055 [P] [US11] Create NotificationPreviewCard widget showing mock phone notification appearance with title and body text, switching between Arabic and English preview in `lib/features/admin/widgets/notification_preview_card.dart`
- [x] T056 [US11] Create AdminNotificationsController extending GetxController with: targetSegment observable (all/customers/drivers/specific), specificUid, titleAr, titleEn, bodyAr, bodyEn, isFormValid computed, sendNotification() calling sendToSegment or sendToUser CF then writing NotificationRecord to admin_notifications collection, sentHistory list from Firestore admin_notifications ordered by sent_at desc, loadSentHistory() in `lib/features/admin/controllers/admin_notifications_controller.dart`
- [x] T057 [US11] Create AdminNotificationsBinding that registers AdminNotificationsController via Get.lazyPut in `lib/features/admin/bindings/admin_notifications_binding.dart`
- [x] T058 [US11] Create AdminNotificationsScreen with two tabs: "Send" tab (segment selector dropdown, specific UID field when "specific" selected, Arabic title/body AppTextFields, English title/body AppTextFields, NotificationPreviewCard, disabled send button when form invalid, ConfirmDialog showing target audience + preview before sending) and "History" tab (AdminDataTable with columns: timestamp, target, title, sender) in `lib/features/admin/screens/admin_notifications_screen.dart`

**Checkpoint**: Admin can compose, preview, and send bilingual notifications with sent history

---

## Phase 14: User Story 12 — Global User Search (Priority: P3)

**Goal**: Topbar search field searches users by phone/name. Dropdown shows matches with type badge. Click navigates to detail.

**Independent Test**: Type phone number in topbar search, verify correct user appears, click navigates to detail.

**Dependencies**: US2 (layout shell), US5 (customer detail screen), US6 (driver detail screen)

### Implementation for User Story 12

- [x] T059 [US12] Create AdminSearchController extending GetxController with: searchQuery observable, searchResults list (UserModel), isSearching flag, search(query) with 300ms debounce calling AdminFirestoreService.searchUsersByPhone then searchUsersByName, clearSearch(), navigateToResult(user) routing to customer or driver detail based on user.type in `lib/features/admin/controllers/admin_search_controller.dart`
- [x] T060 [US12] Wire global search into AdminTopbar: add AdminSearchController (Get.lazyPut), search AppTextField with onChanged triggering debounced search, dropdown overlay below search field showing results with name, phone, UserType badge (customer/driver), onTap calling navigateToResult, close on outside tap in `lib/features/admin/widgets/admin_topbar.dart`

**Checkpoint**: Admin can search any user from any screen via topbar and navigate to their detail

---

## Phase 15: User Story 13 — Referral Program Settings (Priority: P4)

**Goal**: Configure referrer/referee reward amounts. View referral statistics and paginated history.

**Independent Test**: Change referral reward, verify next referral uses updated value.

**Dependencies**: US2 (layout shell). Reward config is part of app_config (super_admin write via US9 CF).

### Implementation for User Story 13

- [x] T061 [P] [US13] Create ReferralStatsModel with totalReferrals, totalRewarded, totalPayout fields in `lib/features/admin/models/referral_stats_model.dart`
- [x] T062 [US13] Create AdminReferralController extending GetxController with: referralStats observable (ReferralStatsModel), referralHistory list with cursor pagination from Firestore referrals collection, referrerReward/refereeReward from app_config, loadStats() aggregating referrals collection, loadHistory(), saveRewards(referrerAmount, refereeAmount) calling updateAppConfig CF (super_admin check) in `lib/features/admin/controllers/admin_referral_controller.dart`
- [x] T063 [US13] Create AdminReferralBinding that registers AdminReferralController via Get.lazyPut in `lib/features/admin/bindings/admin_referral_binding.dart`
- [x] T064 [US13] Create AdminReferralScreen with: 3 StatCards (total referrals, total rewarded, total payout EGP), reward config section (referrer amount, referee amount AppTextFields with save AppButton — disabled for regular admin per FR-038), referral history AdminDataTable (columns: referrer, referee, reward amount, status badge, date) in `lib/features/admin/screens/admin_referral_screen.dart`

**Checkpoint**: Admin can view referral stats/history, super admin can adjust reward amounts

---

## Phase 16: User Story 14 — Analytics & Reports (Priority: P4)

**Goal**: Charts for trip volume (stacked bar), payment breakdown (pie), cancellation trend (line), top 10 drivers table. Period selector (7/30/90 days). CSV export.

**Independent Test**: Load analytics, change period, verify chart data matches records.

**Dependencies**: US2 (layout shell)

### Implementation for User Story 14

- [x] T065 [US14] Create AdminAnalyticsController extending GetxController with: selectedPeriod (7/30/90 days), tripVolumeData (List<ChartDataPoint> per TripType for stacked bar), paymentBreakdown (Map<PaymentMethod, double> for pie chart), cancellationTrend (List<ChartDataPoint> for line chart), topDrivers (List of driver name, trips, earnings, rating), loadAllCharts(period), exportReport() generating CSV and downloading via dart:html in `lib/features/admin/controllers/admin_analytics_controller.dart`
- [x] T066 [US14] Create AdminAnalyticsBinding that registers AdminAnalyticsController via Get.lazyPut in `lib/features/admin/bindings/admin_analytics_binding.dart`
- [x] T067 [US14] Create AdminAnalyticsScreen with: period selector (7d/30d/90d toggle buttons), trip volume stacked BarChart using fl_chart (rides/c2c/b2b stacked by day), payment method PieChart using fl_chart with legend, cancellation rate LineChart using fl_chart, top 10 drivers table (rank, name, trips, earnings, rating) with row tap navigating to driver detail, "Export Report" AppButton in `lib/features/admin/screens/admin_analytics_screen.dart`

**Checkpoint**: Admin can view all analytics charts, toggle periods, and export reports

---

## Phase 17: User Story 15 — Deploy to cPanel (Priority: P4)

**Goal**: Build Flutter Web release, deploy to cPanel as static files, verify on all browsers.

**Independent Test**: Build release, upload to cPanel, verify login and all features work.

**Dependencies**: All other user stories complete

### Implementation for User Story 15

- [x] T068 [US15] Verify web build configuration: ensure `web/index.html` has correct base href, favicon, and title; verify no web-incompatible plugins in admin-only code paths in `web/index.html`
- [x] T069 [US15] Add Firestore security rules for admin_notifications collection (read/write by admin/super_admin custom claim) to `firestore.rules`
- [x] T070 [US15] Add composite Firestore indexes for admin queries (users by type+status+createdAt, trips by type+status+createdAt, transactions by method+createdAt, documents by status+createdAt, promo_codes by is_active+expiry_date) to `firestore.indexes.json`

**Checkpoint**: Admin panel builds, deploys, and works correctly on all target browsers

---

## Phase 18: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [x] T071 [P] Add RTL layout verification: test all admin screens with Arabic locale, verify sidebar flips, text alignment, directional icons in all screens under `lib/features/admin/screens/`
- [x] T072 [P] Add loading states and error handling: ensure all controllers show AppLoading during data fetch, AppSnackbar.error on failures, retry mechanisms for network errors across all admin controllers
- [x] T073 [P] Add empty states: ensure all data tables and list views show appropriate empty state messages when no data matches filters across all admin screens
- [ ] T074 Responsive layout verification: test all screens at 768px, 1024px, 1280px, 1440px, 1920px breakpoints; fix any overflow, wrapping, or alignment issues across all admin screens
- [ ] T075 Cross-browser testing: verify all functionality works on Chrome, Firefox, Safari, and Edge; fix any browser-specific CSS or JavaScript compatibility issues

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion — BLOCKS all user stories
- **US1 Auth (Phase 3)**: Depends on Foundational — BLOCKS US2
- **US2 Layout (Phase 4)**: Depends on US1 — BLOCKS all remaining user stories (US3-US15)
- **US3-US15 (Phases 5-17)**: All depend on US2 completion. Can then proceed in parallel or priority order.
- **Polish (Phase 18)**: Depends on all desired user stories being complete

### User Story Dependencies

```
Phase 1: Setup
    |
Phase 2: Foundational
    |
Phase 3: US1 (Auth) <-- GATE: must complete before any other story
    |
Phase 4: US2 (Layout Shell) <-- GATE: must complete before content stories
    |
    +-- Phase 5:  US3  (Document Review)     [P1] -- independent
    +-- Phase 6:  US4  (Dashboard)           [P2] -- independent
    +-- Phase 7:  US5  (Customer Mgmt)       [P2] -- independent
    +-- Phase 8:  US6  (Driver Mgmt)         [P2] -- independent
    +-- Phase 9:  US7  (Trips)               [P3] -- independent
    +-- Phase 10: US8  (Financial)           [P3] -- independent
    +-- Phase 11: US9  (Config)              [P3] -- independent (super_admin)
    +-- Phase 12: US10 (Promos)              [P3] -- independent
    +-- Phase 13: US11 (Notifications)       [P3] -- independent
    +-- Phase 14: US12 (Global Search)       [P3] -- soft dep on US5+US6 (detail screens)
    +-- Phase 15: US13 (Referrals)           [P4] -- independent
    +-- Phase 16: US14 (Analytics)           [P4] -- independent
    +-- Phase 17: US15 (Deployment)          [P4] -- depends on all stories
    |
Phase 18: Polish
```

### Within Each User Story

- Models before controllers (if story has new models)
- Controllers before screens
- Widgets before screens that use them
- Bindings alongside controllers

### Parallel Opportunities

**After US2 completes, these stories can run in parallel:**
- US3 + US4 + US5 + US6 (all independent, different files)
- US7 + US8 + US9 + US10 + US11 (all independent, different files)
- US13 + US14 (both independent)
- US12 should run after US5+US6 (needs detail screens)

**Within stories, [P] tasks can run in parallel:**
- US4: T027 + T028 (model + widget, different files)
- US8: T044 (model) in parallel with other story work
- US11: T054 + T055 (model + widget, different files)
