# User Mobile Application

## Product & Functional Requirements Specification

**Project:** Motorcycle Mobility & Delivery Platform\
**Component:** Customer / User Mobile Application\
**Version:** 1.0\
**Status:** MVP Implementation Specification\
**Platform Priority:** Android, with iOS support from the same Flutter
codebase\
**Date:** August 28, 2026

> **Purpose:** Define the complete MVP requirements for the
> customer-facing mobile application so the development team can design,
> implement, test, and deliver it without ambiguity.

------------------------------------------------------------------------

# 1. Product Overview

The User App allows customers to request motorcycle-based services using
a bidding model.

The MVP supports two primary services:

1.  **Passenger Ride**\
    The customer requests a motorcycle driver to transport the customer
    from a pickup point to a destination.

2.  **Parcel Delivery**\
    The customer requests a motorcycle driver to collect an item,
    parcel, or document from a pickup point and deliver it to a
    destination.

Pricing is primarily based on **bidding**, not a mandatory fixed fare.

The customer proposes a price, eligible drivers receive the request,
drivers may accept that price or submit counter-offers, and the customer
chooses the preferred driver/offer.

------------------------------------------------------------------------

# 2. MVP Goals

The User App must allow a customer to complete the following journey:

``` text
Register / Login
        ↓
Select Service
        ↓
Choose Pickup
        ↓
Choose Destination
        ↓
Enter Proposed Price
        ↓
Submit Request
        ↓
Receive Driver Offers in Realtime
        ↓
Compare Drivers and Prices
        ↓
Select One Offer
        ↓
Track Assigned Driver
        ↓
Driver Arrives
        ↓
Trip / Delivery Starts
        ↓
Live Tracking
        ↓
Trip / Delivery Completes
        ↓
Rate Driver
        ↓
View Order in History
```

The application should remain fast and simple while preserving all core
business functions.

------------------------------------------------------------------------

# 3. Recommended Technology

## 3.1 Mobile Framework

**Flutter**

One Flutter project for the User App.

## 3.2 Backend

**Supabase**

Use Supabase for:

-   Authentication.
-   PostgreSQL database.
-   Realtime subscriptions.
-   Storage.
-   Row Level Security.
-   Database Functions / RPC.
-   Edge Functions where necessary.

## 3.3 Maps

**Google Maps Platform**

Required for:

-   Map display.
-   Current location.
-   Pickup selection.
-   Destination selection.
-   Place search.
-   Route display.
-   Distance.
-   Estimated duration.
-   Driver live location.

## 3.4 Push Notifications

**Firebase Cloud Messaging (FCM)**

------------------------------------------------------------------------

# 4. User Role

The application has one primary authenticated role:

``` text
CUSTOMER
```

A customer must only be able to access:

-   Their own profile.
-   Their own orders.
-   Driver offers belonging to their own active orders.
-   Assigned driver information for their own orders.
-   Their own ratings and history.

This restriction must be enforced by Supabase RLS/backend authorization,
not only by the Flutter UI.

------------------------------------------------------------------------

# 5. Authentication & Account

## 5.1 Login / Registration

Primary MVP authentication:

**Email + Password**

Required flow:

1.  User enters email and password.
2.  Supabase authenticates the credentials.
3.  If this is a new account, the trusted signup path creates a `CUSTOMER` profile.
4.  User enters the application and the valid session is restored on restart.

Phone OTP / SMS authentication is out of MVP. The final Delivery Confirmation Code is an operational completion control, not a login method.

## 5.2 Basic Profile

Recommended MVP fields:

``` text
id
full_name
phone
profile_photo_url
status
created_at
updated_at
```

## 5.3 Account Status

Recommended statuses:

``` text
ACTIVE
SUSPENDED
DELETED
```

A suspended user must not be able to create new orders.

## 5.4 Profile Functions

Customer can:

-   View profile.
-   Edit name.
-   Change/upload profile photo.
-   View phone number.
-   Logout.
-   Request account deletion according to product policy.

------------------------------------------------------------------------

# 6. Permissions

The app may require:

-   Location while using the app.
-   Background/location permissions only when genuinely required by the
    selected implementation.
-   Notifications.
-   Camera/photo library if profile or delivery images are enabled.

Permission requests must explain why access is needed.

The application must handle denied permissions gracefully.

------------------------------------------------------------------------

# 7. Home Screen

The Home Screen should be extremely simple.

Primary content:

-   Map.
-   Current location.
-   Pickup field.
-   Destination field.
-   Service selection.

