# Biko Admin Dashboard Backend Contract Inventory

**Review date:** 2026-09-19  
**Status:** SOURCE INVENTORY + COORDINATOR CATALOG RECONCILIATION — no behavioral acceptance  
**Scope:** Wave 0 ADM-01. This file maps the contracts present in the checkout so dashboard work does not depend on schema names alone.

## Evidence boundary

This inventory was built from the 26 files under `supabase/migrations/`, the source tests, the dashboard requirements, and the coordinator-owned read-only catalog snapshot at `docs/evidence/admin-dashboard-wave0-catalog-20260919.json`. The catalog is schema/grant/policy/function metadata only; it is not behavioral acceptance. This agent did not run SQL or remote operations, and did not run a build, lint, or browser acceptance. Source and hosted facts are kept in separate sections below. No hosted Production claim is made.

The effective authorization helpers are the latest definitions in `202608300009_wave_a_security_transaction_integrity.sql`:

- `private.is_super_admin()` requires an active profile and a `SUPER_ADMIN` row in `user_roles`.
- `private.has_permission(text)` accepts an active global role or an active office membership with the permission.
- `private.is_office_member(uuid)` requires active user, office, and membership.
- `private.can_access_office(uuid,text)` allows Super Admin or an active membership in the target office with the requested permission. A global non-Super platform role does not satisfy this office-scope helper.

References: `supabase/migrations/202608300009_wave_a_security_transaction_integrity.sql:3-67`, `202608300001_authorization_rls.sql:105-238`.

## Screen-by-screen contract map

The “Existing functions” column lists source functions that may be reused only when their identity and scope match the dashboard operation. Mobile/customer/driver functions are not dashboard contracts merely because they are callable by `authenticated`.

