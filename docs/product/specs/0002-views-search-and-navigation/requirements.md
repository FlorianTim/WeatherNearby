# Requirements: Views, search and navigation

Requirement IDs use the prefix `VSN-`. Every id maps to at least one criterion
in `acceptance-criteria.md`.

Priority: **Must** = required for 3.1.0. **Should** = required unless a story
explicitly defers it with a recorded reason.

## A. View membership (VSN-0xx)

The rules below are the specification of each view. They are written as
predicates because they are implemented as one query layer and tested as
pure functions.

| Id | Requirement | Priority |
|---|---|---|
| VSN-001 | Every view excludes tasks with `deleted_at` set, tasks in an archived list, and tasks in a deleted list. | Must |
| VSN-002 | **Heute** contains a task when it is not completed **and** (`due_date_day <= today` **or** (`start_date_day <= today` and `start_date_day` is set)). A task with neither date is not in Heute's dated sections but appears in its "Ohne Datum" section (VSN-006). | Must |
| VSN-003 | A task whose `start_date_day` is in the future and whose `due_date_day` is null or in the future is **hidden** from Heute. This is the point of a start date and is asserted by test. | Must |
| VSN-004 | Heute groups into **Überfällig** (`due_date_day < today`), **Heute** (`due_date_day == today`, or started and not yet due), and **Ohne Datum**, in that order. | Must |
| VSN-005 | Overdue tasks are never hidden by a future `start`. A deadline that has passed outranks "do not show me this yet". | Must |
| VSN-006 | Heute's "Ohne Datum" section is collapsible and its state is persisted. It exists so Heute is usable as the single working surface, without forcing every task to carry a date. | Should |
| VSN-007 | **Demnächst** contains uncompleted tasks with `due_date_day` in `(today, today + 7]`, grouped by day, each day labelled with its weekday and date. | Must |
| VSN-008 | **Alle** contains every uncompleted task across every non-archived list. | Must |
| VSN-009 | **Erledigt** contains tasks with `progress = 'completed'`, most recently completed first, from the last 30 days, with an explicit control to load older ones. | Must |
| VSN-010 | `failed` and `cancelled` tasks appear in **Alle** and in their list, marked, and are not in Heute or Demnächst. They are not "completed". | Must |
| VSN-011 | A subtask is shown nested under its parent inside a list. In Heute, Demnächst, Alle, Erledigt and search results it may appear flat, and when it does the row names its parent. | Must |
| VSN-012 | "Today" is the device's local calendar day. It is recomputed on app resume and when the day changes while the app is open. | Must |
| VSN-013 | Recurring tasks are rendered as their next due instance; instance computation belongs to spec 0003 and views consume it. An instance with an `excluded` override is not shown. | Must |

## B. Sort and group (VSN-1xx)

| Id | Requirement | Priority |
|---|---|---|
| VSN-101 | Sort options are: manual (`sort_order`), due date, priority, title. Available on list detail and on Alle. | Must |
| VSN-102 | Manual sort is offered only where it is meaningful — on a list detail, not on a cross-list view. Offering it on Heute would imply an order the model does not store. | Must |
| VSN-103 | **Every** ordered query has a deterministic tiebreak (`jscalendar_uid`). No query orders by a `DateTime` column alone — KI-008. | Must |
| VSN-104 | Sorting by due date places tasks without a due date **last**, not first, and not interleaved as if they were due at epoch zero. | Must |
| VSN-105 | Sorting by priority orders 1 (highest) to 9 (lowest) and places 0 (undefined) **last**. The stored inversion is never visible. | Must |
| VSN-106 | Sorting by title uses a locale-aware, case-insensitive comparison for the active locale, not a byte comparison. | Should |
| VSN-107 | Group options are: none, list, priority, due date. Group headers carry a count. | Should |
| VSN-108 | The sort and group choice is persisted **per surface** through the `SettingDef` register, so a choice on one list does not silently change another. | Must |
| VSN-109 | Reordering manually is possible only while sort is set to manual. Any other sort disables the drag handle and says why on long-press. | Must |

## C. Completed-task visibility (VSN-2xx)

| Id | Requirement | Priority |
|---|---|---|
| VSN-201 | A task completed in the current session stays visible in place, struck through, for at least 5 seconds, so completing it reads as progress rather than as deletion. | Must |
| VSN-202 | After that, completed tasks collapse into a per-surface "Erledigt (n)" section that is collapsed by default and expandable. | Must |
| VSN-203 | Completed tasks are never removed automatically from the database. Visibility is a display policy, never a lifecycle (spec 0001, TLD-210). | Must |
| VSN-204 | Un-completing a task returns it to its normal position under the active sort, without a reload. | Must |

## D. Search (VSN-3xx)

| Id | Requirement | Priority |
|---|---|---|
| VSN-301 | Search matches case-insensitive substrings in `title` and in `description_markdown`. | Must |
| VSN-302 | Results indicate **why** a task matched — title or notes — and show a short excerpt around the match when it was the notes. | Should |
| VSN-303 | Search can be narrowed by list and by tag, combinable, and the active filters are visible as removable chips. | Must |
| VSN-304 | Search includes completed tasks and marks them; it excludes trashed tasks and tasks in archived lists. | Must |
| VSN-305 | Search results update as the user types, debounced, and the input never blocks on a query. | Must |
| VSN-306 | An empty query shows the filters and recent searches, not the whole database. | Should |
| VSN-307 | Search terms are **never** logged or persisted beyond the in-memory recent-searches list, which is cleared with "Alle Inhalte löschen". They are personal free text. | Must |
| VSN-308 | Search over 2 000 tasks returns first results within 150 ms on a mid-range device, measured once and recorded. If a `LIKE` scan cannot hold that, an FTS index is added — the requirement is the latency, not the mechanism. | Should |

