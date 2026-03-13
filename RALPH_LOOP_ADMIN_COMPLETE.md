# BikeRide Admin Dashboard - Complete Implementation Tasks

> **Project**: BikeRide Admin Dashboard (Flutter Web)
> **Total Tasks**: 205 tasks across 2 major modules
> **Estimated Timeline**: ~5 weeks
> **Tech Stack**: Flutter Web + Firebase + GetX + Filament-style Admin UI

---

## 📋 MODULE 1: ADMIN CRUD OPERATIONS & DRIVER APPROVAL (99 Tasks)

### Part 1: Driver Approval Workflow (25 Tasks) - CRITICAL PRIORITY

#### Phase 1.1: Service Layer (6 Tasks)

- [ ] **T-APPROVE-1.1**: Add `getPendingDrivers()` to `AdminFirestoreService`
  - Returns drivers with status: `pending_approval`
  - Ordered by `createdAt` ascending (oldest first)
  - Pagination support with `limit` and `startAfter`
  - **File**: `lib/features/admin/services/admin_firestore_service.dart`
  
- [ ] **T-APPROVE-1.2**: Add `getDriverWithDocuments(String driverUid)` to service
  - Returns driver profile + user + all documents in single call
  - For comprehensive review screen
  - **File**: `lib/features/admin/services/admin_firestore_service.dart`

- [ ] **T-APPROVE-1.3**: Add `approveDriver(String driverUid, String adminUid)` to service
  - Atomic batch write: Update `driver_profiles.isApproved = true`
  - Set `driver_profiles.approvedAt = timestamp`
  - Set `driver_profiles.approvedBy = adminUid`
  - Update `users.status = active`
  - Create `wallets/{driverUid}` with balance: 0
  - Update all `documents.status = approved`
  - **File**: `lib/features/admin/services/admin_firestore_service.dart`

- [ ] **T-APPROVE-1.4**: Add `rejectDriverDocuments()` to service
  - Reject specific documents with reason
  - Driver stays pending, can re-upload rejected docs
  - Update `document.status = rejected`
  - Add `adminNote` with rejection reason
  - **File**: `lib/features/admin/services/admin_firestore_service.dart`

- [ ] **T-APPROVE-1.5**: Add `rejectDriverCompletely()` to service
  - Full rejection - driver cannot re-apply
  - Update `users.status = rejected`
  - Store rejection reason and admin who rejected
  - **File**: `lib/features/admin/services/admin_firestore_service.dart`

- [ ] **T-APPROVE-1.6**: Add `sendApprovalNotification()` to FcmService
  - Send FCM to driver on approval/rejection
  - Include rejection reason if applicable
  - **File**: `lib/core/services/fcm_service.dart`

#### Phase 1.2: Model Updates (3 Tasks)

- [ ] **T-APPROVE-2.1**: Update `DriverProfileModel` with approval fields
  - Add: `bool isApproved`
  - Add: `DateTime? approvedAt`
  - Add: `String? approvedBy` (admin uid)
  - Add: `String? rejectionReason`
  - Add: `int rejectionCount`
  - **File**: `lib/features/admin/models/driver_profile_model.dart`

- [ ] **T-APPROVE-2.2**: Create `DriverReviewData` model
  - Contains: `UserModel user`
  - Contains: `DriverProfileModel driverProfile`
  - Contains: `List<DocumentModel> documents`
  - Contains: `int pendingDocumentCount`
  - Contains: `int approvedDocumentCount`
  - Contains: `int rejectedDocumentCount`
  - **File**: `lib/features/admin/models/driver_review_data.dart`

- [ ] **T-APPROVE-2.3**: Create `ApprovalStatsModel` for dashboard
  - Fields: `int pendingCount`
  - Fields: `int approvedTodayCount`
  - Fields: `int rejectedTodayCount`
  - Fields: `double avgApprovalTimeHours`
  - **File**: `lib/features/admin/models/approval_stats_model.dart`

#### Phase 1.3: Controller Updates (4 Tasks)

- [ ] **T-APPROVE-3.1**: Create `AdminApprovalController`
  - Observable: `pendingDrivers`, `selectedDriver`, `isLoading`, `approvalStats`
  - Methods: `loadPendingDrivers()`, `selectDriver()`, `approveDriver()`, `rejectDocuments()`, `rejectCompletely()`
  - **File**: `lib/features/admin/controllers/admin_approval_controller.dart`

- [ ] **T-APPROVE-3.2**: Update `AdminDriversController` with approval actions
  - Add `approveDriver(String driverUid)`
  - Add `rejectDriver(String driverUid, String reason)`
  - Add `suspendDriver(String driverUid, String reason)`
  - **File**: `lib/features/admin/controllers/admin_drivers_controller.dart`

- [ ] **T-APPROVE-3.3**: Update `AdminDocumentsController` with bulk actions
  - Add `approveAllDriverDocuments(String driverUid)`
  - Add `rejectSelectedDocuments(List<String> docIds, String reason)`
  - **File**: `lib/features/admin/controllers/admin_documents_controller.dart`

- [ ] **T-APPROVE-3.4**: Add approval stats to `AdminDashboardController`
  - Observable: `pendingApprovalsCount`
  - Stream: `approvalQueueStream`
  - **File**: `lib/features/admin/controllers/admin_dashboard_controller.dart`

#### Phase 1.4: Widget Layer (6 Tasks)

- [ ] **T-APPROVE-4.1**: Create `ApprovalQueueCard` widget
  - Shows driver info + document thumbnails + action buttons
  - Displays: Driver name, phone, vehicle type
  - Shows: Document preview thumbnails (tap to expand)
  - Buttons: APPROVE / REJECT
  - Shows: Time since registration
  - **File**: `lib/features/admin/widgets/approval_queue_card.dart`

- [ ] **T-APPROVE-4.2**: Create `DocumentReviewGrid` widget
  - Grid of document thumbnails with status badges
  - Click to view full size
  - Individual approve/reject per document
  - Status indicators: pending | approved | rejected
  - **File**: `lib/features/admin/widgets/document_review_grid.dart`

- [ ] **T-APPROVE-4.3**: Create `RejectionReasonDialog` widget
  - Modal dialog for rejection
  - Dropdown of common reasons (blurry, expired, wrong document)
  - Free text field for custom reason
  - Required before rejection
  - **File**: `lib/features/admin/widgets/rejection_reason_dialog.dart`

- [ ] **T-APPROVE-4.4**: Create `ApprovalConfirmationDialog` widget
  - Confirmation before approving
  - Show driver summary
  - Show document checklist (all must be approved)
  - Warn if any document pending/rejected
  - **File**: `lib/features/admin/widgets/approval_confirmation_dialog.dart`

- [ ] **T-APPROVE-4.5**: Create `DriverApprovalSummary` widget
  - Header showing approval stats
  - Pending count with urgency indicator
  - Approved today count
  - Average wait time
  - **File**: `lib/features/admin/widgets/driver_approval_summary.dart`

- [ ] **T-APPROVE-4.6**: Create `ApprovalTimeline` widget
  - Show driver's journey through approval
  - Registration date
  - Document upload dates
  - Review dates
  - Approval/rejection date
  - **File**: `lib/features/admin/widgets/approval_timeline.dart`

#### Phase 1.5: Screen Updates (4 Tasks)

- [ ] **T-APPROVE-5.1**: Create `AdminApprovalQueueScreen`
  - Main approval dashboard
  - Stats header (ApprovalQueueCard)
  - List of pending drivers
  - Filter by: registration date, vehicle type
  - Sort by: oldest first, newest first
  - **File**: `lib/features/admin/screens/admin_approval_queue_screen.dart`

- [ ] **T-APPROVE-5.2**: Create `AdminDriverReviewScreen`
  - Full driver review page
  - Driver info section (name, phone, vehicle, license)
  - Document review grid (all documents with preview)
  - Approval timeline
  - Action buttons: APPROVE ALL / REJECT
  - **File**: `lib/features/admin/screens/admin_driver_review_screen.dart`

- [ ] **T-APPROVE-5.3**: Update `AdminDashboardScreen` with approval stats
  - Add "Pending Approvals" card
  - Show count of pending drivers
  - Quick link to approval queue
  - Alert if pending > 5
  - **File**: `lib/features/admin/screens/admin_dashboard_screen.dart`

