# Data contract: Task and list domain

Authoritative schema for the reference app. Deliverable E of the 3.1.0
planning pass.

Binding inputs: `docs/architecture/contracts/02-database.md`,
`lumbrecode-engineering/docs/JSCALENDAR_TASK_INTEROP.md` sections 2 and 9.2,
`docs/known-issues.md` KI-003, KI-004, KI-008.

Wire format is spec 0004. This file covers storage.

---

## 1. Data structures

### 1.1 Table overview

```text
lists ──────────┐
                │ 1     n
                └──── tasks ──┬── task_tags ── tags
                    ▲   │     ├── task_links
                    └───┘     ├── task_recurrence_overrides
                  parent      └── reminders
```

Declaration order in `@DriftDatabase` is **parents first**
(`Lists, Tags, Tasks, TaskTags, TaskLinks, TaskRecurrenceOverrides,
Reminders`). `wipeAllData()` deletes in reverse declaration order, and with
foreign keys enforced a wrong order aborts the wipe.

### 1.2 `lists`

| Column | Type | Constraints | Notes |
|---|---|---|---|
| `id` | TEXT | PK | app-generated via `generateId()`; never exported |
| `title` | TEXT | NOT NULL, 1..100 trimmed | |
| `color_token` | TEXT | nullable | **token name**, never a hex value — a hex value would not survive a theme change |
| `icon_key` | TEXT | nullable | stable key, never an icon code point |
| `sort_order` | INTEGER | NOT NULL | explicit; never a timestamp |
| `is_inbox` | BOOLEAN | NOT NULL DEFAULT 0 | exactly one row true — see 1.9 |
| `archived_at` | DATETIME | nullable | TLD-508 |
| `deleted_at` | DATETIME | nullable | trash |
| `source_uid` | TEXT | nullable | `Group.uid` of an import — **provenance only** |
| `source_app` | TEXT | nullable | `prodId` of an import — provenance only |
| `imported_at` | DATETIME | nullable | |
| `created_at` | DATETIME | NOT NULL | |
| `updated_at` | DATETIME | NOT NULL | |

Indexes: `sort_order`; partial unique on `is_inbox` where `is_inbox = 1`.

### 1.3 `tasks`

| Column | Type | Constraints | Notes |
|---|---|---|---|
| `id` | TEXT | PK | never exported |
| `list_id` | TEXT | NOT NULL, FK → `lists.id` ON DELETE CASCADE | TLD-503 |
| `jscalendar_uid` | TEXT | NOT NULL UNIQUE | RFC 4122 v4, canonical lowercase |
| `parent_task_id` | TEXT | nullable, FK → `tasks.id` ON DELETE CASCADE | single-parent tree |
| `title` | TEXT | NOT NULL, 1..200 trimmed | |
| `description_markdown` | TEXT | nullable, ≤ 20 000 chars | verbatim source |
| `description_content_type` | TEXT | NOT NULL DEFAULT `'text/markdown; charset=utf-8'` | RFC 7763 |
| `progress` | TEXT | NOT NULL DEFAULT `'needs-action'` | **no CHECK** — see 1.8 |
| `percent_complete` | INTEGER | nullable, CHECK 0..100 | |
| `progress_updated_at` | DATETIME | nullable | moves only with `progress` |
| `priority` | INTEGER | NOT NULL DEFAULT 0, CHECK 0..9 | 0 undefined, 1 highest |
| `start_date_day` | INTEGER | nullable | epoch day |
| `start_minutes` | INTEGER | nullable, CHECK 0..1439 | minutes since midnight |
| `due_date_day` | INTEGER | nullable | epoch day |
| `due_minutes` | INTEGER | nullable, CHECK 0..1439 | |
| `time_zone_id` | TEXT | nullable | IANA id; NULL = floating |
| `show_without_time` | BOOLEAN | NOT NULL DEFAULT 0 | |
| `estimated_duration_minutes` | INTEGER | nullable, CHECK ≥ 0 | model-only in 3.1.0 |
| `recurrence_rule` | TEXT | nullable | RFC 5545 subset string — spec 0003 |
| `recurrence_rule_version` | INTEGER | nullable | grammar version of the stored string |
| `recurrence_mode` | TEXT | NOT NULL DEFAULT `'schedule'` | `schedule` \| `completion`, app-local |
| `sequence` | INTEGER | NOT NULL DEFAULT 0 | revision for re-sharing |
| `sort_order` | INTEGER | NOT NULL DEFAULT 0 | manual order, app-local |
| `unknown_json` | TEXT | nullable, ≤ 8 KiB | preserved unknown standard properties |
| `archived_at` | DATETIME | nullable | |
| `deleted_at` | DATETIME | nullable | trash — **actually used here** |
| `created_at` | DATETIME | NOT NULL | |
| `updated_at` | DATETIME | NOT NULL | |

