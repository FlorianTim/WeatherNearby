# Requirements: Reminders and recurrence

Requirement IDs use the prefix `RRC-`. Every id maps to at least one criterion
in `acceptance-criteria.md`.

Priority: **Must** = required for 3.1.0. **Should** = required unless a story
explicitly defers it with a recorded reason. **Model-only** = persisted and
round-tripped, deliberately without UI in 3.1.0.

## A. The notification boundary (RRC-0xx)

| Id | Requirement | Priority |
|---|---|---|
| RRC-001 | Every notification operation goes through `NotificationGateway` in `core/notifications/`. No widget, notifier or repository imports `flutter_local_notifications`. Asserted by an import-scanning test. | Must |
| RRC-002 | The gateway interface is `schedule`, `cancel`, `cancelAll`, `pending`. `pending()` exists so reconciliation is assertable. | Must |
| RRC-003 | `FakeNotificationGateway` records calls and is what every widget test sees. No test may reach a platform channel. | Must |
| RRC-004 | Scheduling is **local only**: no push, no Firebase, no network, no remote configuration. | Must |
| RRC-005 | Scheduling uses inexact mode (`inexactAllowWhileIdle`). Neither `SCHEDULE_EXACT_ALARM` nor `USE_EXACT_ALARM` is declared. | Must |
| RRC-006 | Notification content and payload never carry a task title or body into a **log line**. The payload carries a task id; the visible notification carries the title subject to RRC-505. | Must |
| RRC-007 | On a platform without local notifications (web), the gateway is a no-op implementation, reminders are still stored, and the UI states that they cannot be delivered here. It never throws and never silently pretends. | Must |

## B. Permission (RRC-1xx)

| Id | Requirement | Priority |
|---|---|---|
| RRC-101 | The notification permission is requested **just in time** — when the user sets their first reminder — through the existing `ensurePermission` flow. Never at startup, never on screen entry. | Must |
| RRC-102 | An in-app rationale is shown before the system dialog. When the state is `permanentlyDenied`, the blocked sheet is shown instead and the system dialog is not attempted. | Must |
| RRC-103 | A denied permission is **not** a failure. The reminder is still stored, the app stays fully usable, and it names exactly what is limited ("Erinnerungen werden nicht angezeigt"). | Must |
| RRC-104 | The concrete `NotificationPermissionGateway` is implemented on the notification plugin's own permission API. **No permission package is added** in 3.1.0 (ADR-0012, decision 6). | Must |
| RRC-105 | Permission state is read from the system on each check, never from a cache. A user who revokes it in the system settings must be noticed. | Must |
| RRC-106 | The receive path (spec 0004) never requests a runtime permission. If it appears to need one, the design is wrong. | Must |
| RRC-107 | A task detail showing a reminder while the permission is missing shows a persistent, dismissible hint with a route to the system settings. | Should |

## C. Reminders — model and behaviour (RRC-2xx)

| Id | Requirement | Priority |
|---|---|---|
| RRC-201 | A reminder belongs to exactly one task, and is stored in `reminders` with `offset_minutes` where 0 means "at the due time" and a positive value means "that many minutes before". | Must |
| RRC-202 | A task may carry more than one reminder. `UNIQUE (task_id, offset_minutes)` prevents duplicates. | Should |
| RRC-203 | A reminder requires a `due` **with a time**. Setting one on a date-only or undated task either prompts to add a time or is refused with a readable reason — never silently scheduled at midnight. | Must |
| RRC-204 | Offered lead times: at the due time, 10 minutes, 1 hour, 1 day, 1 week. Plus a custom value in minutes. | Should |
| RRC-205 | Deleting a task, trashing a task, or completing a task cancels its scheduled notifications. Restoring from the trash re-schedules those still in the future. | Must |
| RRC-206 | A reminder whose computed moment is in the past is **not** scheduled, and the UI says so rather than showing a reminder that will never fire. | Must |
| RRC-207 | `notification_id` is a local platform handle. It is never exported and never treated as stable across a reinstall. | Must |
| RRC-208 | `fired_at` records delivery when the platform reports it, for diagnostics only. It never drives behaviour. | Should |
| RRC-209 | Reminders are **not** interoperable state. JSCalendar `alerts` is neither emitted nor consumed (contract 1.5). | Must |

## D. Scheduling and reconciliation (RRC-3xx)

