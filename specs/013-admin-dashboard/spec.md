# Feature Specification: Admin Dashboard Web Panel

**Feature Branch**: `013-admin-dashboard`
**Created**: 2026-03-02
**Status**: Draft
**Input**: Full admin dashboard for BikeRide platform - Flutter Web with auth, layout shell, dashboard stats, customer/driver management, document review, trips, financial, config, promos, referrals, notifications, analytics, and cPanel deployment. Reuses shared theme, languages, and components from core module.

## Clarifications

### Session 2026-03-02

- Q: What should the `super_admin` role be able to do that a regular `admin` cannot? → A: Super admin can manage app config, toggle maintenance mode, and manage other admins; regular admin handles all other operations.
- Q: Should the admin dashboard maintain an audit log of admin actions? → A: No audit logging — trust admins, keep it simple.
- Q: How long should an admin session last before requiring re-authentication? → A: 7 days — session expires after 7 days of inactivity, requiring re-login.
- Q: Can admins view a history of previously sent notifications? → A: Yes, a simple sent history table showing timestamp, target segment, title, and admin who sent it.
- Q: Do config changes (pricing, commission) apply to in-progress trips or only new trips? → A: New trips only — in-progress trips keep the values they started with.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Admin Login & Session Persistence (Priority: P1)

An admin opens the BikeRide Admin Dashboard in their browser. They log in using their email and password. The system verifies they have admin privileges (custom claim). Once authenticated, the admin sees the dashboard. On subsequent visits, the admin remains logged in without re-entering credentials. Non-admin users who attempt to log in are denied access with a clear error message.

**Why this priority**: Without authentication, no admin functionality is accessible. This is the gateway to the entire system.

**Independent Test**: Can be fully tested by attempting login with admin credentials, non-admin credentials, and invalid credentials. Delivers secure access control.

**Acceptance Scenarios**:

1. **Given** the admin is on the login screen, **When** they enter valid admin email and password, **Then** they are redirected to the dashboard.
2. **Given** the admin is on the login screen, **When** they enter valid credentials for a non-admin account, **Then** they see "Access denied. Not an admin account." and are logged out.
3. **Given** the admin is on the login screen, **When** they enter invalid credentials, **Then** they see "Invalid email or password."
4. **Given** an authenticated admin closes and reopens the browser, **When** the dashboard loads, **Then** they are automatically redirected to the dashboard without re-logging in.
5. **Given** a user without admin privileges accesses any dashboard URL, **When** the auth guard runs, **Then** they are redirected to the login screen.

---

### User Story 2 - Layout Shell with Responsive Navigation (Priority: P1)

An authenticated admin sees a consistent layout on every screen: a sidebar with navigation links on the left and a topbar with the current section title and admin info on the top. On desktop, the sidebar is fully expanded showing icons and labels. On tablet, it collapses to icons only. On mobile, it hides and is accessible via a hamburger menu. The sidebar highlights the currently active section and shows a badge count for pending document reviews.

**Why this priority**: Every feature screen depends on the layout shell. It must be built before any content screens.

**Independent Test**: Can be tested by navigating between sidebar items at different browser widths and verifying correct responsive behavior, active highlighting, and badge display.

**Acceptance Scenarios**:

1. **Given** the admin is on any screen at desktop width (>1200px), **When** they view the layout, **Then** the sidebar is expanded at 240px with icons and labels visible.
2. **Given** the admin is on any screen at tablet width (768-1200px), **When** they view the layout, **Then** the sidebar is collapsed to 72px showing only icons.
3. **Given** the admin is on any screen at mobile width (<768px), **When** they tap the hamburger menu, **Then** the sidebar opens as a drawer overlay.
4. **Given** the admin clicks a sidebar item, **When** the new screen loads, **Then** the clicked item is highlighted and the topbar title updates.
5. **Given** there are 3 pending document reviews, **When** the admin views the sidebar, **Then** the "Document Review" item shows a badge with "3".

---

### User Story 3 - Document Review Queue (Priority: P1)

An admin navigates to the Document Review screen and sees a two-panel layout. The left panel lists all drivers with pending documents, showing their name, phone, and submission time. The right panel shows the selected driver's uploaded documents (National ID, Driver License, Vehicle Registration) as image previews. The admin can click any image to view it full-size, then approve all documents or reject with a reason. Upon approval, the driver's account is activated and they receive a push notification.

**Why this priority**: Drivers cannot go online until their documents are approved. This is the highest priority operational feature after auth and layout.

