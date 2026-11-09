# Data contract: Views, search and navigation

This spec adds **no tables and no columns**. It adds indexes, settings keys,
a query abstraction and a fixture set. The task and list schema is spec 0001's
`data-contract.md`, which stays authoritative.

---

## 1. Data structures

### 1.1 The query abstraction

All four views plus search go through one parameterized entry point
(VSN-601). Four hand-rolled queries is where they drift.

```dart
enum TaskView { heute, demnaechst, alle, erledigt, list, search }
enum TaskSort { manual, due, priority, title }
enum TaskGroup { none, list, priority, due }

final class TaskQuery {
  final TaskView view;
  final String? listId;        // list view, or a search filter
  final Set<String> tagIds;    // search filter
  final String? searchTerm;    // search only
  final TaskSort sort;
  final TaskGroup group;
  final int today;             // epoch day, injected — never DateTime.now()
}
```

`today` is a **parameter**, not a call to the clock inside the query. That is
what makes VSN-002..VSN-005 unit-testable without a database and what makes
the midnight rollover (VSN-012) a matter of re-issuing the query rather than
of praying that a cached value refreshed.

### 1.2 Membership predicates

Each view is a pure predicate over a task record plus `today`. The SQL is
derived from these and asserted against them over the `viewMatrix` fixture
(VSN-603, AC-38).

```text
visible(t)        := t.deletedAt == null
                     && !t.listArchived && !t.listDeleted

open(t)           := t.progress != completed
                     && t.progress != failed
                     && t.progress != cancelled

started(t)        := t.startDay == null || t.startDay <= today
overdue(t)        := t.dueDay != null && t.dueDay < today
dueToday(t)       := t.dueDay == today

heute(t)          := visible(t) && open(t)
                     && (overdue(t) || dueToday(t)
                         || (t.startDay != null && started(t)))
heuteGroup(t)     := overdue(t)          -> ueberfaellig
                     dueDay == today     -> heute
                     dueDay == null      -> ohneDatum

demnaechst(t)     := visible(t) && open(t)
                     && t.dueDay != null
                     && t.dueDay > today && t.dueDay <= today + 7

alle(t)           := visible(t) && t.progress != completed

erledigt(t)       := visible(t) && t.progress == completed
```

Two consequences worth stating, because both are easy to get subtly wrong:

- `heute` deliberately admits a task whose `start` has arrived even when it
  has **no** due date. That is what a start date is for: "let me see this from
  Monday". It lands in the `heute` group, not in `ohneDatum`.
- `overdue` is evaluated **before** `started`, so a passed deadline is never
  suppressed by a future start (VSN-005).

### 1.3 Ordering, spelled out

Every ordering ends in `jscalendar_uid` (VSN-103). Drift stores `DateTime` at
second precision, so two rows written in the same second tie and the order is
otherwise non-deterministic — KI-008.

| Sort | ORDER BY |
|---|---|
| manual | `sort_order ASC, jscalendar_uid ASC` |
| due | `due_date_day IS NULL ASC, due_date_day ASC, due_minutes IS NULL ASC, due_minutes ASC, jscalendar_uid ASC` |
| priority | `CASE priority WHEN 0 THEN 10 ELSE priority END ASC, jscalendar_uid ASC` |
| title | `title COLLATE <locale-aware> ASC, jscalendar_uid ASC` |

- **due**: `IS NULL ASC` puts undated last (VSN-104). A task dated but
  timeless sorts before a timed task on the same day.
- **priority**: the `CASE` maps undefined (0) to 10 so it sorts after 9,
  without ever showing a number to the user (VSN-105).
- **title**: SQLite's default `NOCASE` is ASCII-only and would sort "Äpfel"
  after "Zebra". Either sort in Dart with `intl`'s collation for the active
  locale, or register a custom collation — the requirement is the behaviour
  (VSN-106), and the choice is recorded in `open-questions.md` as Q-2c.

### 1.4 Indexes

No new tables, but this spec is the reason several indexes exist. Adding one
is a schema change and follows the migration rules in spec 0001.

| Index | Serves |
|---|---|
| `(list_id, sort_order)` | list detail in manual order |
| `due_date_day` | Heute, Demnächst, sort by due |
| `start_date_day` | the Heute start-date predicate |
| `deleted_at` | the `visible` predicate on every view |
| `parent_task_id` | nesting inside a list |
| `(progress, progress_updated_at)` | Erledigt, recent-first |

`EXPLAIN QUERY PLAN` for Heute and for a list detail is asserted to use an
index rather than a full scan (AC-40).

### 1.5 Settings keys

Added to the existing `AppSettings` register in `core/settings/`, so they stay
enumerable (VSN-108).

| Key | Type | Default | Notes |
|---|---|---|---|
| `view.sort.<surfaceId>` | `TaskSort` | `manual` for a list, `due` for Alle | `surfaceId` is `list:<id>` or `view:alle` |
| `view.group.<surfaceId>` | `TaskGroup` | `none` | |
| `view.heute.undatedCollapsed` | `bool` | `false` | VSN-006 |

