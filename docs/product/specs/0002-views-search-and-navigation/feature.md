# Feature: Views, search and navigation

## Metadata

- **Status:** specified (planning only — no implementation until an approved
  story exists, per AGENTS.md)
- **Target release:** 3.1.0
- **Source:** Product-owner decision 2026-08-25; planning input
  `drafts/notes/3.1.0/lumbrecode_todo_app_notes.md` section 9
- **Created:** 2026-08-25
- **App:** `openspec/apps/todo.openspec.yaml`
- **Depends on:** spec 0001 (task and list domain)
- **Decisions:** ADR-0011 (reference app), ADR-0010 (go_router)
- **Requirement prefix:** `VSN-`

## Summary

Lists are where tasks live. Views are how a person actually looks at them.

```text
┌─ Heute ───────────────────────────────────────────┐
│  Überfällig                                    2  │
│    [ ] Rechnung bezahlen        fällig gestern    │
│    [ ] Rückruf Werkstatt        fällig 21. Aug    │
│  Heute                                         3  │
│    [ ] Milch kaufen                               │
│    [ ] Schokokuchen backen           10:00     !  │
│  Ohne Datum                                    7  │
│    ...                                            │
└───────────────────────────────────────────────────┘
   Heute      Listen      Suche      Mehr
```

Four views (Heute, Demnächst, Alle, Erledigt), one list overview, one search,
one settings hub, and the routing that connects them. A view is a **saved way
of looking across lists** — never a container. A task is in exactly one list
and can appear in several views.

## Problem

A to-do app with only lists forces the user to remember which list a thing is
in before they can act on it. The category converged on views for a reason:
the everyday question is "what do I need to do now?", not "what is in list
three?".

The interesting design problem is what "now" means, and it is what makes
`start` worth having:

```text
start = Montag      "zeig mir das nicht vor Montag"
due   = Freitag     "das muss bis Freitag fertig sein"
```

**Heute** shows tasks whose `start` has arrived, plus anything due today or
overdue. A task with a future `start` is deliberately hidden. That is the
entire point of a start date, and it is the difference between a useful
"Today" and a wall of everything. An app that ignores `start` has a Today
view that nobody trusts, and a user who stops opening it.

The second problem is smaller but constant: a list of tasks needs to be
orderable four different ways (manual, due date, priority, title) without any
of them producing a non-deterministic order — which, given that Drift stores
timestamps at second precision (KI-008), is a real trap rather than a
theoretical one.

## Goals

- A default landing screen that answers "what now?" in one glance, honouring
  `start` as a hiding rule.
- Four views with defined, testable membership rules, all reading from one
  query layer rather than four hand-rolled ones.
- Sort and group that are per-surface, persisted, and always deterministic.
- Search over titles and notes that is fast enough to be typed into, and
  filterable by list and tag.
- Navigation that survives process death and deep links, because the app is
  entered from a notification (spec 0003) and from a share intent (spec 0004).
- Completed tasks that stay visible briefly, then collapse — so completing
  something feels like progress rather than like the item never existed.

## Non-goals

- The task and list model, and every invariant on it — spec 0001.
- Reminder scheduling and recurrence expansion — spec 0003. Views *render*
  recurring instances; they do not compute them.
- Import and export — spec 0004.
- A calendar view. This is a list app; `due` is a deadline, not a time block.
- Saved custom filters or user-defined smart lists. Four fixed views in
  3.1.0.
- Natural-language search ("überfällig einkauf"). Plain substring matching
  plus explicit filters.

## Users / Actors

- **The person using the app**, who mostly lives on Heute and reaches for a
  list only when organizing.
- **The notification tap** (spec 0003), which deep-links to a task detail and
  must produce a sane back stack.
- **The import review** (spec 0004), which lands on a newly created list.

## Assumptions

- "Today" is the device's local calendar day, recomputed on resume and at
  midnight. A view that silently goes stale overnight is worse than one that
  flickers.
- Two thousand tasks is the realistic upper bound for a personal to-do app.
  Queries are indexed for it; nothing is designed for a hundred thousand.
- Subtasks appear under their parent inside a list, but views may show them
  flat — a subtask due today is due today regardless of where its parent
  sits. The view says so rather than pretending the parent is not there.

## Related docs

- Requirements: `./requirements.md`
- Acceptance criteria: `./acceptance-criteria.md`
- Open questions: `./open-questions.md`
- UX: `./ux.md`
- Data contract: `./data-contract.md`
- Out of scope: `./out-of-scope.md`
- Release plan: `./release-plan.md`
