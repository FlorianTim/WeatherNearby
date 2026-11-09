# Out of scope: JSCalendar interoperability

> **Package location (ADR-0017, 2026-10-08).** The codec is no longer
> `packages/task_interchange` in this repository. It is `task_interchange` in
> `flutter-libraries` (family `interchange`), consumed as a tag-pinned git
> dependency of `apps/mobile_app`. Statements below that say
> `packages/task_interchange` mean that package. Fixtures are read from
> `.lumbrecode/schemas/`, not vendored.

## Explicitly excluded

### Belongs to a sibling spec

- The task and list model and its invariants — **spec 0001**. The importer
  writes through the same repository and gets no privileged path.
- Views, navigation and the fact that the review is a route — **spec 0002**.
- The stored form of a recurrence rule and its expansion — **spec 0003**. This
  spec owns the wire form and the warnings.

### Not in 3.1.0

| Item | Why |
|---|---|
| iOS receive | Android is the only primary platform. An iOS share extension is its own work with its own boundary. |
| An "open file" import path | The narrow share filter is deliberate (INT-302); widening it is not the answer, and a file picker is a separate feature (Q-4a). |
| ICS / `VTODO` export | The right eventual target for the world outside LumbreCode, and not contract v1. |
| JSContact import | RFC 9553 is standardized in `lumbrecode-engineering`, and a to-do app has no obvious use for contacts. If "assign to a person" ever appears, the format is ready. |
| Attachments as bytes | In contract v1 an attachment is a `Link` with `rel: "enclosure"` and the bytes are not in the document. The link is persisted; the UI is later. |
| Emitting a LumbreCode vendor extension | Contract v1 states it has **no** vendor extensions. Being the first to add one unilaterally is exactly what this app must not do (Q-4i). |
| A configurable byte cap | A configurable security limit is a limit that gets raised (Q-4f). |
| Auto-import, even for a "trusted" `sourceappid` | `sourceappid` is a claim, not authentication. Auto-import on an unauthenticated claim is the hole the review exists to close (INT-208, INT-406). |
| "Add to an existing list" in the review | One step from matching, and matching needs conflict rules the contract does not define (Q-4b). |
| Deduplication on re-import | Same reason. A second import creates a second list; the user deletes one (INT-201). |
| Sharing to a specific installed app directly | The system share sheet is the mechanism. A curated target list is a maintenance burden and a privacy signal. |
| Registering `application/cloudevents+json` as its own intent filter | The same share action delivers it and the decoder sniffs the shape. A second filter widens the share sheet for no gain (INT-409). |

### Deliberately never in this app

- **Synchronization, in any form.** Not deferred — excluded by contract
  (guide §10.2, ADR-0020). Sharing is a snapshot: explicit, user-triggered,
  one-way, once. No connection, no back channel, no local "shared at" state.
  If real synchronization is ever wanted, it is a different contract with
  revisions, conflict rules and probably a backend.
- **A matching model.** No `(sourceappid, uid)` index, no tombstones, no
  sequence comparison for matching (INT-143). `sequence` is stored and read
  only by the exporter.
- **Merging two objects because their `uid`s agree.** The single most
  important rule in the guide.
- **Resolving `relatedTo` across documents or against the local database.**
  Within the document only (INT-203).
- **Fetching anything.** No `href`, no favicon, no preview, no size check —
  and not `dataschema` either, however much "validate against the schema it
  names" sounds like an instruction to download one (Q-4n).
- **Reading a path derived from document content.** Only the URI the intent
  delivered (INT-305).
- **Branching on `prodId`, `source` or `sourceappid`.** Provenance is
  displayed, never trusted (INT-009, INT-406).
- **A `*/*` or `text/plain` intent filter.** It would put a to-do app in every
  share sheet on the device (INT-302).
- **`delegated` as a progress value.** Not IANA-registered; never emitted.
- **Occurrences.** None of WasThereSomething's occurrence model is ever
  exported, so none of it can be needed to read a document. If an
  implementation reaches for one, the document has been misread — stop and
  check.

## Possible future extensions

- ICS / `VTODO` export for the world outside LumbreCode.
- Attachment UI on the existing `rel: "enclosure"` links.
- `count` / `until` recurrence, once contract v1.1 defines them on both sides
  (spec 0003, Q-3a).
- A file-picker import path (Q-4a).
- JSContact, if "assign to a person" ever appears.
- Promotion of `packages/task_interchange` to a shared distribution mechanism,
  once a second app consumes it (Q-05).

## Scope boundaries for the implementing agent

When implementing a story derived from this spec, do **not**:

- **Change the interchange format.** It is fixed, tested on both sides, and
  not ours to change. If you believe it is wrong, say so and stop — do not
  fork it, do not extend it, do not "fix" it locally.
- Emit any property, vendor extension or `type` value the contract does not
  define.
- Implement matching, merging, deduplication or synchronization of any kind,
  however convenient it looks (INT-201, INT-202, INT-143).
- Fetch, resolve, preview or size-check any URL from a document — including
  `dataschema`.
- Register `*/*`, `text/plain`, or any filter beyond the two in INT-302.
- Edit an `AndroidManifest.xml` directly. There is no committed `android/`;
  the change goes through the bootstrap patcher, and **both** the bash and the
  PowerShell path must be updated (INT-303, ADR-0013).
- Add `receive_sharing_intent` (ADR-0013, decision 1), `rrule` or the `uuid`
  package (ADR-0014). Any other new dependency stops and asks; `path_provider`
  is decided, `mime` is still open (Q-4g).
- Copy the guide's `share_plus` 10.x snippet. This template resolves 12.0.2
  and the entry point changed during the 11.x line — the verified 12.x call is
  in `data-contract.md` §3.3.
- Write anything before the review is confirmed, or leave a partial write
  after a rejection (INT-207).
- Add a setting, flag or code path that bypasses the import review or the
  share preview (INT-208, INT-507).
- Let a raw exception, a parser message or a stack trace reach the user
  (INT-102).
- Log a title, a body, a `uid` or a file name (INT-310).
- Emit any app-local field into a document (INT-510).
- Construct a `JsLocalDateTime` from a `DateTime`, or a fire moment by parsing
  a stored local date-time as UTC (INT-003).
- Modify a golden fixture in this repository alone. A fixture change happens
  in **both** repositories in the same change (INT-603).
- Change anything under `apps/mobile_app/lib/features/todos/` — the demo keeps
  working until slice 13, which is a separate story.
- Weaken, skip or delete an existing test to make a suite pass.
