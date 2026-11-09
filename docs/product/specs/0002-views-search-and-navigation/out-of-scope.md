# Out of scope: Views, search and navigation

## Explicitly excluded

### Belongs to a sibling spec

- The task and list model, every invariant on it, and the task detail screen
  — **spec 0001**.
- Reminder scheduling, and the computation of recurring instances —
  **spec 0003**. Views *render* the next instance; they never compute it.
- Import, export and the import-review screen's contents — **spec 0004**.
  This spec owns only the fact that the review is a **route** (VSN-406).
- The splash and the startup coordinator. They exist and are unchanged; this
  spec only states where they hand off (VSN-402).

### Not in 3.1.0

| Item | Why |
|---|---|
| A calendar view | This is a list app. `due` is a deadline, not a time block, and nothing may derive an occupied range from `start` and `due` (spec 0001, TLD-302). A calendar is a different product. |
| User-defined smart lists / saved filters | `TaskQuery` is shaped so a saved filter is a persisted query rather than a redesign, but four fixed views are enough to be credible. |
| Natural-language search ("überfällig einkauf") | Plain substring matching plus explicit filter chips. A query language is a feature with its own spec. |
| Search across a shared or remote index | There is no network. |
| Bulk multi-select from a view | Deferred to 3.2 with the rest of the bulk actions. |
| Drag a task between lists from the list overview | Nice, and a whole gesture surface with its own accessibility obligations. 3.2. |
| A home-screen widget showing Heute | A second entry point with its own lifecycle and its own data path. 3.2. |
| Per-view custom colours or icons | Presentation churn for no user problem. |
| A fifth navigation destination | Four is what fits at 200 % text scale on a phone. Alle and Erledigt live in Heute's overflow (Q-2b). |
| Persisting the "Erledigt (n)" collapse state across restarts | Per session, per surface (Q-2g). |
| Sorting by created date or by updated date | Both are `DateTime` columns at second precision (KI-008) and would need their own tiebreak for no demonstrated need. |
| An "all tasks including completed" view | Alle is open tasks; Erledigt is completed. A merged view would need a third membership rule to explain itself. |

### Deliberately never in this app

- **Occurrence-based views.** A view here is a predicate over tasks. There is
  no occurrence, no occurrence key and no calendar projection —
  WasThereSomething product semantics that are never exported and never
  needed to read a document.
- **A view that mutates on read.** Nothing about opening a view may write:
  no "seen" flags, no auto-archiving, no auto-completion of overdue items.
- **Ordering by a timestamp alone.** Every ordering ends in a deterministic
  tiebreak. This is KI-008, and it is not a style preference.

## Possible future extensions

Each is a screen or a persisted query, not a migration:

- Saved filters (a persisted `TaskQuery`).
- FTS5 search, if the latency budget (VSN-308) is missed — this one *is* a
  schema change and is called out as such (Q-2i).
- A configurable Demnächst window.
- Bulk actions and drag-between-lists.
- A home-screen widget reading the same query layer.

## Scope boundaries for the implementing agent

When implementing a story derived from this spec, do **not**:

- Change anything under `apps/mobile_app/lib/features/todos/`. The demo keeps
  working until slice 13, which is a separate story.
- Add a table or a column. This spec adds **indexes and settings keys only**.
  An index is still a schema change and follows the migration rules in spec
  0001's `data-contract.md`.
- Build a second query path. All four views plus search go through one
  parameterized entry point (VSN-601). If a surface seems to need its own
  SQL, that is a finding to raise, not a shortcut to take.
- Call `DateTime.now()` inside a query, a predicate or a view model. `today`
  is injected from the existing `Clock` seam (Q-2k). This is what makes the
  membership rules testable.
- Order by a `DateTime` column without a further tiebreak (VSN-103, KI-008).
- Load a related table inside `asyncMap`. Join it, or the stream will not
  re-emit when it changes (VSN-602, KI-003).
- Copy a `go_router` snippet from WasThereSomething. This template pins **^14**
  against their **^17**, and the shell-route API moved across that range
  (Q-2m). Verify against the resolved version.
- Use `Navigator.push` with an anonymous route anywhere in the feature
  (VSN-403).
- Introduce a new dependency — including an FTS or search package. FTS5 is
  built into SQLite and would be reached through Drift, and only after the
  latency budget is actually missed.
- Weaken, skip or delete an existing test to make a suite pass.
- Add a fifth bottom-navigation destination.
