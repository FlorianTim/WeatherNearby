# Feature: Task and list domain

## Metadata

- **Status:** specified (planning only — no implementation until an approved
  story exists, per AGENTS.md)
- **Target release:** 3.1.0
- **Source:** Product-owner decision 2026-08-25; planning input
  `drafts/notes/3.1.0/lumbrecode_todo_app_notes.md` (non-normative draft,
  explicitly authorized — ADR-0005 exception)
- **Created:** 2026-08-25
- **App:** `openspec/apps/todo.openspec.yaml`
- **Decisions:** ADR-0011 (reference app), ADR-0014 (interchange package)
- **Standard:** RFC 8984 — JSCalendar, object type `Task`
- **Enables:** specs 0002, 0003, 0004
- **Requirement prefix:** `TLD-`

## Summary

The core of the app: a task, a list, and the rules that keep both honest.

```text
Inbox                                   3
  [ ] Milch kaufen
  [ ] Schokokuchen backen        14. Mär, 10:00  !
        [ ] Schokolade kaufen
        [x] Sahne kaufen
  [x] Kerzen kaufen
```

A task is an RFC 8984 `Task`: a stable v4 UUID, a title, an optional Markdown
body with a declared content type, the five-value `progress` vocabulary,
optional `start` and `due` as offset-free local date-times, optional
recurrence, single-parent subtasks, priority, tags and links.

A list is **this app's own concept** — the contract knows nothing about lists.
A task belongs to exactly one list; the Inbox is the list it lands in when the
user chooses nothing, and the Inbox cannot be deleted or renamed.

## Problem

The template's current example of "a thing the user creates" is one flat table
with six columns and a three-value status enum. It is a smoke test, and
ADR-0011 explains why the template now needs more than one.

But "more than one" is not a licence to invent a schema. Three wrong answers
were available:

- **A private "title + done" row.** Solves this week. Every subsequent
  question — a body, a due date, a subtask, sharing it with someone — is a
  migration.
- **A Todoist- or Microsoft-To-Do-shaped schema.** Copies a vendor's product
  decisions, and the result still cannot be exchanged with anything.
- **Reusing the demo's `TodoStatus {pending, inProgress, completed}`.** This
  is the dangerous one, because it looks nearly right. `pending` is not
  `needs-action`, `failed` and `cancelled` are missing, and the difference
  only surfaces the first time a document crosses the boundary.

So the model is the standard's: RFC 8984 `Task`, with the app's own `list`
concept layered beside it rather than mixed into it.

## Goals

- A task can be created with a title alone, in one tap, from any screen that
  shows tasks. No mandatory second screen, ever.
- The persisted model is a faithful, lossless home for everything the
  interchange contract can carry — including the parts with no UI in 3.1.0,
  so that adding the UI later needs no migration.
- Lists and tags are kept as different things: lists are containment
  (exactly one), tags are cross-cutting (zero or more).
- Nothing the user created vanishes on a single tap. Undo first, then a
  trash, then deletion.
- Ordering is explicit and deterministic, never a timestamp.
- The data layer enforces its own invariants. A UI bug must not be able to
  create a cycle in the task tree.

## Non-goals

- Views, search and navigation — spec 0002.
- Reminders and recurrence expansion — spec 0003.
- Import, export and the wire format — spec 0004.
- Sync, accounts, collaboration, assignment. Local-first is a product
  promise, not a phase.
- Occurrences, occurrence keys, calendar projection. Those are
  WasThereSomething product semantics and none of them are exported. If they
  seem necessary to read a document, the document is wrong.

## Users / Actors

- **The person using the app.** Creates, completes, organizes and deletes
  tasks and lists.
- **The import path** (spec 0004), which writes through the same repository
  and is subject to exactly the same invariants. It gets no privileged
  write path.

## Assumptions

- One device, one user, no sync. Nothing in the model needs a conflict rule.
- Task titles and bodies are **personal free text**. They never appear in
  logs, and they leave the device only through an explicit, previewed action.
- Two levels of nesting (task, subtask) is enough for 3.1.0. Deeper nesting
  is rejected rather than silently flattened, because a silent flatten loses
  the user's structure without telling them.
- The demo's rows are **not** migrated (see `data-contract.md`). The demo and
  the reference app coexist until slice 13; nobody has production data in
  `todo_items`.

## Related docs

- Requirements: `./requirements.md`
- Acceptance criteria: `./acceptance-criteria.md`
- Open questions: `./open-questions.md`
- UX: `./ux.md`
- Data contract: `./data-contract.md`
- Out of scope: `./out-of-scope.md`
- Release plan: `./release-plan.md`