| Id | Requirement | Priority |
|---|---|---|
| RRC-301 | The moment to fire is computed from the stored **components** (`due_date_day`, `due_minutes`, `time_zone_id`) plus the offset. A stored local date-time is never round-tripped through an instant to get there (spec 0001, TLD-305). | Must |
| RRC-302 | A task with `time_zone_id = NULL` is floating: it fires at that wall-clock time in the device's current zone. A task with a zone fires at that wall-clock time in that zone. | Must |
| RRC-303 | The OS's scheduled set is a **cache**, never a source of truth. A reconciliation task compares `pending()` against the database and converges. | Must |
| RRC-304 | Reconciliation runs as a `guarded` startup task, on device reboot, and on a time-zone change. It is idempotent: a run with nothing to change schedules nothing. | Must |
| RRC-305 | Reconciliation is bounded. Only reminders within a rolling horizon (proposal: 60 days) are held in the OS at once; the rest are materialized on later runs. Android caps concurrent alarms, and an unbounded schedule silently loses the tail. | Must |
| RRC-306 | A failure to schedule one reminder does not abort the run. Failures are counted and reported by reason code, never as an exception message. | Must |
| RRC-307 | Reconciliation never writes a domain table. It only schedules, cancels and records `notification_id`. | Must |

## E. Notification actions (RRC-4xx)

| Id | Requirement | Priority |
|---|---|---|
| RRC-401 | Two actions are offered: **Erledigt** and **Später** (snooze: 1 Stunde / heute Abend / morgen). | Must |
| RRC-402 | An action handler running in the background **writes no domain table**. It appends exactly one record to an append-only pending-action store and returns (ADR-0012, decision 4). | Must |
| RRC-403 | The background handler touches no Drift domain database, no Riverpod container and no repository. | Must |
| RRC-404 | The queue is drained on the next foreground start or resume, inside the normal app isolate, through the normal repository, in a transaction. | Must |
| RRC-405 | Draining is **idempotent**. Draining the same record twice has the effect of draining it once. | Must |
| RRC-406 | Draining a record whose task no longer exists, or whose state already matches, is a no-op that is counted, not an error. | Must |
| RRC-407 | Tapping the notification body (not an action) opens the task detail with a back stack leading to Heute (spec 0002, VSN-405). | Must |
| RRC-408 | The UI states, where a user could otherwise be misled, that an action taken while the app is closed is applied when the app is next opened. | Should |
| RRC-409 | Snooze reschedules the notification and does **not** change the task's `due`. A snooze is a decision about a reminder, not about a deadline. | Must |

## F. Recurrence — the rule (RRC-5xx)

| Id | Requirement | Priority |
|---|---|---|
| RRC-501 | Supported rule parts are exactly: `FREQ` in {`DAILY`, `WEEKLY`, `MONTHLY`, `YEARLY`}, `INTERVAL`, `BYDAY` (with an optional ordinal), `BYMONTHDAY`. Nothing else. | Must |
| RRC-502 | `COUNT` and `UNTIL` are **not supported in 3.1.0** — see `open-questions.md` Q-3a. A document carrying either imports as non-recurring with a counted warning. | Must |
| RRC-503 | The rule is stored as an RFC 5545 subset **string** with a `recurrence_rule_version`, written only through the parser. No second grammar, no localized string ("jeden Montag") is ever persisted, exported or parsed. | Must |
| RRC-504 | The parser and the expander live in `task_interchange` (`flutter-libraries`, ADR-0017), are pure Dart, and are the same code the codec uses. There is exactly one implementation. | Must |
| RRC-505 | `rrule` is **not** a dependency. A full RFC 5545 engine would let this app emit rules the contract does not support (ADR-0014). | Must |
| RRC-506 | Weekday tokens are uppercase in the stored RFC 5545 string (`MO`) and lowercase on the JSCalendar wire (`mo`). The mapping is a named function with its own test — this is a real and easy bug. | Must |
| RRC-507 | Recurrence requires at least one of `start` or `due`. A recurring task with no date is rejected. | Must |
| RRC-508 | The 3.1.0 UI offers: keine, täglich, wöchentlich, monatlich, jährlich, each with an interval, plus weekday selection for weekly and a day-of-month for monthly. The model accepts every rule the parser accepts. | Must |

## G. Recurrence — instances (RRC-6xx)

