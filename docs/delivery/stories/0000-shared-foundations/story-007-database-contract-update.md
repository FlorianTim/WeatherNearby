# Story: Database contract status update and the worked migration example

## Metadata

- **Status:** ready
- **Feature:** none — template surface. Plan:
  `docs/delivery/implementation-plans/0000-shared-foundations.md`, component 8
- **Target release:** 3.1.0 (`now`)
- **Depends on:** story 001 (converters)

## Goal

Bring `docs/architecture/contracts/02-database.md` in line with what the
template actually provides after story 001, and record the traps the reference
app is about to walk into.

## Context

The audit found that the template is **better** on database hardening than the
planning draft assumed: `PRAGMA foreign_keys = ON`, the downgrade guard,
`addColumnIfMissing`, transactional `wipeAllData()`, `DriftWebOptions` and a
migration fixture test all exist already.

What is missing is not the conventions but their **exercise** — and one
concrete gap: contract rule 6 (date/time semantics) is marked partial, with
the note that the converters "werden erst mit der ersten datumslastigen App
vorgelegt". Story 001 delivers them.

This story is documentation only. It exists as its own story because
documentation that trails a code change by a slice is documentation nobody
writes.

## Scope

- Update the "Stand im Template" table in
  `docs/architecture/contracts/02-database.md`: rule 6 moves from partial to
  done, pointing at `core/domain/time/`.
- Add a short worked example of the fixture-per-version discipline, using the
  upcoming v1 → v2 step as the illustration.
- Add a forward-looking note on the `@ReferenceName` trap (KI-004).

## Out of scope

- Any code. This is a documentation story.
- Changing a contract **rule**. The rules stand; only the status table and the
  explanatory material change.
- Writing the v1 → v2 migration itself. Spec 0001's slice 2 owns it.

## Relevant files

- `docs/architecture/contracts/02-database.md`
- `apps/mobile_app/lib/core/domain/time/` (story 001)
- `apps/mobile_app/test/core/database/migration_test.dart` — the existing
  example
- `docs/known-issues.md` KI-003, KI-004, KI-008

## Acceptance criteria

- [ ] Rule 6's status changes from partial to done and names
      `core/domain/time/` as the location.
- [ ] The `AllDayInterval` half of rule 6 is stated as **still open**, with
      the reason: nothing in 3.1.0 forces it, and speculative helpers are how
      `core/` acquires unused surface. The status must not claim more than
      story 001 delivered.
- [ ] A worked example shows the fixture-per-version discipline concretely: a
      raw-SQL snapshot of the predecessor with seeded rows, opened at the new
      version, asserting rows survive and `user_version` is correct.
- [ ] The example states that a fixture written through the **current** schema
      classes proves nothing about the old schema, and must therefore be raw
      SQL.
- [ ] A note records the `@ReferenceName` trap as forward-looking: it does not
      bite today because `tasks.list_id` and `tasks.parent_task_id` reference
      different tables, and it will the moment a second edge to the same table
      appears — and **the build still succeeds** while silently omitting the
      generated filters.
- [ ] The file stays German, matching its existing language.
- [ ] No rule is added, removed or reworded.

## Test requirements

None — documentation only. Verification is review against the file's own
"Stand im Template" table and against `core/domain/time/` as it actually
exists after story 001.

Commands: `scripts/dev/quality_gate.sh` (nothing should change), and a link
check that every path named in the file exists.

## Documentation requirements

This story **is** the documentation requirement. AGENTS.md: "Update docs when
behavior, architecture, or developer workflow changes."

## Implementation notes

- The file is German. AGENTS.md permits architecture docs to be German when
  that matches the existing file — keep it German, and do not translate the
  surrounding material while editing.
- Be accurate about status. A contract whose status table overstates what
  exists is worse than one that admits a gap: the next reader trusts it and
  skips the check.
- Keep the worked example short. The contract is a rulebook, not a tutorial;
  the full migration matrix already lives in spec 0001's `data-contract.md`
  and should be linked rather than duplicated.

## Review checklist

- [ ] Scope maintained — no rule changed, no code touched
- [ ] Status claims match what story 001 actually delivered
- [ ] `AllDayInterval` still recorded as open
- [ ] German preserved
- [ ] Every path named in the file exists
