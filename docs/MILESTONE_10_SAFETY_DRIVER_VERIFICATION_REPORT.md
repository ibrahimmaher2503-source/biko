# Milestone 10 — Safety, Driver Verification, Geofence Enforcement, and Delivery Confirmation

**Status:** COMPLETE WITH EXTERNAL CONFIGURATION PENDING  
**Date:** 2026-08-30  
**Hosted project:** `biko-development`

## Hosted migration

Applied `supabase/migrations/202608300015_safety_driver_verification_delivery_confirmation.sql` to Development as:

`20260830185634_safety_driver_verification_delivery_confirmation`

After review found that pre-Milestone-10 terminal orders can lack a motorcycle snapshot, the smallest follow-up was applied without editing the first migration:

`20260830190204_m10_legacy_assigned_driver_read_fix`

## Implemented

- Reused `drivers`, `motorcycles`, and `driver_documents`; added verification status, age, expiry, rejection, current-document, and motorcycle-document fields without editing earlier migrations.
- Added private `motorcycle_documents` with owner/admin read policy and private `driver-documents` Storage bucket limited to JPG/PNG/PDF and 10 MB.
- Added server-side eligibility: active account/profile/office, age 21+, required approved current driver documents, approved active motorcycle, no active order, and Ride helmet/equipment acknowledgement.
- Added service-role expiry reconciliation and durable notification-outbox intents; active trips remain finishable after expiry.
- Added trusted PostGIS Pickup (200m) and Destination (300m) geofences using the existing latest-location and settings infrastructure.
- Removed operational OTP requirements: Ride starts after trusted arrival; Delivery pickup starts after trusted arrival. Delivery completion uses one private four-digit Customer Confirmation Code, bcrypt verification, five-attempt lockout, and single-use consumption.
- Added assigned Driver verification/vehicle fields to the existing compact customer read model.
- Added an audited, reason-required, Super Admin-only safety override RPC; normal clients cannot write the audit table.
- Added Driver verification/upload UI, helmet acknowledgement, service-sensitive trip actions, and final Delivery code entry. Added User assigned-driver identity/vehicle presentation and Delivery code card.

## Verification evidence

The hosted harness `supabase/tests/milestone_10_safety_driver_verification.sql` passed once in a migration rollback transaction and after each applied migration. Its 33 assertions plus 18 explicit denial guards covered the 40 requested invariants across:

- verification, age/expiry, motorcycle assignment, eligibility, helmet acknowledgement, and document Storage ownership;
- Ride/Delivery lifecycle authorization, geofence boundaries, no Ride/Pickup OTP, final code ownership, wrong-code handling, lockout, reuse, and terminal protection;
- customer offer privacy, pre-assignment customer privacy, active-job exclusion, cancellation/event behavior, and payload secrecy;
- direct-write/RLS/grant/search-path security for new objects and privileged functions;
- expiry outbox idempotency and active-trip completion protection.

The harness ended with `[]` and rolled back all fixture Auth users, profiles, drivers, motorcycles, orders, offers, events, and Storage rows. A post-run hosted query confirmed zero `m10-%@example.invalid` users.

Focused local checks:

- `apps/driver_app`: `flutter test test/milestone_10_safety_test.dart` — PASS (2 tests).
- `apps/user_app`: `flutter test test/milestone_10_safety_test.dart` — PASS (1 test).
- `apps/user_app`: focused `widget_test.dart` final Delivery-code/assigned-identity check — PASS (1 widget test).
- `apps/driver_app`: `flutter analyze` — PASS, no issues.
- `apps/user_app`: `flutter analyze` — PASS, no issues.
- `scripts/check-foundation.ps1` — PASS after narrowing CR-030 to forbidden authentication/SMS OTP APIs/configuration.

## Security and residual configuration

Hosted catalog checks confirmed RLS on `motorcycle_documents`, `safety_overrides`, and `order_events`; no authenticated direct DML on protected audit/event tables; no anonymous execution of the new privileged RPCs; and `search_path` pinned on all new security-definer functions. `motorcycle_documents` select is owner/admin scoped; `safety_overrides` and `order_events` remain private append-only surfaces.

Remaining public-launch configuration is intentionally outside this migration: a trusted daily invocation of the expiry function, an operations/Admin review UI, legal confirmation of motorcycle document categories/criminal-record requirements, and physical-device Storage/GPS acceptance. No Dashboard or Finance work was performed.
