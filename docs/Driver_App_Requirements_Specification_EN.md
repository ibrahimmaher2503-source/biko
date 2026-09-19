# Driver Mobile Application

## Product & Functional Requirements Specification

**Project:** Motorcycle Mobility & Delivery Platform\
**Component:** Driver Mobile Application\
**Version:** 1.0\
**Status:** MVP Implementation Specification\
**Platform Priority:** Android, with iOS support from the same Flutter
codebase\
**Date:** August 28, 2026

> **Purpose:** Define the complete MVP requirements for the
> driver-facing mobile application so the development team can design,
> implement, test, and deliver it without ambiguity.

------------------------------------------------------------------------

# 1. Product Overview

The Driver App is the operational application used by motorcycle drivers
to receive customer requests, participate in bidding, navigate to pickup
locations, execute passenger rides or parcel deliveries, update trip
status, share live location, and review completed work.

The platform supports two driver business models:

1.  **Independent Driver**
2.  **Office Driver**

An Office Driver belongs to a delivery office managed through the
Unified Admin/Office Dashboard.

The Driver App must use the same backend, order state machine, bidding
engine, and permission model as the User App and Unified Dashboard.

------------------------------------------------------------------------

# 2. MVP Goals

The Driver App must allow an approved driver to complete the following
journey:

``` text
Register / Login
        ↓
Complete Driver Profile
        ↓
Add Motorcycle
        ↓
Upload Required Documents
        ↓
Wait for Approval
        ↓
Account = ACTIVE
        ↓
Go ONLINE
        ↓
Receive Eligible Requests
        ↓
Review Customer Offer
        ↓
Accept Price OR Counter Offer
        ↓
Wait for Customer Selection
        ↓
Customer Selects Driver
        ↓
Navigate to Pickup
        ↓
Mark Arrived
        ↓
Start Ride / Delivery
        ↓
Share Live Location
        ↓
Complete Order
        ↓
View Trip in History / Earnings
```

------------------------------------------------------------------------

# 3. Recommended Technology

## 3.1 Mobile Framework

**Flutter**

One Flutter project dedicated to the Driver App.

Reusable shared packages with the User App are recommended for:

-   Models.
-   API client.
-   Authentication helpers.
-   Localization.
-   Common UI components.
-   Map utilities.
-   Error handling.

Driver-specific flows and permissions must remain separate.

## 3.2 Backend

**Supabase**

Use Supabase for:

-   Authentication.
-   PostgreSQL database.
-   Realtime.
-   Storage.
-   Row Level Security.
-   Database Functions / RPC.
-   Edge Functions where needed.

## 3.3 Maps & Navigation

**Google Maps Platform**

Required for:

-   Current driver location.
-   Pickup location.
-   Destination.
-   Route display.
-   Distance.
-   ETA.
-   Navigation handoff.
-   Live location.

## 3.4 Push Notifications

**Firebase Cloud Messaging (FCM)**

------------------------------------------------------------------------

# 4. Driver Types

Each driver must have one of the following types:

``` text
INDEPENDENT
OFFICE_DRIVER
```

## 4.1 Independent Driver

``` text
office_id = NULL
```

The driver operates directly on the platform.

## 4.2 Office Driver

``` text
office_id = <office_id>
```

The driver belongs to one delivery office.

MVP permits one office maximum. Changing offices requires a trusted Change
Request approved by Platform Admin; historical orders keep their original
office snapshot. This change-request workflow is **PENDING IMPLEMENTATION**.

**MVP recommendation:** A driver belongs to one office only, or is
Independent.

The app must not allow the driver to manually change office ownership
unless the backend explicitly permits it.

------------------------------------------------------------------------

# 5. Driver Account Status

Recommended statuses:

``` text
PENDING
ACTIVE
SUSPENDED
REJECTED
```

### PENDING

Driver has registered but is not yet approved.

### ACTIVE

Driver can go Online and receive requests.

### SUSPENDED

Driver cannot receive new requests.

### REJECTED

Driver application was rejected.

Only `ACTIVE` drivers may become operationally Online.

------------------------------------------------------------------------

# 6. Authentication

Primary MVP method:

**Email + Password**

Required flow:

1.  Driver enters email and password.
2.  Supabase authenticates the credentials.
3.  Existing driver continues to the app.
4.  New public signup remains a `CUSTOMER` until trusted onboarding logic
    creates/promotes the driver identity.

