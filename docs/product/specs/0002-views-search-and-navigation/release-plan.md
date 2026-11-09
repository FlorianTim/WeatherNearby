# Release plan: Views, search and navigation

## Target release

Template **3.1.0**. Roadmap lane: `now`.

## Phases

Delivered by slices 5 and 10 of
`docs/delivery/implementation-plans/0001-todo-reference-app.md`, with the
navigation shell pulled forward into slice 3 because every other screen needs
somewhere to live.

| Phase | Slice | Delivers | Schema |
|---|---|---|---|
| 1 | **3 (tail)** | The four-destination shell, `AppRoutes` entries, `/tasks/:id` and `/lists/:id`, the not-found screen | — |
| 2 | **5 — views** | `TaskQuery`, the membership predicates, Heute, Demnächst, Alle, Erledigt, sort, group, completed-task visibility, the indexes | index-only |
| 3 | **10 — search** | Search over titles and notes, list and tag filters, recent searches, the latency measurement | index-only |

Slice 5 is where the KI-008 and KI-003 traps get their regression guards, and
where the `viewMatrix` fixture is written. Both are cheap there and expensive
later.

## Dependencies

**Blocking, upstream:**

- **Spec 0001, slice 2 (data layer)** — the tables, the repositories and the
  converters. Nothing here can start before those exist.
- **Spec 0001, slice 3 (lists and tasks)** — the task row widget and the list
  detail, which the views reuse rather than reimplement.
- **Slice 0 (shared foundations)** — the snackbar/undo helper, used by the
  completed-task linger (VSN-201) and by every destructive action reachable
  from a view.

**Soft, resolvable in either order:**

- **Spec 0003 (recurrence)** — VSN-013 says views render the next instance of
  a recurring task. Until slice 7 exists, a recurring task renders as its
  stored `due`, which is the correct first instance anyway. No rework, just a
  narrower behaviour.

**This spec blocks:**

- Spec 0003's notification tap target (VSN-405 needs `/tasks/:id`).
- Spec 0004's import review, which is a route (VSN-406).

**External:** none.

## Rollout notes

- **No feature flag.** The views become reachable as they are built. Alle and
  Erledigt live in Heute's overflow from the start, so no navigation change is
  needed when they arrive.
- **The demo keeps its route.** `AppRoutes.todos` and `/todos/:id` stay
  registered until slice 13. The new shell adds routes; it removes none.
- **Landing screen changes twice.** Today the router goes to
  `AppRoutes.settings` after startup. Slice 3 points it at Heute (VSN-402).
  That is a one-line change and it is called out because the startup and
  splash tests assert the destination.

## Migration notes

- **No `schemaVersion` bump owned by this spec.** The indexes in
  `data-contract.md` 1.4 are created in the step that creates their tables
  (v2 for the task indexes, v4 for the recurrence-related one), so this spec
  contributes no migration of its own.
- **Should an index arrive after its table** — for example if the Erledigt
  index is added in slice 5 rather than slice 2 — it is a normal additive
  step with its own `schemaVersion` bump and its own fixture test. It is not
  exempt because it is "only an index".
- **Settings keys** are additive by construction: an absent key reads as its
  default, and `SettingDef.decode` must not throw on a value written by a
  newer version.
- **FTS5, if it ever happens** (Q-2i), *is* a schema change with a virtual
  table and trigger maintenance. It is deliberately not taken pre-emptively.

## Validation

A phase is done when all of the following hold:

1. Every `Must` requirement in the phase's sections has a passing test at the
   level named in `acceptance-criteria.md`.
2. The full `viewMatrix` fixture passes against **both** the pure predicates
   and the SQL path, and the two agree (AC-38).
3. `EXPLAIN QUERY PLAN` for Heute and for a list detail shows an index scan,
   not a full table scan (AC-40).
4. The determinism test (AC-11) passes over 100 repeated reads.
5. The KI-003 regression guard (AC-37) passes for tags **and** for a parent
   title.
6. `scripts/dev/quality_gate.sh` is green, and `melos run codegen` produces
   no diff.
7. Accessibility: Heute, a list detail and search pass at
   `TextScaler.linear(2.0)` on a phone-sized surface, and group headers are
   announced as counted sentences.
8. The latency measurement (AC-25) has been run on a named device and the
   number is recorded in the PR — including if it was missed.
9. The demo still builds, still routes and its tests still pass.
10. Manual steps from `acceptance-criteria.md` walked once, with anything not
    run stated explicitly.

## Risks

| Risk | Mitigation |
|---|---|
| Four views drift into four query paths | VSN-601 plus AC-36, which greps the sources rather than trusting discipline |
| Non-deterministic ordering ships and looks like "random reshuffles" | AC-11 written before the first sort exists; every ordering in `data-contract.md` 1.3 already spells out its tiebreak |
| Stale views after a tag or parent edit (KI-003) | AC-37 as an explicit regression guard, written with the first composed stream |
| `go_router` ^14 vs ^17 API drift on shell routes | Q-2m makes it an explicit verification step; no snippet is copied |
| The midnight timer trips flutter_test's pending-timer invariant (KI-005) | Timer cancelled on dispose; the widget test asserts no pending timer |
| Search latency misses the budget late | AC-25 measures and records rather than gating, so a miss is visible early and FTS5 becomes a decision with evidence |
| Long-list widget tests silently pass because offscreen children never build (KI-005) | Tall viewport mandated in the constraints; the fixture is 2 000 rows |
