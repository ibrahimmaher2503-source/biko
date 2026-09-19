# Backend Gate 1 Report

Date: 2026-08-30  
Project: `biko-development` (`jlkzgsgfzolhwraakhbt`)  
Scope: Backend through Milestone 5; no mobile or Dashboard work

## Result

**Backend Gate 1: PASS**

The complete backend through Milestone 5, including the hosted Email/Password Auth smoke, is ready for mobile development.

| Test Area | Result | Evidence |
| --- | --- | --- |
| Migration/schema drift | PASS | Hosted migration history contains `foundation`, `authorization_rls`, `core_bidding_engine`, and `order_state_machine`. All 14 expected public tables have RLS enabled. |
| Hosted Auth | PASS | One fresh account completed signup with an immediate session, exactly one CUSTOMER profile with no privileged identity, sign-out, password sign-in, valid-session check, refresh-token session restore, and final sign-out. The exact test identity and cascaded data were deleted afterward. |
| Profiles and drivers | PASS | Existing hosted verification covers one CUSTOMER profile per auth user, privileged metadata ignored, duplicate profiles/drivers rejected, trusted driver links, PENDING default, and independent/office driver types. Previously verified; not rerun because no related schema changed. |
| Authorization and RLS | PASS | Current catalog: 14/14 tables use RLS, protected tables have zero anonymous grants and zero authenticated DML grants. Current policies preserve customer, driver, office, and Super Admin scope. |
| Orders and bidding | PASS | Existing hosted verification covers RIDE/DELIVERY creation, auth-derived customer identity, validation, privacy, candidate gating, active-driver offers, offer uniqueness, and direct-write denial. Previously verified; Milestone 4 was not retested. |
| Atomic acceptance | PASS | Existing overlapping-session test produced exactly one accepted offer and rejected the competing acceptance after the row lock/state change. Previously verified; Milestone 4 was not retested. |
| State machine | PASS | Existing hosted verification covers the valid driver sequence, assigned-driver checks, invalid jumps, timestamps, and direct-write denial. Previously verified; no related migration changed. |
| Cancellation and expiry | PASS | Existing hosted verification covers allowed pre-trip cancellation, rejected in-progress/completed cancellation, stale bidding expiry, offer closure, and terminal states. Previously verified; no related migration changed. |
| Concurrency | PASS | Existing overlapping `accept_offer` and stale `complete_order` tests each produced one winner and one expected rejection with consistent final state. Previously verified; not rerun. |
| Data integrity | PASS | Current catalog contains 38 relevant PK/FK/unique/check constraints. Ten hot-path indexes and the partial one-active-offer constraint are present. |
| Performance and cost sanity | PASS | Targeted EXPLAIN statements completed for customer orders, driver candidates, order/driver offers, and office drivers. Ten matching hot-path indexes exist. No Edge Functions are deployed; repository search found no active Redis, paid Maps API, or application polling dependency. |
| RPC security | PASS | All nine sensitive RPCs use safe `search_path=''`; anonymous EXECUTE is denied. Eight intended client RPCs allow authenticated execution, while `expire_order` is service-role-only. |
| Security Advisor | PASS | One run returned only expected warnings for authenticated `SECURITY DEFINER` RPCs. These RPCs are intentional trusted boundaries with internal `auth.uid()` authorization, safe search paths, and no anonymous EXECUTE. Reference: [Supabase lint 0029](https://supabase.com/docs/guides/database/database-linter?lint=0029_authenticated_security_definer_function_executable). |
| Cleanup | PASS | Hosted verification reports zero Backend Gate temporary auth/office rows. Failed transactional harness attempts rolled back automatically. |

## Corrective Migrations

- None.

## Remaining Blocker

- None.

## Mobile Development Gate

**APPROVED**
