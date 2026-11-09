# Acceptance criteria: Task and list domain

Format: Given / When / Then, with the requirement proved and the test level.
Levels: `repository` (Drift, in-memory), `unit`, `widget`, `integration`,
`property`, `manual`.

## Identity and lifecycle

**AC-01 — a title is a whole task** (TLD-004, TLD-101) · repository
Given an empty database with an Inbox
When "Milch kaufen" is created with no other field set
Then a `tasks` row exists with that title, `progress = 'needs-action'`,
`list_id` pointing at the Inbox, a valid v4 UUID, both date pairs `NULL`,
and no row in `task_tags`, `task_links`, `reminders` or
`task_recurrence_overrides`.

**AC-02 — the uid is a real v4 UUID, stable and unique** (TLD-002, TLD-003) · property
Given 100 000 generated uids
Then every one matches `^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$`,
all are distinct, and editing a task's title leaves its uid unchanged.

**AC-03 — the row id never leaves and the uid is never a key** (TLD-001, TLD-003) · unit
Given any exported document produced by the app
Then no `tasks.id` value appears anywhere in it, and no foreign key column in
the schema references `jscalendar_uid`.

**AC-04 — deleting a task deletes nothing else** (TLD-005) · repository
Given a list with three tasks, one of which has a tag, a link and a reminder
When that task is permanently deleted
Then its tag assignment, link and reminder are gone, the tag *definition*
still exists, and the other two tasks and the list are untouched.

**AC-05 — updated_at moves only on a real change** (TLD-006) · repository
Given a task
When it is read, listed and rendered but not edited
Then `updated_at` is unchanged; when its title is edited, `updated_at` moves.

## Content

**AC-06 — Markdown survives verbatim** (TLD-102, TLD-103) · repository
Given the body ``Bitte **dunkle Schokolade**.\n\n- 12 Kerzen\n- Streichhölzer``
When it is saved and read back
Then the string is byte-identical and
`description_content_type = 'text/markdown; charset=utf-8'`.

**AC-07 — the cap is enforced, not silent** (TLD-105) · widget
Given a body of 20 001 characters
When the user saves
Then the save is refused with a readable message and nothing is truncated.

**AC-08 — plain text stays plain** (TLD-106) · widget
Given an imported task whose `description_content_type` is `text/plain` and
whose body contains `**not bold**`
When the detail view renders it
Then the literal asterisks are visible; no Markdown rendering is applied.

**AC-09 — one editor, one renderer** (TLD-104) · unit
Given the app's source tree
Then exactly one widget class provides Markdown editing and exactly one
provides Markdown rendering, both from `packages/design_system`, and no
`features/**` file constructs a `TextField` for a task body directly.

**AC-10 — content stays out of logs** (TLD-107) · integration
Given a task with a distinctive title and body
When a reminder is scheduled, a document is exported, an error is recorded in
the last-error buffer and a feedback mail is composed
Then neither string appears in any captured log line or in any of those
outputs.

## Progress

**AC-11 — the checkbox produces exactly two values** (TLD-203) · widget
Given a task with `progress = 'needs-action'`
When the list checkbox is tapped twice
Then the observed values are `completed` then `needs-action`, and never
`in-process`, `failed` or `cancelled`.

**AC-12 — the full vocabulary is reachable and correct** (TLD-201, TLD-204) · widget
Given the task detail
When the progress picker is opened
Then exactly five options are offered, their persisted values are
`needs-action`, `in-process`, `completed`, `failed`, `cancelled`, and
`delegated` appears nowhere in the source tree.

**AC-13 — an unknown stored value degrades and is preserved** (TLD-202) · repository
Given a row whose `progress` column holds `delegated`
When the task is read, rendered and then re-exported without being edited
Then it behaves as `needs-action` in every query and the exported value is
still `delegated`.

**AC-14 — the demo enum is gone from the new domain** (TLD-205) · unit
Given the new domain sources
Then no file references `TodoStatus`, and no mapping from `pending` to
`needs-action` exists anywhere.

**AC-15 — progressUpdated tracks progress only** (TLD-208) · repository
Given a task
When only its title is edited, `progress_updated_at` is unchanged; when its
progress changes, it is set to the current UTC instant with second precision.

**AC-16 — completion does not cascade** (TLD-209) · repository
Given a parent with two subtasks
When the parent is completed, both subtasks stay `needs-action`; when both
subtasks are completed, the parent stays `needs-action`.