| Dashboard surface | Required projection / columns | Existing functions and read contracts | SELECT / grants / RLS scope | Mutation gap / bounded next contract | Source references |
|---|---|---|---|---|---|
| Login, session, dashboard context | Auth session; active `profiles`; global roles; office memberships; role permissions; suspended-account state | Supabase Auth; `private.is_super_admin()`, `private.has_permission(text)`, `private.is_office_member(uuid)`, `private.can_access_office(uuid,text)` | `profiles`, `user_roles`, `office_members`, `roles`, `permissions`, `role_permissions` grant authenticated SELECT with RLS; helper execution is authenticated-only | No dashboard client/auth route, no bounded “current admin context” projection, no staff invite/reset contract, and no seeded Operations/Support/Verification roles | `202608290001_foundation.sql:10-64,128-134,199-266`; `202608300001_authorization_rls.sql:83-93,105-238`; `apps/dashboard/src/app/page.tsx:1-29` |
| Overview | Scoped counts for orders by status/service/date, online/active drivers, driver type, active offices, and gross completed value only when `finance.view` permits | None. Existing mobile reads (`get_driver_requests`, driver earnings) are not aggregate dashboard contracts | Row-level reads exist for authorized orders/drivers/offices, but no aggregate RPC and no explicit date-bound projection | Add one server-side scoped aggregate contract; define day/timezone and separate gross, commission, and platform revenue. Do not fetch all rows into the browser | `202608300002_core_bidding_engine.sql:24-43,68-80,92-119`; `202608290001_foundation.sql:42-53,66-83`; requirements `Unified_Admin_Office_Dashboard_Requirements_EN.md:193-210` |
| Live Operations | Active orders, permitted driver identity/type/office/status, latest latitude/longitude/accuracy/updated time, service/status filters | No dashboard function. `public.update_driver_location(...)` is the driver write path; mobile tracking contracts are customer-owned | `driver_latest_locations` has RLS and authenticated privileges revoked. `orders`/`drivers` are row-readable by Super Admin or target-office permission, but location rows are not | Add a bounded live-operations read projection/RPC and an explicitly scoped Realtime channel; no direct GPS-table exposure, no customer tracking RPC reuse, no polling fan-out | `202608300013_maps_location_pricing_dispatch.sql:33-54,192-250`; `20260907230010_customer_live_order_tracking.sql:20-24`; requirements `:213-228` |
| Orders list | `orders.id`, service, customer reference/name as permitted, driver, historical `office_id`, proposed/agreed price, status, payment method, created/assigned/completed timestamps, cancellation fields | No dashboard function; direct `public.orders` SELECT is the current source contract | Authenticated SELECT grant; RLS permits customer ownership, Super Admin, or `can_access_office(orders.office_id,'orders.view')`. Historical office scope is stored on the order | Add server-side filtering, pagination, search, and a minimized dashboard projection. No generic table update. No payment method column is present in the core order migration; MVP is Cash by rule | `202608300002_core_bidding_engine.sql:24-43,68-80,92-119`; `202608300008_gate_2_remediation.sql:13-19`; requirements `:232-259` |
| Order detail and timeline | Route, service, customer/driver/motorcycle/office relations, selected offer, prices, timestamps, cancellation, lifecycle/audit timeline | `public.get_driver_requests(uuid)` is driver-owned and not a dashboard detail contract; `public.get_customer_assigned_driver(uuid)` is customer-owned; no admin detail RPC | `orders` and `offers` are selectable for Super Admin/office scope. `order_events` has RLS but no authenticated table privileges. Delivery details are customer-owned | Add an admin-scoped detail/timeline projection. Keep Delivery confirmation secrets and private recipient data out unless explicitly permitted. No arbitrary status editor | `202608300005_driver_business_freeze_reconciliation.sql:12-28`; `202608300007_user_flow_privacy_hardening.sql:40-55`; `202608300008_gate_2_remediation.sql:24-59`; requirements `:260-275` |
| Offers / bids | Offer/order/driver/office IDs, offered amount, status, created/updated time, selected winner | No dashboard function; direct `offers` SELECT is the current source contract. `get_customer_order_offers(uuid)` is customer-owned | Authenticated SELECT grant; RLS allows Super Admin, target-office `orders.view`, or the mobile driver/customer paths | Add bounded order/offer pagination and explicit winning-offer projection. No manual selection or generic bid mutation; customer remains the selector | `202608300002_core_bidding_engine.sql:45-85,121-161`; `202608300006_user_flow_backend_delta.sql:428-443`; requirements `:277-293` |
| Trusted order intervention | Explicit emergency cancellation/recovery/correction with reason, before/after, actor | `public.admin_safety_override(uuid,text,text)` only; validates Super Admin, action, reason, service, and lifecycle; writes `safety_overrides` and `order_events` | Function is executable by authenticated but rejects non-Super Admin. `safety_overrides` has no authenticated SELECT | Missing `admin_cancel_order`, `admin_restore_driver`, `admin_correct_order_data`, and a unified audit read. Add separate permissions and legal transition checks; never expose generic status editing | `202608300015_safety_driver_verification_delivery_confirmation.sql:1155-1219`; freeze `BUSINESS_RULES_FREEZE_V1.md:138-140`; requirements `:566-568` |
| Drivers list/detail | Driver/profile identity, type, office, status, online state, rating fields, completed trips, motorcycle relation, order history | `public.submit_independent_driver_application(...)` is self-service only; `public.review_driver_verification(uuid,driver_status,date,text)` is a trusted review function | `drivers` SELECT: own driver, Super Admin, or target-office `drivers.view`; `profiles` has matching permitted staff/office projections | Missing office-driver create/invite, allowed edit, suspend/restore, history/read projection, and operations flag read. Do not reuse independent self-application to create an office driver | `202608290001_foundation.sql:31-83`; `202608300001_authorization_rls.sql:131-175`; `20260912190128_driver_application_onboarding.sql:4-169`; requirements `:297-331` |
| Motorcycles | Plate, brand, model, color, year, driver/office, operational status, verification status, photos | `public.submit_motorcycle_document(uuid,text,text,date,date)` is owner-only; `public.review_motorcycle(uuid,document_status,text)` is Super Admin-only | `motorcycles` SELECT is own-driver, permitted office, or Super Admin. `motorcycle_documents` table SELECT is own-driver or Super Admin only | Missing office CRUD/link/reassignment contracts, safe photo/file preview, and non-Super verification delegation. Protect active-trip vehicle history | `202608290001_foundation.sql:85-98`; `202608300001_authorization_rls.sql:177-190`; `202608300015_safety_driver_verification_delivery_confirmation.sql:66-115,695-739`; requirements `:365-380` |
| Verification queue/detail | Pending driver/motorcycle applications, document type/status/expiry/reason, file preview, verifier and timestamp | `public.get_driver_verification_overview()` is driver-self only; `review_driver_document(uuid,document_status,text)`, `review_motorcycle_document(uuid,document_status,text)`, `review_motorcycle(uuid,document_status,text)`, `review_driver_verification(uuid,driver_status,date,text)` are available | Metadata rows are partially office-readable for driver documents; motorcycle document rows and Storage files are own-driver/Super Admin only. All review functions check only `private.is_super_admin()` | Add Verification role and target scope, signed URL/Storage authorization, legal state-transition matrix, and atomic audit. `SUSPENDED` reason is required but not persisted; review functions do not write before/after audit rows | `202608300001_authorization_rls.sql:192-210`; `202608300015_safety_driver_verification_delivery_confirmation.sql:174-234,551-780`; requirements `:335-361` |
| Users/customers | Customer profile, status, phone/name minimization, order counts/history, support-review state | No customer-admin function. `private.update_own_profile(...)` / `public.update_own_profile(...)` are customer self-service only | `profiles` SELECT is self, Super Admin, or office-linked permitted records; no office-wide customer history contract | Missing customer list/detail aggregate, suspend/restore, support-review contract, and explicit personal-data projection. Office users must not gain platform-wide customer access | `202608300001_authorization_rls.sql:118-151`; `20260907230031_user_profile_editing.sql:38-120`; requirements `:384-404` |
| Offices list/detail | Office identity/contact/area/status, driver/motorcycle/order counts, reports, commission configuration | None | `offices` authenticated SELECT through `can_access_office(id,'dashboard.view')`; no authenticated INSERT/UPDATE/DELETE grant | Missing platform-scoped create/edit/suspend/restore and office summary RPCs. `commission_config` is unvalidated JSONB and has no write contract | `202608290001_foundation.sql:42-53`; `202608300001_authorization_rls.sql:105-129,153-157`; requirements `:408-443` |
| Office staff | Membership user/office/role/status and staff profile | No staff-management function | `office_members` SELECT for self or target office `dashboard.view`; roles/permissions/user_roles are SELECT-only for Super Admin or `roles.view` | Missing invite/create/activate/suspend/role-assignment contracts; forbid office users from assigning platform roles or touching another office | `202608290001_foundation.sql:55-64,128-134`; `202608300001_authorization_rls.sql:159-166,212-238`; requirements `:447-467` |
| Roles & permissions | Role code/name/scope, permission catalog, role-permission mapping, user-role assignments | `private.has_permission(text)` only; no role-management RPC | Authenticated SELECT for Super Admin or `roles.view`; no authenticated mutation grant | Missing create/rename/permission assignment/user assignment/invariant checks. Prevent self-escalation and removal of the last usable admin | `202608290001_foundation.sql:10-29,199-266`; `202608300001_authorization_rls.sql:212-238`; requirements `:519-530` |
| Reports | Scoped order/service/status, completion/cancellation, gross/agreed value, offer counts, driver/office performance | None; no aggregate/report RPC | Underlying row reads exist for orders/offers/drivers/offices when RLS permits; no report-specific scope or bounded aggregation contract | Add server-side aggregate RPCs with explicit date/timezone/denominator definitions. Ratings must remain unavailable until a ratings source exists | `202608300002_core_bidding_engine.sql:68-80`; requirements `:471-490`; `Database_Schema_Specification_EN.md:692-731` |
| Finance | D07 snapshot status/rates/amounts, commission due, driver credit entries, office-scoped totals, settlement facts | `public.get_driver_earnings(integer)` is driver-self only; `public.record_driver_credit_top_up(uuid,numeric,uuid,text)` is service-role-only | `commission_ledger` has authenticated privileges revoked; `driver_credit_ledger` is service-role SELECT only; no admin finance projection | Add finance-scoped read RPC, session-derived top-up actor, duplicate/reference protection, audit, and bounded weekly office settlement. D07 has no office settlement/invoice model and deliberately leaves Office Driver net/payroll unknown | `20260913090000_d07_financial_truth.sql:162-223,493-588,671-746`; requirements `:493-515,583-599` |
| Settings | Service enablement, bidding/dispatch timing, pricing, commission/promotion, document, location, notification settings | Private getters only: `private.setting_positive_int(text,integer)`, `private.financial_setting_percent(text,numeric)`, `private.financial_setting_days(text,integer)`, `private.financial_setting_amount(text,numeric)` | `platform_settings` has RLS and authenticated privileges revoked. `service_types` is public-read, not admin-write | Add allow-listed typed read/write RPCs, actor/audit metadata, validation, and a consumer for every editable key. Do not expose a generic JSON editor or change historical snapshots | `202608300013_maps_location_pricing_dispatch.sql:4-16,101-135`; `20260913090000_d07_financial_truth.sql:224-298`; requirements `:493-515` |
| Operating zones | Zone name, active flag, PostGIS polygon, effective timestamp | `private.operating_zone_allows(geography)` is internal eligibility logic | `operating_zones` has RLS and authenticated privileges revoked | Add bounded platform read/write contract with geometry validation and audit; changes affect new eligibility only and must not rewrite trip history | `202608300013_maps_location_pricing_dispatch.sql:18-31,126-135`; requirements `:508-515` |
| Audit log | Actor, role/office, action, entity, before/after, reason, timestamp, safe metadata | No `audit_logs` table/function exists in migrations. `order_events` and `safety_overrides` are narrower event stores | `order_events` and `safety_overrides` have no authenticated read grants; D06 review flags are service-role-only | Add one protected append-only audit contract and read projection. Every sensitive mutation must write it in the same transaction; no client update/delete | requirements `:534-568`; `202608300005_driver_business_freeze_reconciliation.sql:12-28`; `202608300015_safety_driver_verification_delivery_confirmation.sql:146-161`; `20260912201346_driver_cancellation_review_flag.sql:26-30` |
| Driver office transfer | Pending request, current/target office, actor, reason, decision, effective time; historical order/financial office remains unchanged | None; no change-request table or RPC exists | Current `drivers.office_id` is protected from normal client DML but has no explicit trusted transfer workflow | Add request table and atomic approve/reject function; prevent direct `office_id` edits, two concurrent approvals, transfer during active work, and movement of historical orders/offers/ledger facts | `202608290001_foundation.sql:66-83`; requirements `:323-331`; freeze `BUSINESS_RULES_FREEZE_V1.md:36,163` |

