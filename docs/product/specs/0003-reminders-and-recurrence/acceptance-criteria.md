# Acceptance criteria: Reminders and recurrence

Format: Given / When / Then, with the requirement proved and the test level.
Levels: `unit`, `property`, `repository`, `widget`, `integration`, `manual`.

## The notification boundary

**AC-01 — nothing imports the plugin except the gateway** (RRC-001) · unit
Given the app's sources
Then exactly one file imports `flutter_local_notifications`, and it is the
gateway implementation in `core/notifications/`.

**AC-02 — no test reaches a platform channel** (RRC-003) · widget
Given every widget test that touches a reminder
Then each runs with `FakeNotificationGateway` injected, and a probe asserting
that the real implementation was never constructed passes.

**AC-03 — scheduling is inexact and declares no alarm permission** (RRC-005) · unit + manual
Given the gateway implementation
Then it passes `inexactAllowWhileIdle`; and the generated `AndroidManifest.xml`
after a bootstrap contains neither `SCHEDULE_EXACT_ALARM` nor
`USE_EXACT_ALARM`.

**AC-04 — the web build degrades honestly** (RRC-007) · widget
Given the no-op gateway used on web
When a reminder is created
Then the row is stored, `schedule` does not throw, and the UI shows that
reminders cannot be delivered on this platform.

**AC-05 — no task content in logs** (RRC-006) · integration
Given a task with a distinctive title and body and a scheduled reminder
When scheduling, reconciliation, delivery and draining all run
Then neither string appears in any captured log line, and the notification
payload contains only an id.

## Permission

**AC-06 — asked at the first reminder, never at startup** (RRC-101) · widget
Given a fresh install
When the app starts, the splash completes and Heute renders
Then no permission has been requested; and when the user saves their first
reminder, the rationale is shown and only then the system dialog.

**AC-07 — permanently denied does not get a rationale** (RRC-102) · widget
Given `PermissionState.permanentlyDenied`
When a reminder is saved
Then the blocked sheet is shown with a route to the system settings, the
rationale is not shown, and `request()` is not called.

**AC-08 — denied keeps the app usable** (RRC-103) · widget
Given the permission is denied
When a reminder is saved
Then the `reminders` row exists, the app remains fully usable, and the UI
names exactly what is limited — not a generic error.

**AC-09 — no permission package was added** (RRC-104) · unit
Given every `pubspec.yaml` in the workspace
Then none declares `permission_handler` or any other permission package, and
the concrete gateway is implemented on the notification plugin's own API.

**AC-10 — state is read from the system, not cached** (RRC-105) · widget
Given the permission was granted and is then revoked externally (fake
gateway flips its state)
When the next reminder is saved
Then the flow observes the new state without an app restart.

## Reminders

**AC-11 — a reminder needs a due time** (RRC-203) · widget
Given a task with no due date, and another with a date-only due
When a reminder is set on each
Then neither is silently scheduled at midnight; each either prompts to add a
time or is refused with a readable reason.

**AC-12 — duplicates are not representable** (RRC-202) · repository
Given a task with a reminder at 60 minutes before
When a second reminder at 60 minutes before is inserted
Then the insert fails on the unique constraint and the first is unchanged.

**AC-13 — lifecycle changes cancel and restore** (RRC-205) · repository
Given a task with two future reminders
When it is completed, then un-completed, then trashed, then restored
Then the gateway received cancels on completion and on trash, and re-schedules
on un-completion and on restore — and only for moments still in the future.

**AC-14 — a past moment is not scheduled and says so** (RRC-206) · widget
Given a task due yesterday at 10:00
When a reminder at the due time is set
Then `schedule` is not called and the UI states that the moment has passed.

**AC-15 — alerts are never on the wire** (RRC-209) · unit
Given any document the app exports
Then it contains no `alerts` and no `useDefaultAlerts` property; and the
importer ignores both while preserving them as unknown properties.

## Scheduling and reconciliation

**AC-16 — the moment comes from components, not from an instant** (RRC-301) · property
Given every due date in a year spanning a DST transition, in `Europe/Berlin`,
each with a 60-minute lead time
When the fire moment is computed
Then the wall-clock time is the due time minus 60 minutes in every case, with
no hour shifted around the transition, and no code path constructs the value
by parsing the stored local date-time as UTC.

