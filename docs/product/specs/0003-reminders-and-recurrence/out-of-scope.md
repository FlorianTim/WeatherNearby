# Out of scope: Reminders and recurrence

## Explicitly excluded

### Belongs to a sibling spec

- The task model, the date columns, the trash and the undo helper —
  **spec 0001**.
- View membership and the *rendering* of a recurring task's next instance —
  **spec 0002**. This spec computes instances; views consume them.
- Serialization of `recurrenceRules` and `recurrenceOverrides`, and the import
  warnings for unsupported rules — **spec 0004**. This spec owns the stored
  form, the parser and the expander; spec 0004 owns the wire form.
- The Android manifest mechanism itself — **ADR-0013**. This spec inherits it
  for `BOOT_COMPLETED` (Q-3h).

### Not in 3.1.0

| Item | Why |
|---|---|
| `COUNT` and `UNTIL` in recurrence | Contract v1 does not define them, and this app must not be the source of incompatibility in the family it exists to validate. The right path is a contract change (Q-3a), not a unilateral extension. |
| Location-based reminders | Background location is its own permission, its own privacy question and its own battery profile. |
| Push notifications, Firebase, any server-side scheduling | There is no backend and there will not be one. Local-first is a product promise. |
| Exact alarms (`SCHEDULE_EXACT_ALARM` / `USE_EXACT_ALARM`) | A special-access permission restricted on Android 14+ to alarm and clock apps, a Play review question, and battery cost — for a benefit no to-do user asked for (ADR-0012, decision 3). |
| A recurring-task "skip this one" from the notification | The exclusion mechanism exists (`excluded` override); a third notification action does not. Two actions is already the useful maximum on a notification. |
| Per-reminder custom sound, vibration pattern or channel | One notification channel, the platform default. Channel proliferation is a settings screen nobody asked for. |
| Snooze presets beyond 1 Stunde / heute Abend / morgen | Three covers the real cases. A custom snooze picker on a notification is not a thing Android does well. |
| Reminders on a `start` date | `due` is the deadline and is what a reminder is about. A "you may begin" notification is a different product idea. |
| Reminders without a due time | RRC-203 refuses them rather than silently scheduling midnight, which is the behaviour every user reads as a bug. |
| A daily digest / "morning summary" notification | A different feature with its own scheduling model and its own settings. |
| Multiple notification channels per list or per priority | Same reasoning as sounds. |
| A UI for `excludedRecurrenceRules` | Persisted and round-tripped, written by no 3.1.0 code path (RRC-607). |
| `RSCALE` / non-Gregorian calendars | Outside contract v1 and outside any stated need. |
| Sub-daily recurrence (`hourly`, `minutely`, `secondly`) | Outside contract v1, and a to-do app that repeats hourly is a timer. |

### Deliberately never in this app

- **A reminder reconciliation service in the WasThereSomething sense.** There,
  a reminder is *derived* from `(rule, occurrence_key)` and a service keeps it
  consistent. Here the user sets a reminder directly on a task, so there is
  nothing to reconcile into existence. The reconciliation in this spec is
  between the database and the **OS** — a different job with a different
  shape. Do not port `ReminderReconciliationService`.
- **`ReminderRule` / `ReminderInstance` as model types.** Same reason.
- **JSCalendar `alerts` / `useDefaultAlerts`.** Outside contract v1 by
  decision: notifications are each app's own concern and are not
  interoperable state. Never emitted, never consumed, preserved as unknown
  properties if they arrive (RRC-209).
- **A domain-table write from a background isolate.** This is the trap
  ADR-0012 exists to close. A second Drift connection to the same file from a
  second isolate, with no `ProviderScope` and no repository invariants, fails
  silently and is untestable in widget tests.
- **A full RFC 5545 engine (`rrule`).** A wider parser is a narrower contract
  (RRC-505, ADR-0014).
- **A localized recurrence string in the database or on the wire.** "jeden
  Montag" is presentation. It is never persisted, never exported, never
  parsed (RRC-503).

## Possible future extensions

Each is additive; none is a migration:

- `COUNT` / `UNTIL`, once contract v1.1 defines them on both sides (Q-3a).
- A UI for `excludedRecurrenceRules` — the column already round-trips.
- A "skip this occurrence" action, using the existing `excluded` override.
- Promotion of the pending-action queue to a package once a second app faces
  the same isolate boundary (Q-3l, ADR-0012 follow-up).
- A configurable scheduling horizon, if the 60-day default proves wrong
  (Q-3i).

## Scope boundaries for the implementing agent

When implementing a story derived from this spec, do **not**:

- Change anything under `apps/mobile_app/lib/features/todos/`. The demo keeps
  working until slice 13, which is a separate story.
- Import `flutter_local_notifications` anywhere except the gateway
  implementation in `core/notifications/` (RRC-001). An import-scanning test
  enforces this.
- Write to any domain table from a background entry point (RRC-402, RRC-403).
  Append one record to the pending-action store and return. If the background
  half appears to need a repository, stop — the design has been misread.
- Add `permission_handler` or any other permission package. The notification
  plugin requests its own permission (RRC-104, ADR-0012 decision 6).
- Add `rrule`, or extend the parser beyond `FREQ`, `INTERVAL`, `BYDAY`,
  `BYMONTHDAY` (RRC-501, RRC-505).
- Declare `SCHEDULE_EXACT_ALARM` or `USE_EXACT_ALARM`, or switch to an exact
  scheduling mode (RRC-005).
- Edit an `AndroidManifest.xml` directly. There is no committed `android/`;
  manifest changes go through the bootstrap patcher, with both the bash and
  the PowerShell path updated (ADR-0013).
- Re-derive a `recurrence_id` from a `DateTime`. It is the verbatim wire
  string (RRC-602).
- Construct a fire moment by parsing a stored local date-time as UTC
  (RRC-301). Compute from components.
- Add an unbounded expansion entry point (RRC-605).
- Persist or parse a localized recurrence string (RRC-503).
- Leave a timer pending in a widget test — flutter_test's invariant will fail
  it (KI-005).
- Introduce any dependency beyond `flutter_local_notifications` and
  `timezone`, both already justified in ADR-0012, and resolve even those
  against the KI-001 tree before adoption.
- Weaken, skip or delete an existing test to make a suite pass.