**Independent Test**: Can be tested by selecting a pending driver, reviewing their document images, approving them, and verifying the driver can now go online and received a notification.

**Acceptance Scenarios**:

1. **Given** a driver has submitted documents, **When** the admin opens Document Review, **Then** the driver appears in the left panel with name, phone, and time since submission.
2. **Given** the admin selects a driver in the left panel, **When** documents load, **Then** three image cards display (National ID, License, Vehicle Registration) from cloud storage.
3. **Given** the admin clicks a document image, **When** the viewer opens, **Then** a full-size version is displayed in a dialog.
4. **Given** the admin clicks "Approve All", **When** confirmed, **Then** all documents are marked approved, the driver profile is activated, the driver is removed from the pending list, and a push notification is sent.
5. **Given** the admin clicks "Reject" and enters a reason, **When** confirmed, **Then** all documents are marked rejected with the reason, and the driver receives a push notification with the rejection reason.
6. **Given** no pending reviews exist, **When** the admin opens Document Review, **Then** an empty state message is displayed.

---

### User Story 4 - Dashboard with Live Stats and Charts (Priority: P2)

An admin navigates to the dashboard and sees four key stat cards at the top: trips today, revenue today (EGP), drivers currently online, and pending document reviews. The drivers online count updates in real-time. Below the stats, a revenue chart shows the last 30 days of commission earnings. The bottom section shows a live driver map and a table of the 10 most recent trips.

**Why this priority**: The dashboard is the landing page and gives the admin confidence the data layer is working. It validates that database integrations function correctly.

**Independent Test**: Can be tested by loading the dashboard and verifying stat values match actual data, observing real-time updates when a driver goes online, and checking chart data points.

**Acceptance Scenarios**:

1. **Given** the admin opens the dashboard, **When** data loads, **Then** four stat cards display correct counts for trips today, revenue today, active drivers, and pending reviews.
2. **Given** a driver goes online, **When** the dashboard is open, **Then** the "Drivers Online" counter increments within 5 seconds without page refresh.
3. **Given** the admin views the revenue chart, **When** data loads, **Then** a line chart shows 30 data points representing daily commission earnings.
4. **Given** the admin views the recent trips table, **When** they click a trip row, **Then** they navigate to the trip detail screen.
5. **Given** the admin resizes the browser to tablet width, **When** the dashboard renders, **Then** stat cards wrap to a 2x2 grid layout.

---

### User Story 5 - Customer Management (Priority: P2)

An admin navigates to the Customers section and sees a paginated table of all customers with search and status filter. They can click "View" on any customer to see their full profile, wallet balance, and recent trips. From the detail screen, the admin can suspend or activate a customer account and adjust their wallet balance (credit or debit) with a reason note.

**Why this priority**: Customer management is essential for platform operations and handling support requests.

**Independent Test**: Can be tested by searching for a customer, viewing their profile, suspending and reactivating their account, and adjusting their wallet balance.

**Acceptance Scenarios**:

1. **Given** the admin is on the customers list, **When** they type "Ahmed" in the search field, **Then** after a short debounce the table filters to show only customers matching "Ahmed" in name or phone.
2. **Given** the admin is on the customers list, **When** they select "Suspended" from the status filter, **Then** only suspended customers are displayed.
3. **Given** the admin views a customer detail, **When** they click "Suspend" and provide a reason, **Then** the customer status changes to "Suspended" and the customer can no longer log in.
4. **Given** the admin views a suspended customer, **When** they click "Activate", **Then** the customer status changes to "Active" and they can log in again.
5. **Given** the admin views a customer detail, **When** they adjust wallet by +50 EGP with a note, **Then** the wallet balance increases by 50 EGP.

---

### User Story 6 - Driver Management (Priority: P2)

An admin navigates to the Drivers section and sees a paginated table of all drivers with search, approval status filter (all/approved/pending/rejected), and online status filter. They can view a driver's full profile including vehicle info, performance stats, documents, and take actions (approve, reject, suspend, activate).

**Why this priority**: Driver management is critical for onboarding new drivers and managing the fleet.

**Independent Test**: Can be tested by filtering drivers by approval and online status, viewing a driver profile, and performing approve/reject/suspend actions.

**Acceptance Scenarios**:

1. **Given** the admin filters by "Pending" approval status, **When** results load, **Then** only drivers with pending approval are displayed.
2. **Given** the admin filters by "Online" status, **When** results load, **Then** only currently online drivers are displayed.
3. **Given** the admin views a driver detail, **When** they see the performance card, **Then** it shows total trips, average rating, total earnings, and live online status.
4. **Given** the admin approves a pending driver, **When** confirmation is given, **Then** the driver status changes to "Approved" and the driver receives a push notification.

---

### User Story 7 - Trips Management (Priority: P3)

An admin navigates to the Trips section and sees a filterable, paginated table of all trips. They can filter by type (ride/C2C/B2B), status, and date range. Clicking a trip row opens the detail screen showing full trip info, route map, payment details, customer and driver cards, all bids received, and a status timeline. For completed trips, the admin can issue a credit to the customer as dispute resolution.

**Why this priority**: Trip monitoring is important for platform oversight but less urgent than authentication and document review.

**Independent Test**: Can be tested by filtering trips, viewing a trip detail, and issuing a credit to a customer for a completed trip.

**Acceptance Scenarios**:

1. **Given** the admin filters trips by "Completed" status, **When** results load, **Then** only completed trips are displayed.
2. **Given** the admin sets a date range filter, **When** results load, **Then** only trips within that date range appear.
3. **Given** the admin views a completed trip detail, **When** they click "Issue Credit" and enter 50 EGP with a reason, **Then** the customer's wallet is credited 50 EGP.
4. **Given** the admin views a trip detail, **When** the map section loads, **Then** pickup and dropoff pins with a route polyline are displayed.

---

### User Story 8 - Financial & Transaction Ledger (Priority: P3)

An admin navigates to the Financial section and sees summary cards (total revenue, total commission, total top-ups, total refunds) and a filterable transaction table. They can filter by user, payment method, transaction type, and date range. The admin can export transactions as a CSV file. A commission breakdown table shows revenue by service type.

**Why this priority**: Financial visibility is important for business operations but depends on trips and payments data existing first.

**Independent Test**: Can be tested by viewing summary cards, filtering transactions, exporting CSV, and verifying commission breakdown totals.

**Acceptance Scenarios**:

1. **Given** the admin opens the financial screen, **When** data loads, **Then** four summary cards show total revenue, commission, top-ups, and refunds for the selected period.
2. **Given** the admin filters by payment method "Vodafone Cash", **When** results load, **Then** only Vodafone Cash transactions are displayed.
3. **Given** the admin clicks "Export CSV", **When** the export completes, **Then** a CSV file downloads with all filtered transactions.
4. **Given** the admin views the commission breakdown, **When** they select a date range, **Then** the table shows trip counts, total fare, commission rate, and commission earned per service type.

---

### User Story 9 - App Configuration (Priority: P3)

An admin navigates to the Configuration screen and sees editable fields for pricing, vehicle multipliers, commission rates, bidding settings, and referral rewards. Changes show an "unsaved changes" banner. On save, values are written to the central config and all apps immediately reflect the new values. A maintenance mode toggle allows the admin to shut down the platform with a confirmation dialog.

**Why this priority**: Configuration management is essential for ongoing operations but not required for initial launch.

**Independent Test**: Can be tested by changing a pricing value, saving, and verifying the customer app reflects the new price.

**Acceptance Scenarios**:

1. **Given** the admin changes the base fare value, **When** the field is modified, **Then** an orange "unsaved changes" banner appears.
2. **Given** the admin clicks "Save", **When** the save completes, **Then** the changes are persisted to the central configuration and all connected apps receive the update.
3. **Given** the admin clicks "Reset", **When** confirmed, **Then** all fields revert to the last saved values.
4. **Given** the admin toggles maintenance mode on, **When** they confirm the warning dialog, **Then** the platform enters maintenance mode.
5. **Given** the admin enters a negative value for base fare, **When** they try to save, **Then** validation prevents the save and shows an error.

---

### User Story 10 - Promo Code Management (Priority: P3)

An admin navigates to the Promo Codes section and sees a table of all promo codes with filters (all/active/expired/inactive). They can create, edit, and deactivate promo codes. Usage counts update as customers use codes.

**Why this priority**: Promo management supports marketing campaigns but is not critical for core operations.

**Independent Test**: Can be tested by creating a promo code, applying it in the customer app, and verifying the usage count increments.

**Acceptance Scenarios**:

1. **Given** the admin clicks "Create New", **When** they fill in code details and save, **Then** the new promo code appears in the table.
2. **Given** a customer uses a promo code, **When** the admin views the promo table, **Then** the usage count has incremented.
3. **Given** the admin deactivates a promo code, **When** a customer tries to use it, **Then** the code is rejected.

