---
name: fast-execution
description: Optimize engineering work for the fastest safe implementation with minimal, targeted verification and no redundant checks.
---

# Fast Execution

Apply this skill to implementation, debugging, integration, migration, UI, backend, and similar engineering work.

## Priority and Workflow

Treat time as a first-class constraint. Optimize for useful progress per minute while preserving verification that materially reduces risk.

Use this default wave:

```text
inspect only what is needed
→ implement a meaningful unit of work
→ targeted verification once
→ continue
```

Do not optimize for the appearance of thoroughness. Do not stop after trivial edits; stop at a completed checkpoint, a genuine blocker, a required approval, or an explicit stop condition.

## Inspection

- Read only files relevant to the current task.
- Do not repeatedly inspect or audit the whole repository.
- Do not re-audit accepted milestones unless the current change can affect them.
- Respect `PRODUCT.md`, `DESIGN.md`, `DECISIONS.md`, `AGENTS.md`, and project requirements.
- Do not reopen settled decisions without a genuine conflict, security issue, or blocker.

## Tool and Dependency Discipline

- Choose the most direct available tool for each concern and stay with it.
- Switch between plugin, CLI, HTTP, or temporary harness only when the selected path is genuinely blocked.
- Run `flutter pub get` only when a Flutter `pubspec.yaml` or dependency version changed, or dependency resolution is broken.
- Install Node dependencies only when package manifests or lockfiles require it.

## Targeted Verification

- Verify the smallest affected scope; do not automatically run full-project checks.
- Run `flutter analyze` only for affected apps/packages, once after the meaningful implementation wave.
- Run tests only for changed business/security logic, a fixed bug, an unverified feature, or a prior failure; prefer targeted tests.
- Do not lint/build an unchanged Dashboard.
- Do not reverify unchanged database foundation.
- Documentation-only changes require no code tests, analysis, builds, or database checks.

## Repeated Commands

Never repeat the same verification command unless its previous run failed and relevant code/configuration was changed to fix that failure. If an unaffected area was already verified, report:

> Previously verified — not rerun because current changes do not affect it.

Before every command, ask:

1. Is it required for the current checkpoint?
2. Has it already passed?
3. Did relevant code change?
4. Will it materially reduce risk?
5. Is there a faster targeted check?

Skip low-value commands.

## Critical Safety Checks

Do not skip meaningful targeted verification for:

- RLS, authorization, or privilege escalation
- atomic database functions or concurrency
- order state transitions
- destructive or production migrations
- irreversible data operations
- payment or commission calculations
- production deployment changes

Run the minimum verification needed to prove the critical behavior, without unrelated regression suites.

## Execution Waves

Group tightly related work and verify it together. For example:

```text
Auth Service + Auth State + Router Protection
→ targeted auth verification
→ checkpoint
```

Do not operate as one wave per enum, file, or provider.

## Avoid Over-Engineering

Add only architecture, packages, abstractions, services, or future features that directly complete the current checkpoint. Defer speculative microservices, layers, code generation, networking wrappers, extra state management, caching, background services, analytics, and future product features.

## Documentation and UI

- Keep completion reports short and update existing progress/decision files briefly when needed.
- Do not duplicate specifications, rewrite approved documents, or maintain conflicting status documents.
- When `DESIGN.md` or a design system exists, reuse its tokens, components, patterns, and layouts.
- Do not polish unrelated UI while backend/core work is the active checkpoint.

## External Services and Git

- Before external-service work, confirm the environment, available connected tool, required settings, and one usable verification path.
- Use one stable integration path instead of repeated experiments.
- Use Git checkpoints after meaningful execution waves; do not create tiny or unnecessary commits, but do not leave major completed waves permanently untracked when the workflow permits a checkpoint.

## Reporting

Prefer:

```text
Implemented:
- ...

Verified:
- ...

Not rerun:
- ...

Blockers:
- ...

Next:
- ...
```