The application must persist valid sessions securely.

Phone OTP / SMS authentication is out of MVP. The final Delivery Confirmation
Code is an operational completion control, not a login method.

------------------------------------------------------------------------

# 7. Driver Registration & Onboarding

New drivers must complete an onboarding process.

Recommended onboarding steps:

1.  Basic personal information.
2.  Driver type.
3.  Office association if applicable.
4.  Motorcycle details.
5.  Required documents.
6.  Review.
7.  Submission.
8.  Pending approval.

The exact number of screens may be reduced for faster delivery.

------------------------------------------------------------------------

# 8. Driver Profile

Recommended fields:

``` text
id
auth_user_id
full_name
phone
profile_photo_url
driver_type
office_id
status
rating
completed_trip_count
created_at
updated_at
```

Additional business fields may be added as needed.

The driver may edit allowed personal fields such as:

-   Name.
-   Profile photo.
-   Basic contact information if permitted.

Sensitive verified fields must require approval or administrative
intervention.

------------------------------------------------------------------------

# 9. Driver Documents

Documents must be stored securely using Supabase Storage.

Required driver documents are:

-   National ID.
-   Valid driving licence.
-   Driver/profile selfie.

Minimum driver age is 21. A criminal record is required before public
launch, subject to legal/regulatory confirmation.

Each document should have a verification status such as:

``` text
PENDING
APPROVED
REJECTED
EXPIRED
```

Recommended document fields:

``` text
id
driver_id
document_type
file_url
status
rejection_reason
uploaded_at
verified_at
verified_by
expiry_date
```

Expiry warnings occur at 30, 7, and 1 day. Expiry blocks new requests but
does not interrupt an active trip. A replacement remains `PENDING` until
approved. Complete expiry enforcement is **PENDING IMPLEMENTATION**.

------------------------------------------------------------------------

# 10. Motorcycle Profile

Each driver must have a motorcycle available for service.

Recommended fields:

``` text
id
driver_id
office_id
plate_number
brand
model
color
model_year
photo_url
status
```

Possible statuses:

``` text
ACTIVE
INACTIVE
SUSPENDED
```

The driver should be prevented from going Online if the assigned
motorcycle is not operationally approved.

Motorcycle verification uses a dedicated `motorcycle_documents` concept/
table for registration/licence, ownership authorization where applicable,
motorcycle photos, and legally/operationally required insurance or
inspection. That table and workflow are **PENDING IMPLEMENTATION**.

------------------------------------------------------------------------

# 11. Driver Home Screen

The Driver Home Screen should focus on operations.

Primary elements:

-   Map.
-   Current location.
-   Online / Offline switch.
-   Current driver status.
-   Active order shortcut.
-   Basic daily activity/earnings summary.
-   Alerts for profile/document problems.

When Offline, the app should clearly indicate that no new requests will
be received.

------------------------------------------------------------------------

# 12. Online / Offline State

The driver can explicitly choose:

``` text
ONLINE
OFFLINE
```

Before allowing `ONLINE`, backend should verify:

-   Driver account is `ACTIVE`.
-   Driver is not suspended.
-   Required documents are approved and unexpired.
-   Motorcycle is valid/operational.
-   Driver has no active order.

The app must not rely only on local state. One driver may have only one
active job. Current backend enforcement is partial; motorcycle/document/
expiry/helmet eligibility remains **PENDING IMPLEMENTATION**.

------------------------------------------------------------------------

# 13. Driver Location

When Online:

-   The app sends driver location updates at an appropriate interval.
-   The backend stores or publishes current operational location.
-   Location frequency must balance:
    -   Accuracy.
    -   Battery consumption.
    -   Mobile data.
    -   Backend cost.

During an active assigned order, tracking may use a more frequent update
interval.

Recommended current location data:

``` text
driver_id
latitude
longitude
heading
speed
accuracy
updated_at
```

Location history should not be stored indefinitely unless required.

------------------------------------------------------------------------

# 14. Request Eligibility

A driver should receive only eligible requests.

Basic eligibility may include:

-   Driver is `ACTIVE`.
-   Driver is `ONLINE`.
-   Driver is not currently unavailable.
-   Driver is within the active 2/4/6/8 km dispatch radius.
-   Service Type is enabled for the driver.
-   Driver/motorcycle meets operational rules.
-   Office rules permit receiving the request.
-   Geographic zone is allowed.

