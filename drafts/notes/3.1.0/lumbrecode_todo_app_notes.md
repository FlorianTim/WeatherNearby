# LumbreCode To-do App — Draft Notes

**Status:** non-normative planning input (ADR-0005). Not a specification.
**Filed under:** template version 3.1.0.
**Created:** 2026-08-25 · **Finalized:** 2026-08-25 after product-owner input
**Basis:** `lumbrecode-engineering/docs/JSCALENDAR_TASK_INTEROP.md`
**Goal:** a genuinely good, local-first to-do app that speaks the LumbreCode
task format natively — **and that replaces the built-in Todo demo as the
template's reference application.**

---

## 1. What this document is for

A full-featured to-do app is to be built from this template. The data format
is already decided and tested; what is missing is everything a *product*
needs — lists, views, notifications, quick capture, the shape of the app.

This note fills those gaps with concrete proposals so that the later
planning pass has something to argue with instead of a blank page. Where a
decision was obvious it is made here and marked as such. Only genuinely open
product questions are left open (§17).

**Nothing here authorizes implementation.** Specs and stories come later.

---

## 2. What already exists — do not re-derive

| Artifact | Where | State |
|---|---|---|
| JSCalendar Task/Group schema | `lumbrecode-engineering/schemas/jscalendar-task/v1/` | done, 24 fixtures |
| CloudEvents envelope profile | `.../schemas/lumbrecode-exchange/v1/` | done, 21 fixtures |
| JSContact (contacts, future) | `.../schemas/jscontact/v1/` | standardized, unimplemented |
| Field-by-field implementation guide | `.../docs/JSCALENDAR_TASK_INTEROP.md` | complete, §15 is the handoff |
| Contract validator | `.../scripts/validate_interop_contracts.py` | 63 fixtures green |

The guide's §2 (canonical model), §4 (serialization), §5 (tolerant reading),
§6 (Android send/receive), §10 (import rules) and §12 (contract tests) are
**binding input**. This note does not repeat them; it covers what they
deliberately leave to the app.

The contract knows **tasks**. It does not know lists, views, notifications or
navigation. That is exactly the gap below.

---

## 3. The app's role — decided

Product-owner decision, 2026-08-25. This app **replaces** the built-in Todo
demo (`apps/mobile_app/lib/features/todos/`). It is not a separate product
that happens to live elsewhere.

That is a deliberate change of what the template's example app is *for*:

| | Today's demo | This app |
|---|---|---|
| Purpose | smoke test, structure reference | **proving ground** |
| Complexity | one flat table, three fields | a real domain: lists, dates, recurrence, interop |
| Question it answers | "does the wiring work?" | "does this concept/standard/upgrade survive contact with something real?" |
| Lifetime | replaced on `replace_todo_app: true` | stays; it is the thing new apps are compared against |

Three consequences worth being explicit about:

1. **The template stays a template.** The app is richer, not a product
   masquerading as infrastructure. Everything it does that is *general* must
   end up in `packages/` or `core/`, not buried in `features/tasks/`. §14.1
   lists what that means concretely.
2. **It is where upgrades get tested.** A Flutter release, a Drift major, a
   Riverpod change, a new standard — try it here first, on something with
   enough surface to actually break, before deriving a productive app.
3. **Whether it is ever published is open** and does not need answering now.
   Nothing in the design depends on it. If it ships, it ships as a normal
   LumbreCode app; if it does not, it has already paid for itself.

This supersedes AGENTS.md's Todo-app preservation rule **for this change
only**. The rule exists so that general maintenance and dry-runs do not
delete the reference app; it is not a rule against deliberately replacing it
with a better one. The replacement must go through the documented path:
an OpenSpec entry with `replace_todo_app: true`, not an ad-hoc deletion.

## 4. Naming — one real decision

Working title throughout this document: **LumbreCode To-do**, slug `todo`,
application id `de.lumbre.code.todo`.

The slug is used consistently so it is find-and-replaceable in one pass. A
real product name is a product-owner decision and the only naming question
this note leaves open (§17, Q-01).

---

## 5. Terminology

Deliberately *narrower* than WasThereSomething, because this app is simpler.

