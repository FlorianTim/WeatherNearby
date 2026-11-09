---
name: test-summary
description: Run the Flutter test suite (or a subset) and get a compact
  pass/fail summary instead of the full log. Use whenever tests need to be
  executed or a change verified.
---

Run `bash scripts/dev/test_summary.sh [args]` (Windows:
`pwsh scripts/dev/test_summary.ps1 [args]`) instead of raw `flutter test`.

- Exit 0 = green (one summary line).
- On failure it prints only the failing test names and the first exception.
- Pass a path/name to scope the run, e.g.
  `bash scripts/dev/test_summary.sh test/features/todos`.

Fall back to the raw `flutter test` log only when the truncated details are
insufficient.
