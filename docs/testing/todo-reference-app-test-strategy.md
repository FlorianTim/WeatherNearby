# Test strategy: the To-do reference app (3.1.0)

Deliverable H of the 3.1.0 planning pass. Covers specs 0001–0004 and the
shared foundations.

This complements `docs/testing/README.md`, which describes the web build and
the integration-test tooling. It does not replace it.

---

## 1. Why this app needs a strategy at all

The demo has four test files and one flat table. The reference app has a
domain with invariants, an external contract with a second implementation, a
platform boundary, a background isolate and two languages. ADR-0011's whole
argument is that the template needs something with enough surface to break —
which is only useful if the breakage is *detected*.

So the strategy is shaped by one question per layer: **what would fail
silently here?**

| Layer | What fails silently |
|---|---|
| Codec | a date shifted by an hour across DST; a dropped property nobody counted |
| Domain | a cycle in the task tree; a non-deterministic sort |
| Database | a migration that loses rows; a stream that never re-emits |
| Views | a task hidden by a start date that should have shown |
| Notifications | a reminder past the scheduling horizon; a background write that never lands |
| Interop | an output the other app cannot read |
| Accessibility | overflow at 200 % text scale; a swipe with no alternative |

Every level below exists to catch one of those.

---

## 2. Test levels

### 2.1 Unit and property — `task_interchange` (in `flutter-libraries`)

Pure Dart, no Flutter. The code and its unit and property suites live in the
`flutter-libraries` repository and run under its own CI (ADR-0017); this
repository consumes it by tag and re-proves it with the contract test in
`apps/mobile_app/test/interop/`. The properties below are therefore owned and
run there.

Owns: the codec, validation, the warning taxonomy, the recurrence subset
parser and the expander.

**Property tests carry the weight here**, because the failure modes are
combinatorial rather than exemplary:

| Property | Cases |
|---|---|
| Date round trip | four date shapes × with/without time × a year around both DST transitions |
| Recurrence round trip | every rule the parser accepts |
| Tree safety | 10 000 random parent assignments over 200 tasks |
| Determinism | every fixture, encoded 10 times |
| `Uuid4` | 100 000 draws: canonical form, version, variant, distinctness |
| No `null`, no empty collections | 1 000 randomly populated models |
| Fuzz | 10 000 mutated documents; **no unhandled exception** |

### 2.2 Unit — pure domain functions in the app

View membership predicates (spec 0002, VSN-603) are pure functions over a
task record plus `today`. They are the cheapest high-value tests in the whole
plan: every rule in the `viewMatrix` fixture is evaluated without opening a
database, and the SQL path is asserted to agree with them.

`today` is **injected** from the existing `Clock` seam. Nothing calls
`DateTime.now()` inside a query, a predicate or a view model — that single
constraint is what makes this level possible.

### 2.3 Repository — Drift, in-memory

`NativeDatabase.memory()`, per ADR-0009. Owns the invariants and everything
transactional.

- Tree safety, list membership, date ordering, the Inbox constraint.
- Ordering determinism: 50 rows written inside one second, read 100 times.
- Composed-stream re-emission (KI-003 regression guard).
- Migration fixtures (§3).
- Reconciliation convergence against the fake notification gateway.
- The pending-action drain: idempotent, tolerant of a deleted target.
- CT-11 (a `uid` twice creates two lists) and CT-12 (a rejected document
  writes zero rows) — they belong here, not in the codec, because they are
  about transactions and rows.

### 2.4 Widget

Every screen, with all seams faked. The rules that already exist in
`test/support/test_app.dart` stay — KI-005 lists what they prevent, and this
plan adds nothing that would let them be simplified away:

- `setUp(rootBundle.clear)` in asset-loading tests.
- Drift setup and assertions inside `tester.runAsync(...)` — awaiting a Drift
  stream in a `testWidgets` body deadlocks under FakeAsync.
- `driftRuntimeOptions.dontWarnAboutMultipleDatabases = true`.
- Unmount and pump once after the body, so Drift's zero-duration close timers
  do not trip the pending-timer invariant.