| Term | Meaning |
|---|---|
| **Task** | The RFC 8984 object. One thing to do. |
| **Subtask** | A task with exactly one parent task. Single-parent tree, max 2 levels — same rule as WTS. |
| **List** | A user-created container of tasks. **App concept, not in the contract.** |
| **Inbox** | The default list every task lands in when no list is chosen. Cannot be deleted or renamed. |
| **View** | A saved way of looking across lists: Today, Upcoming, All, Completed. Not a container. |
| **Tag** | A cross-list label. Maps to JSCalendar `keywords`. |
| **Occurrence** | **Not a concept here.** It is WasThereSomething product semantics. If you need it to import a document, something is wrong with the document. |

A task belongs to **exactly one** list and carries zero or more tags. Lists
are hierarchy; tags are cross-cutting. Keeping those two separate is what
stops the model from turning into a graph nobody can explain.

---

## 6. The product — what a good to-do app actually has

Compiled from what the well-known apps in this category converge on
(Todoist, TickTick, Microsoft To Do, Things, Apple Reminders). Split into
what the first version needs to be *credible* and what can wait.

### 6.1 Must have — version 1.0

| # | Feature | Note |
|---|---|---|
| F-01 | Create a task with a title, in one tap | The single most-used action. No mandatory second screen, ever. |
| F-02 | Complete / reopen a task | Checkbox. Maps `needs-action` ↔ `completed`. |
| F-03 | Markdown notes on a task | The long body. Same editor experience as WTS. |
| F-04 | Due date, optionally with time | `due` + `showWithoutTime` |
| F-05 | Start date | `start`. Distinct from due — see §8.3. |
| F-06 | Priority | 4 levels mapped onto RFC `priority` 0/9/5/1 |
| F-07 | Subtasks | One level of nesting, checkbox each |
| F-08 | Multiple lists | Create, rename, colour, reorder, delete, archive |
| F-09 | Inbox as the default list | Never deleted |
| F-10 | Move a task between lists | |
| F-11 | Views: Today, Upcoming, All, Completed | |
| F-12 | Manual reorder within a list | Explicit `sortOrder`, never a timestamp (see §8.5) |
| F-13 | Sort and group | by due date / priority / manual / title |
| F-14 | Search | title and notes |
| F-15 | Tags | create, assign, filter |
| F-16 | Local notifications | at due time, and at a configurable lead time |
| F-17 | Recurrence | none / daily / weekly / monthly / yearly, plus an interval |
| F-18 | Swipe actions with undo | complete, delete — plus visible menu equivalents |
| F-19 | Delete with undo, then trash | Nothing vanishes irrecoverably on one tap |
| F-20 | **Import** a shared JSCalendar Task/Group | The reason this app exists |
| F-21 | **Export / share** a task, a selection, or a whole list | Standard document by default |
| F-22 | Dark mode, dynamic type, full accessibility | Not a "later" item |
| F-23 | German and English | |
| F-24 | Onboarding, three screens at most | Explains local-first, asks for notification permission just in time |

### 6.2 Should have — soon after

| # | Feature | Note |
|---|---|---|
| F-30 | Quick add with natural-language dates | "Milch kaufen morgen 17 Uhr" → due tomorrow 17:00. Local parsing only, no network. High perceived value, moderate cost. |
| F-31 | Repeating-task completion modes | "next occurrence from due date" vs "from completion date". The difference matters for chores. |
| F-32 | Bulk actions | multi-select → complete / move / delete / tag |
| F-33 | Home-screen widget | Today's tasks. A category expectation on Android. |
| F-34 | Archive a list | Keeps history without cluttering |
| F-35 | Duplicate a task | |
| F-36 | Links on a task | `links`; opens only http/https on explicit tap |
| F-37 | Estimated duration | `estimatedDuration`; feeds a simple daily total |
| F-38 | Percent complete | `percentComplete`, shown only while `in-process` |
| F-39 | Statistics | completed per week, current streak. Motivational, cheap, entirely local. |
| F-40 | Backup / restore | Local file. Whole database, not a JSCalendar document — the two have different jobs. |

### 6.3 Deliberately not in the first versions

| Item | Why |
|---|---|
| Sync, accounts, cloud | LumbreCode is local-first. Would need a backend and a privacy-policy change. |
| Collaboration, shared lists, assignment | Needs the sync decision first |
| Location-based reminders | Needs background location — a permission and privacy question of its own |
| Attachments (files, photos) | Format already decided: `links` with `rel: "enclosure"`. UI later, same as WTS ~2.7. |
| Calendar view | The app is a list app. A calendar is a different product. |
| Email-to-task, web clipper, integrations | All need a network |
| AI suggestions | No |

