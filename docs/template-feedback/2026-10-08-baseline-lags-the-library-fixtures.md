# The template's baseline (1.5.2) is older than the fixtures the library tests against (1.6.0)

- **Date:** 2026-10-08
- **Area:** Baseline / tests
- **Severity:** `friction`
- **Template version:** 3.2.1 (commit f613988 plus uncommitted work)
- **Status:** resolved 2026-10-09 (baseline 1.6.0 adopted; the summary comparison is now real, see `apps/mobile_app/test/interop/packing_list_contract_test.dart`)

## Observed

The library's `fixtures_test.dart` asserts 28 task and 31 exchange fixtures and reads `expected/*.summary.json`. The template's `.lumbrecode/` is baseline 1.5.2: 23 task fixtures (no packing-list fixtures 52 to 54, 97), 21 exchange fixtures, **no `expected/` directory**. The library's suite would fail here; it is not run here.

## Workaround

The contract test iterates by directory, asserts no counts, requires a documented decode outcome for every `9x-invalid-` fixture (a new one fails loudly), and compares summaries only when `expected/` exists. `.lumbrecode/` was not touched.

## Smallest generic change

Library: state the minimum baseline in `docs/consuming.md` and in `libraries.json`. Template: adopt baseline 1.6.0 (separate change); the summary comparison then switches on by itself.

## Check that would catch a recurrence

A "family -> minimum baseline" entry in the library, checked by the consumer's contract test (fail with a clear message when the baseline is older).