Primary service choices:

``` text
RIDE
Passenger transportation

DELIVERY
Send an item / parcel / document
```

The design must make these two services immediately understandable.

------------------------------------------------------------------------

# 8. Location Selection

## 8.1 Pickup

Customer can select Pickup using:

-   Current location.
-   Place/address search.
-   Manual pin selection on map.

Store:

``` text
pickup_lat
pickup_lng
pickup_address
```

## 8.2 Destination

Customer can select Destination using:

-   Place/address search.
-   Manual pin selection.

Store:

``` text
destination_lat
destination_lng
destination_address
```

## 8.3 Route Preview

After Pickup and Destination are selected, show:

-   Route on map.
-   Approximate distance.
-   Approximate duration.

These values are informational and do not create a mandatory fare.

------------------------------------------------------------------------

# 9. Service Selection

## 9.1 Ride

For a Passenger Ride, collect:

-   Pickup.
-   Destination.
-   Customer proposed price.
-   Optional notes.

## 9.2 Delivery

For Parcel Delivery, collect:

-   Pickup.
-   Destination.
-   Customer proposed price.
-   Optional item/parcel description.
-   Recipient name.
-   Recipient phone.
-   Optional notes.

Delivery MVP supports one sealed, motorcycle-safe parcel up to 8 kg and a
declared value up to 3,000 EGP. Cash/currency, high-value valuables,
illegal items, weapons, hazardous materials, live animals,
temperature-controlled medicines, and regulated/prohibited goods are not
accepted. Recipient data must be hidden until operationally required.

These parcel fields and enforcement are **PENDING IMPLEMENTATION**.

------------------------------------------------------------------------

# 10. Pricing & Customer Offer

The customer enters the amount they are willing to pay.

Example:

``` text
Customer Proposed Price: 80 EGP
```

This is not automatically the final price.

The system displays an informational **Suggested Price**, calculated from
configurable Base + Distance Component settings.

Example:

``` text
Suggested Price: 75 EGP
Your Offer:       80 EGP
```

The Suggested Price does not replace bidding or become a mandatory fare.

## 10.1 Validation

The app should validate:

-   Price is present.
-   Price is numeric.
-   Price is greater than zero.
-   Price is at least 70% of Suggested Price.
-   There is no business maximum; technical anti-abuse limits may apply.

Final validation must also occur on the backend.

Suggested Price and the 70% rule are **PENDING IMPLEMENTATION**.

------------------------------------------------------------------------

# 11. Order Confirmation

Before submitting, show an order summary.

Recommended information:

-   Service Type.
-   Pickup.
-   Destination.
-   Distance.
-   Estimated duration.
-   Customer proposed price.
-   Notes where applicable.

Primary action:

**Request Driver**

After confirmation, create the order.

------------------------------------------------------------------------

# 12. Bidding

Bidding is a mandatory core function.

After order submission:

``` text
Order Status = BIDDING
```

The system sends the request to eligible nearby drivers.

The bidding window is 90 seconds. Candidate discovery expands through 2,
4, 6, and 8 km approximately every 20 seconds using PostGIS/database
logic. This timing and progressive radius behavior are **PENDING
IMPLEMENTATION**; the current backend default remains 30 minutes until the
later migration replaces it.

The customer's proposed price cannot be edited after the order enters
`BIDDING`.

The customer enters the **Bidding Screen**.

------------------------------------------------------------------------

# 13. Bidding Screen

The screen should display:

-   Service Type.
-   Pickup/Destination summary.
-   Customer proposed price.
-   Searching state.
-   Number of offers received.
-   Incoming driver offers.
-   90-second bidding expiration/countdown.
-   Cancel Request action where permitted.

Offers must update in **Realtime** without manual refresh.

------------------------------------------------------------------------

# 14. Driver Offer Card

Each driver offer should display enough information for the customer to
make a decision.

Recommended fields:

-   Driver photo.
-   Driver first name.
-   Rating.
-   Completed trip count, when available.
-   Approximate distance from Pickup.
-   Approximate arrival time if available.
-   Motorcycle basic information.
-   Driver offered price.
-   Independent / Office identity.
-   Office name when applicable.
-   Whether the driver accepted the customer's exact price or submitted
    a counter-offer.

Example:

``` text
Ahmed
★ 4.8 | 520 trips
3 min away
Honda Motorcycle

Your price: 80 EGP
Driver offer: 90 EGP

[ Select Driver ]
```