---

## 7. Data model

Deliberately close to the WasThereSomething `todo_tasks` design, because it
is already normalized against real query patterns and already maps to the
contract. Differences are marked **[≠WTS]**.

```text
lists                                       [≠WTS — WTS has no lists]
  id                TEXT PK
  title             TEXT NOT NULL
  color             TEXT           -- token name, not a hex value
  icon              TEXT           -- icon key
  sort_order        INTEGER NOT NULL
  is_inbox          BOOLEAN NOT NULL DEFAULT 0   -- exactly one row true
  archived_at       DATETIME
  created_at / updated_at
  source_uid        TEXT           -- Group.uid of an import, provenance only
  source_app        TEXT           -- prodId of an import, provenance only

tasks
  id                        TEXT PK
  list_id                   TEXT -> lists.id ON DELETE CASCADE   [≠WTS]
  jscalendar_uid            TEXT NOT NULL UNIQUE
  parent_task_id            TEXT -> tasks.id ON DELETE CASCADE
  title                     TEXT NOT NULL
  description_markdown      TEXT
  description_content_type  TEXT NOT NULL DEFAULT 'text/markdown; charset=utf-8'
  progress                  TEXT NOT NULL DEFAULT 'needs-action'
  percent_complete          INTEGER            CHECK 0..100
  progress_updated_at       DATETIME
  priority                  INTEGER NOT NULL DEFAULT 0   CHECK 0..9
  start_date_day            INTEGER            -- epoch day
  start_minutes             INTEGER            CHECK 0..1439
  due_date_day              INTEGER
  due_minutes               INTEGER
  time_zone_id              TEXT
  show_without_time         BOOLEAN NOT NULL DEFAULT 0
  estimated_duration_minutes INTEGER
  recurrence_rule           TEXT
  recurrence_rule_version   INTEGER
  recurrence_mode           TEXT DEFAULT 'schedule'  -- schedule | completion  [≠WTS, F-31]
  sequence                  INTEGER NOT NULL DEFAULT 0
  sort_order                INTEGER NOT NULL DEFAULT 0
  unknown_json              TEXT               -- preserved unknown properties
  archived_at               DATETIME
  deleted_at                DATETIME           -- trash, F-19  [≠WTS: actually wired]
  created_at / updated_at

task_tags            (task_id, tag_id)            PK both      [≠WTS naming]
tags                 id, name UNIQUE, color, created_at
task_links           as WTS todo_task_links
task_recurrence_overrides   as WTS todo_task_recurrence_overrides
reminders                                            [≠WTS — WTS derives these]
  id                TEXT PK
  task_id           TEXT -> tasks.id ON DELETE CASCADE
  offset_minutes    INTEGER NOT NULL    -- 0 = at due time, 60 = one hour before
  fired_at          DATETIME
  notification_id   INTEGER             -- platform handle, local only
```

Notes on the deltas:

- **`list_id` replaces `todo_task_occurrence_links`.** WTS attaches tasks to
  occurrences; here they belong to lists. Same idea, simpler shape, and it is
  the one place the two models genuinely diverge.
- **`reminders` is a real table, not a derived one.** In WTS a reminder is
  reconciled from a rule; here the user sets it directly on the task. Do not
  copy the WTS reconciliation service — it solves a problem this app does
  not have.
- **`deleted_at` is actually used** (trash, F-19). WTS declares it and leaves
  it dormant.
- **`sequence` is stored** so a task re-shared through the CloudEvents
  envelope can be recognized as newer by the receiver.

### 7.1 Identity — the four ids, kept apart

| Id | Owner | Exported |
|---|---|---|
| `tasks.id` | local database | never |
| `tasks.jscalendar_uid` | the task, forever | always |
| `lists.id` | local database | never |
| `lists.source_uid` | a foreign app's Group | provenance only, never a matching key |

The rule from the guide applies unchanged: **a familiar `uid` never triggers
a merge or a sync.**

---

## 8. Semantics worth getting right

### 8.1 Progress

Full RFC 8984 vocabulary, not a boolean:

```text
needs-action | in-process | completed | failed | cancelled
```

The list checkbox produces only the first and third. The other three come
from an explicit picker in the detail view. `delegated` is **not** registered
and must never be emitted.

