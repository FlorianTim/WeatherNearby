# Open questions: JSCalendar interoperability

> **Package location (ADR-0017, 2026-10-08).** The codec is no longer
> `packages/task_interchange` in this repository. It is `task_interchange` in
> `flutter-libraries` (family `interchange`), consumed as a tag-pinned git
> dependency of `apps/mobile_app`. Statements below that say
> `packages/task_interchange` mean that package. Fixtures are read from
> `.lumbrecode/schemas/`, not vendored.

Answered questions are kept and marked, with the answer folded into the
relevant spec file.

Questions marked **(contract)** belong to the owner of
`lumbrecode-engineering` and cannot be settled unilaterally here.

## Product

- **Q-4a — does the app offer an "open file" import path, in addition to the
  share intent?** A user whose file manager sends `.json` as `text/plain`
  will not see the app in the share sheet, and the narrow filter (INT-302) is
  deliberate — widening it is not the answer. A file picker inside the app
  would cover the case without touching the share surface.
  **Status: open.** Not in 3.1.0. Worth revisiting if it turns out to be a
  common complaint rather than a theoretical one.

- **Q-4b — should the review offer "add to an existing list" instead of always
  creating a new one?** **Answered 2026-08-25: no** (INT-201). The contract is
  explicit, and the reason is worth keeping visible: adding to an existing
  list is one step from matching, and matching needs conflict rules this
  contract does not define. A user who wants the tasks elsewhere moves them
  after the import, with the app's own move operation and its own undo.

- **Q-4c — is the "you already imported a list with this name" note worth
  it?** (INT-206) It helps in the accidental-double-import case and is noise
  otherwise. Proposal: show it only when an import with the same
  `source_uid` happened in the last 24 hours. **Status: open** — cheap either
  way, and it must never become behaviour.

## Technical

- **Q-4d (contract) — how should a receiver without a matching model treat
  `de.lumbrecode.exchange.jscalendar.upsert.v1`?**

  This is the one place two binding documents disagree, and the app cannot
  satisfy both literally:

  - `JSCALENDAR_TASK_INTEROP.md` §10.2 — a familiar `uid` never merges, links
    or syncs. Absolute.
  - `LUMBRECODE_EXCHANGE.md` rule 8 — `upsert.v1` means "the receiver **may**
    create or update the matched object", with matching on
    `(sourceappid, data.uid)`.
  - Golden fixture `20-task-in-envelope.json` carries `upsert.v1`, so
    rejecting the type fails a fixture; implementing the update breaks §10.2.

  **This app's position (INT-141..143):** accept both types, execute both as
  an import, and emit a counted `DowngradedUpsert` warning. `upsert` grants a
  *permission*, not an instruction; a receiver that has no matching model may
  decline it, and saying so is more honest than silently copying or refusing.

  **Ask of the contract owner:** state this explicitly in the profile — that
  a receiver without a matching model treats `upsert.v1` as `import.v1` and
  reports the downgrade. That turns a local interpretation into a contract
  rule and stops the next implementation from re-deriving it differently.
  **Status: open, raised.**

- **Q-05 (carried, app-wide) (contract) — how does `packages/task_interchange`
  reach a second app?** Copy, private pub host, or git dependency. Already
  recorded as WasThereSomething spec 0037 Q-05; it is the same question and
  needs one answer.

  Note that it now has a **second instance**: the shared Markdown editor and
  the seams in `packages/design_system` face exactly the same distribution
  question. One answer should cover both.

  Not blocking for 3.1.0: the package is built as if it will be shared —
  pure Dart, no app knowledge, its own tests, a stable public API — so every
  option stays open (ADR-0014, decision 9). **Status: open, deliberately.**

- **Q-4e — how do the golden fixtures stay in sync?** Vendored with a
  `PROVENANCE.md` and a checksum test (INT-601), because the baseline sync the
  guide describes (`.lumbrecode/schemas/`) **does not exist in this
  repository** — verified. Open: whether to add a small script that re-copies
  from a sibling checkout and updates the manifest, so "change both repos in
  one change" has a mechanical path rather than a discipline.
  **Status: open.** The checksum test is the tripwire either way.