## E. Navigation (VSN-4xx)

| Id | Requirement | Priority |
|---|---|---|
| VSN-401 | Bottom navigation has exactly four destinations: **Heute**, **Listen**, **Suche**, **Mehr**. | Must |
| VSN-402 | Heute is the app's landing screen after the splash and after a successful startup. | Must |
| VSN-403 | Routes are declared in `AppRoutes` and built with `go_router`, matching the template's existing router structure. No `Navigator.push` with an anonymous route anywhere in the feature. | Must |
| VSN-404 | Every screen that shows a task has a stable deep-link route: `/tasks/:id` for a detail, `/lists/:id` for a list detail. | Must |
| VSN-405 | Opening a task from a notification produces a back stack that leads to Heute, not to a dead end that exits the app on back. | Must |
| VSN-406 | The import review (spec 0004) is a route, not an anonymous dialog, so a process restart during review cannot leave the app in an unreachable state. | Must |
| VSN-407 | Each bottom-navigation destination keeps its own navigation state while the app runs. Switching tabs does not reset a list's scroll position. | Should |
| VSN-408 | A deep link to a task that no longer exists shows a readable "nicht gefunden" screen with a way back, never an exception and never a blank page. | Must |
| VSN-409 | "Mehr" hosts settings, tags, trash, archive, about and licenses. It is a hub, not a screen with its own content. | Must |

## F. Empty and loading states (VSN-5xx)

| Id | Requirement | Priority |
|---|---|---|
| VSN-501 | Every view has a distinct empty state naming what is empty and offering the one useful action. A shared "keine Daten" is not acceptable. | Must |
| VSN-502 | An empty Heute with tasks elsewhere says so ("Nichts für heute. 12 Aufgaben ohne Datum."), so the user does not think the app lost their data. | Must |
| VSN-503 | While data loads, the previous content stays and the add affordance stays usable. No full-screen spinner on a surface that has shown content before. | Must |
| VSN-504 | A query failure shows a reason code and a retry, never a stack trace, and records the error in the existing last-error buffer. | Must |

## G. Query layer (VSN-6xx)

| Id | Requirement | Priority |
|---|---|---|
| VSN-601 | All four views are expressed through **one** parameterized query layer (`TaskQuery`: view, list filter, tag filter, search term, sort, group). Four hand-rolled queries are not acceptable, because four is where they drift. | Must |
| VSN-602 | Every stream joins every table the emitted object depends on. Loading tags or a parent title inside `asyncMap` is forbidden — KI-003. | Must |
| VSN-603 | View membership predicates are pure functions over a task's fields plus "today", unit-testable without a database, and are the same functions the SQL is derived from or asserted against. | Must |
| VSN-604 | Queries are indexed: `(list_id, sort_order)`, `due_date_day`, `start_date_day`, `deleted_at`, `parent_task_id`. Adding an index is a schema change and follows the migration rules. | Must |
| VSN-605 | No view performs an N+1 read. A view showing 200 tasks with their tags issues a bounded number of queries, asserted by a query-count test. | Should |

## Quality requirements

- **Accessibility** (contract `07-accessibility.md`): group headers are
  announced with their counts as sentences ("Überfällig, 2 Aufgaben"); the
  bottom navigation destinations carry localized labels; every surface is
  tested at `TextScaler.linear(2.0)`; sort and group controls are reachable
  without a gesture.
- **Localization**: German and English, including weekday and date formatting
  through `intl` for the active locale — never a hand-built date string.
- **Performance**: Heute renders within one frame budget for 2 000 tasks;
  scrolling a list of 2 000 tasks does not drop frames; a write to an
  unrelated table does not re-emit a view's stream.

## Constraints

- `go_router` is **^14** in this template, against ^17 in WasThereSomething.
  The routing APIs differ; reuse reasoning, never snippets.
- Providers are generated with `riverpod_annotation` ^3. The generator API
  differs from WasThereSomething's ^4.
- Long lists must be tested on a tall viewport
  (`tester.view.physicalSize = const Size(1080, 3600)`) because lazy
  `ListView`s do not build offscreen children — KI-005.
- The bottom navigation bar swallows taps on edge-visible targets in widget
  tests: unfocus, then drag the scrollable, then tap — KI-005.

## Data requirements

No new tables. This spec adds **indexes** and **settings keys** only; see
`data-contract.md`.

## Privacy / Security considerations

- Search terms are personal free text (VSN-307): never logged, never
  persisted to disk, cleared with app content.
- No view or search surface may render a task body into a log line, a
  screenshot taken by tooling, or an error report.
- Deep links are internal only. The app registers no `http`/`https` app link
  for task routes in 3.1.0; the only external entry points are the share
  intent (spec 0004) and a notification (spec 0003).

## Testability notes

Automated: all of sections A–G. View membership (VSN-002..013) is the highest
value and cheapest to test, because the predicates are pure.

Manual: the perceived behaviour of VSN-201 (completed task lingering), the
midnight rollover (VSN-012), and the notification back stack (VSN-405) on a
real device.

## Traceability

Every requirement maps to a criterion in `acceptance-criteria.md`.