Eligibility must be determined by trusted backend logic.

The radius expands approximately every 20 seconds during the 90-second
bidding window. Candidate discovery uses PostGIS/database logic, not paid
routing APIs. This progressive dispatch behavior is **PENDING
IMPLEMENTATION**.

------------------------------------------------------------------------

# 15. Incoming Request

When a new eligible request is available, the Driver App should show a
request card or full-screen request view.

Recommended information:

-   Service Type:
    -   Ride.
    -   Delivery.
-   Pickup address/location.
-   Destination address/location.
-   Approximate distance from driver to Pickup.
-   Approximate trip distance.
-   Estimated trip duration.
-   Customer proposed price.
-   Optional notes.
-   For Delivery, item/parcel description if provided.
-   Request expiration/countdown.

Private customer information should not be unnecessarily exposed before
assignment.

Specifically, the customer's full name and phone must not be shown before
assignment. A Call button is allowed after assignment; masking and in-app
chat are out of MVP.

------------------------------------------------------------------------

# 16. Driver Bidding Actions

For each active request, the driver may:

``` text
ACCEPT CUSTOMER PRICE
COUNTER OFFER
REJECT / IGNORE
```

## 16.1 Accept Customer Price

If customer proposes:

``` text
80 EGP
```

Driver can accept:

``` text
Offer Amount = 80 EGP
```

## 16.2 Counter Offer

Driver may submit a different price.

Example:

``` text
Customer Offer: 80 EGP
Driver Counter Offer: 95 EGP
```

## 16.3 Reject / Ignore

Driver may reject or allow the request to expire from their view.

Rejection should not cancel the customer's order.

------------------------------------------------------------------------

# 17. Offer Rules

Mandatory:

-   Driver can submit offers only when order is `BIDDING`.
-   Driver can have only one active offer per order.
-   An active offer cannot be edited directly.
-   Driver may withdraw an unselected offer while the order is `BIDDING`.
-   After withdrawal, the driver may submit a new offer.
-   Driver cannot submit an offer after request expiration.
-   Driver cannot submit an invalid/non-positive amount.
-   Backend must validate offer amount.
-   Offer submission must be idempotent where practical.

Suggested offer statuses:

``` text
ACTIVE
SELECTED
REJECTED
WITHDRAWN
EXPIRED
CLOSED
```

------------------------------------------------------------------------

# 18. Waiting for Customer Selection

After submitting an offer, the driver should see a clear waiting state.

Recommended display:

-   Customer proposed price.
-   Driver offered price.
-   Order summary.
-   Offer status.
-   Time remaining.
-   Withdraw Offer action while `BIDDING` and unselected; no direct edit.

Possible outcomes:

``` text
SELECTED
NOT_SELECTED
EXPIRED
ORDER_CANCELLED
OFFER_WITHDRAWN
```

The app must update this state in Realtime.

------------------------------------------------------------------------

# 19. Customer Selects Driver

When the customer selects the driver's offer:

1.  Backend atomically assigns the driver.
2.  Driver receives Realtime event.
3.  Driver receives Push Notification.
4.  Order becomes:

``` text
DRIVER_ASSIGNED
```

The app should automatically open or prominently surface the assigned
trip.

At this point, driver may receive additional customer/contact
information as allowed.

------------------------------------------------------------------------

# 20. Assigned Order Screen

Show:

-   Service Type.
-   Pickup.
-   Destination.
-   Customer name, where permitted.
-   Customer contact action, where enabled.
-   Agreed price.
-   Motorcycle.
-   Navigation action.
-   Current order status.
-   Operational action button.

The `agreed_price` must be read-only for the driver.

------------------------------------------------------------------------

# 21. Navigation to Pickup

Driver should be able to:

-   View Pickup on map.
-   View route from current location to Pickup.
-   See approximate distance and ETA.
-   Open external navigation if desired.

Primary status transition:

``` text
DRIVER_ASSIGNED
        ↓
DRIVER_ON_WAY
```

The backend must validate the transition.

------------------------------------------------------------------------

# 22. Driver On The Way

When status is:

``` text
DRIVER_ON_WAY
```

The User App should receive:

-   Realtime update.
-   Push notification where appropriate.

Driver App should continue live location updates.

------------------------------------------------------------------------

# 23. Arrival at Pickup

Driver presses:

**Arrived**

Backend changes:

``` text
DRIVER_ON_WAY
        ↓
DRIVER_ARRIVED
```

Requirements:

-   Customer receives Realtime update.
-   Customer receives arrival notification.
-   Arrival timestamp is stored.
-   Duplicate arrival actions are prevented.

The Maps milestone must enforce a 200-meter Pickup geofence. GPS failure
allows Retry. Any exception requires an explicit trusted Admin/Support
override, mandatory reason, and audit log. This is **FUTURE MILESTONE**.

------------------------------------------------------------------------

# 24. Starting Passenger Ride

For `RIDE`:

Driver may start the trip after arrival.

Transition:

``` text
DRIVER_ARRIVED
        ↓
IN_PROGRESS
```

No Ride Start OTP is required. After trusted 200-meter Pickup arrival, the
assigned Driver starts the Ride directly.

------------------------------------------------------------------------

# 25. Starting Parcel Delivery

For `DELIVERY`:

After reaching Pickup and collecting the item, driver starts delivery.

Transition:

``` text
DRIVER_ARRIVED
        ↓
IN_PROGRESS
```

No sender Pickup OTP is required. Trusted 200-meter Pickup arrival moves the
Delivery into progress. Completion requires one final 4-digit Customer
Confirmation Code plus the trusted Destination geofence.

------------------------------------------------------------------------

# 26. Active Trip / Delivery

While `IN_PROGRESS`, show:

-   Service Type.
-   Destination.
-   Route.
-   Current location.
-   Customer basic information.
-   Agreed price.
-   Current status.
-   Complete Trip/Delivery action.

Live location remains active.

The driver must not be able to bid on incompatible new orders while
already assigned, unless multi-order support is explicitly introduced
later.

------------------------------------------------------------------------

# 27. Completing the Order

At destination, the driver presses:

**Complete**

Backend validates the request and changes:

``` text
IN_PROGRESS
        ↓
COMPLETED
```

Store:

-   Completion timestamp.
-   Final agreed price.
-   Driver.
-   Office if applicable.
-   Motorcycle.
-   Payment method.
-   Relevant financial values.

The completion action must be protected from duplicate requests.

The Maps milestone must enforce a 300-meter Destination geofence with Retry
and the same audited trusted override rule. This is **FUTURE MILESTONE**.

------------------------------------------------------------------------

# 28. Parcel Proof of Delivery

For Delivery, one final Customer Confirmation Code is required at completion.
Delivery photo and recipient signature are out of MVP. Recipient name/phone
is exposed only when operationally required.

------------------------------------------------------------------------

# 29. Cancellation

The driver may cancel before `IN_PROGRESS`; a reason is mandatory. After
assignment, cancellation makes the order `CANCELLED` and must not return the
same order to `BIDDING`. The customer receives Book Again with pickup,
destination, and proposed price prefilled.

Three post-assignment cancellations within a rolling 7 days flag the driver
for operations review, but do not automatically suspend the account.

Recommended cancellation data:

``` text
cancelled_by
cancellation_reason
cancelled_at
```

These driver cancellation, Book Again, and abuse-flag behaviors are
**PENDING IMPLEMENTATION** and must be enforced by backend rules.

------------------------------------------------------------------------

# 30. Driver History

Driver can view previous orders.

Each history item should show:

-   Service Type.
-   Date/time.
-   Pickup.
-   Destination.
-   Agreed price.
-   Status.
-   Customer rating where available.
-   Office relationship if relevant.

Suggested filters:

``` text
All
Completed
Cancelled
Ride
Delivery
```

Advanced filtering is not required for MVP.

------------------------------------------------------------------------

# 31. Basic Earnings

The MVP should provide a simple operational earnings view.

At minimum:

-   Completed trip count.
-   Gross agreed price total.
-   Daily total.
-   Weekly total or date range total.

Independent Drivers also show:

-   Platform commission.
-   Driver net amount.

Office Drivers show gross completed-trip value only. They do not see office
commission or payroll calculations.

------------------------------------------------------------------------

# 32. Independent Driver Financial View

Possible structure:

``` text
Gross Trip Value
- Platform Commission
= Driver Net
```

Platform commission is 10% of `agreed_price`; launch promotion is 0% for the
first 14 days, then 10%. Values are configurable. This financial view is
**PENDING IMPLEMENTATION**.

------------------------------------------------------------------------

# 33. Office Driver Financial View

The model is `Platform <-> Office`, with 7% Platform commission. The launch
promotion is 5% for the first month, then 7%. The office controls internal
driver compensation. The Driver App shows gross completed-trip value only.
Commission/ledger implementation is **PENDING IMPLEMENTATION**.

------------------------------------------------------------------------

# 34. Driver Rating

Driver should be able to view:

-   Current average rating.
-   Completed trip count.

For MVP, individual written customer reviews may be hidden or shown
depending on product policy.

The driver must not be able to modify ratings.

------------------------------------------------------------------------

# 35. Notifications

Required Push Notifications may include:

-   New eligible request.
-   Customer selected driver's offer.
-   Customer cancelled order.
-   Order expired.
-   Driver account approved.
-   Driver account suspended.
-   Document rejected.
-   Important operational messages.

Notification taps should deep-link to the relevant screen when
practical.

------------------------------------------------------------------------

# 36. Realtime Events

Supabase Realtime should be used where appropriate for:

-   New eligible orders.
-   Order cancellation.
-   Offer selected.
-   Offer closed.
-   Order status updates.
-   Driver account status changes.

The app must recover correctly after:

-   App minimization.
-   App termination/reopen.
-   Temporary connection loss.
-   Realtime reconnect.

The database remains the source of truth.

------------------------------------------------------------------------

# 37. Background Behavior

Driver operations require careful background behavior.

When Online or in an active trip:

-   Location updates should continue according to OS permissions and
    technical limitations.
-   Push notifications should surface important requests.
-   App reopen should restore active order state.

The implementation must respect Android/iOS background execution
policies.

For fastest MVP delivery, Android should be optimized first.

------------------------------------------------------------------------

# 38. Driver Availability State Machine

Recommended operational state:

``` text
OFFLINE
ONLINE_AVAILABLE
OFFER_PENDING
ASSIGNED
ON_WAY
ARRIVED
IN_PROGRESS
```

A driver should not receive incompatible requests when:

``` text
ASSIGNED
ON_WAY
ARRIVED
IN_PROGRESS
```

The exact representation may be derived from order state rather than
stored independently, but behavior must remain consistent.

------------------------------------------------------------------------

# 39. Security Requirements

Mandatory:

-   Supabase Auth.
-   Row Level Security.
-   Driver can access only permitted driver data.
-   Driver can access only their own offers.
-   Driver can access assigned orders.
-   Driver can access eligible bidding requests only through approved
    backend rules.
-   Office Driver cannot access another office's internal data.
-   Driver cannot self-approve.
-   Driver cannot change own verification status.
-   Driver cannot directly modify `agreed_price`.
-   Driver cannot directly assign an order to themselves.
-   Driver cannot force invalid order status transitions.
-   Supabase Service Role Key must never exist in Flutter source.
-   Sensitive transitions use secure backend/database functions.

------------------------------------------------------------------------

# 40. Order State Rules for Driver App

Driver App must honor:

``` text
BIDDING
        ↓ customer selects offer
DRIVER_ASSIGNED
        ↓
DRIVER_ON_WAY
        ↓
DRIVER_ARRIVED
        ↓
IN_PROGRESS
        ↓
COMPLETED
```

Possible terminal alternatives:

``` text
CANCELLED
EXPIRED
```

Invalid transitions must fail on the backend.

Example:

``` text
DRIVER_ASSIGNED -> COMPLETED
```

must not be accepted directly.

------------------------------------------------------------------------

# 41. Weak Network & Error Handling

The app must handle:

-   No internet.
-   GPS disabled.
-   Location permission denied.
-   Background location restricted.
-   Invalid OTP.
-   Request expired while viewing.
-   Offer expired before submission.
-   Customer selected another driver.
-   Customer cancelled request.
-   Duplicate offer submission.
-   Driver account suspended while Online.
-   Realtime disconnected.
-   Trip status update failed.
-   Complete action timed out.
-   Push notification arrived late.

User-facing messages must be clear.

Critical actions should safely retry without producing duplicate state
changes.

