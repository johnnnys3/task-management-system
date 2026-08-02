# 0001 — Store modules for Firestore collections

## Status

Accepted

## Context

Task data access originally had four independent paths into the `tasks` Firestore collection: a thin `TaskService`, a richer `TaskDatabase`, and raw `FirebaseFirestore` calls embedded directly in two screens. No single seam existed to test or reason about task data access, and validation rules were duplicated (and could drift) across paths.

This was collapsed into `TaskStore` — one module, one interface, one seam — with a Firestore adapter (the old `TaskDatabase`, gutted in place) and an in-memory adapter for tests.

Project data access independently arrived at the same shape of problem: five paths into the `projects` collection (`ProjectService`, `ProjectDatabase`, raw Firestore in two screens, plus a lookup in `TaskCreationScreen`) — worse than tasks, since two of those paths were both plausible "correct" abstractions, and one (`ProjectService.getProjects`) silently discarded real Firestore data on every read. The same consolidation — `ProjectStore` — was applied.

Two independent instances of the same shape is the signal this is a pattern for the codebase, not a one-off fix.

## Decision

Every Firestore collection gets exactly one `*Store` module. Screens and providers never call `FirebaseFirestore` directly, and never call a legacy `*Database`/`*Service` class directly — they call the `*Store` module only.

A `*Store` module:

- Has a narrow interface: `create`, `update`, `delete`, `fetch`, `stream` — never one method per query shape (e.g. no `fetchTasksForUser` alongside `fetchTasksByStatus`). Whether `fetch`/`stream` take query parameters (`TaskStore`) or return everything for the caller to filter locally (`ProjectStore`) is a per-`Store` choice, made on the size of the collection and the number of distinct query shapes callers need — not a requirement of the pattern. The requirement is one seam, not identical method signatures.
- Delegates validation to the corresponding model's `validate()` method (e.g. `Task.validate()`, `Project.validate()`), called once inside `create`/`update`. Validation is never duplicated in callers.
- Sits behind a seam with two adapters: a Firestore adapter (built by gutting the existing legacy database class in place — no new wrapper layer) and an in-memory adapter used only in tests.
- Is registered via `Provider` at the app root; callers obtain it with `context.read<XStore>()`, never a global singleton.
- Any thinner, duplicate legacy access class (a `*Service`) is deleted outright once its callers migrate — it carries no logic worth preserving beyond what the `*Store` now provides.

## Consequences

- Firestore collections without a `*Store` yet (e.g. `teams`) are known technical debt, not an oversight — they follow this ADR when they're picked up, without re-litigating the shape.
- New collections should be given a `*Store` from the start rather than a screen-local or ad-hoc service.
- Migrations onto this pattern are expected to surface latent bugs from duplicated validation (as it did for both tasks and projects) — that's expected, not a sign the migration went wrong.