---

### User Story 11 - Push Notification Sender (Priority: P3)

An admin navigates to Send Notification and selects a target segment (all users, all customers, all drivers, or a specific user). They enter notification title and body in both Arabic and English. A preview card shows how the notification will look. Before sending, a confirmation dialog shows the target audience and notification preview.

**Why this priority**: Notification sending is an operational tool for announcements and promotions.

**Independent Test**: Can be tested by sending a notification to a specific user and verifying they receive it on their device.

**Acceptance Scenarios**:

1. **Given** the admin selects "All Customers" and fills in title/body, **When** they confirm and send, **Then** all customer devices receive the push notification.
2. **Given** the admin selects "Specific User" and enters a UID, **When** they confirm and send, **Then** only that user receives the notification.
3. **Given** the title or body is empty, **When** the admin views the send button, **Then** it is disabled.
4. **Given** the admin navigates to the notification history tab, **When** the list loads, **Then** previously sent notifications are displayed in a table with timestamp, target segment, title, and the admin who sent it.

---

### User Story 12 - Global User Search (Priority: P3)

An admin uses the search field in the topbar to search for any user by phone number or name. Results appear in a dropdown showing matching users with a type badge (customer/driver). Clicking a result navigates to the correct detail screen.

**Why this priority**: Fast user lookup is essential for handling support requests efficiently.

**Independent Test**: Can be tested by entering a phone number in the topbar search and verifying the correct user appears.

**Acceptance Scenarios**:

1. **Given** the admin types a phone number in the topbar search, **When** results load, **Then** matching users are displayed in a dropdown with name, phone, and type badge.
2. **Given** the admin clicks a customer result, **When** navigated, **Then** the customer detail screen opens.
3. **Given** the admin clicks a driver result, **When** navigated, **Then** the driver detail screen opens.

---

### User Story 13 - Referral Program Settings (Priority: P4)

An admin navigates to Referrals and configures referrer/referee reward amounts. They see statistics (total referrals, total rewarded, total payout) and a paginated referral history table.

**Why this priority**: Referral configuration is a low-frequency administrative task.

**Independent Test**: Can be tested by changing referral reward amounts and verifying the next referral uses the updated values.

**Acceptance Scenarios**:

1. **Given** the admin changes the referrer reward to 20 EGP, **When** saved, **Then** the next completed referral pays 20 EGP to the referrer.
2. **Given** the admin views referral statistics, **When** data loads, **Then** totals for referrals made, rewarded, and EGP paid out are displayed.

---

### User Story 14 - Analytics & Reports (Priority: P4)

An admin navigates to Analytics and sees charts for trip volume by day (stacked bar chart by type), payment method breakdown (pie chart), cancellation rate trend (line chart), and a top 10 drivers table. They can toggle the time period (7/30/90 days) and export a report.

**Why this priority**: Analytics support strategic decisions but are not required for day-to-day operations.

**Independent Test**: Can be tested by loading analytics, changing the period selector, and verifying chart data matches actual records.

**Acceptance Scenarios**:

1. **Given** the admin selects "7 days" period, **When** charts reload, **Then** all charts show data for the last 7 days only.
2. **Given** the admin views the payment method pie chart, **When** data loads, **Then** percentages sum to 100%.
3. **Given** the admin clicks a row in the top 10 drivers table, **When** they click, **Then** they navigate to the driver detail screen.
4. **Given** the admin clicks "Export Report", **When** the export completes, **Then** a CSV file downloads with the current analytics data.

---

### User Story 15 - Deploy to cPanel (Priority: P4)

The admin panel is built as a web release and deployed to cPanel as static files. The admin domain is added to authorized domains. The deployed panel loads correctly in Chrome, Firefox, Safari, and Edge. All functionality works through the browser with no server-side processing.

**Why this priority**: Deployment is the final step after all features are built and tested locally.

**Independent Test**: Can be tested by building the web release, uploading to cPanel, and verifying login, navigation, and all features work in the browser.

**Acceptance Scenarios**:

1. **Given** the web build is uploaded to cPanel, **When** an admin visits the URL, **Then** the login screen loads.
2. **Given** the admin logs in on the deployed site, **When** they navigate between sections, **Then** all sidebar items load their respective screens.
3. **Given** the admin is on the deployed site, **When** they perform any data operation, **Then** it works identically to local development.

---

### Edge Cases

