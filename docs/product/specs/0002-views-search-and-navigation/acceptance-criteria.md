# Acceptance criteria: Views, search and navigation

Format: Given / When / Then, with the requirement proved and the test level.
Levels: `unit` (pure predicate), `repository` (Drift, in-memory), `widget`,
`integration`, `manual`.

The view-membership block is written against one fixture set, `viewMatrix`,
described in `data-contract.md`.

## View membership

**AC-01 — a future start hides a task from Heute** (VSN-003) · unit
Given today is 25 August and a task with `start = 27 August`, no due date
When Heute's membership predicate is evaluated
Then the task is not a member; and given the same task with
`start = 25 August`, it is.

**AC-02 — an overdue deadline beats a future start** (VSN-005) · unit
Given a task with `start = 27 August` and `due = 24 August`, today 25 August
Then it is a member of Heute, in the **Überfällig** group.

**AC-03 — the three Heute groups, in order** (VSN-004) · widget
Given the `viewMatrix` fixture and today = 25 August
When Heute renders
Then the section order is Überfällig, Heute, Ohne Datum; each header shows a
count; and no task appears in two sections.

**AC-04 — Demnächst is a half-open seven-day window** (VSN-007) · unit
Given tasks due today, tomorrow, in 7 days and in 8 days
Then Demnächst contains exactly the tomorrow and the 7-day task — today
belongs to Heute, and day 8 is outside the window.

**AC-05 — trashed and archived are excluded everywhere** (VSN-001) · repository
Given one trashed task, one task in an archived list and one task in a
deleted list
When each of Heute, Demnächst, Alle, Erledigt and search is evaluated
Then none of the three appears in any of them.

**AC-06 — failed and cancelled are not completed** (VSN-010) · unit
Given one `failed` and one `cancelled` task, both with a due date of today
Then neither is in Heute or Demnächst, both are in Alle marked with their
state, and neither is in Erledigt.

**AC-07 — Erledigt is recent-first and windowed** (VSN-009) · repository
Given completed tasks at 1, 29 and 31 days ago
Then Erledigt shows the first two, most recent first, and the third appears
only after the explicit "ältere laden" control is used.

**AC-08 — a flat subtask names its parent** (VSN-011) · widget
Given a subtask due today whose parent is not due today
When Heute renders
Then the subtask appears, and its row names its parent; and inside its list
detail the same task appears nested, without the parent label.

**AC-09 — today is recomputed, not captured** (VSN-012) · widget
Given the app is open on Heute with a task due "tomorrow"
When the clock crosses midnight (fake clock) and the app resumes
Then that task has moved from Demnächst into Heute without a manual reload.

**AC-10 — an excluded recurrence instance is not shown** (VSN-013) · repository
Given a daily recurring task with an override marking tomorrow `excluded`
Then Demnächst shows the day after tomorrow's instance and not tomorrow's.

## Sort and group

**AC-11 — no ordering is ever non-deterministic** (VSN-103) · repository
Given 50 tasks inserted inside the same second, with identical due dates and
identical priorities
When each sort mode is read 100 times
Then every read returns the identical order, and no generated SQL orders by a
`DateTime` column without a further tiebreak.

**AC-12 — undated tasks sort last, not first** (VSN-104) · unit
Given tasks due yesterday, due tomorrow, and with no due date
When sorted by due date ascending
Then the order is yesterday, tomorrow, undated.

**AC-13 — priority sorts by meaning, not by number** (VSN-105) · unit
Given tasks with priority 0, 1, 5, 9
When sorted by priority
Then the order is 1 (hoch), 5 (normal), 9 (niedrig), 0 (keine), and no
user-visible string contains a digit.

**AC-14 — title sort is locale-aware** (VSN-106) · unit
Given the titles "Zebra", "Äpfel", "apfel" with locale `de`
Then the order is "Äpfel", "apfel", "Zebra" — not a byte order that puts
"Äpfel" after "Zebra".

**AC-15 — sort choice is per surface** (VSN-108) · widget
Given list A sorted by due date and list B sorted manually
When the app is restarted
Then A is still by due date and B is still manual, and each key is present in
the settings register.

**AC-16 — manual reorder is only offered when it means something** (VSN-102, VSN-109) · widget
Given a list detail sorted by priority
Then no drag handle is shown, a long-press explains why, and Heute never
offers manual sort at all.

## Completed-task visibility

**AC-17 — a completed task lingers** (VSN-201) · widget
Given a visible uncompleted task
When its checkbox is tapped
Then it stays in place, struck through, for at least 5 seconds before
collapsing, and an undo affordance is available throughout.

**AC-18 — then it collapses into a counted section** (VSN-202) · widget
Given three completed tasks past the linger window
Then they are inside a collapsed "Erledigt (3)" section which expands on tap
and whose state is not required to persist across restarts.

**AC-19 — un-completing restores the position** (VSN-204) · widget
Given a completed task inside the collapsed section, with sort by title
When it is un-completed
Then it reappears at its alphabetical position without a reload or a flash of
the whole list.

## Search

**AC-20 — titles and notes both match** (VSN-301, VSN-302) · repository + widget
Given a task titled "Milch kaufen" and another whose notes contain
"Milchreis"
When "milch" is searched
Then both appear, the first marked as a title match and the second as a notes
match with an excerpt containing "Milchreis".

