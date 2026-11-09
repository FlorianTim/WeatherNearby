# Acceptance criteria: JSCalendar interoperability

> **Package location (ADR-0017, 2026-10-08).** The codec is no longer
> `packages/task_interchange` in this repository. It is `task_interchange` in
> `flutter-libraries` (family `interchange`), consumed as a tag-pinned git
> dependency of `apps/mobile_app`. Statements below that say
> `packages/task_interchange` mean that package. Fixtures are read from
> `.lumbrecode/schemas/`, not vendored.

Format: Given / When / Then, with the requirement proved and the test level.
Levels: `unit`, `property`, `repository`, `integration`, `widget`, `ci`,
`manual`.

Fixture names refer to `lumbrecode-engineering/schemas/…/v1/examples/`, as
read from `.lumbrecode/schemas/` (baseline sync; not vendored, ADR-0017).

## The codec

**AC-01 — the package is pure Dart** (INT-001) · unit
Given `task_interchange` `lib/` (in `flutter-libraries`)
Then no file imports `package:flutter/*`, `package:drift/*`, `dart:io` or
`dart:ui`, and the package resolves and tests under plain `dart test`.

**AC-02 — a local date-time cannot be built from an instant** (INT-003) · unit
Given the `JsLocalDateTime` type
Then it exposes no constructor, factory or extension taking a `DateTime`, and
no file in the package converts a stored component set into a `DateTime` for
encoding.

**AC-03 — instants have no fractional seconds** (INT-004) · property
Given 1 000 random `DateTime` values with millisecond and microsecond
components
When each is encoded
Then every output matches `^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$`.

**AC-04 — encoding is deterministic** (INT-005, CT-14) · unit
Given every accepted fixture
When each is decoded and re-encoded 10 times
Then all 10 outputs are byte-identical, and the only fields that differ across
two *fresh* `Group` exports are `uid` and `updated`.

**AC-05 — key order and formatting are exact** (INT-006) · unit
Given any encoded object
Then `@type` is the first key, `uid` the second, the rest alphabetical;
indentation is two spaces; the output ends in a newline; the bytes are UTF-8
with no BOM.

**AC-06 — null is never emitted and empty collections are omitted** (INT-007) · property
Given 1 000 randomly populated models with optional fields unset
Then no output contains `: null`, `"keywords": {}`, `"links": {}`,
`"relatedTo": {}` or `"entries": []`.

**AC-07 — output is I-JSON** (INT-008) · property
Given the same 1 000 models
Then no output contains NaN or Infinity, no object has a duplicate member
name, and every string is valid UTF-16 with no unpaired surrogate.

**AC-08 — prodId is written but never acted on** (INT-009) · unit
Given a document whose `prodId` is `-//Evil//Corp 9.9//EN`
Then the import produces exactly the same result as the identical document
with a LumbreCode `prodId`, and no branch in the sources reads `prodId` other
than to display it.

**AC-09 — uid is a real v4 UUID from a secure RNG** (INT-010) · property
Given 100 000 generated uids
Then every one matches the canonical v4 form with the correct version and
variant nibbles, all are distinct, and no `pubspec.yaml` in the workspace
declares the `uuid` package.

## Validation and tolerant reading

**AC-10 — every valid fixture validates against the schema** (INT-601, CT-1) · ci
Given the vendored JSON Schemas and every non-`9x-invalid-` fixture
Then each validates, and this runs in CI rather than only locally.

**AC-11 — every invalid fixture is rejected with a typed, readable error** (INT-101..103, CT-2) · unit
Given `90-invalid-missing-type`, `91-invalid-due-with-offset`,
`92-invalid-progress-value`, `93-invalid-empty-title`,
`94-invalid-percent-out-of-range`, `95-invalid-group-without-entries`,
`96-invalid-uid-not-uuid`
Then each is rejected with a named error type and a message that does not
contain a stack trace or a raw parser exception.

**AC-12 — malformed JSON rejects the whole document** (INT-102) · unit
Given a truncated document and a document with a duplicate member name
Then each is rejected wholly, with a message naming the problem category, and
nothing is written.

