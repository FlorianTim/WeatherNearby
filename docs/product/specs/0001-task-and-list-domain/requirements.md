# Requirements: Task and list domain

Requirement IDs use the prefix `TLD-`. Every id maps to at least one criterion
in `acceptance-criteria.md`.

Priority: **Must** = required for 3.1.0. **Should** = required for 3.1.0
unless a story explicitly defers it with a recorded reason. **Model-only** =
persisted and round-tripped, deliberately without UI in 3.1.0.

## A. Identity and lifecycle (TLD-0xx)

| Id | Requirement | Priority |
|---|---|---|
| TLD-001 | A task has a local row id (`tasks.id`) that is app-generated, stable from insert, never reused and **never exported**. | Must |
| TLD-002 | A task has a `jscalendar_uid`: an RFC 4122 v4 UUID, canonical lowercase, generated once at creation, unique across the database, never regenerated and never reused after deletion. | Must |
| TLD-003 | The row id and the `jscalendar_uid` are separate values with separate purposes. The uid is never a foreign key; the row id never leaves the app. | Must |
| TLD-004 | A task may exist with a title and nothing else. Every other field is optional, including both dates. | Must |
| TLD-005 | Deleting a task deletes that task and its subtree, and nothing else — no list, no tag definition, no other task. | Must |
| TLD-006 | Editing any field updates `updated_at`. Nothing else updates it as a side effect. | Must |
| TLD-007 | `sequence` is persisted, starts at 0, and increments on each user-visible content change. It exists so a re-shared task can be recognized as newer by a receiver. | Should |
| TLD-008 | Every write that touches more than one table runs in a single transaction. | Must |

## B. Content (TLD-1xx)

| Id | Requirement | Priority |
|---|---|---|
| TLD-101 | `title` is required, 1..200 characters after trimming. An all-whitespace title is rejected. | Must |
| TLD-102 | `description_markdown` holds the long-form body, stored as **source, verbatim** — never sanitized, converted, re-wrapped or re-rendered on write. | Must |
| TLD-103 | `description_content_type` is stored and defaults to `text/markdown; charset=utf-8` (RFC 7763). A body that arrived from elsewhere keeps the content type it arrived with. | Must |
| TLD-104 | The body is edited with the shared `MarkdownEditor` from `packages/design_system` and rendered with the shared renderer. No second editor, no second renderer, anywhere in the app. | Must |
| TLD-105 | `description_markdown` is capped at 20 000 characters. The cap is enforced on save with a readable message, never by silent truncation. | Must |
| TLD-106 | A body whose declared content type is `text/plain` is rendered as plain text. The app never guesses that plain text is Markdown. | Must |
| TLD-107 | Titles and bodies are personal free text: never written to a log, never in a notification payload log line, never in a feedback mail, never in a tooling screenshot. | Must |

## C. Progress (TLD-2xx)

| Id | Requirement | Priority |
|---|---|---|
| TLD-201 | `progress` uses the IANA-registered JSCalendar vocabulary exactly: `needs-action`, `in-process`, `completed`, `failed`, `cancelled`. Default `needs-action`. Stored as text. | Must |
| TLD-202 | `delegated` is not registered and is never emitted. An unrecognized value read from the database behaves as `needs-action` and is preserved verbatim on write-back. | Must |
| TLD-203 | The list checkbox maps unchecked to `needs-action` and checked to `completed`, and produces no other value. | Must |
| TLD-204 | `in-process`, `failed` and `cancelled` are selectable from an explicit picker in the task detail, so the vocabulary is not decorative. | Must |
| TLD-205 | The demo's `TodoStatus {pending, inProgress, completed}` enum is **not** reused, extended or mapped. `pending` is not `needs-action`. | Must |
| TLD-206 | `percent_complete` (0..100, `CHECK` enforced) is persisted. The detail view offers it only while `progress` is `in-process`; no list surface shows it. | Should |
| TLD-207 | Setting `completed` sets `percent_complete` to 100 and setting `needs-action` sets it to 0, unless the user set an explicit value in the same edit. | Should |
| TLD-208 | `progress_updated_at` is set to the current UTC instant when and only when `progress` changes. Editing a title must not touch it. | Must |
| TLD-209 | Completing a parent does not complete its subtasks, and completing every subtask does not complete the parent. Any rollup is a later, explicit product decision. | Must |
| TLD-210 | Completed tasks are never deleted automatically. Their visibility is a display policy (spec 0002), not a lifecycle. | Must |