- [ ] **T-APPROVE-5.4**: Update navigation to include approval queue
  - Add "Approvals" menu item in sidebar
  - Badge showing pending count
  - **File**: `lib/features/admin/widgets/admin_sidebar.dart`

#### Phase 1.6: Integration Tests (2 Tasks)

- [ ] **T-APPROVE-6.1**: Write approval workflow integration test
  - Test: Load pending drivers
  - Test: Select driver and load documents
  - Test: Approve driver (verify all updates)
  - Test: Reject documents (verify notifications)
  - **File**: `test/integration/driver_approval_test.dart`

- [ ] **T-APPROVE-6.2**: Write approval edge cases test
  - Test: Approve with missing documents (should fail)
  - Test: Reject without reason (should fail)
  - Test: Double approval (should be idempotent)
  - **File**: `test/integration/driver_approval_edge_cases_test.dart`

---

### Part 2: Customer CRUD Operations (15 Tasks)

#### Phase 2.1: Service Layer (4 Tasks)

- [ ] **T-CUSTOMER-1.1**: Add `createCustomer()` to service
  - Create Firebase Auth user
  - Create Firestore user document
  - Create wallet document
  - Send welcome SMS/email
  - **File**: `lib/features/admin/services/admin_firestore_service.dart`

- [ ] **T-CUSTOMER-1.2**: Add `updateCustomer()` to service
  - Update user profile fields
  - Handle phone number changes (verify)
  - Log audit entry
  - **File**: `lib/features/admin/services/admin_firestore_service.dart`

- [ ] **T-CUSTOMER-1.3**: Add `deleteCustomer()` to service
  - Soft delete (set `deletedAt`)
  - Disable Firebase Auth
  - Check for active trips (prevent if any)
  - **File**: `lib/features/admin/services/admin_firestore_service.dart`

- [ ] **T-CUSTOMER-1.4**: Add `getCustomerStats()` to service
  - Returns: Total trips, total spent, wallet balance
  - Returns: Last trip date, registration date
  - **File**: `lib/features/admin/services/admin_firestore_service.dart`

#### Phase 2.2: Controller Updates (3 Tasks)

- [ ] **T-CUSTOMER-2.1**: Update `AdminCustomersController`
  - Add `createCustomer()` method
  - Add `updateCustomer()` method
  - Add `deleteCustomer()` method
  - **File**: `lib/features/admin/controllers/admin_customers_controller.dart`

- [ ] **T-CUSTOMER-2.2**: Add customer stats loading
  - Load stats when viewing customer detail
  - Cache stats for performance
  - **File**: `lib/features/admin/controllers/admin_customers_controller.dart`

- [ ] **T-CUSTOMER-2.3**: Add validation for customer operations
  - Validate: Phone number format (Egyptian)
  - Validate: Email format
  - Validate: Required fields
  - **File**: `lib/features/admin/controllers/admin_customers_controller.dart`

#### Phase 2.3: Widget Layer (5 Tasks)

- [ ] **T-CUSTOMER-3.1**: Create `CreateCustomerDialog` widget
  - Form fields: Name, phone, email
  - Default wallet balance
  - Validation
  - **File**: `lib/features/admin/widgets/create_customer_dialog.dart`

- [ ] **T-CUSTOMER-3.2**: Create `EditCustomerDialog` widget
  - Edit: Name, phone, email
  - Warning for phone changes
  - **File**: `lib/features/admin/widgets/edit_customer_dialog.dart`

- [ ] **T-CUSTOMER-3.3**: Create `DeleteCustomerDialog` widget
  - Confirmation with warning
  - Check for active trips
  - Show customer stats before delete
  - **File**: `lib/features/admin/widgets/delete_customer_dialog.dart`

- [ ] **T-CUSTOMER-3.4**: Create `CustomerStatsCard` widget
  - Display: Total trips, total spent
  - Display: Wallet balance, last trip
  - **File**: `lib/features/admin/widgets/customer_stats_card.dart`

- [ ] **T-CUSTOMER-3.5**: Update customer detail screen with actions
  - Add: Edit button
  - Add: Delete button
  - Add: View trips button
  - **File**: `lib/features/admin/screens/admin_customer_detail_screen.dart`

#### Phase 2.4: Screen Updates (3 Tasks)

- [ ] **T-CUSTOMER-4.1**: Add "Create Customer" button to customers list
  - Floating action button
  - Opens CreateCustomerDialog
  - **File**: `lib/features/admin/screens/admin_customers_screen.dart`

- [ ] **T-CUSTOMER-4.2**: Add action menu to customer list items
  - Menu: Edit, Delete, View Details
  - **File**: `lib/features/admin/screens/admin_customers_screen.dart`

- [ ] **T-CUSTOMER-4.3**: Add customer stats section to detail screen
  - Show CustomerStatsCard
  - Show recent trips
  - **File**: `lib/features/admin/screens/admin_customer_detail_screen.dart`

---

### Part 3: Driver CRUD Operations (18 Tasks)

#### Phase 3.1: Service Layer (5 Tasks)

- [ ] **T-DRIVER-1.1**: Add `createDriver()` to service
  - Create Firebase Auth user
  - Create Firestore user + driver_profile documents
  - Create wallet document
  - Status: pending_approval
  - **File**: `lib/features/admin/services/admin_firestore_service.dart`

- [ ] **T-DRIVER-1.2**: Add `updateDriver()` to service
  - Update driver profile fields
  - Handle vehicle changes
  - **File**: `lib/features/admin/services/admin_firestore_service.dart`

- [ ] **T-DRIVER-1.3**: Add `deleteDriver()` to service
  - Soft delete driver
  - Check for active/pending trips
  - **File**: `lib/features/admin/services/admin_firestore_service.dart`

- [ ] **T-DRIVER-1.4**: Add `suspendDriver()` to service
  - Set driver status to suspended
  - Force driver offline
  - Send notification
  - **File**: `lib/features/admin/services/admin_firestore_service.dart`

- [ ] **T-DRIVER-1.5**: Add `getDriverEarnings()` to service
  - Calculate: Gross earnings, commission, tips, bonuses
  - Calculate: Net earnings
  - **File**: `lib/features/admin/services/admin_firestore_service.dart`

#### Phase 3.2: Model Updates (2 Tasks)

- [ ] **T-DRIVER-2.1**: Create `DriverEarningsModel`
  - Fields: `grossEarnings`, `commission`, `tips`, `bonuses`, `netEarnings`
  - Fields: `totalTrips`, `avgEarningPerTrip`
  - **File**: `lib/features/admin/models/driver_earnings_model.dart`

- [ ] **T-DRIVER-2.2**: Update `DriverProfileModel` with suspension fields
  - Add: `bool isSuspended`
  - Add: `DateTime? suspendedAt`
  - Add: `String? suspensionReason`
  - **File**: `lib/features/admin/models/driver_profile_model.dart`

#### Phase 3.3: Controller Updates (3 Tasks)

- [ ] **T-DRIVER-3.1**: Update `AdminDriversController`
  - Add `createDriver()` method
  - Add `updateDriver()` method
  - Add `deleteDriver()` method
  - Add `suspendDriver()` method
  - **File**: `lib/features/admin/controllers/admin_drivers_controller.dart`

- [ ] **T-DRIVER-3.2**: Add driver earnings loading
  - Load earnings when viewing driver detail
  - **File**: `lib/features/admin/controllers/admin_drivers_controller.dart`

- [ ] **T-DRIVER-3.3**: Add driver status management
  - Methods to change: online/offline/suspended/blocked
  - **File**: `lib/features/admin/controllers/admin_drivers_controller.dart`

#### Phase 3.4: Widget Layer (5 Tasks)

- [ ] **T-DRIVER-4.1**: Create `CreateDriverDialog` widget
  - Form: Name, phone, email, vehicle type, license plate
  - Validation
  - **File**: `lib/features/admin/widgets/create_driver_dialog.dart`

- [ ] **T-DRIVER-4.2**: Create `EditDriverDialog` widget
  - Edit: Profile fields, vehicle info
  - **File**: `lib/features/admin/widgets/edit_driver_dialog.dart`

- [ ] **T-DRIVER-4.3**: Create `DeleteDriverDialog` widget
  - Confirmation with stats
  - Check for active trips
  - **File**: `lib/features/admin/widgets/delete_driver_dialog.dart`

