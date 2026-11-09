# Implementation Plan: The To-do reference app

## Metadata

- **Status:** draft
- **Feature specs:** `docs/product/specs/0001-task-and-list-domain/`,
  `0002-views-search-and-navigation/`, `0003-reminders-and-recurrence/`,
  `0004-jscalendar-interoperability/`
- **App spec:** `openspec/apps/todo.openspec.yaml` (`replace_todo_app: true`)
- **Target release:** 3.1.0 (`now`)
- **Created:** 2026-08-25
- **Decisions:** ADR-0011, ADR-0012, ADR-0013, ADR-0014 (in part), ADR-0017
- **Companion plan:** `0000-shared-foundations.md` (slice 0)
- **Audit:** `docs/delivery/reviews/2026-08-25-template-readiness-todo-reference-app.md`

## Scope

Deliverable G: the slice sequence that turns template 3.0.0's Todo demo into
the To-do reference application, covering all four feature specs.

Fourteen slices, each shippable and reviewable on its own. Slice 0 is the
shared foundations (its own plan). Slice 1 is consuming `task_interchange` from
`flutter-libraries` (ADR-0017), with no UI. Slice 13 retires the demo.

> **An implementation plan is not an implementation order for code.** Code is
> changed only from an approved story (AGENTS.md). This plan is the basis for
> story decomposition, and every slice below decomposes into stories under
> `docs/delivery/stories/`.

## Non-scope

- Everything in the four specs' `out-of-scope.md` files.
- The 3.2+ candidates from draft §14.1: the in-app manual, feedback-by-mail,
  backup/restore, privacy field classes, archive-before-delete.
- Publishing the app. Undecided, and nothing in the design depends on it
  (ADR-0011, decision 6).

## Relevant docs

- Specs 0001–0004 and their `release-plan.md` files, which own the per-spec
  phase detail
- ADR-0011 (why), ADR-0012 (notifications), ADR-0013 (receive boundary),
  ADR-0014 (interchange package, superseded in part), ADR-0017 (the template
  depends on `flutter-libraries`)
- `docs/architecture/contracts/` — all seven contracts apply
- `docs/known-issues.md` — KI-001, KI-003, KI-004, KI-005, KI-008, KI-009
- `docs/testing/todo-reference-app-test-strategy.md`

---

## Proposed technical approach

### The two rules that shape every slice

1. **The template stays a template.** Anything not specifically about to-do
   lists lands in `packages/` or `core/` **in the slice that introduces it**.
   Never "later" (ADR-0011, decision 4; `0000-shared-foundations.md`).

2. **The demo is replaced, not deleted in passing.** `features/todos/` keeps
   working — routed, tested, l10n-keyed — until slice 13. Slices 0–12 build
   beside it. This is what makes the change reversible at any point before the
   last slice.

### Architecture target

```text
apps/mobile_app/lib/
  core/
    database/          Drift schema, migrations, converters registered
    domain/time/       epoch-day + minute-of-day            [slice 0]
    notifications/     gateway, fake, pending-action queue   [slice 6]
    permissions/       + the first concrete gateway          [slice 6]
    platform/          + allowlisted URL seam, document share seam [slice 0]
  features/
    tasks/             domain / data / application / presentation
    lists/
    views/             Heute, Demnächst, Alle, Erledigt, Suche
    tags/
    reminders/
    recurrence/
    interop/           import review, export, the platform channel
    settings/
    onboarding/
packages/
  design_system/       + Markdown view/editor, undo snackbar [slice 0]
  app_core/            + Uuid4                               [slice 0]
```

Rules carried over from WasThereSomething because they earned their place:

- **No hand-written SQL** for domain access. Drift typed queries, reactive
  `watch*` streams feeding Riverpod.
- **Foreign keys enforced** on every connection — already true here.
- **Every multi-table write in a transaction.**
- **Injectable seams** for sharing, URL launching and notifications, so widget
  tests never touch the platform.
- **Additive migrations only**, with a fixture test per schema version.

**Do not port from WasThereSomething:** occurrences, the occurrence engine,
calendar projection, contacts, the reminder reconciliation service, the
`[WTS2:…]` ownership marker, `show_in_calendar`. None of it applies, and
importing the concepts would make this app harder to understand for no gain.

---

## The slices