The enum **name** is persisted, never its index — a reordered enum must not
change what a stored value means. This is the register's existing rule and
`SettingDef.decode` must not throw: an unusable value degrades to the default.

Recent searches are **in-memory only** (VSN-307) and get no settings key.

---

## 2. API contracts

Not applicable. No backend, no endpoint, no entry in `docs/api/openapi.yaml`.

---

## 3. Export / import formats

None. Views, sort choices, group choices and search terms are app-local
presentation state. They are **never** emitted into an interchange document
(spec 0001, TLD-804), and `sort_order` in particular is app-local by contract.

A future backup file would include the settings keys above, under its own
`formatVersion`, independent of `schemaVersion`.

---

## 4. Versioning

No `schemaVersion` bump is owned by this spec. The indexes in 1.4 are created
in the schema step that creates their tables (v2 for the task indexes, v4 for
the recurrence-related ones), so this spec adds no migration of its own.

Settings keys are versioned by their `decode` implementation: a key written
by a newer app version that this version cannot parse degrades to the default
rather than throwing.

---

## 5. Compatibility notes

- **KI-008 (second precision)** — the reason every ordering in 1.3 ends in
  `jscalendar_uid`. Erledigt orders by `progress_updated_at` and would
  otherwise be non-deterministic for tasks completed in the same second.
- **KI-003 (composed streams)** — a view row carries tags and, when shown
  flat, its parent's title. Both must be **joined**, not loaded inside
  `asyncMap`, or writes to `task_tags` and to the parent will not refresh the
  view. AC-37 is the regression guard.
- **KI-005 (widget-test environment)** — long lists need a tall viewport
  (`tester.view.physicalSize = const Size(1080, 3600)`), the bottom navigation
  swallows taps on edge-visible targets (unfocus, drag, then tap), and a test
  without an explicit locale resolves to `en` while the template ARB is
  `app_de.arb`.
- **go_router ^14** here versus ^17 in WasThereSomething. The routing API
  differs; reuse the reasoning, not the snippets.

---

## 6. Test fixtures

### 6.1 `viewMatrix` — the membership fixture

One fixture, anchored at **today = 2026-08-25**, covering every branch of the
predicates in 1.2. It is the shared input for AC-01..AC-06 and AC-38.

| # | Task | start | due | progress | Expected membership |
|---|---|---|---|---|---|
| 1 | no dates, open | — | — | needs-action | Heute (ohneDatum), Alle |
| 2 | due yesterday | — | 24.08. | needs-action | Heute (überfällig), Alle |
| 3 | due today | — | 25.08. | needs-action | Heute (heute), Alle |
| 4 | due tomorrow | — | 26.08. | needs-action | Demnächst, Alle |
| 5 | due in 7 days | — | 01.09. | needs-action | Demnächst, Alle |
| 6 | due in 8 days | — | 02.09. | needs-action | Alle only |
| 7 | started, undated | 25.08. | — | needs-action | Heute (heute), Alle |
| 8 | future start | 27.08. | — | needs-action | **Alle only** — the VSN-003 case |
| 9 | future start, overdue | 27.08. | 24.08. | needs-action | Heute (überfällig), Alle — the VSN-005 case |
| 10 | completed today | — | 25.08. | completed | Erledigt only |
| 11 | failed, due today | — | 25.08. | failed | Alle only, marked |
| 12 | cancelled, due today | — | 25.08. | cancelled | Alle only, marked |
| 13 | trashed, due today | — | 25.08. | needs-action | **nowhere** |
| 14 | in an archived list | — | 25.08. | needs-action | **nowhere** |
| 15 | subtask due today, parent undated | — | 25.08. | needs-action | Heute flat with parent label; nested in the list |
| 16 | dated but timeless | — | 26.08. (no time) | needs-action | Demnächst, sorts before #17 |
| 17 | dated with time | — | 26.08. 10:00 | needs-action | Demnächst, sorts after #16 |

Every row is a named constant so a failure names the case rather than an
index.

### 6.2 Sort fixtures

- `sameSecond` — 50 tasks inserted inside one second with identical due dates
  and priorities, for AC-11.
- `priorityMix` — priorities 0, 1, 5, 9, for AC-13.
- `titleCollation` — "Zebra", "Äpfel", "apfel", for AC-14.
- `dueMix` — dated past, dated future, undated, for AC-12.

### 6.3 Search and performance fixtures

- `searchCorpus` — a task matching in the title only, one matching in the
  notes only, one matching in both, one completed match, one trashed match.
- `twoThousandTasks` — generated, seeded deterministically, across 8 lists
  with 2 tags each. Used for AC-23, AC-25 and AC-39. Generated rather than
  committed, so the repository does not carry a large fixture file.