- A tall viewport (`Size(1080, 3600)`) for long lists — lazy `ListView`s do
  not build offscreen children, and a 2 000-row fixture in a phone-sized
  viewport silently tests nothing.
- Unfocus, then drag, then tap when a target is only edge-visible behind the
  bottom navigation bar.
- `wrapWithL10n(child)` — a test without an explicit locale resolves to `en`
  while the template ARB is `app_de.arb`.

**New for 3.1.0:** the undo snackbar and the completed-task linger have real
durations. Those tests pump deliberately; `pumpAndSettle` on a surface with a
5-second snackbar either hangs or hides the behaviour.

### 2.5 Integration

`integration_test/`, on a device or emulator.

- The notification back stack: app killed → notification tapped → detail
  opens → one back press reaches Heute.
- Import totality and the `uid`-twice rule end to end.
- The contract end-to-end assertion (§4.3).
- The existing screenshot flow, updated in slice 13 when the demo goes.

### 2.6 Contract tests

Their own suite, named, so they can be run and reported on alone. §4.

### 2.7 Manual

Enumerated per spec. They exist because the alternatives are worse, not
because automation was skipped — §5 says which is which.

---

## 3. Database and migration testing

Database-contract rule 3: **per schema version, a raw-SQL fixture of the
predecessor plus a test that opens, migrates and proves the old rows
survived.**

The chain 3.1.0 introduces:

| Step | Slice | Fixture assertion |
|---|---|---|
| fresh install (`onCreate`) | 2 | all tables, indexes, constraints; exactly one Inbox seeded |
| v1 → v2 | 2 | demo rows intact; new tables present; `user_version` correct |
| v2 → v3 | 6 | seeded lists/tasks/tags/links survive |
| v3 → v4 | 7 | same, plus the new override table |
| v2 → v4 chained | 7 | no loss across two steps |
| v1 → v5 full chain | 13 | end-to-end |
| v4 → v5 | 13 | `todo_items` gone; **every `tasks` row untouched** |
| partially applied upgrade | 2 | re-open completes or fails cleanly; `addColumnIfMissing` idempotent |
| FK-violating legacy row | 2 | migration fails **loudly** rather than deleting rows |
| downgrade (v5 db, v4 build) | 2 | readable `StateError`, no data touched |

Fixtures are raw SQL with seeded rows, not Drift code — a fixture written
through the current schema classes proves nothing about the old schema.

**Domain fixtures use builders** (`TaskFactory`, `ListFactory`), not literal
rows, so adding a column does not break sixty tests.

---

## 4. Contract testing

The part that makes "compatible" a test result rather than a claim.

### 4.1 Fixtures

The golden fixtures are read from `.lumbrecode/schemas/` (the baseline sync of
`lumbrecode-engineering`) **by directory**. They are not vendored a second
time, and no `PROVENANCE.md` is kept: the baseline lock
(`.lumbrecode/baseline.lock.json`) carries the checksums.

Counts are not asserted in this repository: the baseline is adopted on the
template's schedule, and the library's own suite (which asserts the counts of
its baseline) runs in `flutter-libraries`.

**A fixture changes in `lumbrecode-engineering` and arrives through the
baseline sync** — never by a local edit. The baseline lock makes a local edit
fail rather than pass quietly.

### 4.2 CT-1 … CT-15

| # | Test | Owner | Level | Slice |
|---|---|---|---|---|
| CT-1 | every accepted fixture validates against the schema | library | ci | 12 |
| CT-2 | every `9x-invalid-` fixture rejected, typed, readable | library | unit | 1 |
| CT-3 | `encode(decode(fixture))` semantically equals the fixture | library | unit | 1 |
| CT-4 | `decode(encode(model))` equals the model | library | unit | 1 |
| CT-5 | recurrence round trip | library | property | 1 |
| CT-6 | date round trip | library | property | 1 |
| CT-7 | tree safety, 10 000 assignments | library | property | 1 |
| CT-8 | parent/child survives a Group round trip | app | integration | 12 |
| CT-9 | Markdown body byte-identical | library | unit | 1 |
| CT-10 | unknown property survives import → export | library | unit | 1 |
| CT-11 | a `uid` seen twice creates two objects | **app** | integration | 12 |
| CT-12 | a rejected document leaves zero rows | **app** | integration | 12 |
| CT-13 | every loss produces a counted warning | library | unit | 1 |
| CT-14 | determinism: byte-identical output | library | unit | 1 |
| CT-15 | no app-local field in any document | both | unit | 1 + 12 |
| CT-16 | every accepted `Group` fixture imports to its expected summary (packing lists `52`-`54` included) | both | integration | decoder half now (`test/interop/packing_list_contract_test.dart`), database half 8 + 12 |

