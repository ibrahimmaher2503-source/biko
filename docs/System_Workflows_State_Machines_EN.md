# System Workflows & State Machines
## Motorcycle Mobility & Delivery Platform

**Version:** 1.0  
**Date:** August 28, 2026

---

## Current Workflow Snapshot — 2026-08-30

Development implements the 90-second bidding boundary, immutable customer
proposal, offer withdrawal/replacement, multiple cross-order Driver offers
until assignment, one active job per Driver, and atomic closure of other ACTIVE
offers for the selected order or winning Driver. Customer/Driver cancellation
uses the frozen state/reason boundary and writes `order_events`. Creation and
uncertain mutations use stable intent/bounded recovery, and waiting-offer UI is
derived from authoritative order status/expiry. Progressive dispatch,
Realtime, Maps/geofences, and Milestone 10 safety controls are implemented
with external configuration pending. Ride and Delivery Pickup use no OTP;
Delivery completion uses one final Customer Confirmation Code.

---

# 1. Purpose

Define the authoritative operational workflows shared by:

- User App.
- Driver App.
- Unified Dashboard.
- Backend.

All applications must follow the same state rules.

---

# 2. Main Order State Machine

```text
DRAFT
  |
  v
BIDDING
  |
  +-----------------------> EXPIRED
  |
  +-----------------------> CANCELLED
  |
  v
DRIVER_ASSIGNED
  |
  +-----------------------> CANCELLED
  |
  v
DRIVER_ON_WAY
  |
  +-----------------------> CANCELLED
  |
  v
DRIVER_ARRIVED
  |
  +-----------------------> CANCELLED
  |
  v
IN_PROGRESS
  |
  v
COMPLETED
```

---

# 3. Valid Transitions

Recommended allowed transitions:

```text
DRAFT -> BIDDING

BIDDING -> DRIVER_ASSIGNED
BIDDING -> CANCELLED
BIDDING -> EXPIRED

DRIVER_ASSIGNED -> DRIVER_ON_WAY
DRIVER_ASSIGNED -> CANCELLED

DRIVER_ON_WAY -> DRIVER_ARRIVED
DRIVER_ON_WAY -> CANCELLED

DRIVER_ARRIVED -> IN_PROGRESS
DRIVER_ARRIVED -> CANCELLED

IN_PROGRESS -> COMPLETED
```

Any other transition must fail unless explicitly authorized by a special admin recovery process.

Every persisted order creation/status transition, cancellation, or expiry
appends an `order_events` record. This event history is **IMPLEMENTED**.
Recovery uses explicit trusted actions with actor, reason,
timestamp, before/after values, and audit log—never an arbitrary status
editor; those admin recovery actions remain pending.

---

# 4. Customer Ride Workflow

```text
Customer Login
  ↓
Select RIDE
  ↓
Pickup
  ↓
Destination
  ↓
Enter Proposed Price
  ↓
Review Request
  ↓
Create Order
  ↓
BIDDING
  ↓
Receive Driver Offers
  ↓
Select One Offer
  ↓
DRIVER_ASSIGNED
  ↓
Track Driver
  ↓
DRIVER_ON_WAY
  ↓
DRIVER_ARRIVED
  ↓
IN_PROGRESS
  ↓
COMPLETED
  ↓
Rate Driver
```

---

# 5. Parcel Delivery Workflow

```text
Customer Login
  ↓
Select DELIVERY
  ↓
Pickup
  ↓
Destination
  ↓
Item Description / Notes
  ↓
Enter Proposed Price
  ↓
Create Order
  ↓
BIDDING
  ↓
Receive Offers
  ↓
Select Driver
  ↓
DRIVER_ASSIGNED
  ↓
Driver Goes to Pickup
  ↓
DRIVER_ARRIVED
  ↓
IN_PROGRESS
  ↓
Deliver Item
  ↓
Recipient provides final Delivery Confirmation Code
  ↓
COMPLETED
  ↓
Rate Driver
```

Required and optional proof:

```text
Pickup OTP                 NOT USED
Delivery Confirmation Code REQUIRED
Delivery Photo             OUT OF MVP
Signature                  OUT OF MVP
```