------------------------------------------------------------------------

# 42. Loading & Interaction States

Every critical operation requires loading/disabled states.

Examples:

-   OTP verification.
-   Going Online.
-   Going Offline.
-   Loading request.
-   Accepting customer price.
-   Submitting counter-offer.
-   Updating status.
-   Arrived.
-   Starting trip.
-   Completing trip.
-   Uploading documents.

Prevent repeated button taps from causing duplicate backend operations.

------------------------------------------------------------------------

# 43. Suggested Navigation Structure

Recommended bottom navigation:

``` text
Home
History
Earnings
Profile
```

If there is an active assignment, the app must provide a prominent:

**Active Order**

entry point from anywhere.

------------------------------------------------------------------------

# 44. Recommended Screen List

## Authentication & Onboarding

1.  Splash / Initialization.
2.  Email/Password Sign In.
3.  Sign Up / Forgot Password.
4.  Driver Registration.
5.  Driver Type Selection.
6.  Office Association, if required.
7.  Motorcycle Details.
8.  Document Upload.
9.  Application Review.
10. Pending Approval / Rejected Status.

## Driver Operations

11. Home Map.
12. Online / Offline.
13. Incoming Request.
14. Counter Offer.
15. Offer Waiting State.
16. Offer Not Selected / Expired.
17. Assigned Order.
18. Navigation to Pickup.
19. Driver Arrived.
20. Start Ride / Delivery.
21. Active Trip / Delivery.
22. Complete Order.
23. Completion Summary.

## Account

24. History.
25. Trip Details.
26. Earnings.
27. Profile.
28. Motorcycle.
29. Documents.
30. Settings.

Some screens may be combined to reduce implementation time.

------------------------------------------------------------------------

# 45. UX Priorities

The Driver App should prioritize:

1.  Minimal distraction while driving.
2.  Large, clear primary actions.
3.  Fast request review.
4.  Clear customer price.
5.  Simple counter-offer entry.
6.  Clear indication whether offer is still active.
7.  Obvious assigned trip state.
8.  Easy navigation to Pickup/Destination.
9.  Minimal typing during operations.
10. Strong handling of weak network.
11. Prevent accidental duplicate actions.
12. Safety-conscious interaction design.

------------------------------------------------------------------------

# 46. Arabic-First UI

Initial interface should support Arabic as primary language.

Requirements:

-   RTL layout.
-   Arabic-friendly typography.
-   Clear large amounts and EGP display.
-   Map controls suitable for RTL.
-   Localization architecture allowing English later.

Do not hardcode all application strings inside widgets.

------------------------------------------------------------------------

# 47. Performance Requirements

The Driver App should:

-   Open quickly on typical Android phones.
-   Efficiently manage location updates.
-   Avoid unnecessary database subscriptions.
-   Dispose inactive Realtime subscriptions.
-   Minimize battery consumption.
-   Avoid excessive map refreshes.
-   Compress document/image uploads.
-   Cache safe operational data where appropriate.
-   Restore active assignment quickly after app reopen.

------------------------------------------------------------------------

# 48. Driver Analytics Events Recommended

Useful product/operations events include:

``` text
driver_signup_started
driver_signup_completed
documents_submitted
driver_approved
driver_online
driver_offline
request_received
request_accepted_price
counter_offer_submitted
offer_selected
offer_not_selected
driver_on_way
driver_arrived
trip_started
trip_completed
driver_cancelled
```

Analytics provider may be selected later.

------------------------------------------------------------------------

# 49. Core Driver Data Requirements

Driver-safe fields may include:

``` text
driver_id
full_name
phone
profile_photo_url
driver_type
office_id
status
rating
completed_trip_count
online_status
motorcycle_id
created_at
updated_at
```

The application must not receive administrative/internal fields
unnecessarily.

------------------------------------------------------------------------

# 50. Request Data Required by Driver App

Before assignment, customer-safe/driver-safe request fields may include:

``` text
order_id
service_type
pickup_lat
pickup_lng
pickup_address
destination_lat
destination_lng
destination_address
customer_offered_price
distance_to_pickup
route_distance
estimated_duration
notes
bidding_expires_at
```

Sensitive customer information should be limited before assignment.

------------------------------------------------------------------------

# 51. Assigned Order Data

After assignment, the Driver App may additionally receive:

