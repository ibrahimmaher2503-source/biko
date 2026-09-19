# Database Engineering Rules

Permanent rules for keeping the Supabase/PostgreSQL database fast, scalable, secure, and simple.

## Source of Truth

PostgreSQL/Supabase is the source of truth for platform state. Do not maintain conflicting business state independently in Flutter.

## Server-Side Business Logic

Critical business rules should be enforced by constraints, RLS, database functions/RPC, and transactions. Do not rely only on UI/client checks.

## Atomic Operations

Operations that can race must be atomic. Examples include offer selection, assigning one driver, accepting an order, order state transitions, and financial calculations. Use transactions and row locking where appropriate.

## Index Strategy

Create indexes based on actual query patterns; do not add indexes blindly.

Likely high-value access patterns include:

- orders by customer/status/date
- orders by driver/status/date
- offers by order/status
- offers by driver/status
- drivers by office/status
- office_members by user/office
- driver_locations by driver
- geographic driver location search

Use PostGIS spatial indexes for proximity queries. Review index needs for every new high-frequency query.

## Query Rules

Prefer explicit columns, targeted predicates, indexed filters, `LIMIT`/pagination, and set-based SQL.

Avoid unnecessary `select *`, large unbounded scans, N+1 client queries, and repeated reads for values already known in the current transaction.

## Nearby Driver Search

Use PostGIS/database proximity search. Do not call Google routing/distance services just to discover nearby drivers.

Use:

```text
geographic radius
→ eligible driver filters
→ candidate shortlist
```

Detailed route calculations happen only later when justified.

## Driver Locations

Maintain the latest driver location efficiently. Prefer one current-location row per driver with upsert/update behavior. Do not grow a permanent table with unnecessary second-by-second GPS history.

## RLS

RLS must enforce customer ownership, driver ownership, office scope, and privileged platform access. Never rely on frontend filtering for security.

## Security Helpers

Keep RLS helper functions small and reusable. Avoid unnecessary `SECURITY DEFINER` functions. If `SECURITY DEFINER` is required, use a safe `search_path`, explicitly control `EXECUTE` grants, and prevent privilege escalation.

## Data Integrity

Use database-level integrity where possible: foreign keys, unique constraints, check constraints, `NOT NULL`, and enums where stable and appropriate. Do not depend solely on application validation.

## Status Transitions

State transitions must be validated server-side; invalid jumps must fail.

Example:

```text
BIDDING
→ DRIVER_ASSIGNED
→ DRIVER_ON_WAY
→ DRIVER_ARRIVED
→ IN_PROGRESS
→ COMPLETED
```

Provide valid alternate cancellation and expiry paths.

## Migration Discipline

Never edit an already-applied migration. Create a new focused migration, keep migrations small and understandable, and do not combine unrelated schema changes.

## Performance Rule

Do not optimize blindly. First ensure the query is correct, indexes match the query, result size is reasonable, N+1 behavior is absent, and unnecessary API round trips are removed. Add advanced infrastructure only after evidence shows it is necessary.

## Database Verification

Do not repeatedly run full database audits. Run targeted verification only when schema, RLS, function/RPC, constraints, indexes, or a migration changes. Previously verified unaffected database areas should not be rechecked.