- [ ] **T-DRIVER-4.4**: Create `DriverEarningsCard` widget
  - Display: Gross/net earnings, trips count
  - **File**: `lib/features/admin/widgets/driver_earnings_card.dart`

- [ ] **T-DRIVER-4.5**: Create `ForceOfflineDialog` widget
  - Confirmation to force driver offline
  - Optional reason
  - **File**: `lib/features/admin/widgets/force_offline_dialog.dart`

#### Phase 3.5: Screen Updates (3 Tasks)

- [ ] **T-DRIVER-5.1**: Add "Create Driver" button to drivers list
  - Floating action button
  - Opens CreateDriverDialog
  - **File**: `lib/features/admin/screens/admin_drivers_screen.dart`

- [ ] **T-DRIVER-5.2**: Add action menu to driver list items
  - Menu: Edit, Delete, Suspend, Force Offline
  - **File**: `lib/features/admin/screens/admin_drivers_screen.dart`

- [ ] **T-DRIVER-5.3**: Add earnings section to driver detail screen
  - Show DriverEarningsCard
  - Show recent trips
  - **File**: `lib/features/admin/screens/admin_driver_detail_screen.dart`

---

### Part 4: Trip CRUD Operations (12 Tasks)

#### Phase 4.1: Service Layer (3 Tasks)

- [ ] **T-TRIP-1.1**: Add `createTrip()` to service
  - Manual trip creation (for testing/special cases)
  - Create trip document
  - Assign driver
  - **File**: `lib/features/admin/services/admin_firestore_service.dart`

- [ ] **T-TRIP-1.2**: Add `updateTripStatus()` to service
  - Admin can force status change
  - Handle refunds if needed
  - **File**: `lib/features/admin/services/admin_firestore_service.dart`

- [ ] **T-TRIP-1.3**: Add `reassignTrip()` to service
  - Change driver on trip
  - Notify both drivers
  - Update Realtime DB if trip active
  - **File**: `lib/features/admin/services/admin_firestore_service.dart`

#### Phase 4.2: Controller Updates (2 Tasks)

- [ ] **T-TRIP-2.1**: Update `AdminTripsController`
  - Add `createTrip()` method
  - Add `updateTripStatus()` method
  - Add `reassignTrip()` method
  - Add `cancelTrip()` method
  - **File**: `lib/features/admin/controllers/admin_trips_controller.dart`

- [ ] **T-TRIP-2.2**: Add trip validation
  - Validate: Pickup/dropoff locations
  - Validate: Price
  - Check driver availability
  - **File**: `lib/features/admin/controllers/admin_trips_controller.dart`

#### Phase 4.3: Widget Layer (4 Tasks)

- [ ] **T-TRIP-3.1**: Create `CreateTripDialog` widget
  - Form: Customer, pickup, dropoff, service type
  - Auto-calculate price
  - **File**: `lib/features/admin/widgets/create_trip_dialog.dart`

- [ ] **T-TRIP-3.2**: Create `UpdateTripStatusDialog` widget
  - Dropdown: New status
  - Reason field (for cancellation)
  - **File**: `lib/features/admin/widgets/update_trip_status_dialog.dart`

- [ ] **T-TRIP-3.3**: Create `ReassignTripDialog` widget
  - Search and select new driver
  - Reason for reassignment
  - **File**: `lib/features/admin/widgets/reassign_trip_dialog.dart`

- [ ] **T-TRIP-3.4**: Update trip detail screen with admin actions
  - Buttons: Update Status, Reassign, Cancel
  - **File**: `lib/features/admin/screens/admin_trip_detail_screen.dart`

#### Phase 4.4: Screen Updates (3 Tasks)

- [ ] **T-TRIP-4.1**: Add "Create Trip" button to trips list
  - Opens CreateTripDialog
  - **File**: `lib/features/admin/screens/admin_trips_screen.dart`

- [ ] **T-TRIP-4.2**: Add action menu to trip list items
  - Menu: View Details, Update Status, Reassign
  - **File**: `lib/features/admin/screens/admin_trips_screen.dart`

- [ ] **T-TRIP-4.3**: Add trip timeline to detail screen
  - Show: Request → Accept → Pickup → Dropoff → Complete
  - **File**: `lib/features/admin/screens/admin_trip_detail_screen.dart`

---

### Part 5: Promo Code CRUD Operations (10 Tasks)

#### Phase 5.1: Service Layer (3 Tasks)

- [ ] **T-PROMO-1.1**: Add `createPromoCode()` to service
  - Create promo_codes document
  - Validation: Code uniqueness
  - **File**: `lib/features/admin/services/admin_firestore_service.dart`

- [ ] **T-PROMO-1.2**: Add `updatePromoCode()` to service
  - Update: Discount, validity, usage limits
  - **File**: `lib/features/admin/services/admin_firestore_service.dart`

- [ ] **T-PROMO-1.3**: Add `deletePromoCode()` to service
  - Soft delete (set isActive = false)
  - **File**: `lib/features/admin/services/admin_firestore_service.dart`

#### Phase 5.2: Controller Updates (2 Tasks)

- [ ] **T-PROMO-2.1**: Update `AdminPromosController`
  - Add CRUD methods
  - **File**: `lib/features/admin/controllers/admin_promos_controller.dart`

- [ ] **T-PROMO-2.2**: Add promo usage tracking
  - Load usage stats for each promo
  - **File**: `lib/features/admin/controllers/admin_promos_controller.dart`

#### Phase 5.3: Widget Layer (3 Tasks)

- [ ] **T-PROMO-3.1**: Create `EditPromoDialog` widget
  - Form: Code, discount type, amount, validity dates
  - **File**: `lib/features/admin/widgets/edit_promo_dialog.dart`

- [ ] **T-PROMO-3.2**: Create `DeletePromoDialog` widget
  - Confirmation with usage stats
  - **File**: `lib/features/admin/widgets/delete_promo_dialog.dart`

- [ ] **T-PROMO-3.3**: Create `PromoUsageHistory` widget
  - Table: User, trip, discount amount, date
  - **File**: `lib/features/admin/widgets/promo_usage_history.dart`

#### Phase 5.4: Screen Updates (2 Tasks)

- [ ] **T-PROMO-4.1**: Add "Create Promo" button to promos screen
  - Opens EditPromoDialog
  - **File**: `lib/features/admin/screens/admin_promos_screen.dart`

- [ ] **T-PROMO-4.2**: Add usage history to promo detail screen
  - Show PromoUsageHistory widget
  - **File**: `lib/features/admin/screens/admin_promo_detail_screen.dart`

---

### Part 6: Document CRUD Operations (8 Tasks)

#### Phase 6.1: Service Layer (2 Tasks)

- [ ] **T-DOC-1.1**: Add `uploadDocument()` to service
  - Upload to Firebase Storage
  - Create documents collection entry
  - **File**: `lib/features/admin/services/admin_firestore_service.dart`

- [ ] **T-DOC-1.2**: Add `deleteDocument()` to service
  - Delete from Storage
  - Delete Firestore entry
  - **File**: `lib/features/admin/services/admin_firestore_service.dart`

#### Phase 6.2: Controller Updates (2 Tasks)

- [ ] **T-DOC-2.1**: Update `AdminDocumentsController`
  - Add upload/delete methods
  - **File**: `lib/features/admin/controllers/admin_documents_controller.dart`

- [ ] **T-DOC-2.2**: Add document preview
  - Support image preview
  - Support PDF preview
  - **File**: `lib/features/admin/controllers/admin_documents_controller.dart`

#### Phase 6.3: Widget Layer (2 Tasks)

- [ ] **T-DOC-3.1**: Create `UploadDocumentDialog` widget
  - File picker
  - Document type selector
  - **File**: `lib/features/admin/widgets/upload_document_dialog.dart`

- [ ] **T-DOC-3.2**: Update document list with admin actions
  - Action: Delete document
  - **File**: `lib/features/admin/screens/admin_documents_screen.dart`

#### Phase 6.4: Screen Updates (2 Tasks)

- [ ] **T-DOC-4.1**: Add "Upload Document" button
  - Opens UploadDocumentDialog
  - **File**: `lib/features/admin/screens/admin_documents_screen.dart`

- [ ] **T-DOC-4.2**: Add document preview modal
  - Full-screen image/PDF viewer
  - **File**: `lib/features/admin/screens/admin_documents_screen.dart`