## D07 financial draft boundary

`20260913090000_d07_financial_truth.sql` is present in source and defines:

- immutable completion snapshots and `commission_ledger`;
- independent-driver `driver_credit_ledger` and commission debits;
- threshold enforcement before candidates/offers;
- `get_driver_earnings(integer)` for the authenticated Driver;
- service-role-only `record_driver_credit_top_up(...)`.

It does **not** provide dashboard finance reads, weekly office settlement/invoice, authenticated top-up mediation, a platform-balance table, or a general audit record. The source also intentionally keeps pre-snapshot completed orders `UNKNOWN` and leaves Office Driver payroll/net values unset. No dedicated D07 SQL test file is present under `supabase/tests/`; source presence must not be reported as hosted acceptance.

## Local migration inventory (26 source files)

1. `202608290001_foundation.sql`
2. `202608300001_authorization_rls.sql`
3. `202608300002_core_bidding_engine.sql`
4. `202608300003_order_state_machine.sql`
5. `202608300004_driver_app_core.sql`
6. `202608300005_driver_business_freeze_reconciliation.sql`
7. `202608300006_user_flow_backend_delta.sql`
8. `202608300007_user_flow_privacy_hardening.sql`
9. `202608300008_gate_2_remediation.sql`
10. `202608300009_wave_a_security_transaction_integrity.sql`
11. `202608300010_wave_b_recovery_auth_contracts.sql`
12. `202608300011_wave_c_read_correctness.sql`
13. `202608300012_user_app_core_bridge.sql`
14. `202608300013_maps_location_pricing_dispatch.sql`
15. `202608300014_realtime_push_notifications.sql`
16. `202608300015_safety_driver_verification_delivery_confirmation.sql`
17. `202608300016_m10_legacy_assigned_driver_read_fix.sql`
18. `20260907230010_customer_live_order_tracking.sql`
19. `20260907230031_user_profile_editing.sql`
20. `20260908090000_customer_driver_contact.sql`
21. `20260912190128_driver_application_onboarding.sql`
22. `20260912192009_driver_request_experience.sql`
23. `20260912201216_driver_progressive_dispatch_signals.sql`
24. `20260912201346_driver_cancellation_review_flag.sql`
25. `20260912203000_driver_customer_contact.sql`
26. `20260913090000_d07_financial_truth.sql`