``` text
agreed_price
customer_display_name
customer_contact_data_if_allowed
selected_offer_id
assigned_at
order_status
motorcycle_id
```

Only data needed for operation should be exposed.

------------------------------------------------------------------------

# 52. MVP Acceptance Criteria

The Driver App is accepted only when the following work on an actual
Android build.

## Authentication & Onboarding

-   Driver can authenticate using email/password; public signup cannot
    create or activate a driver identity.
-   Driver can enter required profile information.
-   Driver can add motorcycle information.
-   Driver can upload required documents.
-   Pending driver cannot receive requests.
-   Approved driver becomes `ACTIVE`.
-   Suspended driver cannot receive new requests.

## Online Operations

-   Active driver can go Online.
-   Offline driver receives no operational requests.
-   Driver location updates while Online.
-   Active trip location updates correctly.

## Request Reception

-   Eligible requests reach the driver.
-   Non-eligible requests do not appear.
-   Request shows correct service, locations, customer price, and
    relevant route data.

## Bidding

-   Driver can accept customer price.
-   Driver can submit counter-offer.
-   Invalid offer values are rejected.
-   Driver cannot submit multiple unintended active offers for same
    order.
-   Offer state updates in Realtime.
-   Driver receives selected/not-selected result correctly.

## Assignment

-   Selected driver receives assigned order.
-   Non-selected drivers cannot access assigned order actions.
-   Exactly one driver is assigned to the order.
-   Agreed price is correct and read-only.

## Trip Execution

Driver can execute:

``` text
Assigned
-> On Way
-> Arrived
-> Start
-> Complete
```

-   Invalid status transitions fail.
-   Customer receives corresponding status updates.
-   Driver live location is available to the assigned customer.
-   Completion is stored once only.

## History & Earnings

-   Completed trip appears in History.
-   Agreed price is correct.
-   Basic gross totals are correct.
-   Frozen Independent commission/net and Office gross-only views appear once
    the pending commission wave is implemented.

## Security

-   Driver cannot self-approve.
-   Driver cannot edit another driver's data.
-   Driver cannot access another driver's private offers.
-   Office Driver cannot access another office's protected internal
    data.
-   Driver cannot directly manipulate assignment/agreed price through
    API calls.
-   RLS/backend policies enforce these rules.

## Reliability

-   App restores an active trip after reopen.
-   Temporary connection loss does not duplicate offers or status
    changes.
-   Late/outdated request cannot be accepted.
-   Duplicate Complete taps do not create duplicate completion events.

------------------------------------------------------------------------

# 53. Explicitly Out of Driver App MVP Unless Approved

Do not delay the MVP by building:

-   Advanced wallet.
-   Instant cash-out.
-   Online payout system.
-   Driver subscription plans.
-   Advanced incentive system.
-   Heat maps.
-   AI demand forecasting.
-   Multi-order batching.
-   Multi-stop delivery.
-   Scheduled jobs.
-   Advanced in-app chat.
-   Call masking.
-   Referral system.
-   Gamification.
-   Advanced route optimization.
-   Advanced office payroll.
-   Complex settlement accounting.

The architecture should allow later expansion.

------------------------------------------------------------------------

# 54. Frozen Business Decisions Affecting Driver App

Business Rules Freeze v1.0 resolves the prior open questions: one office
maximum; trusted Platform final verification; fixed driver-document set and
separate motorcycle documents; expiry rules; no active-offer editing;
withdraw/new offer flow; 90-second offer window; pre-assignment privacy;
no Ride or Pickup OTP and one final Delivery Confirmation Code; frozen driver cancellation/abuse handling;
Independent and Office commission models; and 200/300-meter geofences. See
`BUSINESS_RULES_FREEZE_V1.md`.

Milestone 10 implements the verification, geofence, and Delivery Confirmation
Code rules. Other rules not present in the current app/backend remain
**PENDING IMPLEMENTATION** or **FUTURE MILESTONE**.

------------------------------------------------------------------------

# 55. Definition of Done for Driver App

A Driver App feature is considered Done only when:

-   Flutter UI is complete.
-   Backend integration is complete.
-   RLS and authorization are enforced.
-   Operational state rules are enforced.
-   Loading states are implemented.
-   Error states are implemented.
-   Realtime behavior works.
-   Required Push Notifications work.
-   Location behavior works under agreed permissions.
-   App restores active operational state after reopen.
-   Critical flow is tested on a real Android device.

