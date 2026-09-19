# Project Execution Rules

## FAST EXECUTION MODE — PROJECT RULE

### Primary Priority

Optimize for:

- fastest safe implementation
- time is the highest-priority constraint

Do not spend time on repeated validation that does not materially reduce risk.

### Verification Rule

Use:

```text
implement
→ targeted verify once
→ continue
```

Do not use:

```text
implement
→ full analyze
→ full test
→ full audit
→ small change
→ full analyze again
→ full test again
```

### Flutter Dependencies

Run `flutter pub get` only when:

- `pubspec.yaml` changed
- dependency versions changed
- a dependency error requires it

Do not run it repeatedly when dependencies did not change.

### Flutter Analysis

Run `flutter analyze` only for the affected app/package. Run it once after the relevant implementation is complete. Do not repeatedly analyze after every small edit or analyze unrelated apps/packages.

### Flutter Tests

Run tests only when:

- business logic changed
- security-sensitive logic changed
- a bug was fixed
- the feature has not yet been verified
- a previous test failed

Prefer targeted tests. Do not repeatedly run full test suites for unrelated changes.

### Dashboard Checks

Do not run `npm build`, `next build`, `eslint`, or full dashboard checks unless Dashboard code/configuration changed.

### Database Checks

Do not rerun database foundation verification if schema/migration code did not change. Do not repeat already-passed Supabase checks unless the current change can affect them.

### Documentation Changes

If only documentation changed, do not run Flutter tests, Flutter analyze, dashboard build, or database checks.

### Repeated Command Rule

Never run the exact same verification command repeatedly unless the previous run failed and code/configuration was changed to address that failure.

If a command already passed and nothing relevant changed, do not rerun it.

### Scope Rule

Only verify the smallest affected scope. Examples:

- `app_core` changed → verify `app_core`
- User App auth changed → verify User App auth
- Driver App unchanged → do not analyze/test Driver App
- Dashboard unchanged → do not build Dashboard

### Critical Exceptions

Do not skip important verification for:

- RLS
- authorization
- privilege escalation
- `accept_offer()` atomic logic
- concurrency
- order state transitions
- payment/commission calculations
- production migrations
- destructive data changes

Even in these cases, run the minimum targeted verification necessary.

### Progress Rule

Do not stop after every tiny task. If the next task is directly related and safe to continue, continue. Stop only at a meaningful checkpoint.

### Reporting Rule

If an area was already verified and current changes do not affect it, report:

> Previously verified — not rerun because current changes do not affect them.

Do not rerun it merely to produce a fresh PASS.

### Final Principle

Always ask internally:

> Will this command meaningfully reduce risk?

If no, do not run it. Time is more important than redundant verification.

## Project Skill

For engineering implementation, debugging, integration, migration, UI, backend, and similar work, apply the `fast-execution` skill at `.agents/skills/fast-execution/SKILL.md`. Time is a primary constraint: prefer meaningful execution waves and targeted verification, and do not repeat already-passing checks unless relevant code changed.

## Cost & Database Efficiency

For database, backend, realtime, maps, and external API work:

- follow `COST_AND_PERFORMANCE_RULES.md`
- follow `DATABASE_ENGINEERING_RULES.md`
- minimize database round trips and prefer Supabase/PostgreSQL over paid APIs where practical
- use PostGIS for nearby-driver discovery and targeted realtime instead of polling
- avoid unnecessary GPS history writes
- do not introduce paid infrastructure without clear justification

These files are authoritative project rules.

## Frozen Business Behavior

For MVP product and business behavior, follow `docs/BUSINESS_RULES_FREEZE_V1.md`. Agents must not invent or alter frozen MVP rules without explicit product-owner approval; report any implementation conflict before proceeding.