The existing template demo uses `TodoStatus {pending, inProgress, completed}`
— close but not the same. `pending` is not `needs-action`, and two values are
missing. Do not reuse that enum.

### 8.2 Dates

`start` and `due` are `LocalDateTime` — no offset, no `Z`, never
round-tripped through an instant. A date without a time is stored with
`*_minutes = NULL` and exported as `T00:00:00` plus `showWithoutTime: true`.

Guide §2.4 is binding here. It is the single easiest thing to get wrong.

### 8.3 `due` is a deadline, `start` is when you may begin

Both matter in a to-do app and they answer different questions:

```text
start = Monday      "do not show me this before Monday"
due   = Friday      "this must be done by Friday"
```

The **Today** view shows tasks whose `start` has arrived or that are due
today or overdue. A task with a future `start` is deliberately hidden — that
is the whole point of having a start date, and it is why "Today" is useful
rather than a wall of everything.

Nothing may derive a duration from `start` and `due`.

### 8.4 Recurrence

Same RFC 5545 subset as WTS (`FREQ`, `INTERVAL`, `BYDAY`, `BYMONTHDAY`), so
the two apps' rules are mutually readable.

**Proposed addition [≠WTS]: support `count` and `until`.** "Every Monday,
four times" is a normal to-do request and WTS deliberately deferred it
(spec 0036, Q-03). The consequence must be stated plainly: a task using
`count`/`until` shared *to* WasThereSomething imports as non-recurring with a
reported loss. That is exactly what the tolerance rules are for, and it is
better than pretending a to-do app does not need it.

**Completion mode (F-31)** is app-local, not a JSCalendar property:

```text
schedule    next instance from the nominal date   (rent, birthdays)
completion  next instance from when you ticked it (water the plants)
```

Stored in `recurrence_mode`, exported as `lumbrecode.de:recurrenceMode` if it
travels at all. It changes nothing about the standard rule.

### 8.5 Ordering

Explicit `sort_order`, never a timestamp. Drift stores `DateTime` at second
precision and equal timestamps make `ORDER BY` non-deterministic — the same
trap recorded as KI-008 in WasThereSomething. Tiebreak on `jscalendar_uid`.

---

## 9. Views and screens

```text
┌─ Bottom navigation ───────────────────────────────┐
│  Heute      Listen      Suche      Mehr           │
└───────────────────────────────────────────────────┘
```

| Screen | Contents |
|---|---|
| **Heute** | Overdue, then today, then a "no date" section. The default landing screen. |
| **Demnächst** | Next 7 days, grouped by day. Reachable from Heute. |
| **Listen** | All lists with open counts; Inbox pinned first; drag to reorder |
| **Listendetail** | The tasks of one list, with sort/group control and the share action |
| **Aufgabendetail** | Title, notes (Markdown), list, dates, priority, recurrence, reminders, tags, subtasks, links |
| **Suche** | Title and notes, with tag and list filters |
| **Mehr** | Settings, tags, trash, archive, backup, about, licenses |

Interaction rules worth writing down now:

- **Add is always one tap and one line.** Every screen that shows tasks has
  an add affordance that creates a task from a title alone.
- **The checkbox never opens anything.** Tapping the row opens the detail;
  tapping the box completes.
- **Every swipe action has a visible menu equivalent.** Accessibility is not
  a later slice.
- **Undo for anything destructive**, then trash for 30 days.
- **Completed tasks stay visible briefly**, then collapse into a "Completed"
  section — same idea as the WTS visibility policy.

---

## 10. Markdown

Same approach as WasThereSomething, deliberately:

- Body stored as **Markdown source, verbatim.** Never sanitized or converted
  on write.
- `descriptionContentType` defaults to `text/markdown; charset=utf-8`
  (RFC 7763).
- Rendering with `flutter_markdown_plus`. Purely local, no network.
- A **shared Markdown editor** with a formatting toolbar (heading, bold,
  italic, strikethrough, list, link) and an action row (undo, redo, reset,
  save, copy, share). WasThereSomething spec 0025 describes exactly this
  component — reimplement it, or better, lift it into
  `packages/design_system` so both apps share it.
- An imported body whose content type is `text/plain` stays plain. Do not
  guess that it is Markdown.

---

## 11. Interoperability

### 11.1 Receiving

One narrow Android intent filter, `application/jscalendar+json`, plus the
CloudEvents types. **Never `*/*`, never `text/plain`** — that would put the
app in every share sheet on the device.