## Coordinator-owned live Supabase catalog (read-only; no behavioral acceptance)

The coordinator captured the Development project catalog after restoration. This is a catalog reconciliation, not proof that a caller can successfully perform an operation under a particular identity. No query or mutation was rerun for this document.

| Catalog fact | Observed value | Interpretation / boundary |
|---|---|---|
| Project | `biko-development` / ref `jlkzgsgfzolhwraakhbt` | Development project only; this document makes no Production claim. |
| Project status | `ACTIVE_HEALTHY` | Snapshot was captured after restore. This is environment status, not feature acceptance. |
| Snapshot | `2026-09-19T18:40:44.843779+00:00` | Evidence file: `docs/evidence/admin-dashboard-wave0-catalog-20260919.json`. |
| Local vs live migration ledger | 26 local files; 17 applied remote rows matched by migration name; 9 local names absent | A name match is not a checksum or definition-equivalence check. No applied-status claim is made for the absent files. |
| Public tables | 25 | Catalog count; table rows retain RLS and authenticated grant flags below. |
| Policies | 24 | Catalog policy rows only; policy expressions were not behaviorally exercised. |
| Functions | 64 total: 24 `private`, 40 `public` | Catalog count. This is 64, not 65. Function metadata was inventoried; no behavioral invocation was accepted. |
| D07 | `20260913090000_d07_financial_truth.sql` absent from the 17 live migration names; `commission_ledger`, `driver_credit_ledger`, `get_driver_earnings`, and `record_driver_credit_top_up` are absent from the catalog | Keep D07 as source draft only; do not present hosted finance/ledger behavior as deployed. |
| Roles | `SUPER_ADMIN`, `OFFICE_ADMIN`, `OFFICE_DISPATCHER`, `OFFICE_ACCOUNTANT` | Catalog role/permission rows only. No seeded-user, suspended-user, cross-office, or privilege-escalation behavior was tested. |

