# Manual test plans

Manual test cases carry **globally unique, never-reused numbers** `T-NNN`.
A number identifies one test case forever — across releases, reports and
bug tickets ("fails in T-014" stays unambiguous years later).

## Registry

The registry is the single source for numbering. **Take the next free
number, add your row, never renumber.**

| Number range | Plan file | Area |
|---|---|---|
| T-001 – T-009 | [smoke.md](smoke.md) | App start, splash, language |

**Next free number: T-010**

## Rules

- One row per plan file; a plan owns a contiguous number range.
- Retired test cases keep their number (mark them *retired* in the plan).
- Every release (see `docs/operations/release-checklist.md`) records which
  T-numbers were executed and their result.

## Plan file format

```markdown
# <Area> — manual test plan

| ID | Precondition | Steps | Expected | Status |
|----|--------------|-------|----------|--------|
| T-001 | fresh install | start app | LumbreCode splash, then app phase | active |
```