**AC-13 — an unknown property survives a round trip** (INT-104, CT-10) · unit
Given a task carrying `"someFutureProperty": {"a": 1, "b": [2]}`
When it is imported, stored and re-exported without editing
Then the property is present, byte-identical, in the output.

**AC-14 — an unknown enum value degrades and is preserved** (INT-105) · unit
Given `"progress": "delegated"`
Then the task behaves as `needs-action` everywhere, the string is stored
verbatim, and re-export emits `delegated`.

**AC-15 — an unknown nested `@type` is skipped and counted** (INT-106) · unit
Given a `Group` whose `entries` contain one `Task`, one `Event` and one object
with `"@type": "Sandwich"`
Then the `Task` is imported, two `SkippedEntry` warnings are counted, and the
document is not rejected.

**AC-16 — clamping and truncation are reported, never silent** (INT-108) · unit
Given `"percentComplete": 140` and a 250-character title
Then the value is clamped to 100 with a `ClampedValue` warning, the title is
truncated to 200 with a `TruncatedTitle` warning, and both appear in the
review.

**AC-17 — a dated property with an offset is rejected, the task is kept** (INT-109) · unit
Given `91-invalid-due-with-offset` as a *property* inside an otherwise valid
task
Then the task imports without a due date, a `RejectedDateProperty` warning is
counted, and **no** conversion is attempted.

**AC-18 — an unsupported recurrence imports flat and reports** (INT-110) · unit
Given `"frequency": "hourly"`, `"count": 4` and
`"until": "2027-01-01T00:00:00"` in three separate documents
Then each task imports as non-recurring with exactly one
`UnsupportedRecurrence` warning.

**AC-19 — an unresolvable parent imports flat and reports** (INT-111) · unit
Given a task whose `relatedTo` names a `uid` not present in the document
Then it imports at top level, an `UnresolvedParent` warning is counted, and
the relation is retained as provenance only.

**AC-20 — contradictory relations import flat** (INT-112) · unit
Given A claiming `parent` of B and B claiming `parent` of A
Then both import flat, a warning is counted, and no cycle is written.

**AC-21 — the byte cap is enforced while reading** (INT-113) · integration
Given a document of 256 KiB + 1 byte
Then reading stops at the cap, the document is rejected as oversized, and the
full content was never held in memory.

**AC-22 — every warning is typed and counted** (INT-114, CT-13) · unit
Given a document exercising each tolerance rule at least once
Then every loss produces an instance of the sealed `ImportWarning` hierarchy,
the counts match the injected defects exactly, and no loss occurs without a
warning.

**AC-23 — repository invariants beat the document** (INT-115) · integration
Given a crafted document asserting a self-parent, a cycle and three-level
nesting
When it is imported
Then each violation is rejected by the repository, the valid remainder is
imported, and each rejection is a counted warning.

## Import behaviour

**AC-24 — a familiar uid creates a second list, never a merge** (INT-201, INT-202, CT-11) · integration
Given `51-group-nested-tasks.json` imported once
When the identical file is imported again
Then two lists exist, each with its own four tasks and its own local ids, the
`jscalendar_uid` values are duplicated across the two lists without conflict,
and no row from the first import was read or modified.

**AC-25 — import is total** (INT-207, CT-12) · integration
Given a document whose fifth of five tasks is invalid in a way that rejects
the document
When the import is attempted
Then `lists`, `tasks` and every side table have exactly the same contents as
before — zero rows written.

**AC-26 — the review has no bypass** (INT-208) · widget + unit
Given the import feature's sources and settings register
Then no setting, flag or code path writes an import without the review being
confirmed, and no key resembling "autoImport" exists.

**AC-27 — the tree survives a Group round trip** (CT-8, INT-203) · integration
Given `51-group-nested-tasks.json`
When it is imported
Then "Schokokuchen backen" has exactly two children, "Pappteller mitbringen"
is top-level, "Sahne kaufen" is `completed` with `percentComplete = 100`, and
relations were resolved only within the document.