| # | Slice | Delivers | Spec | Schema |
|---|---|---|---|---|
| 0 | **Shared foundations** | Converters, `Uuid4`, allowlisted URL seam, document share seam, undo snackbar, Markdown view + editor, database-contract docs. **No user-visible change.** | — | — |
| 1 | **Consume `flutter-libraries`** | `task_interchange` as one tag-pinned `git:` dependency of `apps/mobile_app` (`interchange-v0.1.0`; `jscalendar` and `ijson` ride along), CI access to the private repository, and the contract test over the golden fixtures in `.lumbrecode/schemas/`. The code is **not** built or copied here (ADR-0017 supersedes ADR-0014 in part). **No UI, no database.** | 0004 | — |
| 2 | **Data layer** | `lists`, `tags`, `tasks`, `task_tags`, `task_links`; repositories; tree safety; ordering; migration fixture test. **No UI.** | 0001 | v1→v2 |
| 3 | **Lists and tasks** | Navigation shell, Inbox seeding, list + task CRUD, checkbox, reorder, swipe actions with menu equivalents, undo | 0001, 0002 | — |
| 4 | **Task detail** | Markdown notes, dates, priority, subtasks, tags, links, the five-value progress picker | 0001 | — |
| 5 | **Views** | `TaskQuery`, membership predicates, Heute, Demnächst, Alle, Erledigt, sort, group, completed-task visibility, indexes | 0002 | index |
| 6 | **Reminders** | Spike first. Notification gateway + fake, first concrete permission gateway, `reminders`, scheduling, reconciliation, two actions, pending-action queue | 0003 | v2→v3 |
| 7 | **Recurrence** | `task_recurrence_overrides`, instance handling, completion mode, the recurrence editor with preview | 0003 | v3→v4 |
| 8 | **Import** | **Packing-list obligations (AC-67..70, CT-16 database half).** Platform channel, bootstrap manifest patcher, byte cap, envelope + batch unwrapping, import review route, one-transaction write, report | 0004 | — |
| 9 | **Export / share** | Document building, unskippable preview, `ShareDocument` wiring, cache cleanup, receiver query | 0004 | — |
| 10 | **Search, trash, archive** | Search over titles and notes with filters; soft delete, trash screen, restore, 30-day purge; list archive | 0001, 0002 | — |
| 11 | **Onboarding, settings, about** | At most three onboarding screens, the settings additions, about and licenses | 0001–0003 | — |
| 12 | **Contract tests** | CT-1..CT-15 as one suite, fuzz corpus, checksum test, end-to-end assertion | 0004 | — |
| 13 | **Retire the demo** | Remove `features/todos/`, its routes, providers, tests, table and l10n keys; update OpenSpec, README, AGENTS.md and the initializer docs | — | v4→v5 |

### Why this order

**Slice 0 first** because the shared pieces are what make this a template
change rather than an app. If they come later, they never come.

**Slice 1 second, with no UI**, because it is the piece that must be exactly
right. The code is reviewed and tested in `flutter-libraries`; this slice proves
the consumption (resolution, CI access, the contract test over the golden
fixtures) and is the first test of that dependency from a consumer. It is also independent of slice 2 — the two can run in parallel.

**Slice 2 has no UI either.** The invariants (tree safety, ordering,
transactions, the migration chain) are the valuable part and are reviewable
without a screen.

**Slice 6 opens with a spike.** ADR-0012's background-isolate design is the
biggest unknown in 3.1.0. Proving append-and-drain on a real device costs a
day; discovering it does not work after the reminder UI exists costs the
slice.

**Slice 13 is last.** The demo keeps working until its replacement does
everything it did. This is also what keeps every earlier slice independently
revertible.

### Dependency graph

```text
0 ──┬─► 2 ──► 3 ──┬─► 4 ──► 6 ──► 7
    │             ├─► 5 ──────────┐
    │             └─► 10          │
    │                             │
    └─► 1 ─────────► 8 ──► 9 ──► 12
                     ▲
                     └── needs 2 (persistence) and 3 (routes)

11 ──► after 6 (settings for notifications)
13 ──► after everything
```

Parallelizable: {1} with {2}; {5} with {6}; {9} with {10}.

---

## Data / Model changes

Full schema in spec 0001 `data-contract.md`. Migration chain:

| `schemaVersion` | Slice | Change | Destructive? |
|---|---|---|---|
| 1 | (current) | `todo_items` — the demo | — |
| 2 | 2 | `lists`, `tags`, `tasks`, `task_tags`, `task_links` + indexes | no |
| 3 | 6 | `reminders` + index | no |
| 4 | 7 | `task_recurrence_overrides` + unique index | no |
| 5 | 13 | **drop `todo_items`** | **yes** |

Every step is `createTable` / `createIndex` / `addColumn` with a default.
Nothing rebuilds a table — and if a `TableMigration` rebuild ever becomes
necessary, database-contract rule 2 applies: every column added by a later
migration must appear in `newColumns`, or upgrading an old database crashes.

