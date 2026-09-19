# Business Rules Freeze v1.0

**Status:** APPROVED / FROZEN  
**Adopted:** 2026-08-30

This document is the canonical source for MVP business behavior. It freezes product rules; it does not prove implementation. When this document conflicts with an older specification, this document wins. Implementation status is stated separately below.

## 1. Product and Pricing

- The product develops both `RIDE` and `DELIVERY` from the beginning.
- Bidding is the core pricing model: the customer proposes a price, drivers compete with offers, and the customer manually chooses the driver. There is no automatic assignment.
- Suggested Price is guidance, not a mandatory fare, and uses configurable `Base + Distance Component` values.
- The minimum customer proposal is 70% of Suggested Price. There is no business maximum; technical anti-abuse limits may apply.
- The customer proposal becomes immutable once the persisted order enters `BIDDING`.

## 2. Bidding and Dispatch

- Bidding lasts 90 seconds.
- Candidate radius expands `2 km -> 4 km -> 6 km -> 8 km`, approximately every 20 seconds.
- Nearby-driver discovery uses PostGIS/database logic, not paid routing APIs.
- An offer expires with its order's bidding window.
- A driver may have one `ACTIVE` offer per order.
- An active offer cannot be edited. While the order is `BIDDING` and the offer is unselected, the driver may withdraw it and then submit a new offer.
- The customer chooses the winning driver.

## 3. Pre-selection Privacy

Before selection, the customer may see the driver's photo, first name, rating, completed-trip count, offered price, Independent/Office type, office name when applicable, and ETA when the Maps milestone supports it. The driver's phone is hidden before assignment.

Before assignment, the driver must not see the customer's full name or phone. A Call button is allowed after assignment. Call masking and in-app chat are out of MVP.

## 4. Driver and Office Model

- A driver is either `INDEPENDENT` or `OFFICE_DRIVER`.
- An Office Driver belongs to at most one office in MVP. Multi-office membership is prohibited.
- An office change requires a trusted Change Request approved by Platform Admin. Historical orders retain their original office snapshot.
- Office Admin may create/invite a driver, review data, assist with documents, and submit the application for verification.
- Office Admin cannot perform final approval. Only trusted Platform verification roles may execute `PENDING -> ACTIVE`, `PENDING -> REJECTED`, or `ACTIVE -> SUSPENDED`.

## 5. Driver and Motorcycle Documents

Required driver documents are National ID, valid driving licence, and driver/profile selfie. Minimum driver age is 21.

A criminal record is required before public launch, subject to legal/regulatory confirmation.

Motorcycle documents use a separate `motorcycle_documents` concept/table. Expected evidence includes motorcycle registration/licence, ownership/authorization when not driver-owned, motorcycle photos, and insurance/inspection where legally or operationally required.

Document expiry behavior:

- 30 days: warning.
- 7 days: strong warning.
- 1 day: critical warning.
- At expiry, the driver receives no new requests; an already-active trip may finish.
- A replacement document remains `PENDING` review until approved. Operational eligibility returns only after approval.

## 6. Online Eligibility and Safety

Backend logic may allow Online only when the driver is `ACTIVE`, the motorcycle is valid/operational, required documents are approved and unexpired, and the driver has no active order. Flutter is not the security authority. One driver may hold only one active job in MVP.

`RIDE` supports one passenger. Driver and passenger helmets are mandatory, and the driver must carry an extra passenger helmet to be eligible for Ride requests.

## 7. Geofence and Service Verification

Geofence enforcement is server-side and uses trusted PostGIS location data:

- Arrived requires the driver to be within 200 meters of Pickup.
- Complete requires the driver to be within 300 meters of Destination.
- GPS failure allows Retry.
- An exception requires an explicit trusted Admin/Support action, mandatory reason, and audit log.

Ride has no OTP. After a trusted 200m Pickup arrival, the Driver starts the
Ride directly. Delivery has no Pickup OTP. After a trusted 200m Pickup
arrival, the Driver starts the Delivery directly. Delivery completion requires
one final 4-digit Confirmation Code from the Customer plus the trusted 300m
Destination geofence. A delivery photo and signature are out of MVP.

## 8. Delivery Parcel Rules

- One parcel only, maximum 8 kg, maximum declared value 3,000 EGP.
- The parcel must be sealed and safely transportable on a motorcycle.
- Prohibited examples: cash/currency, high-value valuables, illegal items, weapons, hazardous materials, live animals, temperature-controlled medicines, and regulated/prohibited goods.
- Delivery orders support `recipient_name` and `recipient_phone`; recipient data is exposed only when operationally required.

## 9. Cancellation

Customer cancellation:

- `BIDDING`: allowed and free.
- `DRIVER_ASSIGNED`: allowed; reason required.
- `DRIVER_ON_WAY` or `DRIVER_ARRIVED`: allowed; reason required and recorded as `LATE_CANCEL`.
- `IN_PROGRESS`: no direct customer cancellation; emergencies use trusted Support/Admin action.
- Cash MVP has no cancellation fee and no cancellation debt/wallet logic.
- Three late cancellations in a rolling 7 days create a 24-hour booking cooldown and support review.

Driver cancellation:

- Allowed before `IN_PROGRESS`; reason is mandatory.
- A post-assignment driver cancellation makes the order `CANCELLED`; the same order does not return to bidding.
- The customer receives Book Again with pickup, destination, and proposed price prefilled.
- Three post-assignment driver cancellations in a rolling 7 days flag the account for operations review; this counter alone does not auto-suspend the driver.