**AC-21 — filters combine and are removable** (VSN-303) · widget
Given results across two lists and two tags
When the list filter "Einkauf" and the tag filter "dringend" are applied
Then only tasks satisfying both remain, two removable chips are shown, and
removing one widens the result set accordingly.

**AC-22 — completed included and marked, trashed excluded** (VSN-304) · repository
Given a matching completed task and a matching trashed task
Then the completed one appears marked and the trashed one does not appear.

**AC-23 — typing never blocks** (VSN-305) · widget
Given 2 000 tasks
When ten characters are typed in quick succession
Then the field accepts every character without dropping one, the query is
debounced to fewer executions than keystrokes, and no frame budget violation
is recorded.

**AC-24 — search terms are not persisted** (VSN-307) · integration
Given a search for a distinctive term
When the app is restarted and every log sink, preference file and database
table is inspected
Then the term appears nowhere.

**AC-25 — the latency budget is measured** (VSN-308) · integration
Given the 2 000-task fixture
When a three-character query runs
Then the first results arrive within 150 ms, and the measured value is
recorded in the PR. A miss is a finding, not a silent pass.

## Navigation

**AC-26 — four destinations, Heute first** (VSN-401, VSN-402) · widget
Given a successful startup
Then the app lands on Heute and the bottom navigation offers exactly Heute,
Listen, Suche, Mehr, each with a localized label.

**AC-27 — routes are declared, not anonymous** (VSN-403, VSN-404) · unit
Given the feature's sources
Then `/tasks/:id` and `/lists/:id` are declared in `AppRoutes` and registered
with `go_router`, and no file in the feature calls `Navigator.push` with an
anonymous `MaterialPageRoute`.

**AC-28 — a notification tap leaves a sane back stack** (VSN-405) · integration
Given the app is not running
When a notification for a task is tapped
Then the task detail opens, and pressing back once leads to Heute rather than
exiting the app.

**AC-29 — a dead deep link is a screen, not a crash** (VSN-408) · widget
Given a route to a task id that does not exist
Then a readable "nicht gefunden" screen with a way back is shown, and no
exception is thrown.

**AC-30 — import review survives a restart** (VSN-406) · integration
Given the import review is open
When the process is killed and relaunched
Then the app starts in a valid state, and either the review is reachable
again or the pending payload is discarded with a message — never an
unreachable or half-written state.

**AC-31 — tab state is preserved** (VSN-407) · widget
Given a list scrolled halfway
When the user switches to Suche and back
Then the scroll position is preserved.

## Empty and loading states

**AC-32 — every view has its own empty state** (VSN-501) · widget
Given an empty database with only the Inbox
When each of Heute, Demnächst, Alle, Erledigt, Listen and Suche renders
Then each shows a distinct message naming what is empty, and no two share the
same string key.

**AC-33 — an empty Heute explains itself** (VSN-502) · widget
Given 12 tasks, none dated and none started
Then Heute says that nothing is due and names how many undated tasks exist,
so the user does not conclude the data is gone.

**AC-34 — loading does not blank a populated surface** (VSN-503) · widget
Given a rendered list
When its query re-runs
Then the previous content stays visible, no full-screen spinner appears, and
the add affordance stays usable.

**AC-35 — a failed query is readable** (VSN-504) · widget
Given a repository that throws
Then a reason code and a retry are shown, the retry re-runs the query, the
error is present in the last-error buffer, and no stack trace is on screen.

## Query layer

**AC-36 — one query layer, not four** (VSN-601) · unit
Given the feature's sources
Then exactly one parameterized query entry point serves all four views plus
search, and no view builds its own SQL or its own `select(...)` chain.

**AC-37 — composed streams re-emit for every dependency** (VSN-602) · repository
Given a stream of tasks with their tags and parent titles
When only a `task_tags` row changes, and separately when only a parent's
title changes
Then the stream re-emits in both cases without a manual reload
(KI-003 regression guard).

**AC-38 — membership predicates are pure and testable without a database** (VSN-603) · unit
Given the predicate functions and a plain in-memory task record
Then every rule in AC-01..AC-06 can be evaluated without opening a database,
and the SQL path agrees with the predicate on the whole `viewMatrix` fixture.

**AC-39 — no N+1** (VSN-605) · repository
Given 200 tasks each with two tags
When Alle is loaded
Then the number of executed statements is bounded and independent of the row
count, asserted by a statement-count probe.

**AC-40 — the indexes exist and are used** (VSN-604) · repository
Given the schema at the current version
Then `(list_id, sort_order)`, `due_date_day`, `start_date_day`, `deleted_at`
and `parent_task_id` indexes exist, and `EXPLAIN QUERY PLAN` for Heute and for
a list detail shows an index scan rather than a full table scan.

## Manual verification steps

1. Leave the app open across midnight and confirm Heute rolls over without a
   restart (VSN-012).
2. Complete a task and watch it linger, then collapse — confirm it reads as
   progress, not as deletion (VSN-201).
3. Tap a reminder notification with the app killed, then press back once
   (VSN-405).
4. At 200 % text scale on a phone, walk Heute, a list detail and search — no
   overflow, and group headers still legible.
5. With a screen reader, confirm group headers are announced as sentences
   with their counts.
