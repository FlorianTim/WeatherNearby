# The CT-16 summary projection lives in the library's private test support

- **Date:** 2026-10-09
- **Area:** Library / tests
- **Severity:** `friction`
- **Template version:** 3.2.1 (commit f613988 plus uncommitted work); baseline 1.5.2 -> 1.6.0
- **Status:** worked around

## Observed

Every receiving app must run CT-16 (guide 12.2): decode each accepted `Group` fixture and compare to `expected/*.summary.json`. The projection that turns decoded models and the resolved tree into the summary shape is `test/support/summary.dart` in `flutter-libraries/packages/task_interchange`, which an app cannot import. The guide says the format is language-independent, and each consumer is therefore told to re-implement it.

## Workaround

Copied the file into `apps/mobile_app/test/support/group_summary.dart` with a header naming its origin. Two copies can now drift; the copy will not notice a change to the summary format.

## Smallest generic change

Export it from `task_interchange` as a testing library (`package:task_interchange/testing.dart`, no new dependency), or document in `docs/consuming.md` that consumers copy it and which file to diff against.

## Also for `lumbrecode-engineering`

The guide (12.2) tells consumers to "import and compare" but not which layer counts as import. Say whether comparing at the decoder is enough for the template (it cannot do more before persistence exists) or whether the database result is required.

## Check that would catch a recurrence

The consumer test fails when `summaryVersion` is not 1; today the copy would silently produce the old shape.