| Id | Requirement | Priority |
|---|---|---|
| RRC-601 | A recurring task is **never cloned**. Instances are computed from the rule; only instances with their own state get a row in `task_recurrence_overrides`. | Must |
| RRC-602 | An override is keyed `(task_id, recurrence_id)`, where `recurrence_id` is the JSCalendar `LocalDateTime` **string** the rule produced, stored verbatim and never re-derived from an instant. | Must |
| RRC-603 | Excluding a single instance is an override with `excluded = 1`, per RFC 8984. There is no separate exclusion table and no separate exclusion list. | Must |
| RRC-604 | Completing one instance of a recurring task writes an override for that instance. It never completes the task itself and never affects other instances. | Must |
| RRC-605 | Expansion is bounded and lazy. No code path expands an unbounded rule into a list; every expansion takes a window or a count. | Must |
| RRC-606 | The expander is deterministic: the same rule, anchor and window always produce the same instances, in ascending order. | Must |
| RRC-607 | `excludedRecurrenceRules` is persisted and round-tripped, and is written by no 3.1.0 code path. | Model-only |
| RRC-608 | Expansion is calendar-correct through `DateValidation` / `time_machine2`: 31 January monthly does not produce 31 February, and 29 February yearly materializes only in leap years. The skip behaviour is documented, tested and never a silent shift to the 1st. | Must |

## H. Completion mode (RRC-7xx)

| Id | Requirement | Priority |
|---|---|---|
| RRC-701 | `recurrence_mode` is `schedule` or `completion`, default `schedule`. It is **app-local semantics**; JSCalendar has no property for it. | Must |
| RRC-702 | In `schedule` mode, the next instance is the rule's next occurrence after the current one, regardless of when the user completed it. | Must |
| RRC-703 | In `completion` mode, the next due date is computed from the **completion moment** plus the rule's interval, not from the nominal date. | Must |
| RRC-704 | The choice is visible in the recurrence editor with plain wording ("ab Fälligkeitsdatum" / "ab Erledigung"), not as jargon. | Must |
| RRC-705 | If it travels at all, it travels as the vendor extension `lumbrecode.de:recurrenceMode` on the payload, never in an envelope attribute. It changes nothing about the standard rule. Whether 3.1.0 emits it is spec 0004's decision. | Should |
| RRC-706 | Completing a `completion`-mode task advances its `due` (and `start`, preserving their offset) in one transaction, and reschedules its reminders. | Must |

## Quality requirements

- **Accessibility**: the reminder and recurrence editors are reachable without
  a gesture; every control has a localized semantic label; both are tested at
  `TextScaler.linear(2.0)`; a recurring task's row announces its repetition as
  a sentence ("wiederholt sich alle 3 Tage"), not as a bare icon.
- **Localization**: German and English, including the human-readable
  rendering of a rule. The rendered string is **presentation only** and is
  never persisted or parsed (RRC-503).
- **Reliability**: reconciliation converges from any starting state, including
  an OS set that is empty, stale or contains handles the database does not
  know.

## Constraints

- `flutter_local_notifications` and `timezone` are new dependencies, justified
  in ADR-0012. Both are runtime-only and must still be resolved against the
  KI-001 tree before adoption (library-evaluation rule 10).
- `timezone` has a recorded history of transitive conflicts — KI-009(a). Its
  constraint is recorded when it is added.
- Widget tests must not leave a pending timer; flutter_test's invariant will
  fail the test (KI-005). Any scheduling timer is cancelled on dispose.
- The Android manifest is produced by the bootstrap script, not committed
  (ADR-0013). Any manifest requirement of the notification plugin is applied
  the same way.

## Data requirements

Two tables — `reminders` (schema v3) and `task_recurrence_overrides`
(schema v4) — plus the pending-action store, plus recurrence columns already
declared on `tasks` in spec 0001. See `data-contract.md`.

## Privacy / Security considerations

- **Lock-screen content is a setting**, default "show the title" (RRC-505,
  open question Q-04 in the draft, resolved as proposed). A shared device is
  the case the generic alternative exists for.
- **No task content in logs** (RRC-006). The payload carries an id.
- The pending-action store carries a task id, an action code and a timestamp.
  **No title, no body.**
- No network, no push, no remote token, nothing to correlate a user.

## Testability notes

Automated: sections A–H, with the notable exception of actual OS delivery.
The expander and the parser are pure and get property tests; reconciliation is
tested against the fake gateway; the queue is tested as a unit.

Manual: real delivery, reboot survival, a time-zone change, and an action
tapped with the app killed. All are in the manual test plan, because none can
be asserted in `flutter test`.

## Traceability

Every requirement maps to a criterion in `acceptance-criteria.md`.