- What happens when the admin's session expires (after 7 days of inactivity) while viewing a screen? The system should redirect to login with a message indicating the session expired.
- What happens when the database is temporarily unavailable? The system should show an error state with retry options.
- What happens when the admin tries to suspend themselves? The system should prevent self-suspension.
- What happens when two admins approve/reject the same driver simultaneously? The system should handle concurrent updates gracefully (first action wins).
- What happens when the admin exports CSV for a very large date range (e.g., 1 year)? The system should paginate the export or show a progress indicator.
- What happens when a document image URL is broken or expired? The system should show a placeholder with an error message.
- What happens when the admin sends a notification to "All Users" but no users have push tokens? The system should report 0 notifications sent.
- What happens at different screen resolutions (768px, 1024px, 1280px, 1440px, 1920px)? The layout should adapt responsively at each breakpoint.
- What happens when a promo code has reached its maximum usage limit? The system should show it as "Exhausted" and prevent further use.
- What happens when pricing or commission config is changed while trips are in progress? In-progress trips keep their original values; only newly created trips use the updated config.
- What happens when the admin navigates to a user detail page with an invalid UID? The system should show a "User not found" error and allow navigation back.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST authenticate admins using email and password with admin role verification via custom claims.
- **FR-002**: System MUST persist admin sessions across browser restarts, with sessions expiring after 7 days of inactivity, at which point the admin is redirected to the login screen.
- **FR-003**: System MUST prevent non-admin authenticated users from accessing any dashboard screen.
- **FR-004**: System MUST provide a responsive layout shell with sidebar navigation that adapts to desktop (>1200px expanded), tablet (768-1200px icons only), and mobile (<768px drawer).
- **FR-005**: System MUST display a live count of pending document reviews as a badge on the Document Review sidebar item.
- **FR-006**: System MUST display real-time dashboard statistics including trips today, revenue today, active drivers online, and pending reviews.
- **FR-007**: System MUST update the "drivers online" count in real-time (within 5 seconds) without page refresh.
- **FR-008**: System MUST display a 30-day revenue chart using daily commission earnings data.
- **FR-009**: System MUST provide paginated customer and driver lists with search (by name/phone) and status filtering.
- **FR-010**: System MUST allow admins to view full user profiles including wallet balance, recent trips, and account status.
- **FR-011**: System MUST allow admins to suspend and activate user accounts, with the suspended user's authentication being disabled.
- **FR-012**: System MUST allow admins to adjust user wallet balances (credit/debit) with a mandatory reason note, executed through cloud functions only.
- **FR-013**: System MUST display pending driver documents as image previews with full-size viewing capability.
- **FR-014**: System MUST allow admins to approve all driver documents (activating the driver) or reject with a mandatory reason.
- **FR-015**: System MUST send push notifications to drivers upon document approval or rejection.
- **FR-016**: System MUST provide a filterable trips list with filters for type, status, date range, customer, and driver.
- **FR-017**: System MUST display trip details including route map, payment info, bids, and status timeline.
- **FR-018**: System MUST allow admins to issue credits to customers for dispute resolution on completed trips.
- **FR-019**: System MUST display financial summary cards and a filterable transaction ledger with CSV export capability.
- **FR-020**: System MUST display commission breakdown by service type (rides, C2C delivery, B2B delivery).
- **FR-021**: System MUST allow admins to update platform configuration (pricing, commission rates, bidding settings, referral rewards, maintenance mode).
- **FR-022**: System MUST validate configuration inputs (no negative values, no zero fares) before saving.
- **FR-023**: System MUST propagate configuration changes to all connected apps immediately upon save. Pricing and commission changes apply only to newly created trips; in-progress trips retain the values they started with.
- **FR-024**: System MUST require confirmation before enabling maintenance mode.
- **FR-025**: System MUST allow admins to create, edit, and deactivate promo codes with all relevant fields (code, type, value, max uses, min trip value, expiry date).
- **FR-026**: System MUST allow admins to send push notifications to segments (all, customers, drivers) or specific users with bilingual content (Arabic + English).
- **FR-027**: System MUST show a confirmation dialog with notification preview and target audience count before sending.
- **FR-028**: System MUST display analytics charts (trip volume, payment breakdown, cancellation trends) with selectable time periods (7/30/90 days).
- **FR-029**: System MUST provide a global user search in the topbar that searches by name or phone and navigates to the correct detail screen.
- **FR-030**: System MUST reuse the existing shared theme system from the core module for consistent visual styling.
- **FR-031**: System MUST reuse the existing localization system (Arabic RTL default + English LTR) from the core module.
- **FR-032**: System MUST reuse existing shared widgets (AppButton, AppTextField, AppCard, AppLoading, AppSnackbar, AppMapWidget) where applicable.
- **FR-033**: System MUST be deployable as static files on cPanel with no server-side processing required.
- **FR-034**: System MUST work correctly on Chrome, Firefox, Safari, and Edge browsers.
- **FR-035**: System MUST restrict app configuration changes (pricing, commission, bidding, referral, maintenance mode) to super_admin role only.
- **FR-036**: System MUST restrict admin account management (view, create, deactivate admin users) to super_admin role only.
- **FR-037**: System MUST allow regular admin role to access all operational features (dashboard, user management, document review, trips, financial, promos, notifications, analytics).
- **FR-038**: System MUST show disabled/hidden UI elements for restricted features when a regular admin is logged in, with a clear indication that super_admin access is required.
- **FR-039**: System MUST store a record for each sent notification (timestamp, target segment, title, body, sender admin UID) and display them in a sent history table on the notifications screen.

