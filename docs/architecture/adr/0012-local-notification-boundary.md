# ADR-0012: Local notification boundary — scheduling, actions and what may run without a UI

## Status

proposed

## Date

2026-08-25

## Decision owners

- Product Owner (F. Kroschewski)
- Template architecture

## Related feature / spec

- `docs/product/specs/0003-reminders-and-recurrence/`
- `docs/architecture/contracts/04-permissions.md`
- `docs/architecture/patterns/platform-gateways.md`
- Slice 6 of `docs/delivery/implementation-plans/0001-todo-reference-app.md`

## Related issues / PRs

- none yet

## Context

A to-do app without reminders is a list. Reminders are therefore not optional
for the reference app — and they are the first time this template touches
four things at once: a runtime permission it has never actually requested, an
OS scheduler, a background entry point that can run without any UI, and a
class of data (task titles) that is personal free text.

The template's starting position, verified:

- `core/permissions/` has the just-in-time flow (`ensurePermission`) and the
  `PermissionGateway` interface, but **no concrete implementation and no
  permission plugin**. The only implementation is a test fake.
- There is no notification code, no seam, and no scheduler of any kind.
- `docs/architecture/patterns/permissions.md` names `permission_handler` as
  the intended package but is a pattern doc, not code.

Four decisions are needed: which package, where the boundary sits, what a
notification action is allowed to do, and how exact the scheduling has to be.

The last one is not a detail. Android's `SCHEDULE_EXACT_ALARM` is a
special-access permission; on Android 13 it was grantable by declaration, on
14+ it is restricted to apps whose core function is alarms and clocks, and
Google Play reviews its use. A to-do reminder is not an alarm clock.

The background question is the sharpest. "Erledigt" on a notification means a
database write while the app may have no `Activity`, no `ProviderScope` and,
on Android, a **separate Dart isolate** with its own memory. WasThereSomething
flagged exactly this for its spec 0031 and did not resolve it. Getting it
wrong produces a bug class that is invisible in every widget test: the write
appears to succeed in the background isolate and the foreground never sees it,
or two isolates open the same SQLite file and one loses.

## Decision

1. **`flutter_local_notifications` is the package.** BSD-3, actively
   maintained, no network, first-party-adjacent in the Flutter ecosystem,
   and the only serious option for local-only scheduling. It pulls
   `timezone` (BSD-2) transitively, which the app needs anyway for
   zone-correct scheduling. See "Dependency justification" below.