Import flow, from the guide §9.3:

```text
intent → read under a 256 KiB cap → parse → validate totally
       → collect typed warnings → IMPORT REVIEW (no bypass)
       → one transaction → report what was imported and what was lost
```

Mapping into this app's model:

| Incoming | Becomes |
|---|---|
| a `Group` | a **new list**; `Group.title` becomes the list name |
| a single `Task` | a task in the Inbox, or in a list the user picks |
| a CloudEvents envelope | unwrap, then treat `data` exactly as above |
| a CloudEvents batch | each entry on its own |
| `relatedTo` parent/child | nesting, resolved **within the document only** |

**A Group always becomes a new list — even if the `uid` is familiar.** Guide
§10.1/§10.2. The alternative is a merge, and a merge needs conflict rules
this contract does not define.

### 11.2 Sending

Two formats, the user picks:

| Choice | Format |
|---|---|
| "Als Datei teilen" | `application/jscalendar+json;type=task\|group` |
| "An LumbreCode-App senden" | `application/cloudevents+json` |

The second only when a receiver is installed (package-manager query). Same
rule and the same preview obligation as WTS spec 0037 — an explicit,
unskippable preview naming what leaves the app.

### 11.3 Contract tests

CT-1 … CT-15 from guide §12 are **this app's obligation too**. The same
fixture files are the test inputs on both sides; that is what makes
"compatible" a test result rather than a claim.

The end-to-end assertion:

```text
WasThereSomething export → document → this app's import
        → semantically identical tasks
```

---

## 12. Notifications

A to-do app without reminders is a list. Requirements:

- `flutter_local_notifications`, **local scheduling only** — no push, no
  network, no Firebase.
- Permission requested **just in time**, with an in-app rationale first, when
  the user sets their first reminder — not at startup.
- Per task: at due time, or a configurable lead time (`reminders.offset_minutes`).
- Notification actions: **Erledigt** and **Später** (snooze 1 h / tonight /
  tomorrow).
- Android 13+ `POST_NOTIFICATIONS`, and exact alarms need
  `SCHEDULE_EXACT_ALARM` — check whether inexact scheduling is good enough
  before requesting it. It usually is.
- Rescheduling on reboot and on time-zone change.
- **No task content in logs.**

A spike is advisable before the first story: completing a task from a
notification action may run in a background isolate without a UI, which is
the same trap WasThereSomething flagged for its spec 0031.

---

## 13. Technical stack

Follow WasThereSomething wherever there is no reason not to. Where the
template already pins a different major, the template wins — but the
difference must be *known*, because the APIs differ.

### 13.1 Already in this template

| Package | Template | WTS | Note |
|---|---|---|---|
| `flutter_riverpod` | ^3.0.0 | 3.1.0 | same line |
| `riverpod_annotation` | ^3.0.0 | ^4.0.0 | **different major** — generator API differs |
| `go_router` | ^14.0.0 | ^17.3.0 | **different major** — routing API differs |
| `freezed_annotation` | ^3.0.0 | ^3.0.0 | same |
| `json_annotation` | ^4.9.0 | 4.9.0 | same |
| `drift` / `drift_flutter` | ^2.22.0 / ^0.2.0 | 2.31.0 / 0.2.x | same line |
| `share_plus` | ^12.0.0 | 10.1.4 | **two majors apart** — the static `Share.shareXFiles(...)` entry point was replaced during the 11.x line by an instance-based API. The guide's snippet targets 10.x and will not compile here. Verify the exact 12.x signature against the package docs in slice 9; the share seam isolates it to one file either way. |
| `url_launcher` | ^6.3.0 | 6.3.2 | same |
| `shared_preferences` | ^2.3.0 | — | template-only |

### 13.2 To add