**AC-28 — new local ids, preserved uids** (INT-210) · integration
Given a document imported twice
Then all eight tasks have distinct local ids and the `jscalendar_uid` values
match the document in both imports.

**AC-29 — entries order carries no meaning** (INT-211) · integration
Given a `Group` whose entries are in a deliberate non-alphabetical order
When it is imported and the new list is opened in the app's default sort
Then the displayed order is the app's own, and `sort_order` was assigned by
the app rather than read from the document.

**AC-30 — values without a UI are still stored** (INT-212) · integration
Given a task with `timeZone`, `estimatedDuration`, `percentComplete`,
`keywords` and `links`
When it is imported and re-exported without being edited
Then all five are present and identical in the output.

**AC-31 — plain text stays plain, html reports** (INT-213) · integration
Given one task with `descriptionContentType: text/plain` containing
`**not bold**`, and one with `text/html`
Then the first renders with visible asterisks, the second is stored as
received with an "unsupported body format" warning, and re-export declares the
content type each actually has.

**AC-32 — an unknown time zone degrades and reports** (INT-214) · unit
Given `"timeZone": "Mars/Olympus"`
Then the string is stored, the task is treated as floating, and a warning is
counted.

**AC-33 — Markdown is byte-identical after a round trip** (CT-9) · unit
Given `02-task-markdown.json`
When it is imported and re-exported
Then the `description` string is byte-identical and
`descriptionContentType` is unchanged.

**AC-34 — the report names both halves** (INT-209) · widget
Given a document of five tasks where one recurrence is unsupported and one
title is truncated
Then the summary reads as one sentence naming what was imported and what was
lost, in the active locale.

## The receive boundary

**AC-35 — exactly two narrow filters** (INT-302, INT-303) · integration + manual
Given a fresh `scripts/bootstrap_android.sh` run
Then the generated `AndroidManifest.xml` contains exactly two intent filters
for `application/jscalendar+json`, contains no `*/*` and no `text/plain`
filter, requests no `READ_EXTERNAL_STORAGE`, and `MainActivity` carries
`launchMode="singleTop"`. The same holds after the PowerShell path.

**AC-36 — the patcher is idempotent** (INT-303) · integration
Given a manifest already patched
When the patcher runs again
Then the manifest is unchanged and the run reports that the filter was already
present.

**AC-37 — an intent imports exactly once** (INT-306) · integration
Given a delivered payload
When the screen is rotated, navigated back from, and the process is restored
Then exactly one import occurs.

**AC-38 — a second payload queues** (INT-307) · integration
Given an open import review
When a second payload arrives
Then no second review is pushed, the first stays interactive, and the second
is presented only after the first is resolved.

**AC-39 — only the delivered URI is read** (INT-305) · unit
Given a document whose content contains a file path
Then no code path opens it, and the reader accepts only the URI the channel
delivered.

**AC-40 — no permission from the receive path** (INT-308) · integration
Given a payload arriving on a fresh install with no permissions granted
Then the import completes without any runtime permission request.

**AC-41 — logs carry no content** (INT-310) · integration
Given a document with distinctive titles, bodies, uids and file name
When it is received, parsed, reviewed, imported and reported
Then none of those strings appears in any captured log line.

## The CloudEvents envelope

**AC-42 — the three shapes are sniffed correctly** (INT-401) · unit
Given `50-group-simple.json` (plain), `21-task-group-in-envelope.json`
(envelope) and `07-batch-three-events.json` (batch)
Then each is classified correctly without relying on the intent's MIME
parameter.

**AC-43 — envelope validation is staged and total** (INT-402, INT-403) · unit
Given `91-invalid-specversion`, `92-invalid-unknown-type`,
`95-invalid-missing-dataschema`, `98-invalid-unknown-datacontenttype`
Then each rejects the event, and the envelope is validated before `data` is
looked at.

**AC-44 — subject mismatch and duplicate uids reject** (INT-404) · unit
Given an envelope whose `subject` differs from `data.uid`, and
`99-invalid-batch-duplicate-uids`
Then the first rejects the event and the second rejects the whole batch.

