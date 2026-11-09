# Plan 0003 — UI test profiles

Status: implemented, 2026-10-06. Spec 0009. Add a test-only profile/scroll helper;
apply it to settings/privacy interactions and screenshot text scaling; document
representative coverage and retain focused 2x contract checks. No product changes.
Story: ../stories/0003-ui-test-profile-tuning.md.
Validation: shell/a11y tests, static analysis, full suite attempted. Keep all
existing behavioral assertions; distinguish inspection from real scrolling.

## Validation — 2026-10-06

Flutter 3.47.5 / Dart 3.13.4. Final full suite: 274 tests passed.
Direct Dart analysis of edited tests/helpers/integration carrier: no issues.
Settings/privacy callbacks and confirmations pass on finite phone surfaces;
onboarding retains its existing focused phone 2x checks. Full-tree inspections
are labelled separately. No production code, dependency or reference-app scope
change; no publication or push. Screenshot profile sizes are unchanged.