| Need | Package | Licence | Why |
|---|---|---|---|
| Markdown rendering | `flutter_markdown_plus` | BSD-3 | what WTS uses; local only |
| Markdown → HTML (only if needed) | `markdown` | BSD-3 | already transitive |
| UUID v4 | `uuid` (^4.x) | MIT | cryptographically strong RNG. **Use this**, not WTS's hand-rolled `generateId()` — that exists only because of WTS's dependency lock, and JSCalendar wants RFC 4122. |
| Local notifications | `flutter_local_notifications` | BSD-3 | F-16 |
| Time zones | `timezone` | BSD-2 | needed by notification scheduling |
| Calendar-correct dates | `time_machine2` | Apache-2.0 | what WTS uses; rejects impossible dates |
| Receiving intents | `receive_sharing_intent` (^1.9) **or** an own platform channel | Apache-2.0 | see guide §6.3. WTS chose its own channel for the security boundary; for this app either is defensible. **If the package is used, narrow its manifest entries to the one MIME type.** |
| Cache directory | `path_provider` | BSD-3 | share files |
| Media types | `mime` | BSD-3 | `descriptionContentType` parsing |
| SQLite bundle | `sqlite3_flutter_libs` | MIT | required by drift on Android |
| Test doubles | `mocktail` | MIT | what WTS uses |

**Do not add** `rrule`: the RFC 5545 subset in the guide §2.5 is what the
contract supports, and a full engine would let this app emit rules
WasThereSomething cannot read.

**No JSCalendar library exists for Dart** (checked 2026-08-25). The codec is
hand-written — see §13.3.

### 13.3 The shared package

```text
packages/task_interchange/        pure Dart: no Flutter, no Drift, no Android
  lib/src/jscalendar/   Task, Group, Link, Relation, RecurrenceRule, LocalDateTime
  lib/src/codec/        encode / decode / validation / typed warnings
  test/fixtures/        the golden fixtures from lumbrecode-engineering
```

It belongs **in the template**, not in the app: it is generic, every app
generated from the template may want it, and it is the thing both apps must
agree on. It knows nothing about lists, occurrences or notifications.

How it reaches WasThereSomething is the open infrastructure question already
recorded as spec 0037 Q-05 — copy, private pub host, or git dependency.

### 13.4 Dependency discipline

The template has **no** analyzer/riverpod lock of the kind WasThereSomething
suffers (KI-001), so there is more freedom here. That is not licence to be
careless: AGENTS.md requires every new dependency to be justified with
purpose, licence, maintenance status and a removal path.

---

## 14. Architecture

Feature-first, as ADR-0002 requires, and mirroring the WTS layering:

```text
apps/mobile_app/lib/
  core/
    database/          Drift schema, migrations
    domain/time/       RecurrenceRule, epoch-day helpers   (lift from WTS)
    ui/                MarkdownEditor, share seams, snackbars
  features/
    tasks/             domain / data / application / presentation
    lists/
    views/             Today, Upcoming, Search
    tags/
    reminders/
    interop/           import review, export, share seams
    settings/
    onboarding/
packages/
  task_interchange/    the contract implementation
  design_system/       shared widgets, ideally incl. the Markdown editor
```

Rules carried over from WasThereSomething because they earned their place:

- **No hand-written SQL.** Drift only, typed queries, reactive `watch*`
  streams feeding Riverpod.
- **Foreign keys enforced**: `PRAGMA foreign_keys = ON` on every connection.
- **Every multi-table write in a transaction.**
- **Injectable seams** for sharing, launching URLs and notifications, so
  widget tests never touch the platform.
- **Additive migrations only**, with a fixture test per schema version.

**Do not copy from WasThereSomething:** occurrences, the occurrence engine,
calendar projection, contacts, the reminder reconciliation service, the
`[WTS2:…]` ownership marker. None of it applies here, and importing the
concepts would make this app harder to understand for no gain.

### 14.1 What belongs in the template, not in the app

This is the point of making the reference app richer: whatever it needs that
is **not about to-do lists** should end up somewhere every LumbreCode app
inherits. The test is simple — *would the vacation planner want this too?*

If yes, it goes in `packages/` or `core/`. If it only makes sense for tasks,
it stays in `features/tasks/`.

#### Already in the template — reuse, do not reinvent

| Concept | Where |
|---|---|
| Just-in-time permission flow with an in-app rationale sheet | `core/permissions/` |
| Startup coordinator and startup tasks | `core/startup/` |
| Settings register (`SettingDef`) | `core/settings/` |
| Two-phase splash (company → app) | `features/splash/` |
| Branding, flavor, app links, support mail from one slug | `packages/app_core` |
| Calendar-correct date validation | `packages/app_core/date_validation.dart` |
| Theme and spacing tokens | `packages/design_system` |

#### Must be extracted or added in 3.1.0 — the To-do app forces them