**The v4 → v5 drop is the only destructive step in 3.1.0**, and it is the one
ADR-0011 exists to authorize. Database-contract rule 2 requires an ADR for
anything destructive; ADR-0011 is it.

**No data migration from the demo.** `todo_items` rows are not carried into
`tasks`: nobody has data there, and the status vocabularies do not correspond
(`pending` is not `needs-action`). Writing a mapping would encode a wrong
equivalence in a file that reads as authoritative. Spec 0001
`data-contract.md` §4.2 records this in full.

## API changes

None. `backend_enabled: false`, and it stays that way. No entry in
`docs/api/openapi.yaml`.

## UI changes

| Slice | Screens |
|---|---|
| 3 | Navigation shell (Heute/Listen/Suche/Mehr), Listenübersicht, Listendetail, not-found |
| 4 | Aufgabendetail |
| 5 | Heute, Demnächst, Alle, Erledigt |
| 6 | Reminder section, permission rationale usage |
| 7 | Recurrence editor with live preview |
| 8 | Import review (a **route**), import error, import report |
| 9 | Share preview |
| 10 | Suche, Papierkorb, Archiv |
| 11 | Onboarding (≤ 3 screens), settings additions, Tags |
| 13 | Landing screen switches from the demo path permanently |

Slices 0, 1, 2 and 12 add **no screen at all**, deliberately.

## Tests and validation

Full strategy: `docs/testing/todo-reference-app-test-strategy.md`.

- **Unit / property:** the codec, the recurrence parser and expander, the view
  membership predicates, the converters, `Uuid4`, the warning taxonomy.
- **Repository (Drift, in-memory):** invariants, ordering determinism,
  migration fixtures, reconciliation, the pending-action drain.
- **Widget:** every screen at `TextScaler.linear(2.0)`; swipe alternatives;
  seams faked throughout.
- **Integration:** import totality, `uid`-twice, notification back stack, the
  end-to-end contract assertion.
- **Contract:** CT-1..CT-15 against the vendored golden fixtures — the same
  fixtures WasThereSomething tests against.
- **Manual:** the Kotlin channel, real notification delivery, reboot,
  time-zone change, share-sheet narrowness. Enumerated per spec.

**Commands:** `scripts/dev/quality_gate.sh`, `bash scripts/dev/test_summary.sh`,
`melos run codegen` (must produce no diff), `./scripts/validate.sh`,
`bash scripts/validate_openspec.sh`, `scripts/deps/audit.sh` when a dependency
changes.

## Risks

| Risk | Slice | Mitigation |
|---|---|---|
| The background-isolate design does not survive a real device | 6 | The spike, before any story. Biggest unknown in 3.1.0. |
| The manifest patch exists only in bash and silently no-ops on Windows | 8 | Both paths are a validation item; the check reads the **generated** manifest |
| Shared components end up in `features/tasks/` "for now" | 0, 4 | Target paths fixed before any code; story review checklist |
| KI-001 moves when a dependency is added | 0, 6, 8 | Every new dependency is runtime-only and resolved against the tree **before** adoption |
| `timezone` conflicts transitively (KI-009a) | 6 | Nothing else depends on it today; record the constraint when added |
| Non-deterministic ordering ships and reads as "random reshuffles" | 2, 5 | Every ordering spells out its tiebreak; the determinism test is written first |
| Stale UI after a tag or parent edit (KI-003) | 5 | Regression guard written with the first composed stream |
| Vendored fixtures drift from the contract repo | 1, 12 | `PROVENANCE.md` + checksum test; "change both repos in one change" |
| The `upsert` ambiguity is resolved differently elsewhere | 8 | INT-141..143 states the position and its reasoning; Q-4d raises it with the contract owner |
| Slice 13 breaks the initializer's replace path | 13 | The path is exercised as part of the slice, not assumed |
| The reference app becomes a product and the template drifts | all | ADR-0011's scope; the "would a vacation planner want this?" test per component |
| 3.1.0 grows too large to land | all | Fourteen independently shippable slices; the demo works throughout, so stopping after any slice leaves a coherent template |

## Rollout / Migration notes

- **No feature flags.** Each slice becomes reachable as it lands.
- **The demo works throughout slices 0–12.** Its tests stay in the suite and
  are part of every slice's done criteria.
- **The landing screen moves twice**: today the router goes to
  `AppRoutes.settings` after startup; slice 3 points it at Heute. One line,
  called out because the startup and splash tests assert the destination.
- **Slice 8 changes the installed app's system surface** — it becomes a share
  target for `application/jscalendar+json`. Reviewers check the generated
  manifest.
