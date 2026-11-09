# Data contract: Reminders and recurrence

Spec 0001's `data-contract.md` stays authoritative for `tasks` and `lists`.
This file owns two tables, one non-domain store, and the recurrence columns'
semantics.

---

## 1. Data structures

### 1.1 `reminders` (schema v3)

```text
reminders
  id              TEXT PK
  task_id         TEXT NOT NULL -> tasks.id ON DELETE CASCADE
  offset_minutes  INTEGER NOT NULL    -- 0 = at the due time, 60 = one hour before
  fired_at        DATETIME            -- diagnostics only, never drives behaviour
  notification_id INTEGER             -- local platform handle
  created_at      DATETIME NOT NULL
  UNIQUE (task_id, offset_minutes)
```

Index: `task_id`.

**This is a real table, not a derived value.** In WasThereSomething a reminder
is reconciled from `(rule, occurrence_key)` by a service. Here the user sets
it directly on a task, so there is nothing to reconcile *into existence* — the
reconciliation in section 2 is between the database and the **OS**, which is a
different job. Do not port `ReminderReconciliationService`.

`notification_id` is a **local handle**, not an identity. It is meaningless
after a reinstall, is never exported, and is rewritten on every successful
schedule.

### 1.2 `task_recurrence_overrides` (schema v4)

```text
task_recurrence_overrides
  id            TEXT PK
  task_id       TEXT NOT NULL -> tasks.id ON DELETE CASCADE
  recurrence_id TEXT NOT NULL      -- "2027-03-13T10:00:00" — verbatim wire string
  patch_json    TEXT               -- bounded PatchObject, <= 4 KiB
  excluded      BOOLEAN NOT NULL DEFAULT 0
  UNIQUE (task_id, recurrence_id)
```

`recurrence_id` is stored as its **canonical JSCalendar `LocalDateTime`
string**, not as a `DateTime` and not as an epoch value. It is a key a rule
produced. Re-deriving it from an instant is exactly the class of error
TLD-305 forbids, and here it would also silently break the `UNIQUE` key across
a DST boundary.

`patch_json` holds a bounded RFC 8984 `PatchObject` — in 3.1.0 only
`progress`, `progressUpdated`, `percentComplete` and `excluded` are ever
written. Unknown keys arriving from an import are preserved verbatim.

### 1.3 The pending-action store — deliberately not a domain table

Required by ADR-0012 decision 4. A notification action can run in a
**background isolate** with no `ProviderScope` and its own memory. Opening the
Drift domain database there would be a second connection to the same file from
a second isolate, and every repository invariant assumes single-threaded
foreground execution.

So the background half writes to a tiny, append-only store instead:

```text
pending_notification_actions
  id           TEXT PK          -- generated in the background handler
  task_id      TEXT NOT NULL    -- an id, never a title
  action       TEXT NOT NULL    -- 'complete' | 'snooze'
  parameter    TEXT             -- snooze target, e.g. 'PT1H' | 'tonight' | 'tomorrow'
  created_at   DATETIME NOT NULL
```

Properties that make it safe:

- **Append-only.** The background handler inserts one row and returns. It
  never reads, updates or deletes.
- **No foreign key** to `tasks`. A task deleted between the tap and the drain
  must not make the insert fail; the drain handles the missing target
  (RRC-406).
- **No domain content.** A task id, an action code, a timestamp. No title, no
  body.
- **Drained in the app isolate** on the next start or resume, through the
  normal repository, in a transaction, idempotently (RRC-404, RRC-405).

**Storage choice is open** (see `open-questions.md`, Q-3d): a separate small
Drift database file, or a plain append-only file. What is *not* open is that
it must not be the domain database and must not require the domain schema.

### 1.4 Recurrence columns on `tasks`

Declared in spec 0001; their semantics belong here.

| Column | Meaning |
|---|---|
| `recurrence_rule` | RFC 5545 subset **string**, e.g. `FREQ=WEEKLY;INTERVAL=2;BYDAY=MO,WE`. Written only through the parser. |
| `recurrence_rule_version` | The grammar version the string was written with, so a future grammar change can migrate strings rather than guess. |
| `recurrence_mode` | `schedule` \| `completion`. **App-local semantics** — JSCalendar has no property for it. |

The anchor for expansion is `start ?? due` — the same rule the contract uses
as its calendar anchor.

### 1.5 The supported rule subset

Fixed by the contract. Wider is not better here: a rule this app can emit but
WasThereSomething cannot read is a compatibility bug.

| RFC 5545 (stored) | JSCalendar (wire) |
|---|---|
| `FREQ=DAILY` | `"frequency": "daily"` |
| `FREQ=WEEKLY` | `"frequency": "weekly"` |
| `FREQ=MONTHLY` | `"frequency": "monthly"` |
| `FREQ=YEARLY` | `"frequency": "yearly"` |
| `INTERVAL=n` | `"interval": n` — omitted when 1 |
| `BYDAY=MO,WE` | `"byDay": [{"@type":"NDay","day":"mo"}, …]` |
| `BYDAY=1SA` | `"byDay": [{"@type":"NDay","day":"sa","nthOfPeriod":1}]` |
| `BYDAY=-1FR` | `"byDay": [{"@type":"NDay","day":"fr","nthOfPeriod":-1}]` |
| `BYMONTHDAY=1,15` | `"byMonthDay": [1, 15]` |