2. **Everything goes through one app-owned seam.** No widget, notifier or
   repository ever imports `flutter_local_notifications`. The boundary is:

   ```dart
   // apps/mobile_app/lib/core/notifications/notification_gateway.dart
   abstract interface class NotificationGateway {
     Future<void> schedule(ScheduledNotification n);
     Future<void> cancel(int notificationId);
     Future<void> cancelAll();
     Future<List<int>> pending();
   }
   ```

   with `ScheduledNotification` an app-owned value type (id, title, body,
   local date-time, time-zone id, payload, action set). A `FakeNotificationGateway`
   records calls and is what every widget test sees. This is the
   platform-gateway pattern the template already documents; the notification
   plugin is a platform operation, so a full gateway interface is mandatory,
   not a typedef seam (library-evaluation contract, "when a wrapper is
   mandatory").

3. **Scheduling is inexact by default.** The app uses
   `AndroidScheduleMode.inexactAllowWhileIdle` and does **not** declare
   `SCHEDULE_EXACT_ALARM` or `USE_EXACT_ALARM`. A to-do reminder that arrives
   within the OS's batching window is a correct to-do reminder. Exact alarms
   are a special-access permission for alarm-clock apps, they invite Play
   review questions, and they cost battery. If a future product decision
   genuinely needs to-the-minute delivery, that is a new ADR with a stated
   reason, not a default.

4. **Notification actions do not write to the database from a background
   isolate.** Two actions are offered — **Erledigt** and **Später** (snooze) —
   and both are implemented as *intents recorded for the foreground*, not as
   background mutations:

   ```text
   action tapped
        -> background handler writes ONE pending-action record
           (append-only, its own tiny store, no domain tables touched)
        -> notification is dismissed / rescheduled by the plugin
        -> next foreground start (or resume) drains the queue inside the
           normal app isolate, in the normal repository, in a transaction
   ```

   The background handler therefore touches no Drift database, no Riverpod
   container and no domain code. It appends a record and returns.

   **Why not just write the task row in the background?** Because the
   background isolate is a different isolate with a different memory space:
   the Riverpod container is not there, the Drift database would be a second
   connection to the same file, and every invariant the repository enforces
   (tree safety, transactions, recurrence advancement) lives in code that
   assumes it runs once. A queue makes the background half trivially correct
   and testable, and moves the interesting logic to where it is already
   tested.

   **Cost, stated plainly:** "Erledigt" from a notification does not take
   effect until the app next runs. The notification is dismissed immediately,
   so it *looks* done; the row changes on the next start. For a local to-do
   app with no sync and no second device, this is acceptable. It is written
   down here so nobody discovers it as a bug.

5. **The permission is requested just in time, at the first reminder.** Not
   at startup, not on screen entry — on the action that needs it, through the
   existing `ensurePermission` flow with an in-app rationale first. A denied
   permission is not a failure: the reminder is stored, the app says clearly
   that it cannot notify, and offers the way to the system settings.

6. **The first concrete `PermissionGateway` implementation lands here**, for
   `POST_NOTIFICATIONS`. The plugin decision is deferred by one step on
   purpose: `flutter_local_notifications` can request the notification
   permission itself
   (`AndroidFlutterLocalNotificationsPlugin.requestNotificationsPermission()`),
   so slice 6 implements `NotificationPermissionGateway` on top of the
   notification plugin and adds **no** permission package. A second
   permission (camera, contacts, location) would justify
   `permission_handler`; one permission does not.

7. **Rescheduling is a startup task.** Reminders are re-materialized on boot,
   on time-zone change and on app start, from the database, through the
   gateway. The OS is treated as a cache that may have been cleared, never as
   the source of truth. `pending()` exists so the reconciliation can be
   asserted in a test.

8. **No task content in logs, ever.** Reason codes and counts only. The
   notification *payload* carries a task id, never a title. This follows the
   privacy block of `openspec/apps/todo.openspec.yaml`.

9. **Lock-screen visibility is a setting**, default "show the title"
   (open question Q-04, resolved as proposed). The generic alternative
   ("1 Aufgabe fällig") is one `SettingDef` away for a user who shares a
   device.

## Alternatives considered

| Alternative | Pro | Contra |
|---|---|---|
| **Write the task row directly in the background isolate** | "Erledigt" is instantly true in the database | A second Drift connection to the same file from a second isolate; no Riverpod container; repository invariants that assume single-threaded foreground execution. This is the trap WasThereSomething flagged and did not solve. The failure mode is silent and untestable in widget tests. |
| **No notification actions at all** — tapping opens the app | Simplest possible background story | The two actions are what makes a reminder useful rather than annoying. Category expectation. The queue makes them cheap. |
| **Exact alarms (`SCHEDULE_EXACT_ALARM`)** | To-the-minute delivery | Special-access permission, restricted on Android 14+ to alarm/clock apps, a Play review question, and battery cost — for a benefit no to-do user has asked for. |
| **`permission_handler` now** | One package for every future permission; the pattern doc already names it | A whole permission framework for the one permission the notification plugin can request itself. Library-evaluation rule 9. Revisit when a second permission appears. |
| **`awesome_notifications`** | Richer notification UI, built-in action routing | Much larger surface, more platform coupling, and it wants its own initialization and its own permission model. The seam would be bigger than the feature. |
| **Derive reminders from a rule, WasThereSomething-style reconciliation** | Reuses a proven design | Solves a problem this app does not have. Here the user sets a reminder directly on a task; there is nothing to reconcile. Draft 7 says the same. |

## Consequences

### Positive

- Widget tests never touch a platform channel: the fake gateway is the only
  thing the UI sees.
- The background code path is ~30 lines and has one job, so it can be
  reasoned about and tested with a plain unit test.
- No special-access permission, no Play review conversation, no battery
  complaint.
- The template gains its first real `PermissionGateway` implementation and
  its first notification seam — both reusable by every derived app.

### Negative

- A completion from a notification is eventually consistent, not immediately
  consistent (decision 4). Documented, accepted, and visible in the spec's
  acceptance criteria rather than discovered later.
- The pending-action queue is one more small persistence surface (its own
  store, its own drain, its own test) that exists purely because of an
  isolate boundary.
- Inexact scheduling means a reminder may arrive minutes late in Doze. The
  copy in the reminder editor should not promise a precise time.
- `timezone` enters the dependency tree. KI-009(a) is the recorded worked
  example of two packages becoming mutually unresolvable through exactly this
  package. Nothing else in the tree depends on it today, so the conflict
  surface is currently empty — but the constraint must be recorded when it is
  added, so the next package that wants `timezone` finds the note.

## Dependency justification

Required by `docs/architecture/contracts/06-library-evaluation.md`.

| | `flutter_local_notifications` | `timezone` |
|---|---|---|
| **Purpose** | schedule and cancel local notifications; deliver action taps | zone-correct instants for scheduling |
| **Licence** | BSD-3 | BSD-2 |
| **Maintenance** | actively released, widely used, the de-facto standard | actively released; IANA database updates |
| **Platform coverage** | Android, iOS, macOS, Linux. **Web: not supported** — the app degrades to "no reminders" on web, which must be stated in the UI, not crashed on | pure Dart, all platforms |
| **Network** | none. Verified: local scheduling only, no push, no Firebase | none |
| **Abstraction** | mandatory full gateway (decision 2) | used only inside the gateway implementation |
| **Lock-in risk** | low — the seam is four methods | low |
| **Transitive check** | runtime-only; no analyzer constraint, so it does not move the KI-001 ceiling. **Must still be resolved against the tree before adoption** (library-evaluation rule 10) | pulled by the above; record the constraint per KI-009(a) |
| **Removal path** | delete the gateway implementation; the interface and the fake stay, and the app degrades to "reminders stored, never delivered" | falls away with the above |

## Test and validation impact

- Every reminder-related widget test runs against `FakeNotificationGateway`;
  no test may reach a platform channel.
- Unit tests for the pending-action queue: append, drain, idempotent drain,
  drain with a task that was deleted in the meantime, drain twice.
- A reconciliation test: given N reminders in the database and a gateway
  reporting a different pending set, the startup task converges to N.
- Time-zone and DST cases are unit-testable because scheduling is computed
  from stored components, never from a round-tripped instant.
- Manual test plan entries for: permission denied then granted in settings,
  reboot, time-zone change, action tapped while the app is dead.

## Follow-up tasks

- Record the `timezone` constraint in `docs/known-issues.md` when it is added
  (extend KI-009 rather than opening a new entry).
- Decide whether the pending-action queue belongs in `core/` (template) or in
  `features/reminders/` (app). Proposal: `core/notifications/`, because any
  app with a notification action faces the identical isolate boundary.
- Revisit `permission_handler` when a second runtime permission appears.

## References

- `drafts/notes/3.1.0/lumbrecode_todo_app_notes.md` section 12
- `docs/architecture/contracts/04-permissions.md`
- `docs/architecture/contracts/06-library-evaluation.md`
- `docs/architecture/patterns/platform-gateways.md`
- `docs/known-issues.md` KI-009
- WasThereSomething spec 0031 (system notifications) — the flagged, unsolved
  background-isolate trap