**AC-45 — an unknown extension attribute is ignored, not fatal** (INT-405) · unit
Given `09-unknown-type-and-extensions.json`'s extension attributes on an
otherwise valid event
Then the event imports and the unknown attributes cause no rejection.

**AC-46 — source is displayed, never trusted** (INT-406) · unit
Given two identical envelopes differing only in `source` and `sourceappid`
Then the imported result is identical, and no branch in the sources reads
either value except to display it.

**AC-47 — an unwrapped payload behaves exactly like a plain document** (INT-407) · integration
Given `21-task-group-in-envelope.json` imported twice
Then two lists are created — the envelope changes nothing about INT-201.

**AC-48 — a batch is not a Group** (INT-408) · integration
Given `07-batch-three-events.json`
Then three independent imports occur, not one list containing three things.

**AC-49 — a payload without sequence in an envelope is rejected** (INT-410) · unit
Given `96-invalid-payload-without-sequence.json`
Then the event is rejected with a named error.

**AC-50 — upsert is accepted, downgraded and reported** (INT-141, INT-142) · integration
Given `20-task-in-envelope.json`, whose `type` is
`de.lumbrecode.exchange.jscalendar.upsert.v1`
When it is imported, and then imported a second time
Then both imports succeed, each creates a **new** task, each produces exactly
one `DowngradedUpsert` warning naming that a copy was created instead of an
update, and no existing row was matched or modified.

**AC-51 — no matching model exists** (INT-143) · unit
Given the schema and the sources
Then there is no index, table or query keyed on `(sourceappid, uid)`, no
tombstone table, and `sequence` is read only by the exporter.

## Export and sharing

**AC-52 — round trips are semantically stable** (CT-3, CT-4) · unit
Given every accepted fixture
Then `encode(decode(fixture))` is semantically equal to the fixture, and
`decode(encode(model))` equals the original model, for every model the
generators produce.

**AC-53 — recurrence and dates round-trip** (CT-5, CT-6) · property
Given every rule the parser accepts, and the four date shapes with and
without a time
Then each survives model → JSCalendar → model identically, including the
lowercase weekday tokens on the wire and the `showWithoutTime` pairing.

**AC-54 — tree assignment never produces a cycle** (CT-7) · property
Given 10 000 random parent assignments over 200 tasks
Then no cycle is ever created and every ancestor walk terminates.

**AC-55 — no app-local field is ever emitted** (INT-510, CT-15) · unit
Given documents exported for a task, a selection and a list
Then none contains a local row id, `list_id`, `sortOrder`, `notificationId`,
`deletedAt`, `archivedAt` or `sourceUid`, in any casing, as a standard
property or as a vendor extension.

**AC-56 — a fresh Group uid per share, stable task uids** (INT-511) · unit
Given the same list shared twice
Then the two `Group.uid` values differ, and every task `uid` is identical
across both.

**AC-57 — relations are written in both directions** (INT-512) · unit
Given a parent with two children
Then the parent carries two `child` relations and each child carries one
`parent` relation, keyed by the other object's `uid`.

**AC-58 — unknown properties are merged back, app properties win** (INT-513) · unit
Given a task whose `unknown_json` holds `{"x": 1, "title": "stale"}`
When it is exported
Then `x` is present and `title` is the app's current title, not the stale one.

**AC-59 — sharing writes a file through the seam** (INT-504, INT-505, INT-506) · widget
Given a list shared as a document
Then the fake `ShareDocument` seam received one payload with media type
`application/jscalendar+json;type=group` and a `.jscalendar.json` file name,
no real share sheet was opened, and the call used
`SharePlus.instance.share(ShareParams(files: …))` in the real implementation.

**AC-60 — the preview is unskippable and honest** (INT-507, INT-508) · widget
Given a share of 5 tasks with notes
Then a preview names the count, states that notes travel, states that a
shared copy is out of the sender's control, and there is no code path from the
share action to the seam that bypasses it.