**Weekday tokens are uppercase in RFC 5545 and lowercase in JSCalendar.** This
is a real and easy bug (RRC-506), so the mapping is a named function with a
test covering all seven days in both directions — not an inline
`toLowerCase()`.

Unsupported, and imported as non-recurring **with a counted warning**:
`hourly`, `minutely`, `secondly`, `rscale`, `skip`, `firstDayOfWeek`,
`byMonth`, `byYearDay`, `byWeekNo`, `byHour`, `byMinute`, `bySecond`,
`bySetPosition`, **`count`**, **`until`**.

`count` and `until` are the two most likely to be missed and the two most
likely to be wanted. Their absence is an open question (Q-3a), not an
oversight.

### 1.6 Expansion rules

The expander lives in `task_interchange` (`flutter-libraries`, ADR-0017), is pure Dart, and is the
same code the codec uses (RRC-504).

```dart
Iterable<JsLocalDateTime> expand({
  required RecurrenceRule rule,
  required JsLocalDateTime anchor,
  required JsLocalDateTime windowStart,
  required JsLocalDateTime windowEnd,   // required — no unbounded call exists
});
```

- **Bounded by construction** (RRC-605): there is no overload without a
  window, so an unbounded expansion does not compile.
- **Deterministic and ascending** (RRC-606).
- **Calendar-correct** (RRC-608), through `time_machine2` via
  `DateValidation`:
  - `BYMONTHDAY=31` in February produces **no** instance. It is skipped, not
    shifted to the 28th and not shifted to 1 March. This matches RFC 5545's
    default (no `RSCALE`/`SKIP`), and it is tested rather than assumed.
  - `FREQ=YEARLY` anchored 29 February materializes only in leap years.
- Overrides are applied **after** expansion: an instance with
  `excluded = 1` is removed from the result; an instance with a patch carries
  it.

### 1.7 Completion-mode arithmetic

| Mode | Next due |
|---|---|
| `schedule` | the rule's next occurrence strictly after the current instance's `recurrence_id` |
| `completion` | the completion moment's calendar day, advanced by the rule's interval in the rule's frequency unit, keeping the original time-of-day |

`completion` mode deliberately does **not** consult `BYDAY`/`BYMONTHDAY` for
the next date; those parts describe a calendar pattern, and "three days after
you watered the plants" is not a calendar pattern. If a rule with `BYDAY` is
combined with `completion` mode, the next date is computed from the interval
and then snapped forward to the next matching weekday — and that behaviour is
documented in the editor, not inferred.

When advancing, `start` moves with `due` and the offset between them is
preserved (RRC-706, AC-43).

---

## 2. Reconciliation — the OS is a cache

The OS's scheduled set can be emptied by a reboot, an app update or the user
clearing app data, and it can hold handles the database no longer knows
about. It is therefore never a source of truth (RRC-303).

```text
database (reminders x tasks x due dates)
        │
        │  compute the wanted set inside the horizon
        ▼
   wanted: Set<(reminderId, moment)>
        │
        │  gateway.pending() -> actual: Set<notificationId>
        ▼
   schedule (wanted - actual) · cancel (actual - wanted)
        │
        ▼
   record notification_id · count failures by reason code
```

- **Idempotent** (RRC-304): a run where the sets already match issues no call
  at all. AC-18 case (c) asserts exactly this.
- **Bounded** (RRC-305): only reminders whose moment falls inside a rolling
  **60-day horizon** are held in the OS at once. Android caps concurrent
  alarms, and an unbounded schedule loses the tail silently — the worst
  possible failure mode for a reminder.
- **Per-item failure isolation** (RRC-306): one failure is counted with a
  reason code; the run continues.
- **Writes no domain table** (RRC-307): the only column it may write is
  `reminders.notification_id`.

Triggers: a `guarded` startup task, `BOOT_COMPLETED`, and a time-zone change.
Guarded rather than blocking, because a missing reminder must never prevent
the app from starting.

---

## 3. Export / import formats

Owned by spec 0004. Two rules bind this file:

- **Reminders never travel.** JSCalendar `alerts` and `useDefaultAlerts` are
  outside contract v1 (guide 1.5): notifications are each app's own concern
  and are not interoperable state. The app neither emits nor consumes them,
  and preserves them as unknown properties if they arrive (RRC-209).
- **Recurrence travels as the standard.** `recurrenceRules` and
  `recurrenceOverrides` map as in 1.5 and 1.2. `recurrence_mode` is app-local
  and, if it travels at all, only as `lumbrecode.de:recurrenceMode` on the
  **payload** — never as a CloudEvents attribute, because a receiver that
  strips the envelope must not lose it (RRC-705).

