# Release plan: Reminders and recurrence

## Target release

Template **3.1.0**. Roadmap lane: `now`.

## Phases

Delivered by slices 6 and 7 of
`docs/delivery/implementation-plans/0001-todo-reference-app.md`.

| Phase | Slice | Delivers | Schema |
|---|---|---|---|
| 0 | **6 (spike)** | A time-boxed spike on the background-action isolate before any story: prove that a notification action can append a record and be drained, with the app killed, on a real device | — |
| 1 | **6 — reminders** | `NotificationGateway` + fake, the concrete permission gateway, `reminders` table, scheduling, reconciliation, the two actions, the pending-action queue | v2 → v3 |
| 2 | **7 — recurrence** | Parser and expander in `task_interchange` (`flutter-libraries`, ADR-0017), `task_recurrence_overrides`, instance handling, completion mode, the recurrence editor with preview | v3 → v4 |

**Phase 0 is not optional.** ADR-0012 decision 4 is a design chosen to avoid a
trap that WasThereSomething flagged and did not resolve, and the whole
background half rests on it. A spike that proves the append-and-drain path on
a real device costs a day; discovering it does not work after the reminder UI
is built costs the slice.

Reminders before recurrence (Q-3q): reminders are the more valuable half and
the harder boundary, and recurrence without reminders is far less useful than
the reverse.

## Dependencies

**Blocking, upstream:**

- **Spec 0001, slice 2 (data layer)** — `tasks` with its date columns and the
  epoch-day/minute converters. `reminders` has a foreign key to `tasks`.
- **Spec 0001, slice 4 (task detail)** — the reminder and recurrence editors
  live inside it.
- **Slice 0 (shared foundations)** — the snackbar/undo helper.
- **Spec 0002, slice 3 (navigation shell)** — `/tasks/:id` must exist before a
  notification can deep-link to it (RRC-407).
- **`task_interchange` (`flutter-libraries`, ADR-0017), slice 1** — the recurrence parser and
  expander live there (RRC-504). Slice 7 cannot start before slice 1 has the
  rule model; slice 6 does not depend on it at all.

**External:**

- Two new dependencies, `flutter_local_notifications` and `timezone`,
  justified in ADR-0012. Both must be resolved against the KI-001 tree
  **before** adoption, and `timezone`'s constraint recorded per KI-009(a).
- A real Android device for the manual verification steps. Neither delivery,
  nor reboot survival, nor a time-zone change can be asserted in
  `flutter test`.

**This spec blocks:** nothing. Spec 0004 is independent of it.

## Rollout notes

- **No feature flag.** The reminder section simply appears in the task detail
  when slice 6 lands.
- **The demo is untouched** throughout. It has no reminders and no recurrence.
- **The permission is never requested until a user sets a reminder**, so
  installing 3.1.0 changes nothing for a user who does not use the feature.
- **Web degrades, it does not break** (RRC-007): reminders are stored, the
  gateway is a no-op, and the UI says so. The web build must keep passing CI.
- **Manifest additions** (`BOOT_COMPLETED`, whatever the plugin requires) go
  through the bootstrap patcher (ADR-0013, Q-3h). A reviewer must check the
  **generated** manifest, not a committed file — there is none.

## Migration notes

Full design in `data-contract.md` section 4.

- **v2 → v3** — `createTable reminders` + its index. Additive.
- **v3 → v4** — `createTable task_recurrence_overrides` + its unique index.
  Additive.
- Neither step rebuilds a table, so the `TableMigration.newColumns` trap
  (database-contract rule 2) does not apply — but if a rebuild ever becomes
  necessary, every column added by a later migration must be listed.
- **The recurrence columns on `tasks` are created in v2**, with the table,
  before any UI exists for them. Deliberate: a model-only column costs
  nothing now and would be a migration later.
- **A fixture test per step** (database-contract rule 3): a raw-SQL snapshot
  of the previous version with seeded rows, opened at the new version,
  asserting the old rows are intact and `user_version` is correct — plus the
  chained v2 → v4 case.
- **The pending-action store is versioned independently** of the domain
  `schemaVersion`. That independence is the point of separating it, and it
  means the store can be cleared on a version mismatch without touching user
  data.
- **No data migration.** Both tables start empty.

## Validation

A phase is done when all of the following hold:

1. Every `Must` requirement in the phase's sections has a passing test at the
   level named in `acceptance-criteria.md`.
2. The import-scanning test passes: exactly one file imports
   `flutter_local_notifications` (AC-01), and no test constructs the real
   gateway (AC-02).
3. The background-path assertion passes: no Drift domain database, Riverpod
   container or repository is constructed anywhere in the action handler's
   call path (AC-22).
4. Reconciliation converges from all three starting states, and the converged
   case issues **zero** gateway calls (AC-18).
5. The DST property test (AC-16) and the floating-versus-zoned test (AC-17)
   pass.
6. The full `ruleMatrix` fixture passes, including the four rejection cases
   and the two calendar-correctness cases (AC-28, AC-40).
7. The generated `AndroidManifest.xml` after a bootstrap contains no exact-alarm
   permission (AC-03), and the bootstrap patcher works on **both** the bash and
   the PowerShell path.
8. `scripts/dev/quality_gate.sh` is green; `melos run codegen` produces no
   diff.
9. No widget test leaves a pending timer (KI-005).
10. Accessibility: the reminder section and the recurrence editor pass at
    `TextScaler.linear(2.0)`, and the seven weekday toggles are still 48 dp.
11. The seven manual verification steps have been walked on a named device and
    the results recorded in the PR — **including anything that could not be
    run**.

## Risks

| Risk | Mitigation |
|---|---|
| The background-isolate design does not survive contact with a real device | Phase 0 spike, before any story. This is the single biggest unknown in 3.1.0. |
| Eventual consistency of "Erledigt" reads as a bug | Stated in ADR-0012, surfaced in AC-23 and in the UX copy (RRC-408), and in the manual test plan — so it is a known behaviour rather than a discovery |
| `timezone` conflicts transitively (KI-009a) | Nothing else in the tree depends on it today; resolve before adoption and record the constraint |
| Reminders silently lost past the scheduling horizon | RRC-305 makes the horizon explicit and bounded; AC-19 asserts it; Q-3i flags that 60 days is a guess to be measured |
| A reminder never fires because scheduling failed once | Per-item failure isolation (RRC-306) plus reconciliation on every start; the row shows a retry |
| DST or time-zone arithmetic done through an instant | AC-16 is a property test over a full year around a transition, written before the scheduling code |
| A notification keeps arriving in the old language after a locale change | Reconciliation re-runs on locale change, re-rendering scheduled notifications (see `ux.md`, Localization) |
| The manifest patcher drifts between bash and PowerShell | Both paths are part of validation item 7; a generated-manifest grep after bootstrap catches it on a machine that runs one |
| Expansion of an unbounded rule hangs the UI | RRC-605 makes an unbounded call not compile, rather than relying on discipline |