Indexes: `(list_id, sort_order)`, `parent_task_id`, `due_date_day`,
`start_date_day`, `deleted_at`, and a unique index on `jscalendar_uid`.

### 1.4 `tags` and `task_tags`

```text
tags
  id          TEXT PK
  name        TEXT NOT NULL              -- unique on lower(trim(name))
  color_token TEXT
  created_at  DATETIME NOT NULL

task_tags
  task_id     TEXT -> tasks.id ON DELETE CASCADE
  tag_id      TEXT -> tags.id  ON DELETE CASCADE
  PRIMARY KEY (task_id, tag_id)
```

Uniqueness on the normalized name is enforced by a unique index over a
generated lowercase column, not by application code alone.

### 1.5 `task_links`

```text
task_links
  id            TEXT PK
  task_id       TEXT NOT NULL -> tasks.id ON DELETE CASCADE
  link_key      TEXT NOT NULL      -- the map key on the wire
  href          TEXT NOT NULL
  cid           TEXT
  content_type  TEXT
  size          INTEGER
  rel           TEXT               -- IANA link relation; "enclosure" = attachment
  display       TEXT               -- badge | graphic | fullsize | thumbnail
  title         TEXT
  UNIQUE (task_id, link_key)
```

### 1.6 `task_recurrence_overrides`

```text
task_recurrence_overrides
  id            TEXT PK
  task_id       TEXT NOT NULL -> tasks.id ON DELETE CASCADE
  recurrence_id TEXT NOT NULL      -- LocalDateTime string, e.g. 2027-03-13T10:00:00
  patch_json    TEXT               -- bounded PatchObject, <= 4 KiB
  excluded      BOOLEAN NOT NULL DEFAULT 0
  UNIQUE (task_id, recurrence_id)
```

`recurrence_id` is stored as its canonical wire string, not as a `DateTime`.
It is a key produced by a rule, and re-deriving it from an instant is the
error TLD-305 forbids.

### 1.7 `reminders`

Detailed in spec 0003. Shape:

```text
reminders
  id              TEXT PK
  task_id         TEXT NOT NULL -> tasks.id ON DELETE CASCADE
  offset_minutes  INTEGER NOT NULL   -- 0 = at due time, 60 = one hour before
  fired_at        DATETIME
  notification_id INTEGER            -- platform handle, local only
  UNIQUE (task_id, offset_minutes)
```

This is a **real table**, not a value derived from a rule. In
WasThereSomething a reminder is reconciled from `(rule, occurrence_key)`;
here the user sets it directly on the task. Do not port the reconciliation
service — it solves a problem this app does not have.

### 1.8 Why `progress` has no CHECK constraint

The tolerance rule (TLD-202, interop guide 5.2) requires that an unrecognized
`progress` value is **kept verbatim** while behaving as `needs-action`. A
`CHECK` over the five registered values would make that unrepresentable, and
the app would have to choose between rejecting a document the contract says
to accept and losing data the sender put in.

The vocabulary is enforced in the type converter on read (mapping anything
unknown to `needsAction` for behaviour while retaining the raw string), and
on write for values the app itself produces. This is a deliberate, documented
exception to "constrain it in the schema".

### 1.9 Why exactly one Inbox is a schema fact

