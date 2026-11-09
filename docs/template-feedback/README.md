# Template feedback

Everything about the **template** that got in the way — written as it
happens, not remembered at the end. One file per problem,
`YYYY-MM-DD-short-slug.md`.

Use the `capture-template-feedback` skill, which is synchronized from
`lumbrecode-engineering` and writes into this directory.

> **Why this exists.** A template only improves if the friction it caused is
> written down at the moment it caused it. "The initializer deleted something
> it should have kept" is obvious on the day and gone two weeks later.
>
> In the template repository this is the register of what came back from
> derived apps. In a derived app it is the outbox.

## What belongs here

- **While generating an app:** every ambiguity, stale instruction, wrong
  classification and missing step — **including the ones you worked around**.
  An empty register after a full initialization is a suspicious result, not a
  good one.
- **While building features:** whenever a template decision costs time — a
  missing seam, a rule that turned out wrong, a test helper that does not
  cover the real case.

## What does not

- Bugs in this app's own code. Those are ordinary issues.
- Things the template deliberately does not do, recorded in an
  `out-of-scope.md` or an ADR. Disagreeing with a recorded decision earns an
  entry only if experience now contradicts its reasoning — say which part.

## Severity

| | Meaning |
|---|---|
| `blocker` | Had to be fixed before work could continue |
| `friction` | Cost real time, worked around |
| `papercut` | Small, but it will annoy every derived app |
| `idea` | Not a problem — something the template should have |

## Entries so far

The four dated `2026-08-26` came out of the 3.2.1 review of this template
itself, and are resolved. They are kept as worked examples of the shape.

The five dated `2026-08-27` came out of the first `dry-run` rehearsal of the
initializer — the classification had been read but never executed. Write-up:
`docs/delivery/reviews/2026-08-27-initializer-dry-run.md`. Four are resolved
in the documentation; the coupling behind the `blocker` is a follow-up.