---

### Part 7: App Config CRUD Operations (6 Tasks)

#### Phase 7.1: Service Layer (2 Tasks)

- [ ] **T-CONFIG-1.1**: Add `updateAppConfig()` to service
  - Update app_config document
  - Track version history
  - **File**: `lib/features/admin/services/admin_firestore_service.dart`

- [ ] **T-CONFIG-1.2**: Add `getConfigHistory()` to service
  - Return list of config changes
  - **File**: `lib/features/admin/services/admin_firestore_service.dart`

#### Phase 7.2: Controller Updates (1 Task)

- [ ] **T-CONFIG-2.1**: Create `AdminConfigController`
  - Load/update config
  - Track changes
  - **File**: `lib/features/admin/controllers/admin_config_controller.dart`

#### Phase 7.3: Widget Layer (2 Tasks)

- [ ] **T-CONFIG-3.1**: Create `ConfigHistoryList` widget
  - Show: What changed, who changed it, when
  - **File**: `lib/features/admin/widgets/config_history_list.dart`

- [ ] **T-CONFIG-3.2**: Update config screen with edit form
  - Editable fields for all config values
  - **File**: `lib/features/admin/screens/admin_config_screen.dart`

#### Phase 7.4: Screen Updates (1 Task)

- [ ] **T-CONFIG-4.1**: Add "Reset to Defaults" button
  - Confirmation dialog
  - **File**: `lib/features/admin/screens/admin_config_screen.dart`

---

### Part 8: Cloud Functions for Admin Operations (5 Tasks)

- [ ] **T-CF-1.1**: Create `approveDriver` Cloud Function
  - Verify admin role
  - Batch write all approval updates
  - Send FCM notification
  - Log audit entry
  - **File**: `functions/src/admin/driverApproval.js`

- [ ] **T-CF-1.2**: Create `rejectDriver` Cloud Function
  - Verify admin role
  - Update documents with rejection reason
  - Send FCM notification
  - Log audit entry
  - **File**: `functions/src/admin/driverApproval.js`

- [ ] **T-CF-1.3**: Create `adminCreateUser` Cloud Function
  - Verify admin role
  - Create Firebase Auth user
  - Create Firestore documents
  - Send welcome notification
  - **File**: `functions/src/admin/userManagement.js`

- [ ] **T-CF-1.4**: Create `adminDeleteUser` Cloud Function
  - Verify admin role
  - Soft delete in Firestore
  - Disable Firebase Auth
  - Log audit entry
  - **File**: `functions/src/admin/userManagement.js`

- [ ] **T-CF-1.5**: Create `adminCancelTrip` Cloud Function
  - Verify admin role
  - Handle refunds
  - Update trip status
  - Notify customer and driver
  - **File**: `functions/src/admin/tripManagement.js`

---

## 📊 MODULE 2: FINANCIAL MONITORING & REPORTS (106 Tasks)

### Part 1: Financial Dashboard (15 Tasks)

#### Phase 1.1: Service Layer (4 Tasks)

- [ ] **T-FIN-1.1**: Add `getFinancialSummary()` to service
  - Returns: Total revenue, commission, driver payouts, net profit
  - Returns: Pending payouts, wallet balance total
  - Returns: Completed/cancelled trips, cancellation rate
  - **File**: `lib/features/admin/services/financial_service.dart`

- [ ] **T-FIN-1.2**: Add `getRevenueByPeriod()` to service
  - Support: Daily, weekly, monthly periods
  - Returns: Trip revenue, delivery revenue, total revenue
  - Returns: Commission, trip count per period
  - **File**: `lib/features/admin/services/revenue_service.dart`

- [ ] **T-FIN-1.3**: Add `getCommissionBreakdown()` to service
  - Returns: Ride commission (15% default)
  - Returns: C2C commission (12% default)
  - Returns: B2B commission (custom per merchant)
  - Returns: Total commission
  - **File**: `lib/features/admin/services/commission_service.dart`

- [ ] **T-FIN-1.4**: Add `getPaymentMethodDistribution()` to service
  - Returns: Count, total amount, percentage, avg per method
  - Support: Cash, Wallet, Card, Vodafone Cash, Fawry
  - **File**: `lib/features/admin/services/payment_analytics_service.dart`

#### Phase 1.2: Controller Updates (3 Tasks)

- [ ] **T-FIN-2.1**: Create `AdminFinancialDashboardController`
  - Observables: `summary`, `revenueData`, `commissionBreakdown`, `paymentDistribution`
  - Observables: `recentTransactions`, `topDrivers`, `topCustomers`
  - Date range: `startDate`, `endDate`, `selectedPeriod`
  - Methods: `loadAllData()`, `setDateRange()`, `refreshData()`, `exportReport()`
  - **File**: `lib/features/admin/controllers/admin_financial_dashboard_controller.dart`

- [ ] **T-FIN-2.2**: Add real-time updates with Firestore listeners
  - Listen to recent transactions (last 20)
  - Auto-refresh on new transaction
  - **File**: `lib/features/admin/controllers/admin_financial_dashboard_controller.dart`

- [ ] **T-FIN-2.3**: Add comparison with previous period
  - Calculate: Revenue change %, commission change %, trips change %
  - Show: Green/red indicators
  - **File**: `lib/features/admin/controllers/admin_financial_dashboard_controller.dart`

#### Phase 1.3: Widget Layer (5 Tasks)

- [ ] **T-FIN-3.1**: Create `FinancialStatCard` widget
  - Display: Title, value (animated counter), change %
  - Color-coded: Green (positive), red (negative)
  - Loading skeleton
  - Tap to drill down
  - **File**: `lib/features/admin/widgets/finance/financial_stat_card.dart`

- [ ] **T-FIN-3.2**: Create `RevenueChart` widget
  - Line chart for revenue trend
  - Support: Last 7/30/90 days
  - Hover tooltips
  - **File**: `lib/features/admin/widgets/finance/revenue_chart.dart`

- [ ] **T-FIN-3.3**: Create `PaymentMethodChart` widget
  - Pie chart for payment method distribution
  - Show: Percentage labels
  - **File**: `lib/features/admin/widgets/finance/payment_method_chart.dart`

- [ ] **T-FIN-3.4**: Create `FinancialLeaderboard` widget
  - Top 5 drivers by earnings
  - Top 5 customers by spending
  - **File**: `lib/features/admin/widgets/finance/financial_leaderboard.dart`

- [ ] **T-FIN-3.5**: Create `RecentTransactionsList` widget
  - Table: Time, type, user, amount, status
  - Clickable rows (view details)
  - **File**: `lib/features/admin/widgets/finance/recent_transactions_list.dart`

#### Phase 1.4: Screen Updates (3 Tasks)

- [ ] **T-FIN-4.1**: Create `AdminFinancialDashboardScreen`
  - Grid layout: 4 stat cards at top
  - Revenue chart (full width)
  - Payment methods chart + Commission breakdown (side by side)
  - Recent transactions + Leaderboards
  - **File**: `lib/features/admin/screens/admin_financial_dashboard_screen.dart`

- [ ] **T-FIN-4.2**: Add date range picker to dashboard
  - Preset ranges: Today, Last 7 days, Last 30 days, This month, Custom
  - **File**: `lib/features/admin/screens/admin_financial_dashboard_screen.dart`

- [ ] **T-FIN-4.3**: Add export button to dashboard
  - Export as: PDF, Excel
  - Include: All charts + stats
  - **File**: `lib/features/admin/screens/admin_financial_dashboard_screen.dart`

---

### Part 2: Revenue Tracking (12 Tasks)

#### Phase 2.1: Service Layer (3 Tasks)

- [ ] **T-REV-1.1**: Add `getRevenueByServiceType()` to service
  - Breakdown: Ride revenue vs Delivery revenue vs B2B
  - **File**: `lib/features/admin/services/revenue_service.dart`

- [ ] **T-REV-1.2**: Add `getHourlyRevenuePattern()` to service
  - Returns: Revenue per hour of day (0-23)
  - Useful for: Peak hours analysis
  - **File**: `lib/features/admin/services/revenue_service.dart`

- [ ] **T-REV-1.3**: Add `getRevenueByZone()` to service
  - Returns: Revenue per geographic zone
  - Requires: Zone definitions in app_config
  - **File**: `lib/features/admin/services/revenue_service.dart`

