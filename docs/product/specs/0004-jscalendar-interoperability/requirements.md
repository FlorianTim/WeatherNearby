# Requirements: JSCalendar interoperability

> **Package location (ADR-0017, 2026-10-08).** The codec is no longer
> `packages/task_interchange` in this repository. It is `task_interchange` in
> `flutter-libraries` (family `interchange`), consumed as a tag-pinned git
> dependency of `apps/mobile_app`. Statements below that say
> `packages/task_interchange` mean that package. Fixtures are read from
> `.lumbrecode/schemas/`, not vendored.

Requirement IDs use the prefix `INT-`. Every id maps to at least one criterion
in `acceptance-criteria.md`.

Priority: **Must** = required for 3.1.0. **Should** = required unless a story
explicitly defers it with a recorded reason. **Model-only** = round-tripped,
deliberately without UI in 3.1.0.

> **The format is fixed.** Requirements marked *(contract)* restate a binding
> rule from `lumbrecode-engineering/docs/JSCALENDAR_TASK_INTEROP.md` or
> `docs/LUMBRECODE_EXCHANGE.md`. They are not open to local reinterpretation.
> If one appears wrong, raise it with the contract owner and stop.

## A. The codec (INT-0xx)

| Id | Requirement | Priority |
|---|---|---|
| INT-001 | Models, codec, validation and warnings live in `task_interchange` (`flutter-libraries`, ADR-0017), pure Dart: no Flutter, no Drift, no `dart:io`, no platform channel. Asserted there by an import-scanning test. | Must |
| INT-002 | The codec is hand-written. No Dart JSCalendar library exists (guide §7.1, re-checked 2026-08-25). `rrule` is not added. | Must |
| INT-003 | `start`, `due`, `recurrenceId` and override keys use a dedicated `JsLocalDateTime` type carrying components only. It is never constructed from a `DateTime` and never round-tripped through an instant. *(contract §2.4)* | Must |
| INT-004 | `created`, `updated` and `progressUpdated` use `JsUtcInstant`: `YYYY-MM-DDTHH:MM:SSZ`, second precision, **no fractional seconds**. *(contract §4)* | Must |
| INT-005 | Encoding is deterministic: same input, byte-identical output, except `Group.uid` and `Group.updated`. *(contract §4)* | Must |
| INT-006 | Key order is `@type` first, `uid` second, then alphabetical. Two-space indentation, trailing newline, UTF-8, no BOM. *(contract §4)* | Must |
| INT-007 | **`null` is never emitted.** Absent means absent. Empty collections are omitted — never `"keywords": {}` or `"entries": []`. *(contract §4)* | Must |
| INT-008 | Output is I-JSON (RFC 7493): no NaN, no Infinity, no duplicate member names, no unpaired surrogates. | Must |
| INT-009 | `prodId` is emitted as `-//LumbreCode//<AppDisplayName> <version>//EN`, read for display only, and **never** used as a trust or behaviour signal. *(contract §2.1)* | Must |
| INT-010 | `uid` is an RFC 4122 v4 UUID from a cryptographically secure RNG, canonical lowercase, via the `Uuid4` helper in `packages/app_core`. The `uuid` package is not added (ADR-0014). | Must |

## B. Validation and tolerant reading (INT-1xx)

Validation decides whether a document is usable at all; tolerant reading
decides what to do with the parts inside a usable document that are not
understood. They are different jobs.