### Key Entities

- **Admin User**: Represents an admin with uid, email, name, role (admin/super_admin), and last login time. Authenticates via email/password with custom claims. Regular admins can perform all operational tasks (user management, document review, trips, financial, promos, notifications, analytics). Super admins have exclusive access to app configuration, maintenance mode toggle, and admin account management.
- **Dashboard Stats**: Aggregated metrics including trips today, revenue today, active drivers online, pending reviews, total customers, total drivers, weekly trips, weekly revenue, and cancellation rate.
- **Document Review**: Groups a driver's user profile with their submitted documents (National ID, License, Vehicle Registration) for batch approval/rejection.
- **Driver with Profile**: Combines user account data with driver-specific data (vehicle info, approval status, online status, ratings, earnings) for the driver management views.
- **App Configuration**: Central configuration document controlling pricing, commission rates, vehicle multipliers, bidding settings, referral rewards, and maintenance mode. All apps listen to changes in real-time.
- **Financial Summary**: Aggregated financial data including total revenue, total commission, total top-ups, and total refunds for a given date range.

## Assumptions

- Admin accounts are created manually via Firebase Console or CLI (not through the dashboard itself).
- Custom claims (`role: admin` or `role: super_admin`) are set via Firebase Admin SDK or Cloud Functions, not from the dashboard.
- The dashboard uses the same Firebase project as the customer and driver apps.
- Wallet adjustments and user suspension/activation are performed through existing Cloud Functions (`adjustWalletBalance`, `suspendUser`).
- The shared theme, widgets, translations, and models from `lib/core/` are reusable by the admin app without modification.
- Document images are stored in Firebase Storage and accessible via URLs.
- The admin panel will only be accessed by a small number of administrators (1-5), so heavy optimization for concurrent admin users is not a priority.
- No audit logging of admin actions is required. The team trusts admins and prefers simplicity over traceability for this phase.
- All data tables default to 20-50 items per page with cursor-based pagination.
- The admin app folder structure lives under `lib/admin_app/` alongside the existing `lib/core/` shared modules.
- All sidebar navigation items map to 11 distinct feature sections plus the dashboard home.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Admin can log in and reach the dashboard within 5 seconds on a standard internet connection.
- **SC-002**: Dashboard live stats (drivers online count) update within 5 seconds of a real-time change.
- **SC-003**: Admin can find any user by phone number or name within 10 seconds using the global search.
- **SC-004**: Admin can complete a full document review (view images + approve/reject) in under 30 seconds per driver.
- **SC-005**: All 18 screens are accessible and functional through the sidebar navigation.
- **SC-006**: Layout is fully responsive and usable at all breakpoints: 768px, 1024px, 1280px, 1440px, 1920px.
- **SC-007**: Configuration changes are reflected in connected apps within 10 seconds of saving.
- **SC-008**: CSV export completes and downloads within 15 seconds for up to 10,000 transactions.
- **SC-009**: The admin panel works correctly on Chrome, Firefox, Safari, and Edge browsers.
- **SC-010**: Non-admin users are blocked from accessing any dashboard functionality (100% enforcement of auth guard).
- **SC-011**: Push notifications reach target devices within 30 seconds of admin sending them.
- **SC-012**: All data operations (CRUD on users, promos, config) complete without errors when proper inputs are provided.
