# Motorcycle Platform Development Milestones

**Purpose:** A practical roadmap to track what is completed, what is in progress, and what comes next.

## Recommended Release Groups

| Release | Milestones | Focus |
|---|---|---|
| R1 Foundation | 1–3 | Project setup, database, auth, security |
| R2 Core Engine | 4–5 | Orders, bidding, state machine |
| R3 Driver App | 6 | Driver operational MVP |
| R4 User App + Live Operations | 7–9 | Customer app, maps, realtime, notifications |
| R5 Management | 10–12 | Dashboard, verification, basic financials |
| R6 Production | 13–14 | Testing, security, deployment |

> **Critical checkpoint:** Do not consider the core engine ready until a customer can create an order, multiple drivers can bid, exactly one driver can win, and the order can reach COMPLETED.

## Milestone 1 — Project Foundation

**Goal:** Prepare the project structure and development environments.

### Tasks

- [ ] Create Git repository
- [ ] Create Flutter User App
- [ ] Create Flutter Driver App
- [ ] Create Next.js Dashboard
- [ ] Create Supabase development project
- [ ] Create environment variable strategy
- [ ] Create base folder structure
- [ ] Add /docs folder and place all project specifications inside

### Definition of Done

- All projects run locally without errors and the repository structure is ready.

---

## Milestone 2 — Database + Authentication

**Goal:** Build the initial data foundation and authentication system.

### Tasks

- [ ] Create core database enums
- [ ] Create profiles table
- [ ] Create offices table
- [ ] Create office_members table
- [ ] Create drivers table
- [ ] Create motorcycles table
- [ ] Create driver_documents table
- [ ] Create service_types table
- [ ] Create roles and permissions tables
- [ ] Configure Supabase Auth
- [ ] Implement customer authentication
- [ ] Implement driver authentication
- [ ] Create test Admin and Office accounts

### Definition of Done

- Customer, Driver, Admin, and Office accounts can authenticate and are recognized correctly.

---

## Milestone 3 — Roles, Permissions & Office Isolation

**Goal:** Secure the platform and enforce office-level data boundaries.

### Tasks

- [ ] Create SUPER_ADMIN role
- [ ] Create OFFICE_ADMIN role
- [ ] Create OFFICE_DISPATCHER role
- [ ] Create OFFICE_ACCOUNTANT role
- [ ] Define granular permissions
- [ ] Implement Data Scope model
- [ ] Enable RLS on sensitive tables
- [ ] Create office-scoped RLS policies
- [ ] Test Office A cannot access Office B data
- [ ] Test direct API attempts against other offices fail

### Definition of Done

- Permissions work and office data isolation is enforced at backend/RLS level.

---

## Milestone 4 — Core Orders + Bidding Engine

**Goal:** Build the commercial heart of the platform.

### Tasks

- [ ] Create orders table
- [ ] Create offers table
- [ ] Create order creation flow
- [ ] Support RIDE service
- [ ] Support DELIVERY service
- [ ] Store customer proposed price
- [ ] Create driver Accept Price action
- [ ] Create driver Counter Offer action
- [ ] Enforce one active offer per driver/order
- [ ] Create offer expiration rules
- [ ] Create accept_offer() atomic function
- [ ] Save selected_offer_id
- [ ] Save driver_id and office_id
- [ ] Save agreed_price
- [ ] Close all non-winning offers
- [ ] Test concurrent offer acceptance

### Definition of Done

- Customer creates an order, multiple drivers bid, and exactly one driver can win.

---

## Milestone 5 — Complete Trip Lifecycle

**Goal:** Implement the authoritative order state machine.

### Tasks

- [ ] Implement BIDDING
- [ ] Implement DRIVER_ASSIGNED
- [ ] Implement DRIVER_ON_WAY
- [ ] Implement DRIVER_ARRIVED
- [ ] Implement IN_PROGRESS
- [ ] Implement COMPLETED
- [ ] Implement CANCELLED
- [ ] Implement EXPIRED
- [ ] Create driver_on_way() function
- [ ] Create driver_arrived() function
- [ ] Create start_order() function
- [ ] Create complete_order() function
- [ ] Create cancel_order() function
- [ ] Reject invalid state transitions
- [ ] Test complete lifecycle through backend before UI

### Definition of Done

- A complete order can move safely from bidding to completion through backend functions.

---

## Milestone 6 — Driver App MVP

**Goal:** Create the first operational mobile application.

### Tasks

- [ ] Driver login / OTP
- [ ] Driver registration
- [ ] Independent vs Office Driver
- [ ] Motorcycle profile
- [ ] Document upload
- [ ] Pending / Active / Suspended states
- [ ] Home screen
- [ ] Online / Offline control
- [ ] Incoming request screen
- [ ] Accept customer price
- [ ] Counter offer
- [ ] Waiting for customer selection
- [ ] Assigned trip screen
- [ ] On Way
- [ ] Arrived
- [ ] Start Ride / Delivery
- [ ] Complete Ride / Delivery
- [ ] History
- [ ] Basic earnings
- [ ] Profile

### Definition of Done

- An approved driver can receive, bid on, and complete a real order.

---

## Milestone 7 — User App MVP

**Goal:** Allow a customer to create and complete Ride or Delivery orders.

### Tasks

- [ ] Customer login / OTP
- [ ] Customer profile
- [ ] Home
- [ ] Ride / Delivery selection
- [ ] Pickup selection
- [ ] Destination selection
- [ ] Proposed price
- [ ] Request review
- [ ] Create order
- [ ] Bidding screen
- [ ] Realtime driver offer list
- [ ] Driver comparison
- [ ] Select driver offer
- [ ] Assigned driver screen
- [ ] Trip status
- [ ] Completion summary
- [ ] Driver rating
- [ ] Order history
- [ ] Profile