```sql
CREATE UNIQUE INDEX ux_lists_single_inbox ON lists (is_inbox) WHERE is_inbox = 1;
```

A partial unique index makes a second Inbox impossible to insert, including
from the import path and including from a future bug. TLD-502 asks for a
guard, not for a convention.

### 1.10 Type converters

Declared on the **storage** type, never on the semantic one, and imported
into the database library file — both are KI-004 traps.

| Converter | Column type | Dart type |
|---|---|---|
| `EpochDayConverter` | `integer()` | a day value (`LocalDate` from `time_machine2`) |
| `MinuteOfDayConverter` | `integer()` | `MinuteOfDay` (0..1439) |
| `TaskProgressConverter` | `text()` | `TaskProgress` + the raw string |
| `RecurrenceModeConverter` | `text()` | `RecurrenceMode` |

```dart
// RIGHT — declared on the storage type
IntColumn get dueDateDay => integer().nullable().map(const EpochDayConverter())();

// WRONG — the KI-004 trap
DateTimeColumn get dueDateDay => dateTime().map(const EpochDayConverter())();
```

`EpochDayConverter` and `MinuteOfDayConverter` are **template surface** and
live in `core/domain/time/`, extracted in slice 0. They close the
database-contract rule 6 gap that is currently marked partial.

### 1.11 Foreign-key semantics, per edge

| Edge | Rule | Why |
|---|---|---|
| `tasks.list_id` → `lists.id` | CASCADE | a task has no meaning outside a list; deleting a list is a counted, confirmed decision at the UI level (TLD-506) |
| `tasks.parent_task_id` → `tasks.id` | CASCADE | a subtask has no independent existence |
| `task_tags.task_id` | CASCADE | pure join row |
| `task_tags.tag_id` | CASCADE | pure join row; the tag definition survives |
| `task_links.task_id` | CASCADE | purely dependent |
| `task_recurrence_overrides.task_id` | CASCADE | purely dependent |
| `reminders.task_id` | CASCADE | purely dependent |

No RESTRICT edge exists in 3.1.0, because every deletion that is a domain
decision (list, parent task) is gated by a counted confirmation in the UI and
by soft delete in the repository. Recorded here so the absence is a decision
rather than an omission.

### 1.12 The four ids, kept apart

| Id | Owner | Exported |
|---|---|---|
| `tasks.id` | local database | never |
| `tasks.jscalendar_uid` | the task, forever | always |
| `lists.id` | local database | never |
| `lists.source_uid` | a foreign app's `Group` | provenance only, never a matching key |

---

## 2. API contracts

Not applicable. The app has no backend, no endpoint and no entry in
`docs/api/openapi.yaml`. It must stay that way (`backend_enabled: false`).

---

## 3. Export / import formats

The interchange format is spec 0004 and
`lumbrecode-engineering/docs/JSCALENDAR_TASK_INTEROP.md`. Two rules bind this
file:

- **App-local columns never travel.** `id`, `list_id`, `sort_order`,
  `recurrence_mode` (unless as a documented vendor extension), `archived_at`,
  `deleted_at`, `notification_id`, `fired_at`, `source_uid`, `source_app`.
- **Every wire property has a home.** Anything the contract can carry but the
  app does not surface is still persisted (`time_zone_id`,
  `estimated_duration_minutes`, `percent_complete`, `unknown_json`,
  `task_links.rel = enclosure`), so adding the UI later is a screen, not a
  migration.

A **backup/restore** file (F-40, later) is a different artefact with a
different job: it is the whole database and carries its own `formatVersion`,
independent of `schemaVersion` (database-contract rules 9 and 10). A
JSCalendar document is not a backup and a backup is not shareable.

---

## 4. Versioning

Six version concepts exist side by side and must not be mixed
(database-contract rule 10): repo `VERSION`, `pubspec` version, Android
`versionCode`, release tag, `schemaVersion`, `formatVersion`.

### 4.1 Schema version plan