| Id | Requirement | Priority |
|---|---|---|
| INT-101 | Required fields are enforced: `Task` needs `@type`, `uid`, `updated`, `title`; `Group` needs `@type`, `uid`, `updated`, `entries` (1..500); `Relation` needs `@type` and a non-empty `relation`; `Link` needs `@type` and `href`; `RecurrenceRule` needs `@type` and `frequency`; `NDay` needs `@type` and `day`. *(contract §5.1)* | Must |
| INT-102 | Malformed JSON rejects the **whole** document with a readable message naming the problem category — never a raw parser exception and never a stack trace. *(contract §5.2)* | Must |
| INT-103 | A missing or unrecognized top-level `@type` rejects the document. *(contract §5.2)* | Must |
| INT-104 | An unknown **property** anywhere is kept verbatim in `unknown_json`, ignored for behaviour, and written back on re-export. A document is never rejected for an unknown property. *(contract §5.2, §5.4)* | Must |
| INT-105 | An unknown **enum value** in a property the app acts on (`progress`) behaves as the documented default and the string is kept verbatim. *(contract §5.2)* | Must |
| INT-106 | An unknown `@type` inside `entries`, `relatedTo` or `links` skips that entry, counted and reported; the rest is imported. *(contract §5.2)* | Must |
| INT-107 | An explicit `null` is treated as absent and reported. *(contract §5.2)* | Must |
| INT-108 | An out-of-range value (`percentComplete: 140`) is clamped and reported. A `title` over 200 characters is truncated and reported — **never silently**. *(contract §5.2)* | Must |
| INT-109 | A `due` or `start` carrying `Z` or an offset **rejects that property**, keeps the task, and reports. No conversion is guessed. *(contract §5.2)* | Must |
| INT-110 | An unsupported recurrence (`hourly`, `count`, `until`, `bySetPosition`, …) imports the task as non-recurring and reports the loss. *(contract §5.2, and spec 0003 RRC-502)* | Must |
| INT-111 | A `relatedTo` pointing at a `uid` not present in the document imports the task flat, keeps the relation as provenance, and reports. *(contract §10.4)* | Must |
| INT-112 | Contradictory relations (A claims parent of B, B claims parent of A) import both flat and report. *(contract §10.4)* | Must |
| INT-113 | A document larger than the 256 KiB cap is rejected as oversized, and the cap is enforced **while reading**, not after. *(contract §6.2)* | Must |
| INT-114 | Every "report" is a **counted, typed warning** from a sealed hierarchy (`UnsupportedRecurrence`, `TruncatedTitle`, `UnresolvedParent`, `SkippedEntry`, `ClampedValue`, `RejectedDateProperty`, `ExplicitNull`, `DowngradedUpsert`, …). Never a bare string, never silence. *(contract §5.3)* | Must |
| INT-115 | The tree rules from spec 0001 are enforced on write regardless of what the document claimed: no self-reference, no cycle, one parent, max depth 2. *(contract §10.4)* | Must |

## C. Import behaviour (INT-2xx)

| Id | Requirement | Priority |
|---|---|---|
| INT-201 | A `Group` becomes a **new list**. Always. Even if the `uid` has been seen before. Even if the identical file was imported a minute ago. *(contract §10.1)* | Must |
| INT-202 | A familiar `uid` is **provenance only**. It never matches, merges, links or syncs. It may be stored in `lists.source_uid` and shown as "importiert aus …". *(contract §10.2)* | Must |
| INT-203 | `relatedTo` is resolved **within the document only**. Never across documents, never against the local database. *(contract §10.2, §10.4)* | Must |
| INT-204 | A single `Task` document imports into a list the user picks, defaulting to the Inbox. | Must |
| INT-205 | The user may edit the proposed list name in the review before confirming. | Should |
| INT-206 | The app may warn "you imported a list with this name on 25 August". It may never act on the resemblance. *(contract §10.3)* | Should |
| INT-207 | Import is **total**: the whole document is validated before anything is written, and the write is a single transaction. A rejected document leaves **zero** rows. *(contract §5.5, §10.12)* | Must |
| INT-208 | The import review has **no bypass and no auto-import setting**. A payload is a proposal, never a command. Adding such a setting later requires a new ADR. *(contract §9.3)* | Must |
| INT-209 | After a successful import the app reports what was imported **and what was lost**, in one readable summary. | Must |
| INT-210 | Every imported task gets a **new local row id**; the incoming `uid` is preserved as `jscalendar_uid`. *(contract §2.1)* | Must |
| INT-211 | `Group.title` becomes the list name. `entries` order is the sender's display order and **carries no meaning** — the app sorts by its own rule after import. *(contract §2.8)* | Must |
| INT-212 | Values the app has no UI for (`timeZone`, `estimatedDuration`, `percentComplete`, keywords, `links`) are **stored anyway**. Storing is cheap and keeps re-export lossless. *(contract §10.6)* | Must |
| INT-213 | A body arriving as `text/plain` stays plain; the app never guesses that it is Markdown. `text/html` is stored as received and rendered as plain text with a reported "unsupported body format". *(contract §2.2, §10.10)* | Must |
| INT-214 | An unknown `timeZone` id keeps the string, treats the task as floating, and reports. *(contract §10.11)* | Must |
| INT-215 | `recurrenceOverrides` are imported when the rule was supported. If dropped, the loss is reported. *(contract §10.9)* | Should |