### Local-to-live migration name reconciliation

The remote version is shown exactly as returned by the catalog. Matching is by migration name only; it does **not** establish equal file contents, checksums, SQL definitions, or successful runtime behavior.

| Local source file | Remote catalog version/name | Name status |
|---|---|---|
| `202608290001_foundation.sql` | `20260829123858_foundation` | matched by name |
| `202608300001_authorization_rls.sql` | `20260829230833_authorization_rls` | matched by name |
| `202608300002_core_bidding_engine.sql` | `20260829232707_core_bidding_engine` | matched by name |
| `202608300003_order_state_machine.sql` | `20260829233756_order_state_machine` | matched by name |
| `202608300004_driver_app_core.sql` | `20260830001817_driver_app_core` | matched by name |
| `202608300005_driver_business_freeze_reconciliation.sql` | `20260830010117_driver_business_freeze_reconciliation` | matched by name |
| `202608300006_user_flow_backend_delta.sql` | `20260830014754_user_flow_backend_delta` | matched by name |
| `202608300007_user_flow_privacy_hardening.sql` | `20260830015129_user_flow_privacy_hardening` | matched by name |
| `202608300008_gate_2_remediation.sql` | `20260830021017_gate_2_remediation` | matched by name |
| `202608300009_wave_a_security_transaction_integrity.sql` | `20260830133522_wave_a_security_transaction_integrity` | matched by name |
| `202608300010_wave_b_recovery_auth_contracts.sql` | `20260830135840_wave_b_recovery_auth_contracts` | matched by name |
| `202608300011_wave_c_read_correctness.sql` | `20260830143750_wave_c_read_correctness` | matched by name |
| `202608300012_user_app_core_bridge.sql` | `20260830151837_user_app_core_bridge` | matched by name |
| `202608300013_maps_location_pricing_dispatch.sql` | `20260830163437_maps_location_pricing_dispatch` | matched by name |
| `202608300014_realtime_push_notifications.sql` | `20260830174205_realtime_push_notifications` | matched by name |
| `202608300015_safety_driver_verification_delivery_confirmation.sql` | `20260830185634_safety_driver_verification_delivery_confirmation` | matched by name |
| `202608300016_m10_legacy_assigned_driver_read_fix.sql` | `20260830190204_m10_legacy_assigned_driver_read_fix` | matched by name |

