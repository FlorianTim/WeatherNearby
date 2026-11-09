# ADR-0011: The example app becomes a reference application, not a smoke test

## Status

proposed

## Date

2026-08-25

## Decision owners

- Product Owner (F. Kroschewski)
- Template architecture

## Related feature / spec

- `openspec/apps/todo.openspec.yaml` (`replace_todo_app: true`)
- `docs/product/specs/0001-task-and-list-domain/` .. `0004-jscalendar-interoperability/`
- `docs/delivery/implementation-plans/0000-shared-foundations.md`
- `docs/delivery/implementation-plans/0001-todo-reference-app.md`
- Planning input: `drafts/notes/3.1.0/lumbrecode_todo_app_notes.md`
  (non-normative under ADR-0005, explicitly authorized for this pass)

## Related issues / PRs

- none yet

## Context

The template ships a Todo demo under `apps/mobile_app/lib/features/todos/`.
AGENTS.md protects it with a preservation rule so that general maintenance,
audits and dry-runs cannot delete it. That rule has done its job.

What the demo is, concretely: one flat Drift table with six columns, a
repository, a notifier, a list page and a create dialog. It answers exactly
one question — *does the wiring work?* — and it answers it well.

The problem is the question it cannot answer. The template's stated purpose
is to be the starting point for every LumbreCode app, which means it has to
absorb a Flutter release, a Drift major, a Riverpod change or a new standard
*before* a productive app inherits the damage. A demo with one table and no
foreign key, no transaction, no type converter, no chained migration, no
permission, no notification, no platform boundary and no external data
contract cannot break in any of the ways that matter. Something that cannot
break cannot warn anybody.

The audit
(`docs/delivery/reviews/2026-08-25-template-readiness-todo-reference-app.md`)
makes the same point from the other side: the template documents excellent
conventions — the database contract, the permissions contract, the
accessibility contract, the library-evaluation contract — and exercises
almost none of them. `core/permissions/` has no concrete gateway.
`packages/design_system` has three files. The database contract's rule 6
(date/time semantics) is marked partial "until the first date-heavy app".

At the same time a real need exists: a local-first to-do app that speaks the
LumbreCode task format natively. The format is already decided, schema'd and
tested in `lumbrecode-engineering` with 45 golden fixtures across two
contracts, and WasThereSomething 1.5 implements the sending half. Building
this app inside the template turns two separate pieces of work into one.

Four questions had to be answered.

1. Does the example app stay a smoke test, or become a reference app?
2. If it becomes one, is the demo replaced or kept alongside?
3. What stops a richer app from turning the template into a product?
4. What stops the next maintainer from simplifying it back?

## Decision

1. **The example app becomes the template's reference application and
   proving ground.** Its job is no longer "prove the wiring"; it is
   "survive contact with something real, so upgrades break here first".

2. **The demo is replaced, not kept alongside.** Two example apps would mean
   two answers to every "how do I do X here" question, and the smaller one
   would keep winning because it is easier to read. The replacement goes
   through the documented path: an OpenSpec entry
   (`openspec/apps/todo.openspec.yaml`) with `replace_todo_app: true`, which
   is the mechanism `openspec/README.md` already defines for exactly this.

3. **Retiring the demo is the last slice, not the first.**
   `features/todos/` keeps working until its replacement does everything it
   did. Slice 13 of the implementation plan removes it; slices 0 to 12 build
   the replacement beside it.

4. **Anything the app needs that is not specifically about to-do lists lands
   in `packages/` or `core/`, in the slice that introduces it.** Not "later".
   The extraction list is
   `docs/delivery/implementation-plans/0000-shared-foundations.md`, and the
   test for membership is: *would a vacation planner want this too?* If yes,
   it is template surface. If it only makes sense for tasks, it stays in
   `features/tasks/`.

5. **AGENTS.md's preservation rule is amended, not ignored.** It now protects
   the new reference app *and states what it is for*, so that "this example
   is more complicated than it needs to be" is answered in the rule itself.

6. **Whether the app is ever published is left open** and nothing in the
   design depends on it. If it ships, it ships as a normal LumbreCode app.
   If it does not, it has already paid for itself as the place where
   upgrades break first.

## Alternatives considered