## D. The receive boundary (INT-3xx)

Detailed reasoning in ADR-0013.

| Id | Requirement | Priority |
|---|---|---|
| INT-301 | The receive path is an app-owned platform channel in `MainActivity`. `receive_sharing_intent` is **not** used. | Must |
| INT-302 | Exactly two intent filters are registered, both for `application/jscalendar+json`, on `ACTION_SEND` and `ACTION_SEND_MULTIPLE`. **Never `*/*`, never `text/plain`.** *(contract §6.2)* | Must |
| INT-303 | The manifest change is delivered by an **idempotent bootstrap patcher**, in both `scripts/lib/apply_android_branding.sh` and `scripts/lib/Apply-AndroidBranding.ps1`. There is no committed `android/` to edit. | Must |
| INT-304 | `MainActivity` uses `launchMode="singleTop"`, and both the cold-start and the warm `onNewIntent` paths are handled. *(contract §6.2)* | Must |
| INT-305 | Bytes are read only from the URI the intent delivered, through `ContentResolver`. **No path derived from document content is ever opened.** *(contract §5.5, §6.2)* | Must |
| INT-306 | An intent is consumed **exactly once**. Rotation, back navigation and process restore must not re-trigger an import. *(contract §6.2)* | Must |
| INT-307 | A second payload arriving while a review is open is **queued**. Two review screens never stack. *(contract §6.2)* | Must |
| INT-308 | The receive path never requests a runtime permission. *(contract §6.2)* | Must |
| INT-309 | The import review is a **route**, not an anonymous dialog, so a process restart cannot leave the app unreachable (spec 0002, VSN-406). | Must |
| INT-310 | Logging records counts and reason codes only — never a title, a body, a `uid` or a file name. *(contract §6.4)* | Must |

## E. The CloudEvents envelope (INT-4xx)

| Id | Requirement | Priority |
|---|---|---|
| INT-401 | The decoder sniffs the payload shape: a top-level `@type` of `Task`/`Group` is plain JSCalendar; `specversion` + `data` is a CloudEvent; a JSON array is a batch. *(exchange profile)* | Must |
| INT-402 | Envelope validation is staged and total: envelope first, then `data` against the schema its `datacontenttype` names. *(exchange rule 7)* | Must |
| INT-403 | `specversion` other than `1.0`, an unknown `type`, an unknown `datacontenttype`, or a missing `dataschema` rejects the event. *(exchange reading rules)* | Must |
| INT-404 | A `subject` present but different from `data.uid` rejects the event. Duplicate `data.uid` within one batch rejects the whole batch. *(exchange reading rules)* | Must |
| INT-405 | An unknown CloudEvents **extension attribute** is ignored for behaviour, not a rejection. *(exchange reading rules)* | Must |
| INT-406 | `source` and `sourceappid` are **claims, never authentication**. Displayed as provenance; never a trust decision, a permission or a behaviour branch. *(exchange rule 4)* | Must |
| INT-407 | Once unwrapped, `data` is treated **exactly** as a plain document. Nothing else about the import changes — including INT-201 and INT-202. | Must |
| INT-408 | A batch entry is unwrapped and imported on its own. A CloudEvents **batch** ("these messages travel together") is never conflated with a JSCalendar **Group** ("these objects belong together"). *(exchange profile)* | Must |
| INT-409 | `application/cloudevents+json` is **not** registered as a separate intent filter in 3.1.0. The same share action delivers it and the decoder sniffs the shape (ADR-0013, decision 2). | Should |
| INT-410 | An envelope payload without `sequence` is rejected, per the profile — `sequence` is required inside an envelope and optional in a plain share. *(exchange rule)* | Must |

### INT-14x — the `upsert` resolution