| `schemaVersion` | Introduced by | Contents |
|---|---|---|
| 1 | current template | `todo_items` (the demo) |
| 2 | slice 2 | `lists`, `tags`, `tasks`, `task_tags`, `task_links` — all additive; `todo_items` untouched |
| 3 | slice 6 | `reminders` |
| 4 | slice 7 | `task_recurrence_overrides` |
| 5 | slice 13 | drop `todo_items` — the **only** destructive step, and the reason ADR-0011 exists |

Every step is `createTable` / `createIndex` / `addColumn` with a default.
Nothing rebuilds a table. If a `TableMigration` rebuild ever becomes
necessary, database-contract rule 2 applies: **every column added by a later
migration must be listed in `newColumns`**, or upgrading an old database
crashes.

### 4.2 Migration from the demo schema

There is none, deliberately.

`todo_items` rows are **not** carried into `tasks`. The reasons:

1. The demo is a template artefact. No user has data in it; every derived app
   replaces it before shipping.
2. The status vocabularies do not correspond. `pending` is not
   `needs-action`, and a mapping would encode a wrong equivalence in the
   migration file where it would be read as authoritative.
3. A migration that runs for nobody is untestable in practice and rots.

Slice 13 drops the table after the replacement is complete, and the drop is
covered by its own fixture test proving that no `tasks` row is affected.

---

## 5. Compatibility notes

- **Downgrade** is undefined in Drift and already aborts with a readable
  message in `beforeOpen`. Unchanged.
- **`PRAGMA foreign_keys = ON`** is set per connection in `beforeOpen`.
  Already true; asserted by test (AC-49).
- **Second precision** (KI-008): Drift persists `DateTime` as Unix seconds.
  Consequences honoured here — every ordered query uses `sort_order` with a
  documented tiebreak (TLD-801, TLD-802), and tests truncate expected values
  to whole seconds.
- **Composed streams** (KI-003): a stream that emits a task with its tags must
  **join** `task_tags` and `tags`, not load them inside `asyncMap`. AC-50 is
  the regression guard.
- **Two foreign keys to the same table**: `tasks.list_id` and
  `tasks.parent_task_id` point at different tables, so the `@ReferenceName`
  trap (KI-004) does not apply today. It will the moment a second edge to
  `tasks` or to `lists` is added — annotate both then, and note that the build
  still *succeeds* while silently omitting generated filters.

---

## 6. Test fixtures

### 6.1 Migration fixtures

`test/core/database/fixtures/` holds a raw-SQL snapshot per shipped schema
version, with seeded rows that must survive.

| Case | Assertion |
|---|---|
| fresh install (`onCreate`) | all tables, indexes, constraints, and exactly one Inbox seeded |
| v1 → v5 (full chain) | demo rows irrelevant; new tables present; no data loss in `tasks` |
| v2 → v3 → v4 (chained) | seeded lists, tasks, tags, links survive with identical values |
| v4 → v5 | `todo_items` gone; every `tasks` row untouched |
| partially applied upgrade | re-open completes or fails cleanly; `addColumnIfMissing` is idempotent |
| FK-violating legacy row | migration fails loudly rather than deleting rows |
| downgrade (v5 database, v4 build) | readable `StateError`, no data touched |

### 6.2 Domain fixtures

A builder-based factory (`TaskFactory`, `ListFactory`) rather than literal
rows, so a new column does not break sixty tests. Named scenarios:

- `inboxOnly` — a fresh database
- `twoListsFiveTasks` — the ordinary case
- `nestedTree` — parent with two subtasks, one completed
- `everyDateShape` — the four date combinations from AC-18
- `unknownProgress` — a row holding `delegated`
- `withUnknownJson` — a row carrying a preserved future property
- `trashAges` — trashed tasks at 29, 30 and 31 days

### 6.3 Interchange fixtures

The 24 golden JSCalendar fixtures and the 21 exchange fixtures are vendored
into `.lumbrecode/schemas/` with a provenance file and a
checksum test (ADR-0014). They are the inputs for CT-1..CT-15 and are shared,
unchanged, with WasThereSomething. **If a fixture changes, it changes in both
repositories in the same change.**