Absent from the live migration-name catalog (local only):

`20260907230010_customer_live_order_tracking.sql`, `20260907230031_user_profile_editing.sql`, `20260908090000_customer_driver_contact.sql`, `20260912190128_driver_application_onboarding.sql`, `20260912192009_driver_request_experience.sql`, `20260912201216_driver_progressive_dispatch_signals.sql`, `20260912201346_driver_cancellation_review_flag.sql`, `20260912203000_driver_customer_contact.sql`, `20260913090000_d07_financial_truth.sql`.

### Live source-to-catalog contract observations

The flags below are catalog metadata, not identity-specific probes. `SELECT=true` means an authenticated table grant was observed; RLS still determines which rows a caller can see. All listed authenticated insert/update/delete flags are false. A function appearing in the catalog means metadata was found, not that its intended dashboard caller can pass authorization or that its behavior is correct.

| Dashboard contract area | Live catalog columns / objects | Live functions | Authenticated grant/RLS and policy observations | Remaining acceptance or implementation gap |
|---|---|---|---|---|
| Core order list/detail | `orders` has 37 columns including `office_id`, status/lifecycle timestamps, cancellation fields, route quote/distance/duration/polyline, prices, and `motorcycle_id`; `offers`, `order_delivery_details`, `order_driver_candidates` also present | `accept_offer`, `advance_order_state`, `cancel_order`, `complete_order`, `create_order`, `expire_order`, `get_customer_assigned_driver`, `get_customer_order_offers`, `get_driver_requests`, `record_order_event`, `start_order` | `orders`, `offers`, and candidate/detail tables have authenticated SELECT grants; RLS is enabled; `orders` has `orders_select_assigned_driver` and `orders_select_permitted` policies. Authenticated DML grants are false. `order_events` has no authenticated SELECT grant in the catalog. | No admin list/detail/timeline projection or bounded pagination/filter contract; no tested office/suspended identity behavior. Direct table read is not dashboard acceptance. |
| Live operations / map | `driver_latest_locations` has 8 columns; `drivers` and `driver_work_signals` are present | `ensure_fresh_location_before_online`, `set_driver_online`, `update_driver_location`, `signal_new_driver_work`, `reconcile_driver_idle_availability` | `driver_latest_locations`: RLS enabled, authenticated SELECT false, all authenticated DML false. `drivers`/`driver_work_signals` have SELECT grants with RLS. | No dashboard-safe location projection or Realtime authorization contract; no behavior probe. |
| Drivers / motorcycles | `drivers` (14 columns), `motorcycles` (16), `driver_documents` (13), `motorcycle_documents` (13) | `get_driver_verification_overview`, `review_driver_document`, `review_driver_verification`, `review_motorcycle`, `review_motorcycle_document`, `submit_driver_document`, `submit_motorcycle_document` | Driver/motorcycle/document tables have authenticated SELECT grants, RLS enabled, and no authenticated DML grants. Catalog policy names are permitted-select policies; Storage object policies are separate. | Verification functions exist in catalog but source/latest contract is Super Admin-only; office delegation, signed preview URLs, reason persistence, and audit remain unimplemented/unprobed. |
| Offices / staff / roles | `offices` (10), `office_members` (7), `profiles` (8), `roles` (5), `permissions` (4), `role_permissions` (2), `user_roles` (4) | `can_access_office`, `has_permission`, `is_office_member`, `is_super_admin`, `handle_new_auth_user` | These tables have authenticated SELECT grants with RLS; all authenticated DML grants are false. Catalog policies include `offices_select_permitted`, `office_members_select_permitted`, and authorized role/permission reads. | No admin invite, membership mutation, role assignment, suspend/restore, or current-context projection; no cross-office/suspended probes. |
| Settings / zones | `platform_settings` (3), `operating_zones` (6), `service_types` (8) | `operating_zone_allows`, `setting_positive_int`, `dispatch_radius_meters` | `platform_settings` and `operating_zones`: RLS enabled, authenticated SELECT false, all authenticated DML false. `service_types` has authenticated SELECT with RLS. | No allow-listed admin settings/zones read-write contract or audit. |
| Safety / audit | `safety_overrides` (8), `order_events` (8), `notification_outbox` (18) | `admin_safety_override`, `record_order_event`, notification functions | `safety_overrides` and `order_events`: RLS enabled, authenticated SELECT false, all authenticated DML false. No `audit_logs` table or generic audit function appears in the 25-table/64-function catalog. | `admin_safety_override` remains the narrow trusted intervention; no general admin audit read, cancel/correct/restore functions, or behavioral acceptance. |
| Finance | No `commission_ledger` or `driver_credit_ledger` table appears; no finance aggregate table/function appears | No `get_driver_earnings` or `record_driver_credit_top_up` function appears | This catalog cannot support a hosted D07 dashboard contract. No D07 migration name is present. | Keep D07 source-only; add finance read/top-up mediation/settlement contracts only after an explicit migration and targeted acceptance. |

The dashboard app source remains a static shell (`apps/dashboard/src/app/page.tsx:1-29`); no Supabase client, auth flow, or dashboard read implementation was found in the source slice reviewed. The live catalog therefore records backend metadata only and does not turn the current app into an integrated dashboard.

## Acceptance handoff

Before dashboard screens are marked integrated, the next bounded checks are:

1. Treat the 26-file-to-17-row migration-name reconciliation as complete for ADM-01; compare affected definitions when implementing their next change, because name matching does not prove equivalence.
2. Use the completed `ADMIN_DASHBOARD_ACCESS_MATRIX.md` for Super Admin, platform staff, Office A/B roles, suspended identities, CUSTOMER, DRIVER, and anonymous callers; proposed roles are not deployed grants.
3. Add explicit backend contracts before opening any protected table DML.
4. Test direct API, RLS, and Storage boundaries with two offices and a suspended account.
5. Keep D07 source and hosted/runtime acceptance as separate statuses.