Milestone 10 implements this completion contract with trusted geofences.

---

# 6. Bidding Workflow

```text
Customer Proposed Price
        |
        v
Order = BIDDING
        |
        v
Eligible Drivers Receive Request
        |
   +----+--------------------+
   |                         |
   v                         v
Accept Price           Counter Offer
   |                         |
   +------------+------------+
                |
                v
          Offer = ACTIVE
                |
                v
       Customer Offer List
                |
        +-------+--------+
        |                |
        v                v
No Selection        Select Offer
        |                |
        |                v
        |         Atomic Acceptance
        |                |
        |                v
        |        DRIVER_ASSIGNED
        |
        +--> Expiration -> EXPIRED
```

The bidding window is 90 seconds. PostGIS candidate search expands 2, 4, 6,
then 8 km approximately every 20 seconds. The customer proposal is immutable
after entering `BIDDING`, and the customer manually chooses the winner. The
server-owned 90-second timeout is **IMPLEMENTED**. Progressive PostGIS
dispatch remains **PENDING IMPLEMENTATION**.

---

# 7. Offer State Machine

```text
ACTIVE
  |
  +--> SELECTED
  |
  +--> REJECTED
  |
  +--> WITHDRAWN
  |
  +--> EXPIRED
  |
  +--> CLOSED
```

An active offer cannot be edited. While unselected and the order remains
`BIDDING`, it may be withdrawn; the driver may then submit a new offer. Offer
expiry matches order expiry. Withdrawal/new-offer behavior is **IMPLEMENTED**.

When one offer is selected:

```text
Winning Offer -> SELECTED
Other ACTIVE offers for that order or the winning Driver -> CLOSED
```

---

# 8. Driver Operational State

Recommended conceptual state:

```text
OFFLINE
  |
  v
ONLINE_AVAILABLE
  |
  +--> OFFER_PENDING
  |       |
  |       +--> ONLINE_AVAILABLE (not selected)
  |       |
  |       +--> ASSIGNED
  |
  v
ASSIGNED
  |
  v
ON_WAY
  |
  v
ARRIVED
  |
  v
IN_PROGRESS
  |
  v
ONLINE_AVAILABLE or OFFLINE
```

The implementation may derive this from driver and order state.

---

# 9. Driver Approval Workflow

```text
Driver Registers
  ↓
Profile
  ↓
Motorcycle
  ↓
Documents
  ↓
PENDING
  ↓
Admin Review
  |
  +--> APPROVE -> ACTIVE
  |
  +--> REJECT -> REJECTED
```

Existing Active driver may later become:

```text
ACTIVE -> SUSPENDED
SUSPENDED -> ACTIVE
```

These transitions require trusted Platform verification roles. Office Admin
may prepare and submit the application but cannot perform final approval.

---

# 10. Office Driver Workflow

```text
Office
  ↓
Creates/Invites Driver and Assists Documents
  ↓
Driver linked to office_id
  ↓
Submit for Platform Verification
  ↓
Trusted Platform Role Approves
  ↓
ACTIVE
  ↓
Driver uses same Driver App
  ↓
Orders and performance scoped to Office
```

No separate Office Driver app.

An Office Driver belongs to one office maximum. Office Admin cannot perform
final approval. Office changes require a trusted request approved by Platform
Admin, and historical orders keep their original office snapshot. The change
request/snapshot workflow is **PENDING IMPLEMENTATION**.

---

# 11. Customer Cancellation Workflow

## During Bidding

```text
BIDDING
  ↓
Customer Cancel
  ↓
Backend Validates
  ↓
CANCELLED
  ↓
Close Offers
  ↓
Notify Drivers
```

This cancellation is free.

## After Assignment

```text
DRIVER_ASSIGNED + reason -> CANCELLED
DRIVER_ON_WAY + reason   -> CANCELLED + LATE_CANCEL
DRIVER_ARRIVED + reason  -> CANCELLED + LATE_CANCEL
IN_PROGRESS              -> direct customer cancellation rejected
```

Three late cancellations within a rolling 7 days cause a 24-hour booking
cooldown and support review. Cash MVP has no cancellation fee or debt/wallet
logic. The late-cancel/cooldown behavior is **PENDING IMPLEMENTATION**.