**AC-17 — percentComplete follows progress unless the user spoke** (TLD-206, TLD-207) · repository
Given a task in `in-process` with `percent_complete = 40`
When it is set to `completed` without touching the percentage, the value
becomes 100; when it is set to `needs-action`, the value becomes 0; when
progress and percentage are changed in the same edit, the user's value wins.

## Dates

**AC-18 — all four date shapes are valid and distinguishable** (TLD-301) · repository
Given four tasks with: no date, start only, due only, both
Then all four persist and read back with exactly the columns set that were
set, and no shape is coerced into another.

**AC-19 — a date-only value uses NULL minutes, not midnight** (TLD-303, TLD-304) · repository
Given a task due 14 March 2027 with no time
Then `due_date_day` is the epoch day of that date, `due_minutes IS NULL`, and
`show_without_time = 1`. No `DateTime` column carries the date.

**AC-20 — a local date-time never travels through an instant** (TLD-305) · property
Given every date in a year around a DST transition, in `Europe/Berlin`
When each is stored and read back
Then the calendar day and the minute are identical to the input in every
case, and no code path in the date helpers constructs a `DateTime` from a
stored day/minute pair except for display and scheduling.

**AC-21 — start must not be after due** (TLD-306) · repository + widget
Given a task with `due` on 10 March
When `start` is set to 11 March
Then the repository rejects the write with a typed error, and the editor
refuses the save with a readable message.

**AC-22 — no duration is derived** (TLD-302) · unit
Given a task with `start = Fri 18:00` and `due = Sat 10:00`
Then no accessor, mapper or view model exposes a duration, an end time or an
occupied range derived from the pair.

**AC-23 — impossible dates are rejected calendar-correctly** (TLD-309) · unit
Given 29 February 2027 (not a leap year) and 31 April
Then both are rejected through `DateValidation`, and 29 February 2028 is
accepted.

## Subtasks

**AC-24 — self-parenting is rejected at the repository** (TLD-402) · repository
Given a task
When it is assigned itself as parent through the repository directly
Then the write is rejected and the row is unchanged.

**AC-25 — cycles are impossible** (TLD-403) · property
Given 10 000 random parent assignments over 200 tasks, each applied through
the repository
Then no assignment that would create a cycle succeeds, and walking every
task's ancestor chain terminates.

**AC-26 — depth is capped, not flattened** (TLD-405) · repository
Given a task with a subtask
When a third task is assigned the subtask as parent
Then the write is rejected with a readable message; the third task is not
silently attached to the grandparent.

**AC-27 — deleting a parent names the count** (TLD-406) · widget
Given a parent with two subtasks
When deletion is requested
Then the confirmation names "2 Teilaufgaben", and on confirmation all three
rows move to the trash in one transaction.

**AC-28 — a subtask inherits nothing** (TLD-407) · repository
Given a parent with a due date, a priority and two tags
When a subtask is created under it
Then the subtask has no date, priority 0 and no tags.

**AC-29 — moving a parent moves its subtasks** (TLD-408) · repository
Given a parent with two subtasks in list A
When the parent is moved to list B
Then all three rows have `list_id = B` after a single transaction, and no
intermediate state is observable on the stream.

## Lists

**AC-30 — exactly one Inbox, always** (TLD-502, TLD-507) · repository
Given a fresh database
Then exactly one list has `is_inbox = 1`; attempting to insert a second, to
delete it, to rename it or to archive it fails; and the guard is a schema
constraint, not only a UI rule.

**AC-31 — no list chosen means Inbox** (TLD-504) · widget
Given quick add on the Today screen
When a task is created with a title only
Then its `list_id` is the Inbox.

**AC-32 — deleting a list names the count and takes the tasks with it** (TLD-506) · widget + repository
Given a list with five tasks
When deletion is requested
Then the confirmation names "5 Aufgaben"; on confirmation the list and all
five tasks are in the trash, and none of them appears in the Inbox.

**AC-33 — an archived list keeps its tasks and disappears** (TLD-508) · repository
Given a list with tasks
When it is archived
Then `archived_at` is set, the list appears in no view and in no list
overview, its tasks appear in no view, and restoring returns all of it.

**AC-34 — the Inbox is pinned and outside the reorder range** (TLD-509) · widget
Given four lists including the Inbox
When the user drags a list to position 0
Then the Inbox remains first and the dragged list lands at position 1.

## Tags

**AC-35 — tag names are unique case-insensitively** (TLD-601) · repository
Given a tag "Einkauf"
When "einkauf " is created
Then the existing tag is reused and no second row is inserted.

**AC-36 — tags are cross-cutting** (TLD-603) · repository
Given a tagged task
When it is moved to another list
Then its tag assignments are unchanged, and the same tag is assignable to
tasks in any list.