#### Phase 2.2: Controller Updates (2 Tasks)

- [ ] **T-REV-2.1**: Create `AdminRevenueController`
  - Load: Revenue by service type, hourly pattern, by zone
  - Methods: `loadRevenueData()`, `filterByDate()`, `exportRevenueReport()`
  - **File**: `lib/features/admin/controllers/admin_revenue_controller.dart`

- [ ] **T-REV-2.2**: Add revenue forecast
  - Simple linear forecast based on last 30 days
  - Show: Projected next 7 days revenue
  - **File**: `lib/features/admin/controllers/admin_revenue_controller.dart`

#### Phase 2.3: Widget Layer (4 Tasks)

- [ ] **T-REV-3.1**: Create `RevenueByTypeChart` widget
  - Stacked bar chart: Ride + Delivery + B2B
  - **File**: `lib/features/admin/widgets/finance/revenue_by_type_chart.dart`

- [ ] **T-REV-3.2**: Create `HourlyHeatmap` widget
  - 24-hour heatmap (darker = more revenue)
  - **File**: `lib/features/admin/widgets/finance/hourly_heatmap.dart`

- [ ] **T-REV-3.3**: Create `ZoneRevenueList` widget
  - Table: Zone name, trips, revenue, avg per trip
  - Sortable columns
  - **File**: `lib/features/admin/widgets/finance/zone_revenue_list.dart`

- [ ] **T-REV-3.4**: Create `RevenueForecastCard` widget
  - Show: Projected revenue for next 7 days
  - Trend indicator
  - **File**: `lib/features/admin/widgets/finance/revenue_forecast_card.dart`

#### Phase 2.4: Screen Updates (3 Tasks)

- [ ] **T-REV-4.1**: Create `AdminRevenueScreen`
  - Layout: Revenue by type chart + hourly heatmap
  - Zone revenue table
  - Forecast card
  - **File**: `lib/features/admin/screens/admin_revenue_screen.dart`

- [ ] **T-REV-4.2**: Add navigation link to revenue screen
  - Sidebar menu: "Revenue Analytics"
  - **File**: `lib/features/admin/widgets/admin_sidebar.dart`

- [ ] **T-REV-4.3**: Add export button to revenue screen
  - Export: Revenue report as PDF/Excel
  - **File**: `lib/features/admin/screens/admin_revenue_screen.dart`

---

### Part 3: Commission Management (10 Tasks)

#### Phase 3.1: Service Layer (3 Tasks)

- [ ] **T-COMM-1.1**: Add `getCommissionRates()` to service
  - Returns: Current rates for ride/C2C/B2B
  - **File**: `lib/features/admin/services/commission_service.dart`

- [ ] **T-COMM-1.2**: Add `updateCommissionRates()` to service
  - Update: Rates in app_config
  - Log: Audit entry with old/new rates
  - **File**: `lib/features/admin/services/commission_service.dart`

- [ ] **T-COMM-1.3**: Add `getCommissionCollection()` to service
  - Returns: Collected vs pending commission
  - Per driver breakdown
  - **File**: `lib/features/admin/services/commission_service.dart`

#### Phase 3.2: Controller Updates (2 Tasks)

- [ ] **T-COMM-2.1**: Create `AdminCommissionController`
  - Load: Rates, collection stats
  - Methods: `updateRates()`, `loadCollectionData()`
  - **File**: `lib/features/admin/controllers/admin_commission_controller.dart`

- [ ] **T-COMM-2.2**: Add commission rate change validation
  - Warn: If rate too high (>30%) or too low (<5%)
  - Require: Confirmation before saving
  - **File**: `lib/features/admin/controllers/admin_commission_controller.dart`

#### Phase 3.3: Widget Layer (3 Tasks)

- [ ] **T-COMM-3.1**: Create `CommissionRatesEditor` widget
  - Editable fields: Ride %, C2C %, B2B default %
  - Save button + Reset button
  - **File**: `lib/features/admin/widgets/finance/commission_rates_editor.dart`

- [ ] **T-COMM-3.2**: Create `CommissionCollectionTable` widget
  - Table: Driver, trips, gross earnings, commission collected, pending
  - Export button
  - **File**: `lib/features/admin/widgets/finance/commission_collection_table.dart`

- [ ] **T-COMM-3.3**: Create `CommissionBreakdownCard` widget
  - Display: Total commission, by service type
  - **File**: `lib/features/admin/widgets/finance/commission_breakdown_card.dart`

#### Phase 3.4: Screen Updates (2 Tasks)

- [ ] **T-COMM-4.1**: Create `AdminCommissionScreen`
  - Layout: Rates editor + collection table + breakdown card
  - **File**: `lib/features/admin/screens/admin_commission_screen.dart`

- [ ] **T-COMM-4.2**: Add navigation link to commission screen
  - Sidebar menu: "Commission"
  - **File**: `lib/features/admin/widgets/admin_sidebar.dart`

---

### Part 4: Driver Earnings (14 Tasks)

#### Phase 4.1: Service Layer (4 Tasks)

- [ ] **T-EARN-1.1**: Add `getDriverEarningsReport()` to service
  - Returns: Gross, commission, tips, bonuses, net
  - Returns: Total trips, avg per trip
  - Filter by: Date range
  - **File**: `lib/features/admin/services/driver_earnings_service.dart`

- [ ] **T-EARN-1.2**: Add `getDriverEarningsSummary()` to service
  - Returns: All drivers with earnings
  - Sortable by: Gross, net, trips
  - **File**: `lib/features/admin/services/driver_earnings_service.dart`

- [ ] **T-EARN-1.3**: Add `processPayout()` to service
  - Mark: Payout as processed
  - Update: Driver wallet or external transfer record
  - Log: Audit entry
  - **File**: `lib/features/admin/services/driver_earnings_service.dart`

- [ ] **T-EARN-1.4**: Add `addBonus()` to service
  - Add: Bonus to driver earnings
  - Reason: Required field
  - **File**: `lib/features/admin/services/driver_earnings_service.dart`

#### Phase 4.2: Controller Updates (3 Tasks)

- [ ] **T-EARN-2.1**: Create `AdminDriverEarningsController`
  - Load: Driver earnings summary
  - Methods: `loadEarnings()`, `processPayout()`, `addBonus()`
  - **File**: `lib/features/admin/controllers/admin_driver_earnings_controller.dart`

- [ ] **T-EARN-2.2**: Add pending payouts tracking
  - Calculate: Total pending payouts
  - Filter: Drivers with pending > X
  - **File**: `lib/features/admin/controllers/admin_driver_earnings_controller.dart`

- [ ] **T-EARN-2.3**: Add earnings export
  - Export: Driver earnings as Excel/PDF
  - **File**: `lib/features/admin/controllers/admin_driver_earnings_controller.dart`

#### Phase 4.3: Widget Layer (4 Tasks)

- [ ] **T-EARN-3.1**: Create `DriverEarningsTable` widget
  - Columns: Driver, trips, gross, commission, tips, bonuses, net, pending
  - Sortable, paginated
  - **File**: `lib/features/admin/widgets/finance/driver_earnings_table.dart`

- [ ] **T-EARN-3.2**: Create `DriverEarningsDetailCard` widget
  - Full breakdown for single driver
  - **File**: `lib/features/admin/widgets/finance/driver_earnings_detail_card.dart`

- [ ] **T-EARN-3.3**: Create `ProcessPayoutDialog` widget
  - Form: Payout method (bank transfer, cash, wallet)
  - Form: Payout amount (auto-filled with pending)
  - Confirmation
  - **File**: `lib/features/admin/widgets/finance/process_payout_dialog.dart`

- [ ] **T-EARN-3.4**: Create `AddBonusDialog` widget
  - Form: Driver selector, bonus amount, reason
  - **File**: `lib/features/admin/widgets/finance/add_bonus_dialog.dart`

#### Phase 4.4: Screen Updates (3 Tasks)

- [ ] **T-EARN-4.1**: Create `AdminDriverEarningsScreen`
  - Layout: Summary cards + earnings table
  - Action buttons: Process Payout, Add Bonus
  - **File**: `lib/features/admin/screens/admin_driver_earnings_screen.dart`

- [ ] **T-EARN-4.2**: Create `AdminDriverEarningsDetailScreen`
  - Detail view for single driver
  - Show: DriverEarningsDetailCard + trip history
  - **File**: `lib/features/admin/screens/admin_driver_earnings_detail_screen.dart`