`notification_id`, `fired_at` and the pending-action store are app-local and
never leave.

---

## 4. Versioning

| `schemaVersion` | Introduced by | Contents |
|---|---|---|
| 3 | slice 6 | `reminders` + its index |
| 4 | slice 7 | `task_recurrence_overrides` + its unique index |

Both steps are additive `createTable` / `createIndex`. Nothing is rebuilt, so
the `TableMigration.newColumns` trap (database-contract rule 2) does not
apply — but if a rebuild ever becomes necessary, every column added by a later
migration must be listed.

The recurrence **columns** on `tasks` (`recurrence_rule`,
`recurrence_rule_version`, `recurrence_mode`) are created with `tasks` in
schema v2, before there is any UI for them. That is deliberate: a
model-only column costs nothing, and adding it later would be a migration.

`recurrence_rule_version` is the grammar's own version, independent of
`schemaVersion` and of `formatVersion`. It exists so a future grammar change
can migrate stored strings deterministically instead of guessing which
dialect a row was written in.

The pending-action store, if implemented as its own database file, carries its
own version, independent of the domain `schemaVersion` — that independence is
the point of separating it.

---

## 5. Compatibility notes

- **KI-008 (second precision)** — `fired_at` and `progress_updated_at` are
  `DateTime` columns at second precision. Neither is ever a sort key. Tests
  truncate expected values to whole seconds.
- **KI-009(a) (`timezone` transitive conflicts)** — `timezone` arrives with
  `flutter_local_notifications`. Nothing else in the tree depends on it today,
  so the conflict surface is currently empty; the constraint is recorded when
  it is added, so the next package that wants `timezone` finds the note.
- **KI-005 (pending timers)** — flutter_test fails a test that leaves a timer
  pending. Any scheduling or midnight timer is cancelled on dispose, and the
  widget tests assert it.
- **KI-001 (the analyzer ceiling)** — `flutter_local_notifications` and
  `timezone` are runtime-only and carry no analyzer constraint, so neither
  should move the ceiling. They must still be resolved against the tree
  **before** adoption (library-evaluation rule 10).
- **ADR-0013 (the manifest is generated)** — any manifest entry the
  notification plugin requires is applied through the bootstrap patcher, not
  by editing a committed file. There is no committed `android/`.

---

## 6. Test fixtures

### 6.1 Recurrence rules — `ruleMatrix`

| # | Stored string | Expect |
|---|---|---|
| 1 | `FREQ=DAILY` | parses; daily |
| 2 | `FREQ=DAILY;INTERVAL=3` | parses; every third day |
| 3 | `FREQ=WEEKLY;BYDAY=MO,WE` | parses; wire form lowercase |
| 4 | `FREQ=WEEKLY;INTERVAL=2;BYDAY=FR` | parses |
| 5 | `FREQ=MONTHLY;BYMONTHDAY=1,15` | parses |
| 6 | `FREQ=MONTHLY;BYDAY=1SA` | parses; `nthOfPeriod: 1` |
| 7 | `FREQ=MONTHLY;BYDAY=-1FR` | parses; `nthOfPeriod: -1` |
| 8 | `FREQ=YEARLY` | parses |
| 9 | `FREQ=HOURLY` | **rejected**, typed error |
| 10 | `FREQ=DAILY;COUNT=4` | **rejected**, typed error |
| 11 | `FREQ=DAILY;UNTIL=20270101T000000Z` | **rejected**, typed error |
| 12 | `FREQ=DAILY;BYSETPOS=1` | **rejected**, typed error |
| 13 | `FREQ=MONTHLY;BYMONTHDAY=31` anchored 31.01.2027 | Feb **skipped**; Mar 31 present |
| 14 | `FREQ=YEARLY` anchored 29.02.2028 | next instance 29.02.2032 |

Rows 9–12 double as the import-warning cases for AC-29.

### 6.2 Reminder and reconciliation fixtures

- `reconcileEmpty` — 10 future reminders, gateway reports nothing pending.
- `reconcileStale` — gateway reports 3 handles the database does not know.
- `reconcileConverged` — gateway reports exactly the wanted set; the run must
  issue **zero** calls.
- `reconcileHorizon` — 500 reminders over two years, for the bounded-horizon
  assertion.
- `reconcileFailure` — a gateway that throws for one specific item.
- `dstBoundary` — due dates either side of the `Europe/Berlin` transitions,
  with 60-minute lead times, for AC-16.
- `floatingVsZoned` — the same task floating and zoned, device in
  `America/New_York`, for AC-17.

### 6.3 Pending-action fixtures

- `pendingValid` — one `complete` for an existing open task.
- `pendingStale` — one for a deleted task, one for an already-completed task.
- `pendingDuplicate` — the same record twice, for the idempotency assertion.
- `pendingSnooze` — a `snooze` with each of the three parameters.