This is the one place where two binding documents disagree, and the app cannot
satisfy both literally. Full analysis in the audit §4.8.

- The interop guide §10.2 is absolute: a familiar `uid` never merges or syncs.
- The exchange profile defines `de.lumbrecode.exchange.jscalendar.upsert.v1`
  as "the receiver **may** create **or update** the matched object", with
  matching on `(sourceappid, data.uid)`.
- Golden fixture `20-task-in-envelope.json` carries `upsert.v1`. Rejecting the
  type would fail a golden fixture; implementing the update would break the
  guide's most emphatic rule.

| Id | Requirement | Priority |
|---|---|---|
| INT-141 | Both `…import.v1` and `…upsert.v1` are **accepted**, and **both execute as an import** — a new local copy, never a match, never an update. | Must |
| INT-142 | An `upsert.v1` envelope produces a counted `DowngradedUpsert` warning stating that the sender offered an update and a copy was created instead. | Must |
| INT-143 | The app implements **no** matching model: no `(sourceappid, uid)` index, no tombstones, no sequence comparison for matching. `data.sequence` is stored on the task and used for nothing but re-export. | Must |

The reasoning, recorded so it can be re-argued: `upsert` grants the receiver a
*permission* ("you may update"), not an instruction. A receiver without a
matching model is free not to exercise it, and saying so in a warning is more
honest than either silently copying or refusing the document. Carried to the
contract owner as Q-4d so the profile can state this explicitly.

## F. Export and sharing (INT-5xx)

| Id | Requirement | Priority |
|---|---|---|
| INT-501 | Three scopes can be shared: one task, a selection, a whole list. A list is a `Group`; a single task is a `Task`. | Must |
| INT-502 | The default format is the **plain standard** document. The envelope is the special case. *(exchange rules)* | Must |
| INT-503 | The envelope option is offered only when a receiver is installed, determined by a package-manager query for the MIME type. A dead share entry is worse than no entry. | Should |
| INT-504 | Sharing writes a **file**, not `EXTRA_TEXT`: `<cacheDir>/share/<name>.jscalendar.json`, app-private, then a `content://` URI with a read grant. *(contract §6.1)* | Must |
| INT-505 | Sharing goes through an injectable seam (`ShareDocument`) so no widget test opens a real share sheet. The seam is extended from the template's existing `ShareText` in slice 0. | Must |
| INT-506 | The `share_plus` 12.x API is used: `SharePlus.instance.share(ShareParams(files: [XFile(path, mimeType: …)]))`. The guide's 10.x `Share.shareXFiles(...)` snippet does not compile here. | Must |
| INT-507 | An **unskippable preview** names what will leave the device: how many tasks, which fields, and that notes travel. *(contract §6.4, WTS spec 0037)* | Must |
| INT-508 | The preview states that a shared copy is out of the sender's control, rather than implying a guarantee. | Must |
| INT-509 | Temporary share files live in the app-private cache and are deleted at the next app start at the latest. *(contract §6.1)* | Must |
| INT-510 | **No app-local field appears in any document**: no row id, no `list_id`, no `sort_order`, no `notification_id`, no `deleted_at`, no `archived_at`, no `source_uid`. *(contract §15.7, CT-15)* | Must |
| INT-511 | A `Group.uid` is a **fresh** v4 UUID per share; task `uid`s are stable. A group is one act of sending; a task is a thing that can be recognized again. *(contract §2.8)* | Must |
| INT-512 | Parent/child relations are written in **both** directions — `parent` on the child, `child` on the parent — so a receiver reading only one still gets the tree. *(contract §2.6)* | Must |
| INT-513 | `unknown_json` is merged back over the app's own properties on export, with the app's properties winning on conflict. *(contract §5.4)* | Must |
| INT-514 | A document carries no device id, no install id, no account and no analytics identifier. *(contract §6.4)* | Must |

## G. Contract tests (INT-6xx)