### Definition of Done

- Customer and Driver can complete the full business flow using two real mobile builds.

---

## Milestone 8 — Maps + Live Location

**Goal:** Add real route and driver location behavior.

### Tasks

- [ ] Configure Google Maps project and keys
- [ ] Current location
- [ ] Pickup pin/search
- [ ] Destination pin/search
- [ ] Route display
- [ ] Distance calculation
- [ ] ETA
- [ ] Create driver_locations backend flow
- [ ] Driver location updates while Online
- [ ] More frequent updates during active order
- [ ] Customer sees assigned driver live
- [ ] Test battery/network behavior

### Definition of Done

- Customer can see the assigned driver moving on the map and route data is accurate enough for MVP.

---

## Milestone 9 — Realtime + Push Notifications

**Goal:** Make the platform responsive when apps are open, backgrounded, or closed.

### Tasks

- [ ] Realtime new offers
- [ ] Realtime offer selection
- [ ] Realtime order status changes
- [ ] Realtime driver location
- [ ] Configure Firebase project
- [ ] Configure FCM tokens
- [ ] Push: New Request
- [ ] Push: New Offer
- [ ] Push: Offer Selected
- [ ] Push: Driver Arrived
- [ ] Push: Trip Started
- [ ] Push: Trip Completed
- [ ] Push: Cancelled / Expired
- [ ] Deep-link notifications to relevant order

### Definition of Done

- Core events arrive without manual refresh and important background events generate push notifications.

---

## Milestone 10 — Unified Admin / Office Dashboard

**Goal:** Build one management dashboard for Admin and Offices.

### Tasks

- [ ] Dashboard authentication
- [ ] Permission-aware navigation
- [ ] Overview
- [ ] Orders
- [ ] Order Details
- [ ] Live Operations Map
- [ ] Drivers
- [ ] Driver Verification
- [ ] Motorcycles
- [ ] Users
- [ ] Offices
- [ ] Bids / Offers
- [ ] Reports
- [ ] Roles & Permissions
- [ ] Settings
- [ ] Audit Log
- [ ] Office scope filtering
- [ ] Test Super Admin vs Office Admin views

### Definition of Done

- Super Admin sees platform-wide data and Office users see only their own office in the same codebase.

---

## Milestone 11 — Driver & Office Verification

**Goal:** Finalize operational onboarding and compliance flows.

### Tasks

- [ ] Driver application review
- [ ] Document verification states
- [ ] Approve driver
- [ ] Reject driver
- [ ] Suspend driver
- [ ] Reactivate driver
- [ ] Motorcycle verification if required
- [ ] Prevent unapproved driver from going Online
- [ ] Record verifier and timestamps
- [ ] Audit all sensitive verification actions

### Definition of Done

- Only approved operational drivers can receive requests.

---

## Milestone 12 — Payments & Basic Commission

**Goal:** Record the financial snapshot for completed orders without building a full wallet.

### Tasks

- [ ] Use CASH as MVP payment method
- [ ] Store customer_offered_price
- [ ] Store agreed_price
- [ ] Define platform commission model
- [ ] Define office commission model
- [ ] Store commission snapshot if enabled
- [ ] Store driver net amount if finalized
- [ ] Show correct basic earnings
- [ ] Avoid building advanced settlement until required

### Definition of Done

- Every completed order has a reliable financial snapshot.

---

## Milestone 13 — Testing, Reliability & Security

**Goal:** Harden the system before production.

### Tasks

- [ ] RLS tests
- [ ] Cross-customer isolation tests
- [ ] Cross-driver isolation tests
- [ ] Cross-office isolation tests
- [ ] Concurrent offer selection test
- [ ] Duplicate order prevention
- [ ] Duplicate Complete prevention
- [ ] Invalid status transition tests
- [ ] Weak network tests
- [ ] App close/reopen recovery
- [ ] Realtime reconnect tests
- [ ] Location permission failure tests
- [ ] Notification delay/failure tests
- [ ] Suspended account tests
- [ ] Basic performance tests

### Definition of Done

- Critical flows remain correct under concurrency, permission attacks, and common mobile failures.

---

## Milestone 14 — Production Release

**Goal:** Prepare and deploy the production pilot.

### Tasks

- [ ] Create Production Supabase project/environment
- [ ] Apply migrations
- [ ] Configure Production Firebase
- [ ] Configure Production Google Maps keys
- [ ] Configure secrets securely
- [ ] Android signing
- [ ] Build User AAB/APK
- [ ] Build Driver AAB/APK
- [ ] Deploy Dashboard
- [ ] Create production Admin account
- [ ] Create test Office account
- [ ] Prepare README
- [ ] Prepare backup/recovery process
- [ ] Enable error/crash logging
- [ ] Prepare known limitations list
- [ ] Run final smoke test

### Definition of Done

- Pilot-ready production environment is deployed with installable apps and working dashboard.

---

## Core Flow That Must Work Before UI Polish

```text
Customer creates order
→ Drivers bid
→ Customer selects one offer
→ Exactly one driver is assigned
→ Driver goes On Way
→ Driver Arrives
→ Trip / Delivery Starts
→ Trip / Delivery Completes
```

## Main Technology Stack

```text
User App     → Flutter
Driver App   → Flutter
Dashboard    → Next.js + TypeScript
Backend      → Supabase
Maps         → Google Maps
Push         → Firebase Cloud Messaging
```