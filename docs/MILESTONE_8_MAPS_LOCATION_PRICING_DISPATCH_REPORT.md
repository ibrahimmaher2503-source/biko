# Milestone 8 — Maps, Location, Pricing, and PostGIS Dispatch

Status: **COMPLETE WITH EXTERNAL CONFIGURATION PENDING**  
Date: 2026-08-30  
Hosted Development migration: **`20260830163437_maps_location_pricing_dispatch`**

## Implemented contract

- CR-014: Driver order/offer detail families auto-dispose, Request/Active screens expose manual refresh, both apps invalidate operational providers on resume, and User active detail accepts the refreshed same-order object.
- CR-007: both main Android manifests explicitly declare INTERNET plus coarse/fine foreground location. Merged release-manifest and release-device evidence remain pending.
- Maps: Android manifest placeholder and iOS xcconfig placeholders keep SDK keys outside source control; both apps target supported platform floors. User pickup/destination selection supports map tap, current foreground location, controlled Places search/details, and a readable route preview. Driver request and active-trip screens show the operational route.
- Route/pricing: `route-quote` calls Google Routes with a narrow field mask, then uses a service-role-only PostgreSQL RPC. PostgreSQL owns quote identity, ownership, coordinates, expiry, exact money, service-specific Base/distance configuration, Suggested Price, and the exact 70% minimum. Order creation snapshots the quote and validates the stable intent before quote expiry/use, preserving uncertain recovery.
- Book Again: terminal orders remain terminal and prefill a new form without reusing the old quote or creation intent; a fresh quote is required.
- Driver location: authenticated Driver identity comes from `auth.uid()`. Foreground upload uses one UPSERT row, immediate acquisition, 50 m movement filtering, a 15-second minimum upload interval, and a 90-second foreground heartbeat to keep a stationary Driver within the 120-second freshness window. A fresh location is required before Online; assigned Drivers can continue updates.
- Dispatch: PostGIS geography points and GiST indexes enforce fresh-location discovery from server order age. Radius stages are 2 km at 0–20 seconds, 4 km at 20–40, 6 km at 40–60, and 8 km from 60 seconds until the 90-second bidding expiry. Discovery is pull-based on entry/resume/manual refresh and does not depend on Customer timers or polling.
- Privacy/security: geographic candidates retain the existing compact request projection. Customer identity/phone and Delivery recipient data are absent. Current geography is rechecked by offer-insert and assignment triggers. New tables use RLS; clients cannot directly write locations, quotes, settings, or zones; anon cannot execute the new RPCs; all SECURITY DEFINER functions use an empty search path.
- Geographic foundation: an empty PostGIS MultiPolygon operating-zone table is ready for an approved polygon. With no active polygon configured, the milestone does not invent or enforce a business zone. External Google Maps navigation opens only after assignment.

## Verification evidence

- Hosted rollback SQL: PASS. Covered one-row Driver UPSERT; Customer write denial; stale/fresh/offline/suspended/outside-radius/active-job behavior; 2/4/6/8 km stages; candidate privacy; RIDE/DELIVERY pricing isolation; below/exact/above 70%; quote ownership, coordinate, expiry, and stable-intent recovery; grants, RLS, safe search paths, and direct-write denial. Rollback left no fixtures or temporary pricing.
- Hosted inspection: PostGIS 3.3.7 installed; migration ledger includes `20260830163437_maps_location_pricing_dispatch`; RIDE and DELIVERY production pricing configs remain null; all four new tables have RLS and no anon/authenticated write grants.
- User Flutter: 16 core/maps tests PASS; focused Places debounce, stable-intent uncertain recovery, and active-detail freshness widget tests PASS.
- Driver Flutter: 4 focused model/projection tests PASS.
- Static: `flutter analyze --no-pub` PASS for User App and Driver App. Platform manifests, iOS floor, key placeholders, and permissions were inspected. Deno was unavailable, so no local `deno check` was claimed.

## External configuration pending

1. Create restricted Maps SDK keys for each Android/iOS application and place them in local/CI platform configuration.
2. Set hosted `GOOGLE_MAPS_SERVER_API_KEY`, enable only Places API (New) and Routes API, then deploy `places` and `route-quote`.
3. Product owner must supply authoritative RIDE and DELIVERY `suggested_price_base` and `suggested_price_distance_component` values; set `suggested_price_enabled=true` only with those approved values.
4. Supply an approved operating-zone polygon if zone enforcement is desired.
5. Run the smallest Development device smoke for Maps rendering, Places, Routes, current location, merged release INTERNET permission, and external navigation. No live Google or production acceptance is claimed yet.

## Explicitly deferred

Realtime, FCM, background tracking, driver-to-customer live movement, ETA refresh, Ride/Delivery OTPs, geofence arrival automation, ratings, commission, payments/wallet, cancellation cooldown, Admin zone management, scheduled/multistop orders, and Dashboard work remain outside Milestone 8.
