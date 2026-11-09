# Story — UI test profile tuning

Status: implemented. User approval 2026-10-06. References: spec 0009, plan 0003.
Acceptance: explicit/restored logical size, DPR and text factor; finite shell
interaction tests with scrolling; tall content-order inspections labelled;
normal-text screenshots; contract 07 remains intact. No app/runtime change.
Required checks: settings, privacy and a11y tests; analysis; full suite attempted.

## Validation — 2026-10-06

Flutter 3.47.5 / Dart 3.13.4. Final full suite: 274 tests passed.
Direct Dart analysis of edited tests/helpers/integration carrier: no issues.
Settings/privacy callbacks and confirmations pass on finite phone surfaces;
onboarding retains its existing focused phone 2x checks. Full-tree inspections
are labelled separately. No production code, dependency or reference-app scope
change; no publication or push. Screenshot profile sizes are unchanged.