- [ ] **T-EARN-4.3**: Add navigation link to earnings screen
  - Sidebar menu: "Driver Earnings"
  - **File**: `lib/features/admin/widgets/admin_sidebar.dart`

---

### Part 5: Customer Wallets (12 Tasks)

#### Phase 5.1: Service Layer (3 Tasks)

- [ ] **T-WALLET-1.1**: Add `getWalletSummary()` to service
  - Returns: Total customer wallet balance
  - Returns: Total driver wallet balance
  - Returns: Recent wallet activity (last 50 transactions)
  - **File**: `lib/features/admin/services/wallet_service.dart`

- [ ] **T-WALLET-1.2**: Add `getWalletActivityReport()` to service
  - Returns: Top-ups, deductions, transfers
  - Filter by: User, date range, transaction type
  - **File**: `lib/features/admin/services/wallet_service.dart`

- [ ] **T-WALLET-1.3**: Add `adjustWallet()` to service
  - Add/deduct: Amount from user wallet
  - Reason: Required field
  - Log: Audit entry
  - **File**: `lib/features/admin/services/wallet_service.dart`

#### Phase 5.2: Controller Updates (2 Tasks)

- [ ] **T-WALLET-2.1**: Create `AdminWalletController`
  - Load: Wallet summary, activity
  - Methods: `loadWalletData()`, `adjustWallet()`
  - **File**: `lib/features/admin/controllers/admin_wallet_controller.dart`

- [ ] **T-WALLET-2.2**: Add top-up analytics
  - Track: Total top-ups, avg top-up amount
  - Track: Top-up methods distribution
  - **File**: `lib/features/admin/controllers/admin_wallet_controller.dart`

#### Phase 5.3: Widget Layer (4 Tasks)

- [ ] **T-WALLET-3.1**: Create `WalletSummaryCards` widget
  - Cards: Total customer balance, total driver balance
  - Cards: Recent top-ups, recent spending
  - **File**: `lib/features/admin/widgets/finance/wallet_summary_cards.dart`

- [ ] **T-WALLET-3.2**: Create `WalletActivityTable` widget
  - Table: User, type, amount, balance after, timestamp
  - Filterable, exportable
  - **File**: `lib/features/admin/widgets/finance/wallet_activity_table.dart`

- [ ] **T-WALLET-3.3**: Create `TopUpMethodsChart` widget
  - Pie chart: Cash, Card, Vodafone, Fawry
  - **File**: `lib/features/admin/widgets/finance/top_up_methods_chart.dart`

- [ ] **T-WALLET-3.4**: Create `WalletAdjustmentDialog` widget
  - Form: User selector, amount (+ or -), reason
  - Confirmation
  - **File**: `lib/features/admin/widgets/finance/wallet_adjustment_dialog.dart`

#### Phase 5.4: Screen Updates (3 Tasks)

- [ ] **T-WALLET-4.1**: Create `AdminWalletMonitoringScreen`
  - Layout: Summary cards + activity table + top-up chart
  - Action button: Adjust Wallet
  - **File**: `lib/features/admin/screens/admin_wallet_monitoring_screen.dart`

- [ ] **T-WALLET-4.2**: Add wallet section to customer detail screen
  - Show: Balance, recent transactions
  - Action: Adjust wallet
  - **File**: `lib/features/admin/screens/admin_customer_detail_screen.dart`

- [ ] **T-WALLET-4.3**: Add navigation link to wallet monitoring
  - Sidebar menu: "Wallets"
  - **File**: `lib/features/admin/widgets/admin_sidebar.dart`

---

### Part 6: Payment Analytics (10 Tasks)

#### Phase 6.1: Service Layer (3 Tasks)

- [ ] **T-PAY-1.1**: Add `getPaymentSuccessReport()` to service
  - Returns: Success rate per payment method
  - Returns: Failed payments with error codes
  - **File**: `lib/features/admin/services/payment_analytics_service.dart`

- [ ] **T-PAY-1.2**: Add `getCashVsDigitalReport()` to service
  - Returns: Cash payments vs digital payments
  - Breakdown by: Service type, time period
  - **File**: `lib/features/admin/services/payment_analytics_service.dart`

- [ ] **T-PAY-1.3**: Add `getPaymobTransactions()` to service
  - Returns: All Paymob transactions
  - Filter by: Status, method
  - **File**: `lib/features/admin/services/payment_analytics_service.dart`

#### Phase 6.2: Controller Updates (2 Tasks)

- [ ] **T-PAY-2.1**: Create `AdminPaymentAnalyticsController`
  - Load: Payment success rates, cash vs digital, Paymob data
  - **File**: `lib/features/admin/controllers/admin_payment_analytics_controller.dart`

- [ ] **T-PAY-2.2**: Add failed payment tracking
  - Track: Total failed payments
  - Alert: If failure rate > 10%
  - **File**: `lib/features/admin/controllers/admin_payment_analytics_controller.dart`

#### Phase 6.3: Widget Layer (3 Tasks)

- [ ] **T-PAY-3.1**: Create `PaymentSuccessChart` widget
  - Bar chart: Success rate per method
  - **File**: `lib/features/admin/widgets/finance/payment_success_chart.dart`

- [ ] **T-PAY-3.2**: Create `CashVsDigitalChart` widget
  - Line chart: Cash vs digital over time
  - **File**: `lib/features/admin/widgets/finance/cash_vs_digital_chart.dart`

- [ ] **T-PAY-3.3**: Create `FailedPaymentsTable` widget
  - Table: Trip, user, amount, method, error, timestamp
  - **File**: `lib/features/admin/widgets/finance/failed_payments_table.dart`

#### Phase 6.4: Screen Updates (2 Tasks)

- [ ] **T-PAY-4.1**: Create `AdminPaymentAnalyticsScreen`
  - Layout: Success chart + cash vs digital + failed payments
  - **File**: `lib/features/admin/screens/admin_payment_analytics_screen.dart`

- [ ] **T-PAY-4.2**: Add navigation link to payment analytics
  - Sidebar menu: "Payment Analytics"
  - **File**: `lib/features/admin/widgets/admin_sidebar.dart`

---

### Part 7: Transaction Monitoring (11 Tasks)

#### Phase 7.1: Service Layer (3 Tasks)

- [ ] **T-TRANS-1.1**: Add `getRecentTransactions()` to service
  - Returns: Last N transactions (real-time stream)
  - **File**: `lib/features/admin/services/transaction_service.dart`

- [ ] **T-TRANS-1.2**: Add `searchTransactions()` to service
  - Filter by: User, type, status, date range, amount
  - **File**: `lib/features/admin/services/transaction_service.dart`

- [ ] **T-TRANS-1.3**: Add `flagSuspiciousTransaction()` to service
  - Mark: Transaction as suspicious
  - Reason: Required
  - **File**: `lib/features/admin/services/transaction_service.dart`

#### Phase 7.2: Controller Updates (2 Tasks)

- [ ] **T-TRANS-2.1**: Create `AdminTransactionMonitorController`
  - Real-time: Listen to new transactions
  - Methods: `search()`, `flagSuspicious()`, `export()`
  - **File**: `lib/features/admin/controllers/admin_transaction_monitor_controller.dart`

- [ ] **T-TRANS-2.2**: Add suspicious transaction detection
  - Auto-flag: Transactions > 500 EGP
  - Auto-flag: Multiple failed attempts
  - **File**: `lib/features/admin/controllers/admin_transaction_monitor_controller.dart`

#### Phase 7.3: Widget Layer (4 Tasks)

- [ ] **T-TRANS-3.1**: Create `TransactionFilterPanel` widget
  - Filters: Type, status, date range, amount range
  - Search by: User name, transaction ID
  - **File**: `lib/features/admin/widgets/finance/transaction_filter_panel.dart`

- [ ] **T-TRANS-3.2**: Create `TransactionTable` widget
  - Columns: Time, type, user, amount, status, actions
  - Real-time updates
  - **File**: `lib/features/admin/widgets/finance/transaction_table.dart`

- [ ] **T-TRANS-3.3**: Create `TransactionDetailSheet` widget
  - Bottom sheet: Full transaction details
  - Action: Flag as suspicious
  - **File**: `lib/features/admin/widgets/finance/transaction_detail_sheet.dart`

