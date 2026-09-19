# Cost & Performance Rules

Permanent project rules for minimizing infrastructure cost, external API usage, network traffic, database round trips, and unnecessary realtime usage.

## Core Principle

Optimize for:

- minimum external API cost
- minimum network round trips
- minimum unnecessary database writes
- fast user experience
- simple MVP architecture

Prefer PostgreSQL / Supabase before paid external APIs. Use external APIs only when they provide functionality we cannot reasonably perform inside the existing stack.

## Database Round Trips

Prefer one secure RPC/database transaction over multiple sequential client requests.

For critical operations such as `create_order`, `submit_offer`, `accept_offer`, `driver_on_way`, `driver_arrived`, `start_order`, `complete_order`, and `cancel_order`, prefer:

```text
one client call
→ server-side validation
→ atomic database work
→ one result
```

Avoid client-side chains of multiple reads/writes when the database can perform the operation safely in one transaction.

## Realtime

Use Supabase Realtime only for data that genuinely needs live updates, including:

- new eligible order/request
- driver offers
- selected offer
- active trip status
- active trip location

Do not use realtime for profile pages, historical orders, static settings, archived records, or earnings/history screens unless required.

Do not use polling when realtime or event-driven updates can solve the problem. Polling is an exception and must be justified.

## Push Notifications

Use FCM for background notification/event delivery instead of having apps repeatedly poll the database.

Examples include new ride requests, new delivery requests, offer selection, and relevant trip events.

## Driver Location Cost Rule

Do not insert a new permanent database row for every GPS update. For the current driver position, use one row per driver and UPSERT the latest location.

- Offline: no location updates.
- Online but idle: low-frequency or significant-movement updates only.
- Active trip: higher frequency, approximately every 5–10 seconds when useful.

Do not send a location update when movement is too small to provide useful new information. Trip location history must not be stored by default unless a future business, legal, or analytics requirement justifies it.

## Google Maps / Paid APIs

Treat Google Maps APIs as cost-sensitive resources. Use Google for map display, place search, and selected route/distance/ETA when needed.

Do not use expensive routing APIs to find all nearby drivers. Nearby-driver discovery should use PostgreSQL/PostGIS:

```text
pickup coordinates
→ PostGIS proximity query
→ eligible nearby drivers
→ routing API only when route-level precision is needed
```

Do not calculate detailed route/ETA for dozens or hundreds of drivers. Use coarse geographic proximity first.

## Places Search

Autocomplete must use debounce, a minimum useful query length, proper session behavior where supported, and only necessary fields.

Store selected location data such as `place_id`, address, latitude, and longitude. Do not geocode the same selected place repeatedly without reason.

## Navigation

For MVP, prefer opening external Google Maps navigation from the Driver App rather than implementing a costly embedded navigation stack unless explicitly required.

## Caching

Do not introduce Redis or another cache infrastructure prematurely. First use:

- indexed PostgreSQL queries
- compact queries
- locally retained UI state where appropriate

Add additional caching infrastructure only after measured performance data proves it is required.

## Edge Functions

Use Edge Functions only when there is a real requirement, such as secret external API calls, webhooks, scheduled jobs, or integrations that should not run directly in the client/database.

Do not move ordinary internal business logic into Edge Functions when PostgreSQL functions/RPC can safely perform it.

## Payload Size

Never fetch data blindly. Prefer required columns only, server-side filtering, `LIMIT`, pagination, and cursor pagination where useful. Avoid large `select *` queries in high-traffic flows.

## Cost Review Rule

Before adding a new external API or paid service, evaluate:

1. Can PostgreSQL/Supabase already do this?
2. Can the client do this safely without another API?
3. Is this call required on every request or only at key moments?
4. Can the result be reused?
5. Does the API charge per request, per element, per route, or per session?
6. What happens to cost at 1,000 / 10,000 / 100,000 trips?

If a cheaper safe architecture exists, prefer it.