**Slice 12 is a consolidation slice, not the first appearance.** CT-2, 3, 4,
5, 6, 7, 9, 10, 13, 14 are written and run in `flutter-libraries` alongside the
code they test (ADR-0017); slice 1 here re-proves CT-1..CT-4, CT-10 and CT-14
against the baseline fixtures from the consumer's side. Slice 12 adds the
app-side tests, the end-to-end assertion, and names the whole set as one suite.

**CT-16 is the packing-list obligation.** Fixtures are found by directory, so a
`5x` fixture released by a baseline sync is exercised without a code change.
The decoder half runs today; the database half (section / sub-task tree in
`tasks`, keywords stored, date-only `due` preserved, two files = two lists,
the same file twice = two lists, a rejected file writes nothing) is carried
by the four skipped tests in that file and becomes real in slice 8.

### 4.3 The end-to-end assertion

```text
WasThereSomething export → document → this app's import
        → semantically identical tasks
```

"Semantically identical" means: same titles, bodies, body content types,
dates and date-only flags, progress, percentages, priorities, keywords, links
and tree structure. It does **not** mean same local ids or same ordering.

`51-group-nested-tasks.json` *is* WasThereSomething's exporter output, so
importing it is a genuine end-to-end test of the standard layer. The full
device-to-device path (share sheet, content URI, intent) stays manual (§5).

---

## 5. What is manual, and why

Manual entries are a cost. Each one below exists because the automated
alternative does not exist or would prove less than it appears to.

| # | Step | Why not automated |
|---|---|---|
| 1 | Cold start with a shared payload | The Kotlin channel is outside `flutter test`; ADR-0013 accepts this openly |
| 2 | Warm delivery via `onNewIntent` | Same |
| 3 | Rotation during import review | Same |
| 4 | Second payload during review | Same |
| 5 | Document one byte over the cap, end to end | The Dart half **is** automated; the intent half is not |
| 6 | App does **not** appear in the share sheet for a photo, a note or a PDF | The system share sheet cannot be asserted from a test |
| 7 | A reminder actually arrives, app killed | Real OS delivery |
| 8 | Reminders survive a reboot | Real OS lifecycle |
| 9 | Time-zone change behaviour | The arithmetic **is** unit-tested; the OS trigger is not |
| 10 | "Erledigt" from a notification with the app killed | The queue and drain **are** unit-tested; the background entry point is not |
| 11 | Permission denied → granted in system settings → return | Real system UI |
| 12 | Lock-screen content, setting on and off | Real lock screen |
| 13 | Midnight rollover with the app open | Automated with a fake clock; the real-device pass confirms the trigger |
| 14 | Completed task lingering "feels like progress" | A judgement, not an assertion |
| 15 | Screen-reader pass over a task row | Semantics are asserted; how they *read* is not |
| 16 | Colour tokens in light and dark | Contrast is a review item per the a11y contract |

These land in `docs/testing/manual-test-plans/` as their slices arrive.

**Rule:** a PR states which manual steps were walked **and which were not, and
why**. "Not run" is an acceptable answer; a silent omission is not.

---

## 6. Accessibility testing

Against `docs/architecture/contracts/07-accessibility.md`, whose minimum scope
is deliberately small: one text-scale test per main screen, one semantics test
for the most important list, one non-gesture-alternative test per swipe.

3.1.0 makes two of the contract's rules non-trivial for the first time:

- **Rule 10 (swipe alternatives)** — the template has never had a swipe
  action. Now it does, so the rule is genuinely exercised rather than
  vacuously satisfied.
- **Rule 11 (dynamic content announced as text)** — currently marked partial
  "no example in the template". Group headers with counts ("Überfällig, 2
  Aufgaben") become the example.

Text-scale tests at `TextScaler.linear(2.0)`, on a **phone-sized** surface,
for: the task row, the task detail, the list overview, Heute, search, the
reminder section, the recurrence editor and the import review. Overflow throws
in the test build, which is the assertion.

The recurrence editor is the densest surface in the app and is where overflow
will appear first. Its seven weekday toggles are the tightest 48 dp targets
anywhere in the plan.

---

## 7. What is deliberately not tested

Stated so the gaps are decisions rather than oversights.

| Not tested | Why |
|---|---|
| The Kotlin channel, automatically | Would need instrumentation tests and a device in CI. ADR-0013 accepts the manual entries instead, and everything downstream of the channel is pure Dart and fully covered |
| Real notification delivery | Same |
| The generated `AndroidManifest.xml`, in CI | There is no committed `android/`; the check runs after a bootstrap on a developer machine |
| The search latency budget, as a gate | A CI machine is not a mid-range phone. AC-25 **measures and records**; a regression is visible without being flaky-blocking (spec 0002, Q-2o) |
| The full fuzz corpus on every run | A seeded subset per run, the full 10 000 nightly (spec 0004, Q-4p) |
| Web beyond "it builds and does not crash" | Notifications and share intents do not exist there; the app degrades and says so |

---

## 8. Commands

```bash
scripts/dev/quality_gate.sh          # format + analyze + test, compact
bash scripts/dev/test_summary.sh     # compact pass/fail summary
melos run test:dart                  # pure-Dart workspace packages (task_interchange now lives in flutter-libraries)
melos run test:flutter               # app + design_system, with coverage
melos run codegen                    # must produce NO diff
bash scripts/validate_openspec.sh
./scripts/validate.sh                # full
scripts/deps/audit.sh                # when a dependency changes
```

`melos run codegen` producing no diff is a real gate: generated output is
committed, and CI fails on drift. `gen-l10n` is the half that gets forgotten —
it is part of the same script for exactly that reason.

---

## 9. Per-slice test obligations

| Slice | Must be green before merge |
|---|---|
| 0 | Converter round trips incl. DST; `Uuid4` property test; URL allowlist rejections; share seam fake; undo snackbar; Markdown view + editor widget tests; `design_system` imports no app l10n |
| 1 | CT-2..CT-7, CT-9, CT-10, CT-13..CT-15; `ruleMatrix`; no Flutter import in `lib/`; runs under `dart test` |
| 2 | Invariants; ordering determinism; KI-003 guard; migration fixtures v1→v2 incl. partial and downgrade |
| 3 | Screen tests; swipe alternatives; undo; a11y at 200 % |
| 4 | Detail tests; Markdown wiring; date-order rejection; link scheme rejection |
| 5 | Full `viewMatrix` against **both** predicates and SQL; determinism; `EXPLAIN QUERY PLAN` uses an index; N+1 probe |
| 6 | Spike result recorded; reconciliation convergence (3 states, zero calls when converged); DST property test; queue idempotency; no domain write in the background path |
| 7 | `ruleMatrix` incl. rejections and calendar correctness; completion-mode arithmetic; bounded expansion |
| 8 | Import totality; `uid`-twice; crafted-document invariants; cap enforced while reading; generated manifest correct from **both** bootstrap paths |
| 9 | No app-local field emitted; determinism; preview unskippable; cache cleaned |
| 10 | Search matching and filters; trash lifecycle; purge idempotency |
| 11 | Onboarding at 200 %; settings register keys unique |
| 12 | Full CT suite named and green; fuzz; checksum; end-to-end |
| 13 | v4→v5 fixture proving `tasks` untouched; no dangling reference to `features/todos`; initializer replace path exercised |
