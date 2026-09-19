# Implementation Decisions

## DEC-001 — Authentication without OTP for the current scope

- Date: 2026-08-29
- Status: Accepted
- Decision: Do not implement phone OTP now. Keep Supabase SMS authentication disabled and use email/password for the first authentication slice.
- Reason: Explicit product-owner instruction during implementation.
- Consequence: Phone remains an optional profile field. OTP can be reconsidered only when explicitly requested.

## DEC-002 — Auth sign-up cannot grant elevated identity

- Date: 2026-08-29
- Status: Accepted
- Decision: Every direct Supabase Auth sign-up creates a `CUSTOMER` profile. Driver and staff promotion must use trusted backend/admin logic.
- Reason: User metadata is not a safe authorization source.

## DEC-003 — Financial rules remain unset

- Date: 2026-08-29
- Status: Superseded by DEC-004
- Decision: Financial rules were previously unset.
- Reason: Business Rules Freeze v1.0 now defines the MVP commission and settlement direction.

## DEC-004 — Business Rules Freeze v1.0

- Date: 2026-08-30
- Status: APPROVED / FROZEN
- Canonical reference: `docs/BUSINESS_RULES_FREEZE_V1.md`
- Decision: Freeze the MVP service, bidding, privacy, driver/office, document, eligibility, verification, parcel, cancellation, commission, Cash payment, office permission, order lifecycle, admin recovery, and launch rules defined in the canonical reference.
- Authentication remains Email + Password for User App, Driver App, and Dashboard. Phone/SMS authentication is out of MVP; trip verification OTPs are not login OTPs.
- Implementation status remains separate from business approval. Rules marked planned or pending in the canonical reference are not complete.

Do not invent new MVP business rules during implementation. If an implementation requirement conflicts with `BUSINESS_RULES_FREEZE_V1.md`, stop and report the conflict.

## DEC-005 — Single Delivery Confirmation Code

- Date: 2026-08-30
- Status: APPROVED / FROZEN
- Decision: Ride uses no start OTP. Delivery uses no Pickup OTP. Delivery completion uses one final 4-digit Customer Confirmation Code together with the trusted Destination geofence.
- Authentication remains Email + Password; Phone/SMS authentication remains out of MVP.
- This decision supersedes older requirements that called for Ride Start, Delivery Pickup, or multiple Delivery OTPs.

## DEC-006 — Commission promotion anchor and legacy orders

- Date: 2026-09-13
- Status: Accepted by product owner
- Decision: The launch commission promotion starts at trusted account approval/first activation (`ACTIVE`), not signup/creation while `PENDING`. Keep a trusted activation timestamp; later suspension/restoration must not restart the promotion.
- Decision: Orders completed before financial snapshots are introduced remain without retrospective commission or ledger charges. Display missing historical financial values as unknown, never as zero commission.
- Reason: Explicit product-owner confirmation during Driver App execution.
- Scope: Frozen configurable commission rates and promotion durations remain unchanged. Office promotion uses its trusted account approval/activation, not `created_at`.
