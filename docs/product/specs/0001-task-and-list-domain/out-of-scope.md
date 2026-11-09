# Out of scope: Task and list domain

## Explicitly excluded

### Belongs to a sibling spec, not here

- Views (Heute, Demnächst, Alle, Erledigt), sorting, grouping, search and
  navigation — **spec 0002**.
- Local notifications, reminder scheduling, recurrence rules and instance
  handling — **spec 0003**.
- Import, export, the wire format, the Android receive boundary and the
  contract tests — **spec 0004**.
- The shared components this spec depends on (Markdown editor, snackbar/undo
  helper, share and URL seams, epoch-day converters) — they are built in
  slice 0 under
  `docs/delivery/implementation-plans/0000-shared-foundations.md`, not here.

### Not in 3.1.0 at all

| Item | Why |
|---|---|
| Sync, accounts, cloud storage | Local-first is a product promise, not a phase. Would need a backend and a privacy-policy change. |
| Collaboration, shared lists, assignment to a person | Needs the sync decision first. |
| Location-based reminders | Background location is a permission and privacy question of its own. |
| Attachments (files, photos) | The format is already decided — a `Link` with `rel: "enclosure"` — and is persisted (TLD-704). Only the UI is deferred. |
| A calendar view of tasks | This is a list app. A calendar is a different product with different semantics, and `due` is a deadline, not a time block (TLD-302). |
| Email-to-task, web clipper, integrations | All need a network. |
| AI suggestions of any kind | No. |
| Natural-language quick add ("morgen 17 Uhr") | Real value, moderate cost, no contract implications. Deferred to 3.2 so 3.1.0 ships. |
| Bulk multi-select actions | Same reasoning. Deferred to 3.2. |
| Home-screen widget | A category expectation on Android and a real want, but it is a second entry point with its own lifecycle. 3.2. |
| Task duplication | Cheap, but not needed to be credible. 3.2. |
| Statistics (completed per week, streaks) | Entirely local and cheap, but decorative for a first version. 3.2. |
| Backup / restore of the database | Needed eventually by every local-first app, and deliberately **not** a JSCalendar document — the two have different jobs (`data-contract.md` section 3). 3.2. |
| Deeper nesting than two levels | Rejected with a message rather than silently flattened (TLD-405). Raising the cap later needs no migration. |
| Rollup completion (parent follows subtasks) | Product decision with real edge cases; deferred, not rejected (Q-1b). |
| A time-zone picker per task | The column exists and round-trips (TLD-307). Tasks created in 3.1.0 are floating. |
| A UI for `estimatedDuration` | Persisted, no UI (TLD-308). Feeds a daily-total feature later. |

### Deliberately never in this app

- **Occurrences, occurrence keys, occurrence contexts, calendar projection,
  the reminder reconciliation service, the `[WTS2:…]` ownership marker.**
  These are WasThereSomething product semantics. None of them is exported, so
  none of them can be needed to read a document. If an implementation finds
  itself reaching for one, the document is wrong or the model has been
  misread — stop and check, do not port the concept.
- **`show_in_calendar`.** A WasThereSomething preference. Do not reuse the
  name and do not expect it on the wire.
- **A `delegated` progress value.** Not IANA-registered. Never emitted
  (TLD-202).
- **A full RFC 5545 recurrence engine (`rrule`).** A wider parser is a
  narrower contract — see ADR-0014.

## Possible future extensions

The model is deliberately built so that each of these is a screen, not a
migration:

- Attachments (`task_links.rel = 'enclosure'` already persists).
- A time-zone picker (`time_zone_id` already persists).
- `estimatedDuration` with a daily total (already persists).
- `percentComplete` on list surfaces (already persists).
- Deeper nesting (a constant, plus relaxing one repository check).
- Multiple lists per task — would need `list_id` to become a join table, so
  this one *is* a migration and is called out as such.

## Scope boundaries for the implementing agent

When implementing a story derived from this spec, do **not**:

- Change any file under `apps/mobile_app/lib/features/todos/` or its tests.
  The demo keeps working until slice 13, and slice 13 is a separate story.
- Delete or rename the demo's l10n keys, routes, table or startup task.
- Extend the database schema beyond the tables this spec defines, or bump
  `schemaVersion` beyond the step the story names.
- Introduce a new dependency. Every dependency for 3.1.0 is decided in
  ADR-0012 / ADR-0013 / ADR-0014 and in the shared-foundations plan; a story
  that appears to need another one stops and asks.
- Put a shared component inside `features/tasks/` with a promise to extract
  it later. If it is general, it lands in `packages/` or `core/` **in the same
  story** (ADR-0011, decision 4).
- Hand-write SQL for domain access, or edit a generated file
  (`*.g.dart`, `*.freezed.dart`, `lib/core/l10n/generated/`).
- Weaken or delete an existing test to make a suite pass.
- Copy code from the `WasThereSomething` repository without compiling it here
  first. The version deltas are real: `riverpod_annotation` ^3 vs ^4,
  `go_router` ^14 vs ^17, `share_plus` 12 vs 10.
- Touch the interchange format. It is fixed, tested on both sides, and not
  ours to change. If it appears to be wrong, say so and stop.