| Concept | Target | Why it is general |
|---|---|---|
| **Markdown editor with toolbar** (heading, bold, italic, strikethrough, list, link) and action row (undo, redo, reset, save, copy, share) | `packages/design_system` | Named explicitly by the product owner. Every app with a free-text field should feel identical. WasThereSomething spec 0025 is the reference behaviour. |
| **Markdown rendering** conventions | `packages/design_system` | Same renderer, same defaults, everywhere |
| **Share seams** — text and typed document, injectable | `core/ui/` | Every app shares something; no widget test may open a real share sheet |
| **URL launcher seam with a scheme allowlist** (`https`/`http` only, on explicit tap) | `core/ui/` | Security-relevant and identical in every app |
| **Snackbar / undo helper** | `packages/design_system` | Z-013 "undo for risky quick actions" is a cross-app product rule, not a task feature |
| **UUID v4 generation** | `packages/app_core` | Standardize once; several standards want RFC 4122 |
| **Date/time domain helpers** — epoch-day storage, the RFC 5545 recurrence subset | `core/domain/time/` or a package | Any app with dates needs these; the recurrence subset is also an interop contract |
| **Drift hardening conventions** — `PRAGMA foreign_keys = ON`, transactions for multi-table writes, additive migrations with a fixture test per version, a baseline schema test | `core/database/` + instructions | Today's demo has one flat table and proves none of this |
| **Notification seam** | `core/` | Local-only scheduling, injectable for tests |
| **`packages/task_interchange`** | new package | Generic JSCalendar model and codec; no Flutter, no Drift |

#### General, but not forced by this app — candidates for 3.2+

| Concept | From | Note |
|---|---|---|
| In-app user manual and FAQ from bundled Markdown, de/en, screenshots synced from the integration-test pipeline | WTS spec 0017 | The single most reusable thing WasThereSomething built. Also brings the Z-017 rule: a feature change updates manual, FAQ, integration tests and the test plan **in the same change**. |
| Feedback and error report by mail intent, content visible and editable before sending | WTS spec 0023 | No backend, works everywhere |
| Local backup / restore of the database | WTS F-060 | Every local-first app needs it eventually |
| Privacy field classes (neutral / personal / sensitive) as a documented convention | WTS Z-011 | Cheap to adopt, prevents leaks into logs and screenshots |
| Archive-before-delete | WTS Z-012 | Product rule, not a feature |
| Known-issues register discipline | already present | Keep feeding it |

**A warning worth writing down:** the temptation will be to leave the
Markdown editor and the seams inside `features/tasks/` because that is where
they are first needed, and to "extract them later". Later does not happen.
Extract them in the slice that introduces them.

---

## 15. Privacy

Same baseline as every LumbreCode app:

- Local-first. No backend, no account, no analytics, no crash reporting
  without opt-in.
- Task titles and notes are personal free text. They never appear in logs,
  never leave the device except through an explicit, previewed user action.
- Links from an imported document are **never fetched automatically** — not
  for a preview, not for a favicon. Only `https:` and `http:` open, only on
  an explicit tap.
- Temporary share files live in the app cache and are cleaned at the next
  start.
- A shared document carries no device id, no install id, no account.
- Notification content is a product decision: showing a task title on the
  lock screen is convenient and is also a leak. Propose a setting, default
  to showing the title.

---

## 16. Suggested build order

Vertical slices, each shippable and reviewable.

| # | Slice | Delivers |
|---|---|---|
| 0 | **Shared foundations** | Extract/add the §14.1 items the app needs: Markdown editor into `design_system`, share and URL seams, snackbar/undo helper, UUID, date/time helpers, Drift hardening conventions. No task code yet. |
| 1 | `packages/task_interchange` | Models, codec, validation, warnings; all fixtures green. No UI, no database. |
| 2 | Data layer | Schema, repositories, tree safety, ordering, migration fixture test |
| 3 | Lists and tasks | Inbox, list CRUD, task CRUD, checkbox, reorder |
| 4 | Task detail | Notes (Markdown), dates, priority, subtasks, tags |
| 5 | Views | Today, Upcoming, Completed, sort and group |
| 6 | Reminders | Local notifications, actions, reboot rescheduling |
| 7 | Recurrence | Rules, completion mode, instance handling |
| 8 | Import | Intent filter, byte cap, validation, import review, warnings |
| 9 | Export / share | Both formats, preview, share seam |
| 10 | Search, trash, archive | |
| 11 | Onboarding, settings, about | |
| 12 | Contract tests CT-1..CT-15 | Against WasThereSomething's fixtures |
| 13 | **Retire the demo** | Remove `features/todos/`, its routes, providers, tests and l10n keys; update the OpenSpec entry, README and AGENTS.md so the reference app is the new one |