## D. Dates (TLD-3xx)

| Id | Requirement | Priority |
|---|---|---|
| TLD-301 | A task may have no date, `start` only, `due` only, or both. All four are valid and each has a defined rendering. | Must |
| TLD-302 | `start` is "do not show me this before", `due` is a **deadline**. No code path derives a duration, an end time or an occupied range from the pair. | Must |
| TLD-303 | Calendar days are stored as epoch-day integers (`*_date_day`) and times as minutes since midnight (`*_minutes`, `CHECK 0..1439`). Never as a midnight `DateTime`. | Must |
| TLD-304 | A missing time component means "date only": `*_minutes IS NULL`. `show_without_time` is the exported form of that fact and is stored alongside it. | Must |
| TLD-305 | A local date-time is never round-tripped through an instant. Components are parsed and kept; a moment is derived only for display and for notification scheduling, and never written back. | Must |
| TLD-306 | When both are set, `start` must not be after `due`. The editor prevents it; the repository rejects it. | Must |
| TLD-307 | `time_zone_id` is persisted. `NULL` means floating local wall time. A present value is a valid IANA identifier, never an abbreviation and never an offset. 3.1.0 offers no time-zone picker; tasks created here are floating. | Model-only |
| TLD-308 | `estimated_duration_minutes` is persisted as whole non-negative minutes. 3.1.0 offers no UI for it. | Model-only |
| TLD-309 | Date validity is checked with `DateValidation` from `packages/app_core`, not with a hand-written month-length switch. | Must |

## E. Subtasks (TLD-4xx)

| Id | Requirement | Priority |
|---|---|---|
| TLD-401 | The hierarchy is a single-parent tree in `tasks.parent_task_id`. There is exactly one source of truth for it. | Must |
| TLD-402 | A task cannot be its own parent. Rejected in the repository, not only in the UI. | Must |
| TLD-403 | A cycle of any length is rejected: setting a parent walks the ancestor chain first. | Must |
| TLD-404 | A task has at most one parent. Multiple parents are not representable by the schema. | Must |
| TLD-405 | Nesting depth is capped at 2 levels (task, subtask). A deeper assignment is rejected with a readable message, never silently flattened. | Must |
| TLD-406 | Deleting a parent deletes its subtasks, after a confirmation that names how many. | Must |
| TLD-407 | A subtask inherits nothing automatically — not the dates, not the priority, not the tags. It may carry its own. | Must |
| TLD-408 | A subtask belongs to the same list as its parent. Moving a parent moves its subtasks in the same transaction. | Must |
| TLD-409 | A subtask appears under its parent, not independently at the top level of a list. Views (spec 0002) may show it flat, and say so. | Must |

## F. Lists (TLD-5xx)