## 10. Commission, Earnings, and Payments

- Independent Driver: Platform commission is 10% of `agreed_price`; `Gross Fare - Platform Commission = Net Earnings`.
- Office Driver: Platform commission is 7% of `agreed_price`, between Platform and Office. The office controls internal driver compensation/payroll.
- Launch promotion: Independent first 14 days 0%, then 10%; Office first month 5%, then 7%. These values are configurable business settings, not client constants.
- Cash commission collection uses a limited Commission Ledger with `commission_due` and `platform_balance`, not a full wallet.
- Independent drivers must meet a configurable platform-credit threshold to receive new jobs; initial top-up may use an approved/manual transfer workflow.
- Offices settle/invoice weekly.
- Independent earnings show gross fare, platform commission, and net earnings. Office Driver earnings show gross completed-trip value only.
- MVP is `CASH ONLY`: no customer card payments, customer wallet, driver withdrawal/cash-out, or debt engine.

## 11. Authentication

- User App: Email + Password.
- Driver App: Email + Password.
- Dashboard staff/admin: Email + Password.
- Phone/SMS authentication is out of MVP and must not be reintroduced without a later explicit decision.
- Privileged admin accounts may require MFA before public launch.

The final Delivery Confirmation Code is an operational completion control and does not change this authentication decision.

## 12. Office Permissions

- Office Admin: drivers, motorcycles, office staff, office orders, office reports.
- Office Dispatcher: orders, drivers, live operations.
- Office Accountant: finance, reports.
- All office roles remain restricted to their office. Existing database RLS remains authoritative.

## 13. Order Technical Rules

- `DRAFT` is client-side only; a persisted order starts as `BIDDING`.
- Trusted acceptance is `accept_offer(order_id, offer_id)`; customer identity comes from `auth.uid()`, never a client-supplied `customer_id`.
- `selected_offer_id` is the official FK to `offers.id`.
- `agreed_price` is immutable after `DRIVER_ASSIGNED`.
- Driver assignment is immutable after `IN_PROGRESS` except controlled recovery.

`order_events` is required for meaningful lifecycle transitions, cancellation, expiry, and trusted admin recovery. It supports operations, disputes, debugging, and the dashboard timeline.

Sensitive administration uses explicit trusted operations such as `admin_cancel_order`, `admin_suspend_driver`, `admin_restore_driver`, and `admin_correct_order_data`; there is no generic arbitrary status editor. Each sensitive action records actor, reason, timestamp, before values, after values, and an audit entry.

## 14. Market Launch

- Initial pilot: East Cairo, targeting Nasr City, Heliopolis, and New Cairo; expansion is zone-by-zone and operating zones ultimately become Dashboard-configurable.
- Development includes both `RIDE` and `DELIVERY`.
- Public rollout soft-launches Delivery first, then enables Ride after operations, safety, legal, and licensing gates pass.
- Regulatory approval is a launch gate, not a development gate.

## 15. Out of MVP

Full wallet, customer card payments, chat, call masking, subscriptions, promotions engine, loyalty, multi-stop, scheduled orders, AI dispatch, advanced settlement, advanced payroll, advanced BI, and multiple active driver jobs.

## 16. Current Implementation Status (2026-08-30)

This snapshot prevents frozen requirements from being mistaken for completed implementation.

**Implemented/verified current base:** Email/password authentication; `RIDE` and `DELIVERY` service types; CUSTOMER-only public signup; Independent/Office Driver identity foundation; one driver identity per profile; core order/offer tables; server-owned 90-second bidding expiry; immutable customer proposal after `BIDDING`; one active offer per driver/order; multiple cross-order Driver offers until assignment; offer withdrawal and replacement while eligible; one-active-job protection; assignment closes competing offers for the order and the winning Driver; customer-owned atomic `accept_offer(order_id, offer_id)` using `auth.uid()`; selected-offer/assignment integrity; privacy-safe Driver request and customer offer projections; Ride/Delivery creation including recipient and parcel limits; frozen customer/Driver cancellation boundaries; creation-intent recovery; bounded mutation recovery; authoritative waiting-offer state; transactionally maintained `completed_trip_count`; lifecycle `order_events`; core state transitions and RLS; Cash as the current MVP payment method.

**Milestone 10 implementation:** Driver/motorcycle verification, private document Storage, expiry eligibility, helmet acknowledgement, trusted 200m/300m PostGIS geofences, the single final Delivery Confirmation Code, and audited safety override are implemented and hosted-verified. Verification review remains a trusted backend operation; an operations/Admin UI and an external daily scheduler still need deployment/configuration before public launch. Motorcycle document categories beyond the generic supported set remain subject to legal/operational confirmation.

**Partially implemented:** The remaining public-launch dependencies are the operations/Admin UI, external daily expiry invocation, and legal confirmation noted above.

**Pending implementation:** Suggested Price and 70% minimum; progressive PostGIS radius dispatch; broader call/privacy timing; trusted office-change requests and historical snapshots; criminal-record launch gate; operations/Admin review UI and daily scheduler deployment; cancellation cooldowns/abuse flags and User App Book Again UI; commissions, promotions, ledger, credit thresholds, earnings splits, and settlement; configurable pilot zones.

Do not mark a pending item complete until its code/database behavior is implemented and verified.
