# Shell tests assert the template's own web slug, so "the shell's tests still pass" cannot hold after initialization

- **Date:** 2026-08-27
- **Area:** Initialization
- **Severity:** `friction`
- **Template version:** 3.2.1
- **Status:** documented in 3.2.1; the tests are a follow-up

## Observed

The verification step says the shell survived when `/settings`, `/intro`,
`/help/*`, `/privacy`, `/pro` and `/about` resolve **and the shell's own tests
still pass**. They cannot. Three of them assert the literal `todo-app`:

| Test | Assertion |
|---|---|
| `test/features/about/about_page_test.dart:64` | `https://lumbrecode.de/apps/todo-app/privacy/` |
| `test/features/about/about_page_test.dart:121,137` | `subject=[app:todo-app] Bug report` / `Feedback` |
| `test/features/splash/startup_error_page_test.dart:106` | `[app:todo-app] Startup failure: database` |

The same table mandates rewriting `AppIdentity.webSlug`, which is what those
strings are derived from. Doing the initialization correctly is what makes
them fail.

## Root cause

The tests pin the value rather than the derivation. They were written when the
template *was* the todo app and `todo-app` was simply true.

The failure is loud and the fix is obvious, which is exactly why it is
dangerous: an agent under instruction to make the gate green has three failing
shell tests and a rule that says shell tests must pass. Deleting them is the
shortest path, and a deleted test is how a deleted feature goes unnoticed.

## Change made

The verification step now says what to expect: after the `webSlug` rewrite
these three assertions fail, they are **adapted to the new slug, never
deleted**, and no other shell test should be red.

## What would catch a recurrence

Having the tests derive their expectation from `AppIdentity` — assert that the
mail subject carries `AppIdentity.webSlug`, not that it carries `todo-app`.
Then a rewrite changes both sides at once and the test keeps testing what it
was written to test: that the link is built from the identity.