| Id | Requirement | Priority |
|---|---|---|
| INT-601 | The JSCalendar and exchange golden fixtures are read from `.lumbrecode/schemas/` (baseline sync) **by directory**, not vendored; the baseline lock carries their checksums. Counts are not asserted in the template (ADR-0017). | Must |
| INT-602 | CT-1 to CT-15 from guide §12 are implemented. CT-1..CT-10, CT-13, CT-14, CT-15 belong to `task_interchange` (`flutter-libraries`); CT-11 and CT-12 belong to the app's data layer, because they are about transactions and rows. | Must |
| INT-603 | A fixture change happens in **both** repositories in the same change; otherwise the contract test stops proving anything. The checksum test makes a divergence fail CI rather than pass quietly. | Must |
| INT-604 | The decoder is fuzzed with truncated, oversized and randomly mutated documents. **No input may produce an unhandled exception.** *(contract §12.3)* | Must |
| INT-605 | The end-to-end assertion is exercised: a document produced by WasThereSomething's exporter imports here into semantically identical tasks — same titles, bodies, content types, dates and date-only flags, progress, percentages, priorities, keywords, links and tree structure. Not the same local ids and not the same ordering. | Must |
| INT-606 | **CT-16:** every accepted `Group` fixture imports to its `expected/<fixture>.summary.json`. Fixtures are found by directory; the test carries no list of names and no count. *(guide §12.2)* | Must |
| INT-607 | A packing list (guide §2.9) is an ordinary `Group`. Sections are parent tasks and items their children; `completed` / `in-process` + `percentComplete` / `needs-action` are stored as sent; `to-buy`, `last-minute` and category slugs are stored as keywords; a date-only `due` stays date-only. **The quantity lives in the title and is shown as is — a receiver never parses a title.** `prodId` never changes behaviour. | Must |
| INT-608 | Several files of one trip are independent lists: never merged, never renamed, never linked, even when their titles share a prefix. Importing a file twice creates two lists. *(guide §2.9.6, §10.3)* | Must |
| INT-609 | A `Group` over 500 entries, a malformed file or an unusable entry rejects the whole file; no row is written. *(guide §2.9, CT-12)* | Must |

## Quality requirements

- **Accessibility**: the import review and the share preview are ordinary
  screens and obey the same rules — 48 dp targets, semantic labels, no
  overflow at `TextScaler.linear(2.0)`, warnings conveyed as text and not by
  colour alone.
- **Localization**: German and English for every warning, every review label
  and every summary. Warning types are **enums with stable persistence
  values**, localized only at display time — never an English string stored or
  logged.
- **Robustness**: no document, however malformed, may crash the app or leave a
  partial write.

## Constraints

- The contract is fixed. Implement it; do not redesign it. If it appears
  wrong, say so and stop.
- `share_plus` is **12.0.2** here against 10.1.4 in WasThereSomething. The
  entry point changed during the 11.x line — verified in the audit §4.5.
- `path_provider` and `mime` are new dependencies (cache directory,
  `descriptionContentType` parsing). Both runtime-only; resolve against the
  KI-001 tree before adoption.
- The Kotlin side is not covered by `flutter test`; it needs manual test-plan
  entries (ADR-0013).

## Data requirements

No new tables. This spec uses `lists.source_uid` / `source_app` /
`imported_at`, `tasks.unknown_json`, `tasks.sequence` and
`task_recurrence_overrides`, all declared in specs 0001 and 0003. See
`data-contract.md`.

## Privacy / Security considerations

- **Nothing leaves without an explicit, previewed action** (INT-507).
- **Nothing is fetched, ever** — no `href` is resolved, previewed or
  size-checked automatically (spec 0001, TLD-706).
- **Only `http`/`https` open, only on a tap** (spec 0001, TLD-705).
- **Counts and reason codes in logs, never content** (INT-310).
- **Provenance is displayed, never trusted** (INT-406).
- **The share sheet stays narrow** (INT-302): the app appears only for
  documents it can read.
- **Temporary files are app-private and short-lived** (INT-509).

## Testability notes

Automated: everything except the Kotlin channel. The codec is pure Dart and
gets the property and fixture tests; import totality and the `uid`-twice rule
are integration tests against a real in-memory database.

Manual (ADR-0013): cold start with a payload, warm delivery via `onNewIntent`,
rotation during review, a second payload during review, and a document one
byte over the cap.

## Traceability

Every requirement maps to a criterion in `acceptance-criteria.md`.
