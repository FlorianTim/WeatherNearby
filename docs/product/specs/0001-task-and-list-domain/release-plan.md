# Release plan: Task and list domain

## Target release

Template **3.1.0**. Roadmap lane: `now`.

## Phases

This spec is delivered by slices 2 to 4 of
`docs/delivery/implementation-plans/0001-todo-reference-app.md`, plus the
slice-10 tail. Each slice is one shippable, reviewable change.

| Phase | Slice | Delivers | Schema |
|---|---|---|---|
| 1 | **2 — data layer** | `lists`, `tags`, `tasks`, `task_tags`, `task_links`; repositories; tree safety; ordering; converters; migration fixture test. **No UI.** | v1 → v2 |
| 2 | **3 — lists and tasks** | Inbox seeding, list CRUD, task CRUD, checkbox, manual reorder, swipe actions with menu equivalents, undo | — |
| 3 | **4 — task detail** | Markdown notes, dates, priority, subtasks, tags, links, the five-value progress picker | — |
| 4 | **10 — trash and archive** | Soft delete, trash screen, restore, 30-day purge, list archive | — |

Slice 2 having no UI is deliberate: the invariants (tree safety, ordering,
transactions, the migration chain) are what must be right, and they are
reviewable against tests alone.

## Dependencies

**Blocking, upstream:**

- **Slice 0 — shared foundations.** This spec depends on the Markdown editor
  and renderer (TLD-104), the snackbar/undo helper (TLD-901), the
  scheme-allowlisted URL seam (TLD-705), the `Uuid4` helper (TLD-002) and the
  epoch-day / minute-of-day converters (TLD-303). None of them exists in the
  template today. Slice 2 can start on the converters alone; slices 3 and 4
  cannot start before slice 0 is merged.

**Blocking, downstream — this spec blocks:**

- spec 0002 (views) — needs the tables and the repositories.
- spec 0003 (reminders and recurrence) — needs `tasks` and the date columns.
- spec 0004 (interoperability) — needs the persistence target and the
  invariants the import path must respect (TLD-1007).

**Not a dependency:** `task_interchange` (`flutter-libraries`, ADR-0017) (slice 1). It is pure Dart
with no database, so slices 1 and 2 can proceed in parallel.

**External:** none. No backend, no network, no service.

## Rollout notes

- **No feature flag.** `packages/feature_flags` exists, but flagging
  scaffolding that is not yet routed into the navigation would be ceremony
  (Q-1n). The new feature becomes reachable when slice 3 has something to
  show.
- **The demo stays live throughout.** `features/todos/` keeps its route, its
  table, its startup task and its l10n keys until slice 13. Nothing in this
  spec may touch it.
- **Both features coexist in the database.** `todo_items` and `tasks` are
  independent tables; v2 is purely additive.

## Migration notes

Full design in `data-contract.md` section 4.

- **Schema step:** v1 → v2, additive only (`createTable`, `createIndex`).
  No table is rebuilt.
- **No data migration from the demo.** `todo_items` rows are not carried into
  `tasks`, deliberately: nobody has data there, and the status vocabularies do
  not correspond (`pending` is not `needs-action`). Writing a mapping would
  encode a wrong equivalence in a file that reads as authoritative.
- **Fixture test required for the step** (database-contract rule 3): a raw-SQL
  snapshot of v1 with seeded rows, opened at v2, asserting the old rows are
  intact, the new tables exist and `user_version` is correct.
- **Inbox seeding** happens in `onCreate` *and* in the v1 → v2 upgrade, so a
  database that already exists gets an Inbox. The seeding is idempotent and
  guarded by the partial unique index.
- **No breaking change** for anything outside this app.

## Validation

A phase is done when all of the following hold:

1. Every `Must` requirement of the phase's sections has a passing test at the
   level named in `acceptance-criteria.md`.
2. `scripts/dev/quality_gate.sh` is green: format check, analyze, tests.
3. `melos run codegen` produces no diff — generated output is committed and CI
   fails on drift.
4. The migration fixture test for the phase's schema step passes, including
   the chained case.
5. The three accessibility tests (row, detail, list overview) pass at
   `TextScaler.linear(2.0)`, and the swipe-alternative test passes.
6. `flutter test` shows no new skipped or weakened test.
7. The demo still builds, still routes and its tests still pass.
8. Manual verification steps from `acceptance-criteria.md` have been walked
   once on a device, and the result is recorded in the PR — including
   anything that could not be run.

## Risks

| Risk | Mitigation |
|---|---|
| Slice 0 slips and blocks slices 3 and 4 | Slice 2 depends only on the converters; sequence them first inside slice 0 |
| The composed-stream trap (KI-003) surfaces as "stale UI" late | AC-50 is written as a regression guard before the first composed stream exists |
| A story quietly puts a shared widget in `features/tasks/` | Called out in `out-of-scope.md` and in the story template's review checklist |
| Adding a dependency drags the KI-001 analyzer ceiling | No new dependency in this spec at all; the ones 3.1.0 needs are pre-decided in ADRs |
| The demo breaks while the new domain grows beside it | Its tests stay in the suite and are part of the phase-done criteria (validation 7) |