| Alternative | Pro | Contra |
|---|---|---|
| **Keep the demo, build the To-do app in its own repository** | Template stays minimal; no risk of product creep | The template keeps proving nothing. Every shared component the app needs (Markdown editor, seams, notification boundary, interchange package) would be built outside the template and then have to be back-ported, which is the same work done twice and usually not done at all. The upgrade-canary need stays unmet. |
| **Keep both: demo *and* reference app** | Nothing is lost; gentle migration | Two answers to every structural question, and readers follow the simpler one. The demo would rot: nobody updates the app they are not using. Doubles the surface slice 13 has to keep consistent. |
| **Grow the existing demo in place** | No deletion, no OpenSpec entry, smallest diff | `features/todos/` is named, routed, tested and l10n-keyed as a demo, and its `TodoStatus {pending, inProgress, completed}` enum is *close enough to be dangerous* — `pending` is not `needs-action`, and `failed`/`cancelled` are missing. Growing it would preserve exactly the wrong parts. A clean feature with a correct vocabulary is cheaper than a rename plus a data migration plus a vocabulary correction. |
| **Make the reference app something other than a to-do app** (e.g. a notes app) | Free choice of surface | A to-do app is the one whose data contract already exists, is schema-validated and has 45 golden fixtures and a second implementation to test against. Any other domain would need that contract invented first — which is the expensive half. |

## Consequences

### Positive

- The template gains a body of code that exercises its own contracts:
  foreign keys, multi-table transactions, type converters, chained
  migrations, a real permission flow, an Android platform boundary, an
  external data contract, swipe actions with accessible alternatives.
- Upgrades break here first. That is the entire point.
- `packages/design_system` and `core/` grow the components every derived app
  wants, driven by a real consumer rather than by speculation.
- `task_interchange` becomes a dependency of the template (ADR-0017, from
  `flutter-libraries`; ADR-0014 planned it as `packages/task_interchange`), so
  any future LumbreCode app can read and write the task format without
  re-deriving it.
- Interoperability becomes a test result rather than a claim: the same
  golden fixtures are the test inputs on both sides.

### Negative

- The example app stops being readable in one sitting. A newcomer looking for
  "the smallest example of a Drift table" now has more to wade through. The
  mitigation is documentation, not simplification: the pattern catalogue in
  `docs/architecture/patterns/` stays the entry point for "how do I do X".
- More template surface means more to keep green. Every Flutter/Drift/Riverpod
  upgrade now has a bigger blast radius inside the template itself — which is
  the intended trade, but it is a real cost in maintenance time.
- More dependencies (Markdown rendering, local notifications, timezone,
  path_provider, mime, a permission plugin). Each is justified individually
  in the shared-foundations plan and in ADR-0012/0013/0014; each has a
  removal path; but the baseline dependency count of every derived app goes
  up.
- The template initializer's "replace the example app" path becomes a bigger
  operation, because there is more to remove. Slice 13 must leave it working.

## Test and validation impact

- The reference app carries the template's first **contract test suite**
  (CT-1..CT-15 from the interop guide 12), run against vendored golden
  fixtures. See `docs/testing/todo-reference-app-test-strategy.md`.
- The migration fixture test grows from one schema version to a chain, which
  is the first real exercise of database-contract rule 3.
- Accessibility rule 10 ("every swipe gesture has an alternative") becomes a
  real obligation for the first time, because the template acquires its first
  swipe action.
- CI runtime grows. The plan keeps the pure-Dart `task_interchange` tests
  separate from the Flutter suite so the expensive half can be run alone.

## Follow-up tasks

- Amend the AGENTS.md preservation rule (decision 5) — done as part of the
  3.1.0 planning pass.
- Update `README.md`, `.github/copilot-instructions.md`,
  `.github/agents/template-initializer.agent.md`,
  `openspec/README.md` and `docs/operations/template-initialization.md`
  in slice 13, when the demo is actually removed.
- Retire `openspec/apps/todoapp.openspec.yaml` in slice 13.
- Decide the product name (open question Q-01). Low urgency; `todo` is a
  consistent placeholder.

## References

- `drafts/notes/3.1.0/lumbrecode_todo_app_notes.md` sections 3, 14.1, 16
- `docs/delivery/reviews/2026-08-25-template-readiness-todo-reference-app.md`
- `openspec/README.md` — the `replace_todo_app` mechanism
- ADR-0002 (feature-first Flutter), ADR-0005 (drafts are non-normative)
- WasThereSomething ADR-0019, ADR-0020 — the sibling implementation's
  precedents for tone and depth
