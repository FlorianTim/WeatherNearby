# Feature: Reminders and recurrence

## Metadata

- **Status:** specified (planning only — no implementation until an approved
  story exists, per AGENTS.md)
- **Target release:** 3.1.0
- **Source:** Product-owner decision 2026-08-25; planning input
  `drafts/notes/3.1.0/lumbrecode_todo_app_notes.md` sections 8.4 and 12
- **Created:** 2026-08-25
- **App:** `openspec/apps/todo.openspec.yaml`
- **Depends on:** spec 0001 (task and list domain)
- **Decisions:** ADR-0012 (local notification boundary), ADR-0014 (the
  recurrence subset lives in `task_interchange` (`flutter-libraries`, ADR-0017))
- **Standard:** RFC 8984 `RecurrenceRule` / `NDay`; RFC 5545 recurrence
  grammar subset
- **Requirement prefix:** `RRC-`

## Summary

Two features that share a spec because they share a hard problem: turning a
stored rule into a moment, without ever going through the wrong kind of
timestamp.

```text
Blumen gießen              ↻ alle 3 Tage
  fällig 25. Aug                              🔔 1 Std. vorher

  [ Erledigt ]  [ Später ▾ ]        ← from the notification, without opening the app
```

**Reminders** are locally scheduled notifications, at the due time or at a
configurable lead time, with two actions. **Recurrence** is an RFC 5545 subset
— `FREQ`, `INTERVAL`, `BYDAY`, `BYMONTHDAY` — stored as a string, expanded on
demand, never cloned into rows.

## Problem

### Reminders

A to-do app without reminders is a list. But a reminder is the first thing in
this template that touches four uncomfortable things at once:

1. **A runtime permission the template has never actually requested.**
   `core/permissions/` has the just-in-time flow and the `PermissionGateway`
   interface, and **no concrete implementation anywhere** — the only one is a
   test fake.
2. **An OS scheduler** that may be cleared by a reboot, a time-zone change or
   an app update, and must therefore be treated as a cache rather than as a
   source of truth.
3. **A background entry point that can run without a UI.** "Erledigt" tapped
   on a notification means a write while the app may have no `Activity`, no
   `ProviderScope` and — on Android — a **separate Dart isolate with its own
   memory**. This is the trap WasThereSomething flagged for its spec 0031 and
   did not resolve. ADR-0012 resolves it here by making the background half
   append-only.
4. **Personal free text on a lock screen.** Convenient, and a leak.

### Recurrence

"Alle 3 Tage" looks trivial and is not, for two reasons.

**The interoperability constraint.** The supported subset is fixed by the
contract: four frequencies, `interval`, `byDay` with `nthOfPeriod`, and
`byMonthDay`. Everything else JSCalendar allows — `hourly`, `rscale`,
`byMonth`, `bySetPosition`, and notably `count` and `until` — is unsupported
by contract v1. A wider parser here would let this app emit rules
WasThereSomething cannot read, which is a compatibility bug wearing a
feature's clothes. That is why `rrule` is not a dependency (ADR-0014).

**The completion-mode question.** Two tasks that repeat weekly behave
differently:

```text
Miete überweisen      ↻ monatlich    from the nominal date
                                     — the 1st is the 1st, late or not
Blumen gießen         ↻ alle 3 Tage  from when you actually did it
                                     — three days after watering, not after
                                       the date it was supposed to happen
```

Getting this wrong produces either a rent reminder that drifts later every
month, or a plant that gets watered on a schedule invented in March. It is
app-local semantics — JSCalendar has no property for it — and it is stored in
`recurrence_mode`.

## Goals

- A reminder is set in two taps from the task detail, and the notification
  permission is requested at that moment, with a rationale, never at startup.
- A denied permission leaves the app fully usable and says exactly what is
  limited.
- Scheduled notifications survive a reboot, a time-zone change and an app
  update, by being reconciled from the database rather than trusted from the
  OS.
- Notification actions work with the app dead, without a background write to
  the domain database.
- Recurrence is exactly the contract's subset — no more, so documents stay
  mutually readable; no less, so "alle 3 Tage" and "jeden 1. Montag" work.
- A recurring task is never cloned. Instances are computed; only instances
  with their own state get a row.
- Both completion modes exist and the difference is visible in the UI.

## Non-goals

- The task model, the date columns, the trash — spec 0001.
- View membership and rendering of instances — spec 0002. This spec *computes*
  the next instance; views consume it.
- The wire format for `recurrenceRules` and `recurrenceOverrides` — spec 0004.
  This spec owns the stored form and the expansion; spec 0004 owns
  serialization.
- Push notifications, Firebase, any server-side scheduling. Local only, and
  it is a product promise, not a phase.
- Location-based reminders. Background location is its own permission and its
  own privacy question.
- Snooze presets beyond the three named here.
- Exact alarms. ADR-0012 decision 3 says why.

## Users / Actors

- **The person using the app**, who sets a reminder on a task and later acts
  on the notification.
- **The Android system**, which delivers, batches, may delay, and forgets
  everything on reboot.
- **The startup coordinator**, which reconciles the OS's scheduled set against
  the database on every start.

## Assumptions

- Local-only scheduling is sufficient. No second device, no sync, so a
  reminder has exactly one place to fire.
- Inexact delivery is acceptable for a to-do reminder (ADR-0012, decision 3).
  Copy in the reminder editor must therefore not promise a precise minute.
- A completion from a notification may be **eventually consistent**: applied
  at the next foreground run. The notification is dismissed immediately, so it
  looks done; the row changes on the next start. This is stated in ADR-0012
  and surfaced in the acceptance criteria rather than discovered as a bug.
- Web has no local notifications. The app degrades to "reminders stored, never
  delivered" and says so, rather than crashing or pretending.

## Related docs

- Requirements: `./requirements.md`
- Acceptance criteria: `./acceptance-criteria.md`
- Open questions: `./open-questions.md`
- UX: `./ux.md`
- Data contract: `./data-contract.md`
- Out of scope: `./out-of-scope.md`
- Release plan: `./release-plan.md`
