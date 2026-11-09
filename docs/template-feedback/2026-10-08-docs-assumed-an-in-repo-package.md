# ADR, plan, specs and the test strategy assumed `packages/task_interchange` in this repository

- **Date:** 2026-10-08
- **Area:** Docs
- **Severity:** `friction`
- **Template version:** 3.2.1 (commit f613988 plus uncommitted work)
- **Status:** resolved in ADR-0017

## Observed

ADR-0014, ADR-0011, plans 0001/0000, specs 0001/0003/0004 and the test strategy name `packages/task_interchange/...` and vendored fixtures with a `PROVENANCE.md` in about 40 places. The extraction to `flutter-libraries` (Packzeit ADR-0016) made them wrong without any of them being flagged.

## Workaround

ADR-0017, ADR-0014 marked superseded in part, plan slice 1 rewritten, a "Package location" banner on every spec 0004 file, targeted rewording elsewhere. Plan 0000 and the readiness review keep their historical wording on purpose.

## Smallest generic change

When code moves to a shared library, the extraction ADR (Packzeit ADR-0016, `flutter-libraries` ADR-0001) should list the template documents that name the old path, so the template can be updated in the same step.

## Check that would catch a recurrence

A docs check that fails on a path under `packages/` that does not exist.