Do not show the driver's phone before assignment. ETA appears when the Maps
milestone supports it. Office identity is shown when applicable.

------------------------------------------------------------------------

# 15. Offer Selection

The customer can select one driver offer.

When the customer presses **Select Driver**:

1.  Show confirmation if required.
2.  Send the selected `offer_id` to secure backend logic.
3.  Backend verifies:
    -   Order still exists.
    -   Order is still `BIDDING`.
    -   Offer is still active.
    -   Driver is still eligible.
4.  Backend atomically locks the order.
5.  Exactly one offer becomes selected.
6.  Exactly one driver becomes assigned.
7.  `agreed_price` is stored.
8.  Other offers close automatically.
9.  Order becomes:

``` text
DRIVER_ASSIGNED
```

The Flutter client must never be trusted to perform this operation by
itself.

------------------------------------------------------------------------

# 16. Assigned Driver Screen

After successful assignment, show:

-   Driver photo.
-   Driver name.
-   Driver rating.
-   Motorcycle information.
-   Agreed price.
-   Pickup.
-   Destination.
-   Driver live location.
-   Driver distance from Pickup.
-   Approximate ETA.
-   Current order status.
-   Contact action if enabled.
-   Cancel action if still permitted.

The customer should no longer see bidding actions.

------------------------------------------------------------------------

# 17. Live Driver Tracking

After assignment:

-   Display driver's marker on the map.
-   Update driver location in Realtime.
-   Show Pickup marker.
-   Show Destination marker.
-   Show route where appropriate.

Possible statuses:

``` text
DRIVER_ASSIGNED
DRIVER_ON_WAY
DRIVER_ARRIVED
IN_PROGRESS
COMPLETED
```

The interface should clearly explain the current state.

------------------------------------------------------------------------

# 18. Driver Arrival

When the driver marks arrival:

``` text
Status = DRIVER_ARRIVED
```

Customer should receive:

-   Realtime status update.
-   Push notification.

Example notification:

``` text
Your driver has arrived.
```

Ride requires no start OTP. After trusted Pickup arrival, the assigned Driver
starts the Ride directly.

------------------------------------------------------------------------

# 19. Active Ride

For Passenger Ride:

When the driver starts:

``` text
Status = IN_PROGRESS
```

Show:

-   Current status.
-   Driver.
-   Agreed price.
-   Route.
-   Current position where available.
-   Destination.

The customer cannot change the agreed price.

------------------------------------------------------------------------

# 20. Active Delivery

For Parcel Delivery:

After collection and start:

``` text
Status = IN_PROGRESS
```

Show:

-   Driver.
-   Pickup.
-   Destination.
-   Agreed price.
-   Live location.
-   Delivery status.

Delivery requires no sender Pickup OTP. The User App shows one final 4-digit
Customer Confirmation Code after assignment; the Customer provides it only
at final delivery. Delivery photo and signature are out of MVP.

------------------------------------------------------------------------

# 21. Completion

When the driver completes the service:

``` text
Status = COMPLETED
```

Display completion summary:

-   Service Type.
-   Driver.
-   Pickup.
-   Destination.
-   Agreed price.
-   Payment method.
-   Completion time.

MVP payment method:

``` text
CASH
```

------------------------------------------------------------------------

# 22. Rating

After completion, customer can rate the driver.

Required:

-   1 to 5 stars.

Optional:

-   Written comment.

Recommended data:

``` text
rating
comment
order_id
customer_id
driver_id
created_at
```

A customer should only rate a driver for a completed order belonging to
that customer.

Prevent duplicate ratings unless editing is intentionally supported.

------------------------------------------------------------------------

# 23. Order History

The customer can view previous orders.

Each history item should display:

-   Service Type.
-   Date/time.
-   Pickup.
-   Destination.
-   Driver.
-   Agreed price.
-   Status.

Useful filters may include:

``` text
All
Completed
Cancelled
Ride
Delivery
```

Advanced filtering is not required for the MVP.

------------------------------------------------------------------------

# 24. Order Details

For any accessible historical order, show:

-   Order ID/reference.
-   Service Type.
-   Created date/time.
-   Pickup.
-   Destination.
-   Customer proposed price.
-   Agreed price.
-   Driver.
-   Motorcycle.
-   Status.
-   Payment method.
-   Cancellation information if applicable.
-   Rating if completed and rated.

------------------------------------------------------------------------

# 25. Cancellation

Backend policy is authoritative:

-   `BIDDING`: free cancellation.
-   `DRIVER_ASSIGNED`: allowed with required reason.
-   `DRIVER_ON_WAY` and `DRIVER_ARRIVED`: allowed with required reason and
    recorded as `LATE_CANCEL`.
-   `IN_PROGRESS`: no direct customer cancellation; emergency handling is a
    trusted Support/Admin action.
-   No cancellation fee or debt/wallet logic in Cash MVP.
-   Three late cancellations within a rolling 7 days cause a 24-hour
    booking cooldown and support review.

The current backend supports only the existing pre-trip cancellation slice;
the reason, late-cancel, cooldown, and support-review rules are **PENDING
IMPLEMENTATION**.

Recommended cancellation data:

``` text
cancelled_by
cancellation_reason
cancelled_at
```

------------------------------------------------------------------------

# 26. Expired Requests

If no acceptable offer is selected before expiration:

``` text
Status = EXPIRED
```

Customer should see a clear message and actions such as:

-   Try Again.
-   Change Price.
-   Create New Request.

The exact retry model may be simplified in the MVP.

------------------------------------------------------------------------

# 27. Push Notifications

The User App should receive notifications for important events.

Required MVP events:

-   New driver offer.
-   Offer/driver successfully selected.
-   Driver on the way.
-   Driver arrived.
-   Trip started.
-   Trip completed.
-   Order cancelled.
-   Order expired.

Notification taps should deep-link to the relevant order when practical.

------------------------------------------------------------------------

# 28. Realtime Events

Supabase Realtime should be used where appropriate for:

-   New offers.
-   Offer updates.
-   Order status changes.
-   Driver assignment.
-   Driver location updates.

The app must correctly recover state after:

-   App minimization.
-   Reopening.
-   Temporary internet loss.
-   Realtime reconnect.

The database remains the source of truth.

------------------------------------------------------------------------

# 29. Core Order Data Required by User App

The User App requires access to customer-safe fields such as:

``` text
id
customer_id
service_type
pickup_lat
pickup_lng
pickup_address
destination_lat
destination_lng
destination_address
customer_offered_price
agreed_price
selected_offer_id
driver_id
office_id
motorcycle_id
status
payment_method
notes
created_at
bidding_expires_at
assigned_at
arrived_at
started_at
completed_at
cancelled_at
```

The API/view should expose only fields appropriate for the customer.

------------------------------------------------------------------------

# 30. Offer Data Required by User App

Customer-safe offer information may include:

``` text
offer_id
order_id
driver_id
amount
offer_status
created_at
driver_display_name
driver_photo
driver_rating
completed_trip_count
distance_to_pickup
estimated_arrival
motorcycle_summary
```

Do not expose private driver or office information unnecessarily.

------------------------------------------------------------------------

# 31. Security Requirements

Mandatory:

-   Supabase Auth.
-   Row Level Security.
-   Customer can read only their own orders.
-   Customer can read only offers related to their own eligible orders.
-   Customer cannot modify driver data.
-   Customer cannot manually assign a driver by writing directly to the
    order.
-   Customer cannot manually change `agreed_price`.
-   Customer cannot complete an order themselves unless the business
    explicitly permits it.
-   Sensitive actions use secure database/backend functions.
-   Supabase Service Role Key must never be included in the Flutter
    application.
-   Input validation must exist on both client and backend.

------------------------------------------------------------------------

# 32. Weak Network & Error Handling

The application must handle common failures cleanly.

Examples:

-   No internet.
-   GPS disabled.
-   Location permission denied.
-   Invalid OTP.
-   OTP expired.
-   Map failed to load.
-   Order creation failed.
-   Driver offer expired before selection.
-   Another operation changed the order before customer selection.
-   Driver became unavailable.
-   Realtime connection dropped.
-   Request expired.
-   Push notification delayed.

The user should receive understandable messages and safe retry options.

Never create duplicate orders because the customer tapped twice or
retried after a timeout.

------------------------------------------------------------------------

# 33. Loading & Interaction States

Every critical action must have a loading state.

Examples:

-   OTP verification.
-   Address search.
-   Route calculation.
-   Creating request.
-   Selecting offer.
-   Cancelling order.
-   Loading history.
-   Submitting rating.

Critical buttons should be temporarily disabled while an action is being
processed to prevent duplicate submissions.

------------------------------------------------------------------------

# 34. Suggested Navigation Structure

A simple bottom navigation can use:

``` text
Home
Orders
Profile
```

The active order should remain easy to access from anywhere in the
application.