**AC-17 — floating and zoned behave differently and correctly** (RRC-302) · unit
Given two identical tasks, one with `time_zone_id = NULL` and one with
`Europe/Berlin`, while the device is in `America/New_York`
Then the floating one fires at the wall-clock time in New York and the zoned
one fires at the wall-clock time in Berlin.

**AC-18 — reconciliation converges from any state** (RRC-303, RRC-304) · repository
Given a database with 10 future reminders, and a gateway reporting: (a) an
empty pending set, (b) a stale set with 3 handles the database does not know,
(c) the correct set
When reconciliation runs in each case
Then the resulting pending set is exactly the 10 in all three, unknown handles
are cancelled, and case (c) issues **no** schedule or cancel call at all.

**AC-19 — reconciliation is bounded** (RRC-305) · repository
Given 500 future reminders spread over two years
When reconciliation runs
Then only those inside the 60-day horizon are scheduled, the count is bounded
and reported, and a later run materializes the next window.

**AC-20 — one failure does not abort the run** (RRC-306) · repository
Given a gateway that throws for one specific reminder
When reconciliation runs over 10
Then the other 9 are scheduled, the failure is counted with a reason code,
and no exception message reaches the UI.

**AC-21 — reconciliation writes no domain table** (RRC-307) · repository
Given a populated database
When reconciliation runs
Then the only column written anywhere is `reminders.notification_id`, and
every `tasks`, `lists`, `tags` and override row is byte-identical afterwards.

## Notification actions

**AC-22 — the background handler appends and returns** (RRC-402, RRC-403) · unit
Given a notification action invoked in the background entry point
Then exactly one pending-action record is appended, and no Drift domain
database, Riverpod container or repository is constructed anywhere in the
call path.

**AC-23 — the queue drains through the normal repository** (RRC-404) · integration
Given a pending "Erledigt" record for an existing task
When the app next starts
Then the drain runs in the app isolate, the task's `progress` becomes
`completed` through the repository in a transaction, and `progress_updated_at`
is set.

**AC-24 — draining is idempotent** (RRC-405) · repository
Given one pending record
When the drain runs twice
Then the resulting state is identical to running it once, and the second run
reports zero applied.

**AC-25 — a stale record is counted, not an error** (RRC-406) · repository
Given pending records for: a deleted task, a task already completed, and a
valid task
When the drain runs
Then the valid one is applied, the other two are counted as skipped with
reason codes, and nothing throws.

**AC-26 — snooze moves the reminder, not the deadline** (RRC-409) · repository
Given a task due today at 10:00 with a reminder at the due time
When "Später — 1 Stunde" is applied
Then the notification is rescheduled to 11:00 and `due_date_day` /
`due_minutes` are unchanged.

**AC-27 — tapping the body opens the task with a sane back stack** (RRC-407) · integration
Given the app is not running
When the notification body is tapped
Then the task detail opens and one back press leads to Heute, not out of the
app.

## Recurrence — the rule

**AC-28 — exactly the supported subset parses** (RRC-501) · unit
Given `FREQ=DAILY;INTERVAL=3`, `FREQ=WEEKLY;BYDAY=MO,WE`,
`FREQ=MONTHLY;BYDAY=1SA`, `FREQ=MONTHLY;BYMONTHDAY=1,15`, `FREQ=YEARLY`
Then all five parse; and `FREQ=HOURLY`, `FREQ=DAILY;COUNT=4`,
`FREQ=DAILY;UNTIL=20270101T000000Z`, `FREQ=DAILY;BYSETPOS=1` are each
rejected with a typed, nameable error.

**AC-29 — an unsupported rule imports as non-recurring with a warning** (RRC-502) · unit
Given a document with `"frequency": "daily", "count": 4`
When it is imported
Then the task is created without recurrence and exactly one
`UnsupportedRecurrence` warning is counted and surfaced.

**AC-30 — weekday case is mapped, not assumed** (RRC-506) · unit
Given the stored string `FREQ=WEEKLY;BYDAY=MO,WE`
When it is encoded to JSCalendar and decoded back
Then the wire form carries `"day": "mo"` and `"day": "we"` in lowercase, the
round trip returns the identical uppercase stored string, and the mapping
function is covered for all seven days in both directions.

