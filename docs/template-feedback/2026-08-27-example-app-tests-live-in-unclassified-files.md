# Example-app tests live in files the classification never mentions

- **Date:** 2026-08-27
- **Area:** Initialization
- **Severity:** `papercut`
- **Template version:** 3.2.1
- **Status:** resolved in 3.2.1

## Observed

The table classifies test **folders** — `test/features/todos/` goes, the shell
suites stay. Three files fall outside that shape:

| File | What it is |
|---|---|
| `test/smoke_test.dart` | five shell tests (splash, settings hub, language switch) **and one greeting test** in the same file |
| `integration_test/app_flow_test.dart` | one flow, `splash -> settings -> greeting`, half shell and half example |
| `test/core/database/{migration,wipe_all_data}_test.dart` | shell tests written against the todo schema |

None is deletable and none is keepable as it stands. Each needs an edit, and
an edit is the one outcome a keep/delete table cannot express.

## Root cause

The classification assumes a file belongs entirely to the shell or entirely to
the example app. These files are mixed, because the example app was the only
app when they were written and there was nothing to separate them from.

## Change made

The three files are named explicitly with the edit each needs: drop the
greeting test from the smoke suite, re-point the integration flow at the new
app's main screen, rewrite the database tests against the new schema.

## What would catch a recurrence

Keeping mixed files out of the shell: an example-app test belongs under
`test/features/<feature>/`, and a shell test belongs in a suite whose fixtures
are the shell's own. Where that is impractical — the database tests need
*some* table — the file gets a comment saying which schema it borrows.
