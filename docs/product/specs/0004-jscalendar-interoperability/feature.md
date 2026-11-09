# Feature: JSCalendar interoperability — import, export and contract tests

> **Package location (ADR-0017, 2026-10-08).** The codec is no longer
> `packages/task_interchange` in this repository. It is `task_interchange` in
> `flutter-libraries` (family `interchange`), consumed as a tag-pinned git
> dependency of `apps/mobile_app`. Statements below that say
> `packages/task_interchange` mean that package. Fixtures are read from
> `.lumbrecode/schemas/`, not vendored.

## Metadata

- **Status:** specified (planning only — no implementation until an approved
  story exists, per AGENTS.md)
- **Target release:** 3.1.0
- **Source:** Product-owner decision 2026-08-25; planning input
  `drafts/notes/3.1.0/lumbrecode_todo_app_notes.md` section 11
- **Created:** 2026-08-25
- **App:** `openspec/apps/todo.openspec.yaml`
- **Depends on:** spec 0001 (task and list domain)
- **Decisions:** ADR-0013 (Android receive boundary), ADR-0014
  (`packages/task_interchange`)
- **Standards:** RFC 8984 (JSCalendar), CloudEvents 1.0, RFC 7493 (I-JSON),
  RFC 7763 (`text/markdown`), RFC 4122 §4.4 (UUID v4)
- **Binding contract:** `lumbrecode-engineering`
  - `docs/JSCALENDAR_TASK_INTEROP.md` — the implementation guide
  - `docs/LUMBRECODE_EXCHANGE.md` — the CloudEvents profile
  - `schemas/jscalendar-task/v1/` — schema + 24 golden fixtures
  - `schemas/lumbrecode-exchange/v1/` — schema + 21 golden fixtures
- **Sibling implementation:** WasThereSomething specs 0036, 0037 (the sending
  half, already built)
- **Requirement prefix:** `INT-`

## Summary

The reason the app exists in this shape: a task list can leave one app and
arrive in another, as a standard document that neither app owns.

```text
WasThereSomething
  Geburtstag Mia, 14.03.2027
    ├── Schokokuchen backen
    │     ├── Schokolade kaufen
    │     └── Sahne kaufen
    └── Pappteller mitbringen

        │  teilen  →  Group (application/jscalendar+json;type=group)
        ▼

LumbreCode To-do
  neue Liste "Geburtstag von Mia - 14.03.2027"
    ├── Schokokuchen backen
    │     ├── Schokolade kaufen
    │     └── Sahne kaufen
    └── Pappteller mitbringen
```

**The format is fixed.** It is specified, schema-validated, covered by 45
golden fixtures and already implemented on the sending side. This spec
implements it. It does not redesign it, and if something in it turns out to be
wrong, the answer is to raise it with the contract owner and stop — not to
fork.

## Problem

Two apps written by the same people need to hand tasks to each other. Four
options existed and three were wrong:

- **A LumbreCode-defined task JSON.** Solves it once, recreates the problem
  for the third app.
- **`text/plain`.** No structure, no dates, no subtasks, no identity. The
  receiver can only paste it.
- **iCalendar `VTODO`.** A real standard, but line-based with folding and
  escaping rules — heavy as an internal model and as an app-to-app payload.
  It remains the right *export* target for the outside world, later.
- **JSCalendar `Task` (RFC 8984).** Chosen. JSON-native, registered media
  type, registered progress vocabulary, defined relation model, a container
  type for lists, a documented recurrence model.

That decision is already made and recorded (WasThereSomething ADR-0019,
ADR-0020). What is left is the part every receiving implementation gets wrong,
and the guide is emphatic about each:

1. **A familiar `uid` is not an instruction to merge.** The moment two apps
   treat a shared `uid` as identity, a hand-off becomes a distributed-state
   problem: conflict rules, revision counters, a back channel, eventually a
   backend. A `Group` becomes a **new list**, always — even on a second import
   of the identical file.
2. **Import is total.** A rejected document writes zero rows. Not "best
   effort", not "the half that parsed".
3. **Every loss is reported.** "4 von 5 Aufgaben importiert. Eine
   Wiederholung konnte nicht übernommen werden." is honest. Silently dropping
   a repetition is not.
4. **Unknown properties are kept, not rejected.** Read tolerantly, write
   conservatively.
5. **Nothing is fetched.** A `href` in an untrusted document is inert until an
   explicit tap, and only for `http`/`https`.

And one thing this repository adds, which the guide could not know:
**`apps/mobile_app/android/` is not committed.** The intent filter is a
bootstrap-script change, not a manifest edit (ADR-0013).

## Goals

- A shared JSCalendar document arrives, is validated totally, is reviewed by
  the user, and becomes a new list in one transaction.
- Every loss the tolerance rules permit is counted, typed and shown.
- A task, a selection or a whole list leaves as a standard document, with an
  unskippable preview naming what is about to leave the device.
- CT-1 to CT-15 pass against the **same golden fixtures** WasThereSomething
  tests against — so "compatible" is a test result, not a claim.
- The receive boundary is narrow enough that this app appears in the share
  sheet only for documents it can actually read.
- The codec is template surface (`packages/task_interchange`), reusable by any
  future LumbreCode app.

## Non-goals

- The task and list model — spec 0001. The importer writes through the same
  repository and gets no privileged path.
- Views and navigation — spec 0002, which owns only the fact that the import
  review is a route.
- The stored form of a recurrence rule, and its expansion — spec 0003. This
  spec owns the wire form and the warnings.
- **Synchronization, in any form, ever.** Not deferred: excluded by contract
  (guide §10.2, ADR-0020). Sharing is a snapshot, one-way, with no back
  channel and no relationship afterwards.
- iOS receive. Android is the only primary platform; an iOS share extension is
  its own work.
- ICS / `VTODO` export. The right eventual target for the outside world, not
  contract v1.
- Attachments as bytes. In contract v1 an attachment is a `Link` with
  `rel: "enclosure"`; the bytes are not in the document.
- JSContact. RFC 9553 is standardized in `lumbrecode-engineering` and a to-do
  app has no obvious use for contacts (draft Q-06).

## Users / Actors

- **The person receiving a document**, who must be able to see what will be
  created *before* anything is written, and what was lost afterwards.
- **The person sending one**, who must see what leaves the device before it
  leaves.
- **The sending app** (WasThereSomething 1.5 today), whose `prodId` and
  `sourceappid` are **claims, never trust decisions** — the app must not
  branch on either.
- **The Android share sheet**, which must not offer this app for a photo.

## Assumptions

- Documents are attacker-controlled in the general case. The app cannot know
  what produced one, and nothing in the payload authenticates anything.
- 256 KiB is a sufficient cap for a task list, and a document over it is
  rejected as oversized rather than truncated.
- A second import of the same file creating a second list is **acceptable and
  correct**. The user deletes one if they did not want it. The alternative —
  guessing that two imports are "the same list" — is a merge, and a merge needs
  conflict rules this contract does not define.
- The golden fixtures must be vendored into this repository: the baseline sync
  the guide describes (`.lumbrecode/schemas/`) **does not exist here**
  (ADR-0014, and the audit §4.2).

## Related docs

- Requirements: `./requirements.md`
- Acceptance criteria: `./acceptance-criteria.md`
- Open questions: `./open-questions.md`
- UX: `./ux.md`
- Data contract: `./data-contract.md`
- Out of scope: `./out-of-scope.md`
- Release plan: `./release-plan.md`