- **Version bump to 3.1.0** happens once, at the end: `VERSION`,
  `apps/mobile_app/pubspec.yaml` (kept in sync, checked by `validate.sh`), and
  `CHANGELOG.md`.
- **KI-006:** agents cannot commit — commit signing is interactive. Every
  slice ends with a staged change and a prepared commit message for the human.

## Definition of done, per slice

Every slice, without exception:

1. Every `Must` requirement it covers has a passing test at the level the
   spec's `acceptance-criteria.md` names.
2. `scripts/dev/quality_gate.sh` green: format, analyze, test.
3. `melos run codegen` produces no diff — generated output is committed and CI
   fails on drift.
4. The migration fixture test for any schema step passes, chained cases
   included.
5. Accessibility: any new screen passes at `TextScaler.linear(2.0)`; every
   swipe has a visible alternative; icon-only controls carry semantic labels.
6. German and English for every new user-visible string.
7. **The demo still builds, still routes and its tests still pass** (slices
   0–12).
8. No test weakened, skipped or deleted to make a suite pass.
9. Manual steps walked where the spec names them, with results recorded in the
   PR — **including anything that could not be run**.
10. The PR references its story, spec and acceptance criteria.

## Plan change 2026-10-09 — packing lists from Packzeit

**Question:** can the reference app import a Packzeit packing list now?
**Answer: no.** The import is slice 8, which needs slice 2 (persistence) and
slice 3 (routes). Today only step 2.1b exists: `task_interchange` as a
dependency and a contract test. There is no `tasks` table, no tree storage, no
keyword or `percentComplete` storage and no import review route. Building the
import out of order would break "slices 0-12 build beside the demo".

**What changed instead (documents and tests only, no feature code):**

- Baseline 1.5.2 -> 1.6.0 (fixtures `52`-`54`, `97`, `expected/*.summary.json`).
- Spec 0004: INT-606..609, AC-67..70, data contract §3.6 and the CT-16 row.
- Test strategy: CT-16 added to the matrix.
- `test/interop/packing_list_contract_test.dart`: the decoder half of CT-16
  over every `5x` fixture found by directory, the packing conventions, and
  whole-file rejection. Four **skipped** tests carry the database half.

**Slice 8 inherits:** AC-67..70, the four skipped tests, and one open design
question (do `to-buy`, `last-minute` and category slugs become user tags?).
No story is drafted: stories are drafted as their slice approaches (see
"Story breakdown").

## Story breakdown

Stories live in `docs/delivery/stories/<NNNN-name>/story-NNN-<slug>.md`.

| Slice | Story folder | Stories | Status |
|---|---|---|---|
| 0 | `0000-shared-foundations/` | 7 — see `0000-shared-foundations.md` | drafted |
| 1 | `0004-jscalendar-interoperability/` | models; codec + validation; warnings; recurrence parser + expander; fixtures + provenance | to draft |
| 2 | `0001-task-and-list-domain/` | tables + converters; repositories + invariants; ordering; migration fixtures | to draft |
| 3 | `0001-task-and-list-domain/` | navigation shell; list CRUD; task CRUD; reorder; swipe + undo | to draft |
| 4 | `0001-task-and-list-domain/` | detail scaffold; notes; dates; priority + progress; subtasks; tags; links | to draft |
| 5 | `0002-views-search-and-navigation/` | `TaskQuery` + predicates; Heute; Demnächst; Alle/Erledigt; sort + group | to draft |
| 6 | `0003-reminders-and-recurrence/` | **spike**; gateway + fake; permission gateway; table + editor; reconciliation; actions + queue | to draft |
| 7 | `0003-reminders-and-recurrence/` | overrides table; instance handling; completion mode; editor + preview | to draft |
| 8 | `0004-jscalendar-interoperability/` | platform channel; manifest patcher; reader + cap; review route; transactional write | to draft |
| 9 | `0004-jscalendar-interoperability/` | document building; preview; share wiring; cache cleanup | to draft |
| 10 | `0002-…/` + `0001-…/` | search; trash; archive; purge | to draft |
| 11 | `0001-task-and-list-domain/` | onboarding; settings; about | to draft |
| 12 | `0004-jscalendar-interoperability/` | contract suite; fuzz; checksum; end-to-end | to draft |
| 13 | `0000-retire-demo/` | remove feature; drop table; docs sweep; OpenSpec + AGENTS.md | to draft |

Only slice 0's stories are drafted in this pass. The rest are drafted as their
slice approaches, so they reflect what the previous slice actually produced
rather than what it was expected to produce.