---

# 12. Driver Cancellation Workflow

```text
Assigned Driver before IN_PROGRESS
  ↓
Requests Cancel
  ↓
Reason Required
  ↓
Backend Validates
  |
  +--> Allowed -> CANCELLED
  |
  +--> Not Allowed -> Reject
```

The same order does not return to `BIDDING`. The customer receives Book Again
with pickup, destination, and proposed price prefilled. Three post-assignment
driver cancellations within a rolling 7 days flag the account for operations
review without automatic suspension. These behaviors are **PENDING
IMPLEMENTATION**.

---

# 13. Order Expiration Workflow

```text
Order = BIDDING
  ↓
bidding_expires_at reached
  ↓
No winning offer
  ↓
EXPIRED
  ↓
Close all active offers
  ↓
Notify customer
```

---

# 14. Reconnect Recovery Workflow

For User App or Driver App:

```text
App reconnects
  ↓
Fetch active order from database
  ↓
Fetch authoritative status
  ↓
Restore correct screen
  ↓
Subscribe to current Realtime channels
```

Never rely only on locally cached state.

---

# 15. Push + Realtime Workflow

Example: Driver Arrived

```text
Driver presses Arrived
  ↓
Backend validates transition
  ↓
orders.status = DRIVER_ARRIVED
  ↓
Realtime update to User App
  ↓
Push Notification to Customer
```

Realtime is for immediate UI sync.

Push is for background/attention.

---

# 16. Atomic Offer Selection Workflow

```text
Customer selects offer
  ↓
accept_offer(order_id, offer_id)
  ↓
BEGIN TRANSACTION
  ↓
Lock order
  ↓
Verify BIDDING
  ↓
Verify offer ACTIVE
  ↓
Assign driver
  ↓
Set agreed_price
  ↓
Set selected_offer_id
  ↓
Set DRIVER_ASSIGNED
  ↓
Close other offers
  ↓
COMMIT
```

If any validation fails:

```text
ROLLBACK
```

---

# 17. Permissions Workflow for Office Dashboard

```text
Office User Login
  ↓
Resolve Office Membership
  ↓
Resolve Role
  ↓
Resolve Permissions
  ↓
Resolve office_id scope
  ↓
UI Shows Allowed Modules
  ↓
Backend/RLS Restricts Data
```

Even if a URL is manually entered, RLS must reject unauthorized records.

---

# 18. Completion Workflow

```text
Driver presses Complete
  ↓
Backend verifies:
- assigned driver
- IN_PROGRESS
- completion allowed
- within 300 meters of Destination, once Maps/geofence is implemented
  ↓
Set COMPLETED
  ↓
Save completed_at
  ↓
Finalize financial snapshot
  ↓
Notify Customer
  ↓
Update Driver history
  ↓
Update Customer history
  ↓
Enable Rating
```

Arrival similarly requires 200-meter Pickup proximity. GPS failure allows
Retry; exceptions require explicit trusted Admin/Support override, mandatory
reason, and audit log. Geofence checks are a **FUTURE MILESTONE**.

---

# 19. Rating Workflow

```text
COMPLETED Order
  ↓
Customer submits 1-5 stars
  ↓
Backend verifies customer ownership
  ↓
Ensure one rating per order
  ↓
Save rating
  ↓
Update driver aggregate rating
```

---

# 20. Invalid Flow Examples

Must be rejected:

```text
BIDDING -> IN_PROGRESS
DRIVER_ASSIGNED -> COMPLETED
DRIVER_ON_WAY -> COMPLETED
COMPLETED -> BIDDING
CANCELLED -> IN_PROGRESS
EXPIRED -> DRIVER_ASSIGNED
```

---

# 21. Acceptance Criteria

Workflow implementation is accepted when:

- All valid transitions work.
- Invalid transitions fail at backend.
- User App, Driver App, and Dashboard show the same order state.
- Reconnect restores correct state.
- Double assignment is impossible.
- Expiration closes active offers.
- Cancellation records actor and reason.
- Completion happens once.
- Rating can only occur for a completed owned order.

---

**End of System Workflows & State Machines**