**AC-61 — cache files are private and cleaned** (INT-509) · integration
Given two shares
When the app is restarted
Then the previous temporary files are gone, and every written file was under
the app-private cache directory.

**AC-62 — a document carries no identifiers** (INT-514) · unit
Given any exported document
Then it contains no device id, install id, account, advertising id or
analytics token.

**AC-63 — the envelope option appears only when a receiver exists** (INT-503) · widget
Given a package-manager query seam reporting no receiver, then one receiver
Then the envelope option is hidden in the first case and offered in the
second.

## Contract tests and fixtures

**AC-64 — fixtures come from the baseline and are read by directory** (INT-601, INT-603) · unit
Given `.lumbrecode/schemas/`
Then every accepted and `9x-invalid-` JSCalendar fixture and every exchange
fixture is exercised without a hand-picked list, and the baseline lock
(`.lumbrecode/baseline.lock.json`) fails the baseline check if any fixture's
content diverges.

**AC-65 — the fuzz suite never throws** (INT-604) · property
Given 10 000 mutated documents — truncated at random offsets, byte-flipped,
oversized, deeply nested, with duplicate keys
Then every one produces either a successful decode or a typed rejection, and
**none** produces an unhandled exception.

**AC-66 — the end-to-end assertion holds** (INT-605) · integration
Given a document produced by WasThereSomething's exporter
(`51-group-nested-tasks.json` is exactly that)
When it is imported here
Then the resulting tasks match on titles, bodies, body content types, dates
and date-only flags, progress, percentages, priorities, keywords, links and
tree structure — and deliberately do **not** match on local ids or ordering.

**AC-67 — every accepted `Group` fixture imports to its expected summary** (INT-606, CT-16) · integration
Given every accepted `5x` fixture under `.lumbrecode/schemas/jscalendar-task/v1/examples/`,
found by directory
When it is imported into the database
Then the resulting list, its tasks and their tree equal
`examples/expected/<fixture>.summary.json` — titles unchanged, `progress`,
effective `percentComplete`, priority band, keywords, links, date-only `due`
and the section / sub-task tree. A `5x` fixture released later is picked up
without a code change. *(Until slice 8 the same comparison runs against the
decoder: `test/interop/packing_list_contract_test.dart`.)*

**AC-68 — packing lists keep their conventions** (INT-607) · integration
Given `52-group-packing-list-by-category.json`
Then the sections ("Kleidung", "Technik") are parent tasks and the items their
children; an `in-process` item keeps its percentage; `to-buy`, `last-minute`
and the category slug are stored as keywords (an unknown slug is stored as it
is); a `last-minute` `due` stays date-only; a title such as `T-Shirt ×3` or
`Wasser 1,5 l` is stored and shown exactly as received — **it is never
parsed**; and `prodId` changes nothing about any of it.

**AC-69 — files of one trip are separate lists** (INT-608, CT-11) · integration
Given `52-…` ("Urlaub Italien") and `53-…` ("Urlaub Italien - Medikamente")
When both are imported, then the same file once more
Then there are three lists with three `Group` titles, none merged or renamed
for sharing a prefix, and nothing is deduplicated by `uid` (guide 10.3).

**AC-70 — a packing-list file is accepted or rejected as a whole** (INT-609, CT-12) · integration
Given a `Group` with 501 entries, malformed JSON, or one entry without a title
Then the import is rejected with a typed reason and writes zero rows.

## Manual verification steps

Required by ADR-0013; none can be asserted in `flutter test`.

1. Cold start: share a `.jscalendar.json` from a file manager with the app
   killed; the review appears.
2. Warm delivery: repeat with the app in the foreground (`onNewIntent`).
3. Rotate the device while the import review is open.
4. Send a second payload while the review is open.
5. Share a document one byte over 256 KiB and confirm the oversized message.
6. Confirm the app does **not** appear in the share sheet for a photo, a plain
   text note or a PDF.
7. Share a list from the app to another app and confirm the file name, the
   media type and the preview.
8. Share from WasThereSomething into this app end-to-end on one device.