- [ ] **T-TRANS-3.4**: Create `SuspiciousTransactionsList` widget
  - Table: Flagged transactions
  - Action: Review, clear flag
  - **File**: `lib/features/admin/widgets/finance/suspicious_transactions_list.dart`

#### Phase 7.4: Screen Updates (2 Tasks)

- [ ] **T-TRANS-4.1**: Create `AdminTransactionMonitorScreen`
  - Layout: Filter panel + transaction table + suspicious list
  - Real-time indicator
  - **File**: `lib/features/admin/screens/admin_transaction_monitor_screen.dart`

- [ ] **T-TRANS-4.2**: Add navigation link to transaction monitor
  - Sidebar menu: "Transactions"
  - Badge: Count of suspicious transactions
  - **File**: `lib/features/admin/widgets/admin_sidebar.dart`

---

### Part 8: Financial Reports (12 Tasks)

#### Phase 8.1: Service Layer (3 Tasks)

- [ ] **T-REPORT-1.1**: Add `generateFinancialReport()` to service
  - Support: Revenue, Driver Payout, Transaction, Custom reports
  - Format: PDF, Excel
  - **File**: `lib/features/admin/services/financial_report_service.dart`

- [ ] **T-REPORT-1.2**: Add `scheduleReport()` to service
  - Schedule: Daily, weekly, monthly reports
  - Email: Send to admin email
  - **File**: `lib/features/admin/services/financial_report_service.dart`

- [ ] **T-REPORT-1.3**: Add `getReportHistory()` to service
  - Returns: Previously generated reports
  - Store: Report metadata + download links
  - **File**: `lib/features/admin/services/financial_report_service.dart`

#### Phase 8.2: Controller Updates (2 Tasks)

- [ ] **T-REPORT-2.1**: Create `AdminReportsController`
  - Methods: `generateReport()`, `scheduleReport()`, `downloadReport()`
  - **File**: `lib/features/admin/controllers/admin_reports_controller.dart`

- [ ] **T-REPORT-2.2**: Add report templates
  - Templates: Revenue summary, Driver payout summary, Transaction log
  - **File**: `lib/features/admin/controllers/admin_reports_controller.dart`

#### Phase 8.3: Widget Layer (4 Tasks)

- [ ] **T-REPORT-3.1**: Create `ReportTypeSelector` widget
  - Radio buttons: Revenue, Driver Payout, Transaction, Custom
  - **File**: `lib/features/admin/widgets/finance/report_type_selector.dart`

- [ ] **T-REPORT-3.2**: Create `ReportParameterForm` widget
  - Form: Date range, filters (based on report type)
  - **File**: `lib/features/admin/widgets/finance/report_parameter_form.dart`

- [ ] **T-REPORT-3.3**: Create `ScheduleReportDialog` widget
  - Form: Frequency (daily, weekly, monthly), email recipients
  - **File**: `lib/features/admin/widgets/finance/schedule_report_dialog.dart`

- [ ] **T-REPORT-3.4**: Create `ReportHistoryList` widget
  - Table: Report name, generated date, download link
  - **File**: `lib/features/admin/widgets/finance/report_history_list.dart`

#### Phase 8.4: Screen Updates (3 Tasks)

- [ ] **T-REPORT-4.1**: Create `AdminReportsScreen`
  - Layout: Report type selector + parameter form + generate button
  - Section: Scheduled reports
  - Section: Report history
  - **File**: `lib/features/admin/screens/admin_reports_screen.dart`

- [ ] **T-REPORT-4.2**: Add navigation link to reports
  - Sidebar menu: "Reports"
  - **File**: `lib/features/admin/widgets/admin_sidebar.dart`

- [ ] **T-REPORT-4.3**: Add quick report buttons to dashboard
  - Buttons: "Generate Daily Report", "Generate Monthly Report"
  - **File**: `lib/features/admin/screens/admin_financial_dashboard_screen.dart`

---

### Part 9: Settlement System (10 Tasks)

#### Phase 9.1: Service Layer (3 Tasks)

- [ ] **T-SETTLE-1.1**: Add `getSettlementSummary()` to service
  - Returns: Total drivers to pay, total amount
  - Returns: Pending settlements
  - **File**: `lib/features/admin/services/settlement_service.dart`

- [ ] **T-SETTLE-1.2**: Add `processSettlement()` to service
  - Mark: All driver payouts as processed
  - Create: Settlement record
  - Update: Driver wallets
  - **File**: `lib/features/admin/services/settlement_service.dart`

- [ ] **T-SETTLE-1.3**: Add `getSettlementHistory()` to service
  - Returns: Past settlement records
  - **File**: `lib/features/admin/services/settlement_service.dart`

#### Phase 9.2: Controller Updates (2 Tasks)

- [ ] **T-SETTLE-2.1**: Create `AdminSettlementController`
  - Load: Settlement summary, history
  - Methods: `processSettlement()`, `exportSettlementReport()`
  - **File**: `lib/features/admin/controllers/admin_settlement_controller.dart`

- [ ] **T-SETTLE-2.2**: Add settlement validation
  - Verify: Bank details for all drivers
  - Warn: If any driver missing info
  - **File**: `lib/features/admin/controllers/admin_settlement_controller.dart`

#### Phase 9.3: Widget Layer (3 Tasks)

- [ ] **T-SETTLE-3.1**: Create `SettlementSummaryCard` widget
  - Display: Drivers to pay, total amount, period
  - **File**: `lib/features/admin/widgets/finance/settlement_summary_card.dart`

- [ ] **T-SETTLE-3.2**: Create `DriverSettlementTable` widget
  - Table: Driver, pending amount, bank details, status
  - **File**: `lib/features/admin/widgets/finance/driver_settlement_table.dart`

- [ ] **T-SETTLE-3.3**: Create `ProcessSettlementDialog` widget
  - Confirmation with full breakdown
  - **File**: `lib/features/admin/widgets/finance/process_settlement_dialog.dart`

#### Phase 9.4: Screen Updates (2 Tasks)

- [ ] **T-SETTLE-4.1**: Create `AdminSettlementScreen`
  - Layout: Summary card + driver settlement table
  - Action button: Process Settlement
  - Section: Settlement history
  - **File**: `lib/features/admin/screens/admin_settlement_screen.dart`

- [ ] **T-SETTLE-4.2**: Add navigation link to settlement
  - Sidebar menu: "Settlement"
  - **File**: `lib/features/admin/widgets/admin_sidebar.dart`

---

### Part 10: Cloud Functions for Finance (5 Tasks)

- [ ] **T-FIN-CF-1**: Create `generateFinancialReport` Cloud Function
  - Generate: PDF/Excel reports
  - Store: In Firebase Storage
  - Email: Send to admin
  - **File**: `functions/src/finance/reports.js`

- [ ] **T-FIN-CF-2**: Create `processDriverPayout` Cloud Function
  - Update: Driver wallet or external transfer log
  - Send: Notification to driver
  - Log: Audit entry
  - **File**: `functions/src/finance/payouts.js`

- [ ] **T-FIN-CF-3**: Create `adjustWallet` Cloud Function
  - Verify: Admin permissions
  - Update: Wallet balance
  - Log: Reason + admin who adjusted
  - **File**: `functions/src/finance/wallets.js`

- [ ] **T-FIN-CF-4**: Create `processSettlement` Cloud Function
  - Batch: Process all driver payouts
  - Create: Settlement record
  - Send: Notifications to all drivers
  - **File**: `functions/src/finance/settlement.js`

- [ ] **T-FIN-CF-5**: Create `detectSuspiciousTransaction` Cloud Function
  - Auto-run: On new transaction
  - Flag: If meets suspicious criteria
  - Alert: Admin via email/notification
  - **File**: `functions/src/finance/fraud.js`

---

## 🎯 EXECUTION PRIORITY & TIMELINE

### Week 1: Driver Approval (CRITICAL)
- ✅ Complete Part 1: Driver Approval Workflow (25 tasks)
- Priority: HIGHEST - Blocks driver onboarding

### Week 2: CRUD Operations
- ✅ Complete Part 2: Customer CRUD (15 tasks)
- ✅ Complete Part 3: Driver CRUD (18 tasks)
- ✅ Complete Part 4: Trip CRUD (12 tasks)