| Id | Requirement | Priority |
|---|---|---|
| TLD-501 | A list has a title, an optional colour **token name** (never a hex value), an optional icon key and an explicit `sort_order`. | Must |
| TLD-502 | Exactly one list has `is_inbox = 1`. It is created on first run, cannot be deleted, cannot be renamed and cannot be archived. A `CHECK`/unique constraint or an equivalent guard makes a second Inbox unrepresentable. | Must |
| TLD-503 | A task belongs to exactly one list. `list_id` is `NOT NULL` with a foreign key to `lists.id`. | Must |
| TLD-504 | A task created without a list choice lands in the Inbox. | Must |
| TLD-505 | Moving a task between lists is one operation, moves its subtasks with it, and preserves everything else about the tasks. | Must |
| TLD-506 | Deleting a list requires a confirmation naming how many tasks it holds. The tasks go to the trash with the list, not to the Inbox — moving them silently would hide the loss. | Must |
| TLD-507 | The Inbox cannot be deleted, so the "delete the last list" case cannot arise. | Must |
| TLD-508 | A list can be archived. An archived list keeps its tasks, disappears from the list overview and from every view, and can be restored. | Should |
| TLD-509 | Lists can be reordered manually. The Inbox is pinned first and is not part of the reorderable range. | Must |
| TLD-510 | `source_uid` and `source_app` on a list are **provenance only** (spec 0004). Nothing may match, merge or sync on them. | Must |

## G. Tags (TLD-6xx)

| Id | Requirement | Priority |
|---|---|---|
| TLD-601 | A tag has a name, unique case-insensitively after trimming, and an optional colour token. | Must |
| TLD-602 | A task carries zero or more tags, through `task_tags (task_id, tag_id)` with both columns as the primary key. | Must |
| TLD-603 | Tags are cross-cutting: a tag is never scoped to a list, and a task's list membership never changes its tags. | Must |
| TLD-604 | Deleting a tag removes its assignments and leaves every task intact. | Must |
| TLD-605 | Tag names map to and from JSCalendar `keywords` (spec 0004). The wire form is a set; values are always `true`. | Must |

## H. Priority and links (TLD-7xx)

| Id | Requirement | Priority |
|---|---|---|
| TLD-701 | `priority` is an integer 0..9 with RFC/iCalendar semantics: **0 undefined, 1 highest, 9 lowest**. `CHECK` enforced. | Must |
| TLD-702 | The UI offers four choices mapped to 0 (keine) / 9 (niedrig) / 5 (normal) / 1 (hoch), and displays "keine" for 0. The inversion is never exposed to the user. | Must |
| TLD-703 | Links are persisted as full JSCalendar `Link` objects: `href` required, plus optional `cid`, `content_type`, `size`, `rel`, `display`, `title`, with `UNIQUE (task_id, link_key)`. | Must |
| TLD-704 | 3.1.0 lets the user add and open **URL** links only (`rel` absent or `describedby`). `rel: "enclosure"` — the future attachment form — is persisted and never written by 3.1.0. | Should |
| TLD-705 | A link opens through the allowlisted URL seam, only for `https:` and `http:`, and only on an explicit tap. Every other scheme is displayed and not launched. | Must |
| TLD-706 | No link is ever fetched, resolved, previewed or size-checked automatically. Not for a favicon, not for a thumbnail. | Must |
| TLD-707 | Binary content is never stored in a task row. | Must |

## I. Ordering (TLD-8xx)

| Id | Requirement | Priority |
|---|---|---|
| TLD-801 | Manual order is an explicit `sort_order INTEGER NOT NULL` on `tasks` and on `lists`. A timestamp is never a sort key. | Must |
| TLD-802 | Every ordered query has a deterministic tiebreak. For tasks it is `jscalendar_uid`; for lists it is `id`. | Must |
| TLD-803 | Reordering rewrites the affected `sort_order` values in one transaction. A partially applied reorder is not observable. | Must |
| TLD-804 | `sort_order` is app-local. It is never emitted into an interchange document and never read from one. | Must |
| TLD-805 | Insertion assigns a `sort_order` that places the new task where the UI showed it being inserted, without renumbering the whole list. | Should |

## J. Deletion, undo and trash (TLD-9xx)

