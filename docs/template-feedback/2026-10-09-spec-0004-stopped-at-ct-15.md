# Spec 0004 and the plan predate CT-16 and the packing-list fixtures

- **Date:** 2026-10-09
- **Area:** Specs / docs
- **Severity:** `friction`
- **Template version:** 3.2.1 (commit f613988 plus uncommitted work); baseline 1.5.2 -> 1.6.0
- **Status:** fixed

## Observed

Spec 0004 (INT-602, AC-64, data contract 6.1/6.2, release plan, test strategy) names CT-1..CT-15 and counts fixtures ("17 accepted, 45 total"). The guide has CT-16 (every accepted `Group` fixture imports to its summary) and baseline 1.6.0 has `52`-`54`, `97` and `expected/`. Nothing in the specs told a reader that packing lists are in scope, and a fixed fixture count is exactly what INT-601 forbids. The existing contract test carried a "compare summaries once the baseline has them" placeholder that only checked the summary files decoded, not that they matched.

## Workaround

Added INT-606..609, AC-67..70, data contract 3.6, the CT-16 row, a plan-change note, and replaced the placeholder with a real comparison. Stale counts in 6.1 were left as is (they describe the 1.5.2 era and should be rewritten with the slice that vendors nothing).

## Smallest generic change

Specs should reference "the guide's contract-test list" instead of restating a range, and never restate fixture counts.

## Check that would catch a recurrence

A docs check that greps specs for `CT-1..CT-` and `accepted)` counts and compares them to the guide.