### Week 3: Finance Dashboard & Core Monitoring
- ✅ Complete Part 1: Financial Dashboard (15 tasks)
- ✅ Complete Part 2: Revenue Tracking (12 tasks)
- ✅ Complete Part 7: Transaction Monitoring (11 tasks)

### Week 4: Advanced Finance Features
- ✅ Complete Part 3: Commission Management (10 tasks)
- ✅ Complete Part 4: Driver Earnings (14 tasks)
- ✅ Complete Part 5: Customer Wallets (12 tasks)

### Week 5: Analytics & Reports
- ✅ Complete Part 6: Payment Analytics (10 tasks)
- ✅ Complete Part 8: Financial Reports (12 tasks)
- ✅ Complete Part 9: Settlement System (10 tasks)
- ✅ Complete Part 5-7 (Promo, Doc, Config CRUD) (24 tasks)
- ✅ Complete Part 8 & Part 10: Cloud Functions (10 tasks)

---

## 📁 FILES STRUCTURE

### New Models to Create
```
lib/features/admin/models/
├── driver_review_data.dart
├── approval_stats_model.dart
├── customer_stats_model.dart
├── driver_earnings_model.dart
├── config_history_entry.dart
└── finance/
    ├── financial_summary.dart
    ├── daily_revenue.dart
    ├── commission_breakdown.dart
    ├── commission_rates.dart
    ├── payment_stats.dart
    ├── driver_earnings_report.dart
    ├── driver_earnings_summary.dart
    ├── pending_payout.dart
    ├── wallet_summary.dart
    ├── wallet_activity_report.dart
    ├── top_up_analytics.dart
    ├── payment_success_report.dart
    ├── cash_digital_report.dart
    ├── transaction_stats.dart
    ├── suspicious_transaction.dart
    ├── settlement_summary.dart
    ├── driver_settlement.dart
    ├── settlement_record.dart
    ├── generated_report.dart
    ├── report_template.dart
    └── scheduled_report.dart
```

### New Services to Create
```
lib/features/admin/services/
├── admin_crud_service.dart
└── finance/
    ├── financial_service.dart
    ├── revenue_service.dart
    ├── commission_service.dart
    ├── driver_earnings_service.dart
    ├── wallet_service.dart
    ├── payment_analytics_service.dart
    ├── transaction_service.dart
    ├── financial_report_service.dart
    └── settlement_service.dart
```

### New Controllers to Create
```
lib/features/admin/controllers/
├── admin_approval_controller.dart
├── admin_config_controller.dart
└── finance/
    ├── admin_financial_dashboard_controller.dart
    ├── admin_revenue_controller.dart
    ├── admin_commission_controller.dart
    ├── admin_driver_earnings_controller.dart
    ├── admin_wallet_controller.dart
    ├── admin_payment_analytics_controller.dart
    ├── admin_transaction_monitor_controller.dart
    ├── admin_reports_controller.dart
    └── admin_settlement_controller.dart
```

### New Widgets to Create (60+ widgets)
```
lib/features/admin/widgets/
├── approval_queue_card.dart
├── document_review_grid.dart
├── rejection_reason_dialog.dart
├── approval_confirmation_dialog.dart
├── driver_approval_summary.dart
├── approval_timeline.dart
├── create_customer_dialog.dart
├── edit_customer_dialog.dart
├── delete_customer_dialog.dart
├── customer_stats_card.dart
├── create_driver_dialog.dart
├── edit_driver_dialog.dart
├── delete_driver_dialog.dart
├── driver_earnings_card.dart
├── force_offline_dialog.dart
├── create_trip_dialog.dart
├── update_trip_status_dialog.dart
├── reassign_trip_dialog.dart
├── edit_promo_dialog.dart
├── delete_promo_dialog.dart
├── promo_usage_history.dart
├── upload_document_dialog.dart
├── config_history_list.dart
└── finance/
    ├── financial_stat_card.dart
    ├── revenue_chart.dart
    ├── payment_method_chart.dart
    ├── financial_leaderboard.dart
    ├── recent_transactions_list.dart
    ├── revenue_by_type_chart.dart
    ├── hourly_heatmap.dart
    ├── zone_revenue_list.dart
    ├── revenue_forecast_card.dart
    ├── commission_rates_editor.dart
    ├── commission_collection_table.dart
    ├── commission_breakdown_card.dart
    ├── driver_earnings_table.dart
    ├── driver_earnings_detail_card.dart
    ├── process_payout_dialog.dart
    ├── add_bonus_dialog.dart
    ├── wallet_summary_cards.dart
    ├── wallet_activity_table.dart
    ├── top_up_methods_chart.dart
    ├── wallet_adjustment_dialog.dart
    ├── payment_success_chart.dart
    ├── cash_vs_digital_chart.dart
    ├── failed_payments_table.dart
    ├── transaction_filter_panel.dart
    ├── transaction_table.dart
    ├── transaction_detail_sheet.dart
    ├── suspicious_transactions_list.dart
    ├── report_type_selector.dart
    ├── report_parameter_form.dart
    ├── schedule_report_dialog.dart
    ├── report_history_list.dart
    ├── settlement_summary_card.dart
    ├── driver_settlement_table.dart
    └── process_settlement_dialog.dart
```

### New Screens to Create (15+ screens)
```
lib/features/admin/screens/
├── admin_approval_queue_screen.dart
├── admin_driver_review_screen.dart
└── finance/
    ├── admin_financial_dashboard_screen.dart
    ├── admin_revenue_screen.dart
    ├── admin_commission_screen.dart
    ├── admin_driver_earnings_screen.dart
    ├── admin_driver_earnings_detail_screen.dart
    ├── admin_wallet_monitoring_screen.dart
    ├── admin_payment_analytics_screen.dart
    ├── admin_transaction_monitor_screen.dart
    ├── admin_reports_screen.dart
    └── admin_settlement_screen.dart
```

### Cloud Functions to Create
```
functions/src/admin/
├── index.js
├── driverApproval.js
├── userManagement.js
└── tripManagement.js

functions/src/finance/
├── reports.js
├── payouts.js
├── wallets.js
├── settlement.js
└── fraud.js
```

---

## 🔧 TECHNICAL REQUIREMENTS

### Dependencies (add to pubspec.yaml)
```yaml
dependencies:
  # Already in project
  get: ^4.6.6
  cloud_firestore: ^4.15.0
  firebase_auth: ^4.17.0
  firebase_storage: ^11.6.0
  
  # Add for charts
  fl_chart: ^0.66.0
  syncfusion_flutter_charts: ^24.2.8
  
  # Add for PDF/Excel export
  pdf: ^3.10.7
  excel: ^4.0.2
  
  # Add for date picker
  flutter_date_range_picker: ^0.1.0
```

### Firebase Collections Structure
```
firestore:
  - users/
  - driver_profiles/
  - documents/
  - trips/
  - promo_codes/
  - wallets/
  - transactions/
  - app_config/
  - settlements/
  - audit_logs/
```

---

## ✅ DEFINITION OF DONE (Per Task)

Each task is complete when:
- [ ] Service method implemented with error handling
- [ ] Controller method with loading/error states
- [ ] Widget/Dialog created (if applicable)
- [ ] Screen updated (if applicable)
- [ ] Works in Arabic RTL
- [ ] Works in Dark mode
- [ ] Loading states implemented
- [ ] Error messages implemented
- [ ] Success feedback implemented
- [ ] Audit logging added (where applicable)
- [ ] Code documented with comments

---

## 📝 NOTES FOR RALPH LOOP EXECUTION

**Important**: This file contains 205 tasks across 2 major modules. Ralph Loop should:

1. **Execute tasks sequentially** following the week-by-week priority
2. **Read project context** from existing BikeRide codebase
3. **Follow existing code patterns** (GetX, Firebase, admin services structure)
4. **Create files in specified locations**
5. **Maintain consistency** with existing admin dashboard style
6. **Add Arabic translations** for all new strings
7. **Test each feature** after implementation

**Project Context Files**:
- `CLAUDE.md` - Main project documentation
- `USER_APP_TASKS.md` - Customer app reference
- `ADMIN_DASHBOARD_TASKS.md` - Admin dashboard structure
- `WORKFLOW.md` - Development workflow

**Execution Mode**: Sequential, with checkpoint after each Part completion.

---

*Generated: 2026-03-11 | Total: 205 tasks | Est. Timeline: 5 weeks*