| Id | Requirement | Priority |
|---|---|---|
| TLD-901 | Every destructive action (complete, delete, move, archive) offers an undo for at least the duration of its snackbar, through the shared undo helper. | Must |
| TLD-902 | Deleting a task sets `deleted_at` and removes it from every view. It is not erased. | Must |
| TLD-903 | A trash screen lists deleted tasks, allows restore and allows permanent deletion, and is reachable from "Mehr". | Must |
| TLD-904 | Trashed tasks older than 30 days are permanently deleted. The retention period is a documented constant, and a purge run is idempotent. | Should |
| TLD-905 | Restoring a task restores it to its original list. If that list is gone, it goes to the Inbox and the app says so. | Must |
| TLD-906 | Restoring a subtask whose parent is gone restores it as a top-level task and the app says so. | Must |
| TLD-907 | Permanent deletion removes the row and its dependent rows (tags, links, reminders, recurrence overrides) in one transaction. | Must |

## K. Data layer rules (TLD-10xx)

| Id | Requirement | Priority |
|---|---|---|
| TLD-1001 | No hand-written SQL for domain access. Drift typed queries only; reactive `watch*` streams feed Riverpod. | Must |
| TLD-1002 | `PRAGMA foreign_keys = ON` on every connection — already true in the template and asserted by test. | Must |
| TLD-1003 | Foreign-key semantics are documented per edge: CASCADE for purely dependent rows, RESTRICT where deletion is a domain decision. | Must |
| TLD-1004 | Migrations are additive, idempotent (`addColumnIfMissing`) and carry a raw-SQL fixture test of the previous schema per version. | Must |
| TLD-1005 | Every stream that emits a composed object joins every table that object depends on. Loading a related table inside `asyncMap` is forbidden — see KI-003. | Must |
| TLD-1006 | Epoch-day and minutes-of-day conversion goes through shared `TypeConverter`s declared on the **storage** type, imported into the database library file — see KI-004. | Must |
| TLD-1007 | Tree-safety, list-membership and date-order invariants are enforced in the repository, so the import path (spec 0004) cannot bypass them. | Must |
| TLD-1008 | `unknown_json` (bounded, 8 KiB) persists unrecognized standard properties from an imported document, and is merged back on export with local properties winning. | Must |

## Quality requirements

- **Accessibility** (contract `07-accessibility.md`): 48 dp targets; a
  semantic label on every icon-only control; a merged, meaningful description
  per task row ("Milch kaufen, offen, fällig morgen"); no overflow at
  `TextScaler.linear(2.0)`; a visible menu equivalent for every swipe action;
  status never conveyed by colour alone.
- **Localization**: German and English for everything user-visible. `app_de.arb`
  stays the template ARB.
- **Performance**: a list of 2 000 tasks scrolls without a frame budget
  violation, and its stream re-emits only for writes that affect it.

## Constraints

- Generators are mandatory: `riverpod_annotation` for providers, Freezed for
  immutable models and union states, `json_serializable` where a model is
  serialized, Drift codegen for tables and DAOs. Generated files are never
  edited by hand.
- Version deltas against WasThereSomething are real: `riverpod_annotation` ^3
  here vs ^4 there, `go_router` ^14 vs ^17. Reuse the reasoning, never the
  snippets.
- New dependencies are resolved against the KI-001 tree **before** adoption
  and justified with purpose, licence, maintenance status and a removal path.

## Data requirements

See `data-contract.md` for the full schema, the type converters, the
foreign-key semantics, the migration design and the fixture matrix.

## Privacy / Security considerations

- Local-first: no backend, no account, no analytics, no network.
- Titles and bodies are personal free text (TLD-107).
- Links from an imported document are inert until an explicit tap, and only
  for `http`/`https` (TLD-705, TLD-706).
- `android:allowBackup` stays `false`, as the bootstrap already sets it —
  otherwise the database can be uploaded to the user's Google account, which
  would quietly break the local-first promise.

## Testability notes

Automated: every requirement in sections A–K except TLD-107 (partly manual)
and the accessibility items, which have their own widget tests.

Manual: colour-token rendering in light and dark, the confirmation copy for
list deletion, and the screen-reader pass over a task row.

## Traceability

Every requirement maps to a criterion in `acceptance-criteria.md`.