- **Q-4f — should the byte cap be configurable?** No. 256 KiB is the value the
  contract names, and a configurable security limit is a limit that gets
  raised. Recorded so the absence is a decision.

- **Q-4g — is `mime` needed, or is `descriptionContentType` parsing simple
  enough by hand?** The app needs to split `text/markdown; charset=utf-8`
  into a type and parameters and compare the type case-insensitively. That is
  a handful of lines, and library-evaluation rule 9 is the template's own rule
  against a package for a trivial problem — the same rule that kept the `uuid`
  package out (ADR-0014). **Proposal: drop `mime`** and write the parser in
  `task_interchange`, which also keeps the package free of one more
  dependency. **Status: open — decide in slice 1 and record it.**

- **Q-4h — where does the temporary share directory live, and who cleans it?**
  `<cacheDir>/share/` via `path_provider`, cleaned at the next app start
  (INT-509). Open: whether cleaning is a `fireAndForget` startup task or
  happens lazily before the next write. Proposal: a `fireAndForget` startup
  task, so a user who shares once and never again does not keep the file.

- **Q-4i — does the app emit `lumbrecode.de:recurrenceMode`?** Spec 0003
  RRC-705 says it travels on the payload if it travels at all. Open here
  because emitting **any** vendor extension requires the contract to document
  it first (guide §1.6: namespaced, documented before emitted, ignorable
  without loss). **Proposal for 3.1.0: do not emit it.** Contract v1 states it
  has no vendor extensions, and being the first to add one unilaterally is
  exactly what this app must not do. The column stays local. **(contract)** if
  it should change.

## Architecture

- **Q-4j — does the Kotlin channel belong in a shared package once a second
  app receives documents?** Copied is fine for two (ADR-0013 follow-up).
  Recorded so it is a decision at three, not a surprise.

- **Q-4k — should the importer write through the repository, or through a
  dedicated bulk path?** Through the repository (INT-115, spec 0001
  TLD-1007), so the import path cannot bypass an invariant. Open only as a
  performance question: a 500-entry `Group` through per-row repository calls
  inside one transaction may be slow. Measure before optimizing, and if a
  bulk path becomes necessary it must run the same validation.

- **Q-4l — where does the import-review state live across a process restart?**
  INT-309 makes the review a route. Open: whether the pending payload is
  persisted (so the review survives) or discarded with a message. Proposal:
  discarded with a message — persisting an unvalidated payload is a small
  attack surface for a small convenience. **Status: open**, and AC-30 in spec
  0002 accepts either as long as the state is never unreachable.

## Privacy / Security

- **Q-4m — does the import report name task titles?** Warnings currently name
  the affected task for readability ("„Blumen gießen": Die Wiederholung …").
  That is on screen only and never logged (INT-310). Open: whether a
  screenshot-taking tool in the integration pipeline could capture it.
  Proposal: the manual test plan uses fixture data with neutral titles.

- **Q-4n — should the app verify `dataschema` by fetching it?** **No, never.**
  Nothing is fetched (spec 0001 TLD-706). `dataschema` is compared as a
  string against the known URI. Recorded because "validate against the schema
  it names" reads like an instruction to download one.

## Testing

- **Q-4o — can the end-to-end assertion (INT-605) be automated?** Partly.
  `51-group-nested-tasks.json` **is** WasThereSomething's exporter output, so
  importing it is a real end-to-end test of the standard layer. The full
  device-to-device path (share sheet, content URI, intent) stays manual.

- **Q-4p — how large should the fuzz corpus be in CI?** 10 000 cases (INT-604)
  is fast for a pure-Dart decoder but not free. Proposal: a smaller seeded set
  on every run and the full corpus on a nightly job. **Status: open.**

## Release

- **Q-4q — does import ship before export?** Import first (slice 8), export
  second (slice 9). Import is the reason the app exists — WasThereSomething
  already sends and nothing yet receives. Export is symmetric and cheaper once
  the codec exists.