**AC-37 — deleting a tag leaves tasks intact** (TLD-604) · repository
Given a tag on three tasks
When the tag is deleted
Then all three tasks still exist and hold no dangling assignment.

## Priority and links

**AC-38 — the inversion never reaches the user** (TLD-701, TLD-702) · widget + repository
Given the priority picker
When "hoch" is chosen
Then `priority = 1` is stored, the row shows a "hoch" indicator, and no
user-visible string contains the number.

**AC-39 — only http and https launch** (TLD-705) · widget
Given a task with links `https://example.invalid/a`, `mailto:x@example.invalid`
and `file:///etc/passwd`
When each is tapped
Then only the first reaches the URL seam; the other two are displayed and the
seam is never called.

**AC-40 — nothing is fetched automatically** (TLD-706) · integration
Given a task with three links
When the detail view is opened and fully rendered
Then the network seam records zero calls, and no favicon, preview or size
lookup was attempted.

## Ordering

**AC-41 — order is explicit and deterministic** (TLD-801, TLD-802) · repository
Given twenty tasks inserted inside the same second
When the list is read in manual order
Then the order is exactly the assigned `sort_order` sequence, is identical on
100 repeated reads, and no query orders by a `DateTime` column.

**AC-42 — a reorder is atomic** (TLD-803) · repository
Given a list of ten tasks
When one is dragged from position 8 to position 1
Then the stream emits exactly one new ordering, and no intermediate ordering
is ever observed.

**AC-43 — sort_order never travels** (TLD-804) · unit
Given any exported document
Then it contains no `sortOrder` property and no vendor extension carrying one.

## Deletion, undo, trash

**AC-44 — every destructive action is undoable** (TLD-901) · widget
Given a task
When it is completed by swipe, deleted by swipe, moved, and its list is
archived
Then each action shows an undo affordance, and each undo restores the exact
previous state.

**AC-45 — deletion is soft first** (TLD-902, TLD-903) · repository + widget
Given a deleted task
Then `deleted_at` is set, the row still exists, the task appears in no view,
and it is listed in the trash screen with restore and permanent-delete
actions.

**AC-46 — restore handles a missing home** (TLD-905, TLD-906) · repository
Given a trashed subtask whose parent was permanently deleted, and a trashed
task whose list was permanently deleted
When each is restored
Then the first becomes a top-level task and the second lands in the Inbox,
and in both cases the app reports what it had to change.

**AC-47 — the purge is idempotent** (TLD-904) · repository
Given trashed tasks aged 29, 30 and 31 days
When the purge runs twice
Then only the 31-day task is removed, the second run removes nothing, and the
run is safe to interrupt.

**AC-48 — permanent deletion takes the dependents** (TLD-907) · repository
Given a task with tags, links, a reminder and a recurrence override
When it is permanently deleted
Then no orphan row remains in any dependent table, in one transaction.

## Data layer

**AC-49 — foreign keys are actually enforced** (TLD-1002, TLD-1003) · repository
Given an open database
When a task is inserted with a non-existent `list_id`
Then the insert fails; and `PRAGMA foreign_keys` reads `1` on a freshly
opened connection.

**AC-50 — a composed stream re-emits for every table it depends on** (TLD-1005) · repository
Given a stream of tasks with their tag names
When only a `task_tags` row changes
Then the stream re-emits with the new value, without a manual reload
(KI-003 regression guard).

**AC-51 — the migration chain is lossless** (TLD-1004) · repository
Given a raw-SQL fixture of each shipped schema version
When the database is opened at the current version
Then every fixture upgrades without error, every seeded row survives with its
values intact, and `user_version` matches — for N-1 to N and for N-2 to N.

**AC-52 — the import path cannot bypass an invariant** (TLD-1007) · integration
Given a crafted document asserting a cycle, a three-level nesting and a
`start` after `due`
When it is imported
Then the repository rejects each violation, the import still succeeds for
what is valid, and each rejection produces a counted warning.

**AC-53 — unknown properties survive** (TLD-1008) · unit
Given an imported task carrying `"someFutureProperty": {"a": 1}`
When it is stored and re-exported without editing
Then the property is present, byte-identical, in the exported document.

## Manual verification steps

1. Colour tokens for lists render with sufficient contrast in light and dark,
   and every list row also carries its name — colour is never the only
   distinguishing signal.
2. A screen-reader pass over a task row announces one sentence, not five
   fragments.
3. At 200 % text scale, the task row, the task detail and the list overview
   show no overflow on a phone-sized surface.
4. Every swipe action on the task row has a visible equivalent in the row's
   overflow menu.