If a customer has an active order, the app should prominently surface:

**View Active Order**

------------------------------------------------------------------------

# 35. Recommended Screen List

## Authentication

1.  Splash / App Initialization.
2.  Email/Password Sign In.
3.  Sign Up / Forgot Password.
4.  Complete Profile where needed.

## Main Booking Flow

5.  Home Map.
6.  Select Pickup.
7.  Select Destination.
8.  Select Service.
9.  Ride Details / Delivery Details.
10. Enter Proposed Price.
11. Order Review.
12. Bidding / Searching Drivers.
13. Driver Offers.
14. Offer Confirmation.
15. Assigned Driver / Driver Approaching.
16. Driver Arrived.
17. Active Ride / Delivery.
18. Completion Summary.
19. Driver Rating.

## Account & History

20. Orders / History.
21. Order Details.
22. Profile.
23. Edit Profile.
24. Basic Settings.

Several booking steps may be combined into fewer physical screens to
accelerate development.

------------------------------------------------------------------------

# 36. UX Priorities

The MVP should prioritize:

1.  Fast request creation.
2.  Minimal typing.
3.  Clear map interaction.
4.  Clear distinction between Ride and Delivery.
5.  Bidding that is understandable at first use.
6.  Easy comparison between driver offers.
7.  Clear agreed price.
8.  Clear current trip state.
9.  No confusing duplicate actions.
10. Strong recovery after connection interruptions.

------------------------------------------------------------------------

# 37. Arabic-First UI

The initial product should support Arabic as the primary interface.

Requirements:

-   RTL support.
-   Arabic-friendly typography.
-   Correct alignment of map overlays and controls.
-   Prices displayed clearly in EGP.
-   Phone number handling suitable for the launch market.

Architecture should allow English localization later without rebuilding
screens.

Use localization keys rather than hardcoding all UI strings directly in
widgets.

------------------------------------------------------------------------

# 38. Performance Requirements

The app should:

-   Open quickly on typical Android devices.
-   Avoid unnecessary Realtime subscriptions.
-   Unsubscribe from inactive order channels.
-   Avoid excessive location polling.
-   Cache safe non-sensitive UI data where useful.
-   Paginate history when necessary.
-   Compress uploaded images.
-   Avoid blocking UI while network operations run.

------------------------------------------------------------------------

# 39. Analytics Events Recommended

Basic product analytics should be designed around events such as:

``` text
signup_completed
service_selected
pickup_selected
destination_selected
order_created
bidding_started
offer_received
offer_selected
order_cancelled
driver_arrived
trip_started
trip_completed
rating_submitted
```

The analytics provider can be selected later if necessary.

------------------------------------------------------------------------

# 40. MVP Acceptance Criteria

The User App is accepted when the following work on an actual build.

## Authentication

-   New customer can register using email/password and receives only a
    `CUSTOMER` profile.
-   Existing customer can login.
-   Session persists appropriately.
-   Logout works.

## Maps

-   Customer can grant location access.
-   Current location is shown.
-   Customer can select Pickup.
-   Customer can select Destination.
-   Route information is displayed.

## Services

-   Customer can create a Passenger Ride.
-   Customer can create a Parcel Delivery.

## Pricing

-   Customer can enter a proposed price.
-   Suggested Price guidance is shown and the backend enforces the 70%
    minimum once that pending engine is implemented.

## Bidding

-   Submitted order enters bidding.
-   Multiple eligible driver offers can arrive.
-   Offers appear in Realtime without manual refresh.
-   Customer can compare driver and price information.
-   Customer can select one active offer.
-   Expired/closed offer cannot be selected.
-   Exactly one driver can be assigned.

## Assigned Driver

-   Customer sees assigned driver information.
-   Customer sees agreed price.
-   Customer sees live driver location.
-   Status updates correctly when driver is on the way and arrives.

## Active Trip

-   Customer sees trip start.
-   Customer sees active order information.
-   Agreed price cannot be edited.

## Completion

-   Completed order shows correct summary.
-   Customer can rate driver.
-   Completed order appears in history.

## Security

-   Customer cannot access another customer's orders.
-   Customer cannot access unrelated offers.
-   Customer cannot manually change assignment or agreed price through
    direct API/database calls.

## Reliability

-   Reopening the app restores the active order.
-   Temporary connection loss does not create a duplicate order.
-   Failed offer selection returns a clear error and refreshes current
    order state.

------------------------------------------------------------------------

# 41. Explicitly Out of User App MVP Unless Approved