Slice 0 comes first on purpose: the shared pieces are what make this a
template change rather than an app. Slice 1 has no UI either — it is the
piece that must be right, and it can be reviewed against the fixtures alone.

Slice 13 is last, not first. The demo keeps working until its replacement
does everything it did.

---

## 17. Open questions

Only what cannot be answered from the contract, this template or an existing
decision.

**Q-01 — The product name.** `todo` / `de.lumbre.code.todo` is a placeholder
used consistently so it can be replaced in one pass. A real name is a
product-owner decision — and a low-urgency one, because publishing is
undecided (§3) and the template does not care what the reference app is
called.

**Q-02 — Does the app support `count` / `until` in recurrence?** §8.4
proposes yes, with the stated consequence that such tasks lose their
recurrence when shared to WasThereSomething. The alternative is staying
exactly at the WTS subset and telling users "four times" is not available.

**Q-03 — ~~Is the built-in Todo example app replaced or kept?~~
ANSWERED 2026-08-25: replaced.** See §3. The app becomes the template's
reference application and deliberate proving ground. The replacement goes
through an OpenSpec entry with `replace_todo_app: true`, and AGENTS.md's
preservation rule is amended rather than quietly ignored.

**Q-04 — Notification content on the lock screen.** Title visible by
default, or generic ("1 Aufgabe fällig")? §15 proposes visible with a
setting.

**Q-05 — Where does `packages/task_interchange` live once two apps use it?**
Copy, private pub host, or git dependency. Already recorded as spec 0037
Q-05 in WasThereSomething; it is the same question and needs one answer.
Note that this now has a second instance: the Markdown editor and the seams
in `packages/design_system` face exactly the same distribution question.

**Q-07 — How far does "the same everywhere" go?** The Markdown editor is
settled. Open: whether list rows, empty states, confirmation dialogs and
undo snackbars should also be shared widgets rather than conventions. Shared
widgets give real consistency and real coupling. Suggest deciding per
component as the reference app produces them, rather than up front.

**Q-06 — Does the app get a JSContact import path later?** RFC 9553 is
already standardized in `lumbrecode-engineering`. A to-do app has no obvious
use for contacts, so probably not — but if "assign to a person" ever appears,
the format is ready.

---

## 18. What the planning pass should produce

Mirroring what WasThereSomething's 1.5 planning produced:

1. An OpenSpec app entry, `openspec/apps/<slug>.openspec.yaml`, with
   `replace_todo_app: true` and the reasoning from §3
2. Feature specs under `docs/product/specs/` using the existing `_template/`
3. A data contract and the Drift migration design
4. UX flows and acceptance criteria
5. An ADR wherever the notification boundary, the receive boundary or the
   package layout warrant one — the WasThereSomething precedents are
   ADR-0016 (Android receive boundary), ADR-0019 (canonical model) and
   ADR-0020 (sharing boundary)
6. An implementation plan with the slices from §16
7. A test strategy: domain, serialization, database, widget, contract
8. An amendment to AGENTS.md: the Todo-app preservation rule now protects
   the new reference app, and the paragraph should say what that app is
   for (§3) so the next maintainer does not simplify it back
9. A first implementation prompt

Everything in §2 is input, not something to re-derive.

---

## 19. Sources

- `lumbrecode-engineering/docs/JSCALENDAR_TASK_INTEROP.md` — the binding guide
- `lumbrecode-engineering/docs/LUMBRECODE_EXCHANGE.md` — the CloudEvents profile
- `lumbrecode-engineering/docs/APP_INTEROP_OVERVIEW.md` — the catalogue
- WasThereSomething specs 0035 / 0036 / 0037 — the sibling implementation
- WasThereSomething `docs/known-issues.md` — KI-001 (dependency lock),
  KI-008 (second-precision timestamps)
- RFC 8984 (JSCalendar), RFC 7763 (`text/markdown`), RFC 4122 §4.4 (UUID v4)
- Feature comparison drawn from the common ground of Todoist, TickTick,
  Microsoft To Do, Things and Apple Reminders
