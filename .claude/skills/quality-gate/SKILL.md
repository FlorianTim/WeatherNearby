---
name: quality-gate
description: Run the local quality gate (format check + analyze + tests) for
  the mobile app with compact output. Use before committing or when asked to
  verify a change is clean.
---

Run `bash scripts/dev/quality_gate.sh` (Windows:
`pwsh scripts/dev/quality_gate.ps1`).

- Each step prints one `PASS`/`FAIL` line; full output appears only for a
  failing step.
- Mirrors what the pre-commit hook and CI enforce (format, analyze, test).
- Fix any FAIL before committing; re-run to confirm `== QUALITY GATE PASSED ==`.