The following should not delay the first release:

-   Full Wallet.
-   Credit/debit card payments.
-   Promo codes.
-   Loyalty program.
-   Referral system.
-   Subscription plans.
-   Advanced in-app chat.
-   Multi-stop booking.
-   Scheduled booking.
-   Favorite drivers.
-   Corporate booking.
-   Advanced fare calculator replacing bidding.
-   Call masking.
-   Advanced support center.
-   AI recommendations.

The architecture should allow these later without including them in the
first build.

------------------------------------------------------------------------

# 42. Frozen Business Decisions Affecting the User App

Business Rules Freeze v1.0 resolves the prior open questions: Suggested
Price guidance with a 70% minimum, immutable customer proposal after
`BIDDING`, a 90-second progressive-radius bidding window, manual driver
selection, defined pre-selection privacy, frozen cancellation rules,
no Ride or Pickup OTP and one final Delivery Confirmation Code,
post-assignment calling, no MVP chat or
masking, and an East Cairo pilot. See `BUSINESS_RULES_FREEZE_V1.md`.

Items not present in the current mobile/backend implementation remain
**PENDING IMPLEMENTATION** and are not acceptance evidence.

------------------------------------------------------------------------

# 43. Definition of Done for the User App

A User App feature is considered Done only when:

-   Flutter UI is complete.
-   Backend integration is complete.
-   Authorization and RLS are enforced.
-   Loading states are implemented.
-   Error states are implemented.
-   Realtime behavior works where required.
-   Push notification behavior works where required.
-   The feature survives app close/reopen when relevant.
-   Critical flow is tested on a real Android build.

------------------------------------------------------------------------

# 44. User App Delivery Package

The development handover should include:

-   Flutter source code.
-   Organized repository.
-   Environment configuration documentation.
-   No production secrets committed to source.
-   Android installable build.
-   Production/release build instructions.
-   README.
-   Demo customer account or test authentication procedure.
-   List of known limitations/bugs.
-   Required Google Maps configuration instructions.
-   Required Firebase/FCM configuration instructions.
-   Supabase integration configuration notes.

------------------------------------------------------------------------

# Appendix A - Main User Journey

``` text
HOME
 |
 +--> RIDE
 |      |
 |      +--> Pickup
 |      +--> Destination
 |      +--> Proposed Price
 |      +--> Bidding
 |      +--> Select Driver
 |      +--> Track Driver
 |      +--> Ride
 |      +--> Complete
 |      +--> Rate
 |
 +--> DELIVERY
        |
        +--> Pickup
        +--> Destination
        +--> Item Details
        +--> Proposed Price
        +--> Bidding
        +--> Select Driver
        +--> Track Driver
        +--> Delivery
        +--> Complete
        +--> Rate
```

------------------------------------------------------------------------

# Appendix B - Bidding Journey

``` text
Customer Offer: 80 EGP
        |
        v
Order = BIDDING
        |
        +------------------------------+
        |              |               |
        v              v               v
Driver A          Driver B         Driver C
Accepts 80        Offers 90        Offers 75
        |              |               |
        +--------------+---------------+
                       |
                       v
              Customer Offer List
                       |
                       v
              Customer selects one
                       |
                       v
                Atomic Backend Lock
                       |
                       v
               agreed_price saved
                       |
                       v
              One Driver Assigned
```

------------------------------------------------------------------------

# Appendix C - User App MVP Checklist

  Feature                         Required
  ------------------------------- ----------
  Email/Password Authentication   Yes
  Customer Profile                Yes
  Current Location                Yes
  Pickup Selection                Yes
  Destination Selection           Yes
  Google Maps                     Yes
  Passenger Ride                  Yes
  Parcel Delivery                 Yes
  Customer Proposed Price         Yes
  Driver Counter-Offers           Yes
  Realtime Bidding                Yes
  Driver Comparison               Yes
  Offer Selection                 Yes
  Atomic Assignment               Yes
  Assigned Driver Details         Yes
  Live Driver Tracking            Yes
  Push Notifications              Yes
  Trip Status Tracking            Yes
  Cash Payment                    Yes
  Rating                          Yes
  Order History                   Yes
  Cancellation                    Yes
  RLS / Customer Data Isolation   Yes
  Wallet                          Later
  Online Payment                  Later
  Promo Codes                     Later
  Multi-stop                      Later
  Scheduled Orders                Later
  Advanced Chat                   Later

------------------------------------------------------------------------

**End of User Mobile Application Requirements Specification**