**AC-31 — no localized rule string is ever persisted** (RRC-503) · unit
Given the sources and the database after exercising the recurrence editor in
both locales
Then no column holds "jeden Montag", "every monday" or any localized form,
and the human-readable rendering exists only in the presentation layer.

**AC-32 — recurrence needs a date** (RRC-507) · repository
Given a task with neither `start` nor `due`
When a recurrence rule is set
Then the write is rejected with a readable message.

**AC-33 — `rrule` is not a dependency** (RRC-505) · unit
Given every `pubspec.yaml` in the workspace
Then none declares `rrule`.

## Recurrence — instances

**AC-34 — a recurring task is never cloned** (RRC-601) · repository
Given a daily task expanded over 90 days, with two instances completed and
one excluded
Then `tasks` holds exactly one row, and `task_recurrence_overrides` holds
exactly three.

**AC-35 — the override key is the wire string, verbatim** (RRC-602) · repository
Given an instance at 13 March 2027, 10:00
Then the stored `recurrence_id` is exactly `2027-03-13T10:00:00` — no offset,
no `Z` — and it is not re-derived from a `DateTime` on read.

**AC-36 — exclusion is an override, not a table** (RRC-603) · unit
Given an excluded instance
Then it is a row with `excluded = 1`, the schema contains no separate
exclusion table, and the exported form is
`"recurrenceOverrides": {"…": {"excluded": true}}`.

**AC-37 — completing one instance leaves the others alone** (RRC-604) · repository
Given a weekly task with instances on three consecutive Mondays
When the second is completed
Then an override exists for the second only, the task's own `progress` is
unchanged, and the first and third instances are still open.

**AC-38 — expansion is bounded** (RRC-605) · unit
Given `FREQ=DAILY` with no end
When expansion is requested
Then every entry point requires a window or a count, and no API can return an
unbounded list. An attempt to expand without bounds does not compile.

**AC-39 — expansion is deterministic and ordered** (RRC-606) · property
Given 1 000 random valid rules, anchors and windows
When each is expanded 10 times
Then every run returns the identical, strictly ascending instance list.

**AC-40 — expansion is calendar-correct** (RRC-608) · unit
Given `FREQ=MONTHLY;BYMONTHDAY=31` anchored 31 January 2027
Then February produces no instance (it is skipped, not shifted to the 1st or
the 28th), March produces the 31st; and given `FREQ=YEARLY` anchored
29 February 2028, the next instance is 29 February 2032.

## Completion mode

**AC-41 — schedule mode ignores when you finished** (RRC-702) · repository
Given a monthly task due the 1st, in `schedule` mode, completed on the 9th
Then the next due date is the 1st of the following month.

**AC-42 — completion mode counts from completion** (RRC-703) · repository
Given `FREQ=DAILY;INTERVAL=3` in `completion` mode, due the 25th, completed on
the 27th
Then the next due date is the 30th, not the 28th.

**AC-43 — advancing preserves the start/due offset** (RRC-706) · repository
Given a task with `start` two days before `due`, in `completion` mode
When it is completed
Then both dates advance in one transaction, the two-day gap is preserved, and
the task's reminders are rescheduled to match.

**AC-44 — the mode is worded, not jargon** (RRC-704) · widget
Given the recurrence editor with a rule set
Then the two choices read "ab Fälligkeitsdatum" and "ab Erledigung" in
German, with equivalents in English, and neither label contains the word
"mode" or a technical value.

**AC-45 — the mode never leaks into a standard property** (RRC-705) · unit
Given an exported task in `completion` mode
Then no standard JSCalendar property is altered by the mode, and if the mode
is emitted at all it appears only as `lumbrecode.de:recurrenceMode` on the
payload — never as a CloudEvents attribute.

## Manual verification steps

None of these can be asserted in `flutter test`. All are manual test-plan
entries.

1. A reminder actually arrives on a device, roughly on time, with the app
   killed.
2. After a device reboot, previously scheduled reminders still arrive
   (reconciliation ran).
3. After changing the device time zone, a floating and a zoned reminder each
   behave as AC-17 specifies.
4. "Erledigt" tapped on a notification with the app killed: the notification
   disappears immediately, and the task is completed when the app is next
   opened (the eventual-consistency behaviour from ADR-0012).
5. Denying the notification permission, then granting it in the system
   settings, then returning to the app.
6. Lock-screen content with the title setting on and off.
7. The recurrence editor at 200 % text scale, in both locales.