------------------------------------------------------------------------

# 56. Driver App Delivery Package

Development handover should include:

-   Flutter source code.
-   Organized repository.
-   Environment configuration documentation.
-   No production secrets committed to source.
-   Installable Android build.
-   Release/build instructions.
-   README.
-   Demo/test driver accounts.
-   At least one Independent Driver test account.
-   At least one Office Driver test account.
-   Test cases for `PENDING`, `ACTIVE`, and `SUSPENDED`.
-   Known bugs/limitations.
-   Google Maps configuration instructions.
-   Firebase/FCM configuration instructions.
-   Supabase integration notes.
-   Background location configuration notes.

------------------------------------------------------------------------

# Appendix A - Main Driver Journey

``` text
LOGIN
  |
  v
DRIVER PROFILE
  |
  v
MOTORCYCLE + DOCUMENTS
  |
  v
PENDING APPROVAL
  |
  v
ACTIVE
  |
  v
ONLINE
  |
  v
RECEIVE REQUEST
  |
  +--> ACCEPT CUSTOMER PRICE
  |
  +--> COUNTER OFFER
  |
  +--> REJECT / IGNORE
  |
  v
WAIT FOR CUSTOMER
  |
  +--> NOT SELECTED -> AVAILABLE
  |
  +--> SELECTED
             |
             v
        ASSIGNED
             |
             v
          ON WAY
             |
             v
          ARRIVED
             |
             v
        IN PROGRESS
             |
             v
         COMPLETE
             |
             v
       HISTORY / EARNINGS
```

------------------------------------------------------------------------

# Appendix B - Driver Bidding Journey

``` text
Customer Request
Price: 80 EGP
     |
     v
Driver receives request
     |
     +---------------------------+
     |                           |
     v                           v
Accept 80 EGP              Counter 95 EGP
     |                           |
     +-------------+-------------+
                   |
                   v
              ACTIVE OFFER
                   |
                   v
          Wait for Customer
                   |
        +----------+----------+
        |                     |
        v                     v
   NOT SELECTED            SELECTED
        |                     |
        v                     v
   Back Available       DRIVER_ASSIGNED
                              |
                              v
                           ON WAY
                              |
                              v
                           ARRIVED
                              |
                              v
                         IN_PROGRESS
                              |
                              v
                          COMPLETED
```

------------------------------------------------------------------------

# Appendix C - Office Driver Relationship

``` text
Platform
   |
   +--> Independent Driver
   |
   +--> Delivery Office
            |
            +--> Office Admin
            |
            +--> Office Drivers
            |
            +--> Motorcycles
```

An Office Driver uses the same Driver App as an Independent Driver.

The difference is determined by:

``` text
driver_type
office_id
permissions
business rules
```

No separate Office Driver mobile app is required.

------------------------------------------------------------------------

# Appendix D - Driver App MVP Checklist

  Feature                           Required
  --------------------------------- ----------
  Email/Password Authentication     Yes
  Driver Registration               Yes
  Independent Driver                Yes
  Office Driver                     Yes
  Driver Approval Status            Yes
  Document Upload                   Yes
  Motorcycle Profile                Yes
  Online / Offline                  Yes
  Driver Live Location              Yes
  Receive Eligible Requests         Yes
  Passenger Ride Requests           Yes
  Parcel Delivery Requests          Yes
  Customer Proposed Price           Yes
  Accept Customer Price             Yes
  Counter Offer                     Yes
  Realtime Offer Status             Yes
  Customer Selection Notification   Yes
  Assigned Trip                     Yes
  Navigation to Pickup              Yes
  Driver On Way                     Yes
  Arrived                           Yes
  Start Trip / Delivery             Yes
  Live Tracking During Trip         Yes
  Complete Order                    Yes
  Trip History                      Yes
  Basic Earnings                    Yes
  Driver Rating Display             Yes
  Push Notifications                Yes
  RLS / Driver Data Isolation       Yes
  Full Wallet                       Later
  Advanced Payout                   Later
  Multi-order Batching              Later
  AI Dispatch                       Later
  Advanced Incentives               Later

------------------------------------------------------------------------

**End of Driver Mobile Application Requirements Specification**
