# Open questions: Views, search and navigation

Answered questions are kept and marked, with the answer folded into the
relevant spec file.

## Product

- **Q-2a — should Heute include tasks whose `start` has arrived but which
  have no due date?** **Answered 2026-08-25: yes** (VSN-002, `heute`
  predicate). "Zeig mir das ab Montag" is exactly what a start date is for,
  and a Today view that ignores it would make start dates decorative.

- **Q-2b — do Alle and Erledigt deserve their own tabs?** **Answered
  2026-08-25: no.** Four destinations, with Alle and Erledigt in Heute's
  overflow. A five-tab bar on a phone gives none of the labels room at 200 %
  text scale, and the accessibility contract's rule 5 is not negotiable.
  Revisit if usage shows Alle being reached constantly.

- **Q-2d — is a 7-day Demnächst window right?** Seven matches the category
  and matches a week's planning horizon. Open only in the sense that nobody
  has argued for a different number; it is one constant.

- **Q-2e — should there be user-defined smart lists / saved filters?** Not in
  3.1.0 (out of scope). The query abstraction (`TaskQuery`) is shaped so that
  a saved filter is a persisted `TaskQuery`, not a redesign. Recorded so the
  door stays visibly open.

## UX

- **Q-2f — how long should a completed task linger before collapsing?**
  Proposal: 5 seconds, matching the undo snackbar's lifetime so the two
  windows agree. **Status: open**, needs one pass on a device — the number is
  a feel judgement, not a derivation.

- **Q-2g — does the "Erledigt (n)" collapse state persist across restarts?**
  Proposal: no. It is per session, per surface. Persisting it would need a
  settings key per surface for very little value.

- **Q-2h — should a flat subtask in Heute be tappable to its parent, or only
  to itself?** Proposal: the row opens the subtask; the parent label is a
  secondary tap target. Needs a check against the 48 dp rule — two targets in
  one row is where that gets violated.

## Technical

- **Q-2c — how is locale-aware title sorting implemented?** Two options:
  sort in Dart using `intl` collation for the active locale, or register a
  custom SQLite collation through Drift. Dart-side is simpler and correct but
  loads the whole result set before ordering; a SQLite collation keeps the
  ordering in the query and pages properly. **Status: open — decide in slice 5
  and record it.** The requirement (VSN-106) is the behaviour, not the
  mechanism. SQLite's default `NOCASE` is ASCII-only and is not an option: it
  sorts "Äpfel" after "Zebra".

- **Q-2i — `LIKE` scan or FTS5 for search?** Start with `LIKE` over `title`
  and `description_markdown`. VSN-308 states the requirement as a **latency
  budget** (150 ms for first results over 2 000 tasks), measured once and
  recorded. If `LIKE` misses it, add an FTS5 virtual table — which is a schema
  change with its own migration and its own trigger-maintenance cost, and is
  therefore not taken pre-emptively.

- **Q-2j — how does the midnight rollover fire?** Options: recompute on
  `AppLifecycleState.resumed` only, or additionally schedule a timer to the
  next local midnight. Proposal: both, because an app left open on the
  bedside table is exactly the case where the user notices. The timer must be
  cancelled on dispose, and a widget test must not leave it pending —
  flutter_test's pending-timer invariant (KI-005).

- **Q-2k — where does `today` come from?** From the existing `Clock` seam in
  `core/utils/clock.dart`, injected into the query (see `data-contract.md`
  1.1). Never `DateTime.now()` inside a query or a predicate — that is what
  makes the whole membership block testable.

## Architecture

- **Q-2l — one `TaskQuery` for search too, or a separate search path?**
  Proposal: one, with `TaskView.search`. A separate path is the beginning of
  the drift VSN-601 exists to prevent. Revisit only if FTS5 (Q-2i) makes the
  shapes genuinely different.

- **Q-2m — does the app use go_router's `StatefulShellRoute` for the four
  tabs?** It is the idiomatic way to get VSN-407 (per-tab state), but this
  template pins **go_router ^14** while WasThereSomething runs ^17, and the
  shell-route API moved across that range. **Verify the ^14 API before
  writing routing code**; do not copy a ^17 snippet.

## Privacy / Security

- **Q-2n — are recent searches acceptable at all?** In-memory only, cleared on
  restart and by "Alle Inhalte löschen" (VSN-307). Open: whether to have them
  at all. They are a convenience with a small but real leak surface if the
  decision ever slips to persisting them.

## Testing

- **Q-2o — how is the 150 ms latency budget measured repeatably?** A CI
  machine is not a mid-range phone, so the number cannot be a CI gate.
  Proposal: an integration test that measures and **records** the value in the
  PR, with the device named. A regression is then visible without being
  flaky-blocking.

## Release

- **Q-2p — does Heute ship before search?** Yes. Slice 5 delivers the views;
  search arrives with slice 10. Heute, Demnächst and the list detail are what
  make the app usable; search is what makes it pleasant.
