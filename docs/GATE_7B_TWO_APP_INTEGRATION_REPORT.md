# Gate 7B — User + Driver Core End-to-End Integration

Date: 2026-08-30  
Target: hosted Supabase Development project `biko-development`  
Decision: **PASS**  
Hosted baseline: `20260830151837_user_app_core_bridge`

Gate 7B verified the current manual-refresh core only. Maps, Realtime, password-recovery email callback, and physical-device execution were outside this gate.

## Scenario Evidence

| Scenario | Evidence level | Result | Evidence / issue |
|---|---|---:|---|
| Ride create and Driver discovery | HOSTED BACKEND + SERVICE CONTRACT | PASS | Stable intent recovered one logical BIDDING order with a server-owned ~90-second deadline. Candidate Driver saw the compact request and submitted through current RPCs. |
| Multiple offers | HOSTED BACKEND + FLUTTER WIDGET | PASS | Two public Driver identities/prices/counts reached the Customer; selected offer became `SELECTED`, loser became `CLOSED`, and losing refresh had no action. |
| Withdraw and resubmit | HOSTED BACKEND | PASS | Other Driver withdrawal was denied; owner withdrawal became non-actionable; replacement used a new ID with one ACTIVE offer. |
| Cross-order offer closure | HOSTED BACKEND | PASS | Driver held two ACTIVE offers before assignment. Selecting Order A closed the Driver's Order B offer while Order B stayed unassigned `BIDDING`. |
| Selection and assignment | HOSTED BACKEND | PASS | Driver, selected offer, agreed price, assignment status, offline availability, and exactly one assignment event agreed. A second active job/new offer was denied. |
| Driver lifecycle to Customer | HOSTED BACKEND + FLUTTER WIDGET/ROUTER | PASS | `ASSIGNED → ON_WAY → ARRIVED → IN_PROGRESS → COMPLETED` was observed through authoritative Customer and Driver reads after every transition; assignment/price stayed intact and completion count incremented once. |
| Customer cancellation | HOSTED BACKEND + FLUTTER WIDGET | PASS | BIDDING no-reason, assigned required-reason, ON_WAY/ARRIVED `LATE_CANCEL`, and IN_PROGRESS denial propagated to Driver reads without rebid. |
| Driver cancellation | HOSTED BACKEND | PASS | Assigned Driver cancellation persisted terminal `CANCELLED` with `DRIVER_CANCEL` event metadata; Customer refresh observed it. |
| Expiry | HOSTED BACKEND + FLUTTER WIDGET | PASS | Customer reconciliation used elapsed server deadline, persisted `EXPIRED`, closed the offer, and removed Driver actionability. |
| Delivery core | HOSTED BACKEND | PASS | Delivery retained recipient/parcel data for its Customer, used the same offer/assignment/lifecycle engine, completed successfully, and did not leak private details to candidate Driver or Customer B. |
| Book Again | HOSTED BACKEND + FLUTTER WIDGET | PASS | Terminal source stayed unchanged; deliberate resubmit used a new creation intent and created a new order with reusable route/price. Delivery owner retained reusable parcel data. |
| Customer restoration | FLUTTER WIDGET/ROUTER + HOSTED BACKEND | PASS | Customer bootstrap restored BIDDING, ASSIGNED, ON_WAY, ARRIVED, and IN_PROGRESS states from authoritative order truth. |
| Driver restoration | FLUTTER WIDGET/ROUTER + HOSTED BACKEND | PASS | Driver bootstrap restored ASSIGNED, ON_WAY, ARRIVED, and IN_PROGRESS independently of optional request/offer feeds. |
| Ownership and privacy | HOSTED BACKEND | PASS | Customer B could not read/cancel/accept Customer A data; Driver B could not mutate Driver A trip/offer; compact projections excluded phones, private profiles, and Delivery fields. |
| User uncertain mutation | FLUTTER WIDGET + SERVICE CONTRACT | PASS | One lost/uncertain creation response reconciled the retained intent through bounded reads with one write and no blind replay. |
| Driver uncertain mutation | FLUTTER WIDGET + SERVICE CONTRACT | PASS | One lost lifecycle response reconciled to `DRIVER_ON_WAY`; the previous CTA disappeared and no write replay occurred. |
| Stale offer | HOSTED BACKEND | PASS | Driver became ineligible after offer refresh; selection failed safely, order remained unassigned `BIDDING`, and authoritative offer refresh removed it. |
| History consistency | HOSTED BACKEND + SERVICE CONTRACT | PASS | Customer and Driver terminal reads agreed on owned service, route, status, price, and date; Customer B saw none of Customer A history. |

## Targeted Tests

- `supabase/tests/gate_7b_two_app_integration.sql`: PASS once against hosted Development inside one transaction, followed by rollback.
- User App: 9 targeted widget checks passed.
- Driver App: 11 targeted router/state checks passed.
- App Core: 2 targeted mutation-recovery/shared-presentation checks passed.
- Previously verified unaffected contracts were not rerun. No Flutter analyze ran because no production Flutter code changed.

## Changes and Cleanup

- Production code changes: **None**.
- Backend changes/migrations: **None**.
- Test-only changes: Gate 7B hosted SQL harness and expanded Customer/Driver restoration coverage.
- Cleanup: zero reserved Auth users, profiles, Drivers, candidates, orders, offers, Delivery details, `order_events`, offices, and memberships remained.
- Device evidence: **NOT TESTED ON DEVICE**. This gate accepted hosted/service/widget/router evidence.

## Decision

- New P0: None.
- New P1: None.
- Non-blocking Gate 7B issues: None.
- Gate 7B: **PASS**.
- Milestone 8: **UNBLOCKED**.
