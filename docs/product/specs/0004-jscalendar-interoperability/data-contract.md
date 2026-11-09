# Data contract: JSCalendar interoperability

> **Package location (ADR-0017, 2026-10-08).** The codec is no longer
> `packages/task_interchange` in this repository. It is `task_interchange` in
> `flutter-libraries` (family `interchange`), consumed as a tag-pinned git
> dependency of `apps/mobile_app`. Statements below that say
> `packages/task_interchange` mean that package. Fixtures are read from
> `.lumbrecode/schemas/`, not vendored.

The wire format is **fixed and external**. This file states how it maps onto
this app's storage and where the authoritative definitions live. It never
redefines the format.

**Authoritative sources** (`lumbrecode-engineering`):

| Document | Owns |
|---|---|
| `docs/JSCALENDAR_TASK_INTEROP.md` | the canonical model, serialization, tolerance rules, import rules, contract tests |
| `docs/LUMBRECODE_EXCHANGE.md` | the CloudEvents envelope profile |
| `schemas/jscalendar-task/v1/jscalendar-task-v1.schema.json` | payload schema |
| `schemas/lumbrecode-exchange/v1/lumbrecode-exchange-v1.schema.json` | envelope schema |
| `schemas/*/v1/examples/` | 24 + 21 golden fixtures |

---

## 1. Data structures

### 1.1 No new tables

This spec adds nothing to the schema. It uses columns declared elsewhere:

| Column | Declared in | Used for |
|---|---|---|
| `tasks.jscalendar_uid` | spec 0001 | the `uid`, preserved as provenance |
| `tasks.unknown_json` | spec 0001 | unrecognized standard properties, ≤ 8 KiB |
| `tasks.sequence` | spec 0001 | the revision half of a re-share; read only by the exporter |
| `tasks.description_content_type` | spec 0001 | declared truthfully on re-export |
| `tasks.time_zone_id` | spec 0001 | preserved even without a UI |
| `tasks.estimated_duration_minutes` | spec 0001 | preserved even without a UI |
| `task_links.*` | spec 0001 | full `Link` objects including `rel`, `cid`, `display` |
| `lists.source_uid` / `source_app` / `imported_at` | spec 0001 | **provenance only** |
| `task_recurrence_overrides.*` | spec 0003 | `recurrenceOverrides` |

`lists.source_uid` deserves repeating: it is displayed ("importiert aus …")
and **never** used to match, merge or sync (INT-202).

### 1.2 In-memory model — `task_interchange` (`flutter-libraries`)

```text
Task            uid created updated sequence? title
                description descriptionContentType
                start due timeZone showWithoutTime estimatedDuration
                priority progress percentComplete progressUpdated
                recurrenceRules excludedRecurrenceRules
                recurrenceOverrides recurrenceId
                relatedTo keywords links
                unknown (verbatim map)
Group           uid prodId updated sequence? title entries
Relation        relation: { parent | child }
Link            href cid contentType size rel display title
RecurrenceRule  frequency interval byDay byMonthDay
NDay            day nthOfPeriod
PatchObject     progress progressUpdated percentComplete excluded
```

```dart
enum TaskProgress { needsAction, inProcess, completed, failed, cancelled }
enum LinkDisplay  { badge, graphic, fullsize, thumbnail }
enum RelationType { parent, child }   // first/next parsed, not modelled
enum Frequency    { daily, weekly, monthly, yearly }
```

Two dedicated value types carry the whole date discipline (INT-003, INT-004):

```dart
/// Components only. No offset, no zone, no instant.
/// Deliberately offers no constructor taking a DateTime — see AC-02.
final class JsLocalDateTime { … }   // start, due, recurrenceId, override keys

/// UTC, second precision, no fractional seconds.
final class JsUtcInstant { … }      // created, updated, progressUpdated
```

`delegated` is **not** a `TaskProgress` member and is never emitted. An
incoming `delegated` behaves as `needsAction` and the raw string is preserved
(INT-105).

### 1.3 Field mapping, wire to storage

| JSCalendar | Column | Notes |
|---|---|---|
| `uid` | `jscalendar_uid` | preserved; **never** a matching key |
| `created` / `updated` | `created_at` / `updated_at` | `created` absent → import time |
| `sequence` | `sequence` | required inside an envelope, optional plain |
| `title` | `title` | > 200 chars → truncate **and report** |
| `description` | `description_markdown` | verbatim, never normalized on write |
| `descriptionContentType` | `description_content_type` | absent → treat as `text/plain` per RFC |
| `start` / `due` | `*_date_day` + `*_minutes` | components; `Z` or an offset rejects the property |
| `showWithoutTime` | `show_without_time` | paired with `*_minutes IS NULL` |
| `timeZone` | `time_zone_id` | unknown id → keep string, treat floating, report |
| `estimatedDuration` | `estimated_duration_minutes` | ISO 8601 duration → whole minutes |
| `priority` | `priority` | 0 undefined, 1 highest, 9 lowest |
| `progress` | `progress` | five registered values; unknown kept verbatim |
| `percentComplete` | `percent_complete` | clamp 0..100 **and report** |
| `progressUpdated` | `progress_updated_at` | |
| `recurrenceRules` | `recurrence_rule` (+ version) | contract subset only; else import flat and report |
| `recurrenceOverrides` | `task_recurrence_overrides` | key = the LocalDateTime string, verbatim |
| `relatedTo` | `parent_task_id` | resolved **within the document only** |
| `keywords` | `task_tags` / `tags` | a set; wire values are always `true` |
| `links` | `task_links` | full objects; `UNIQUE (task_id, link_key)` |
| *(anything unrecognized)* | `unknown_json` | verbatim, merged back on export |
| `Group.title` | `lists.title` | editable after import |
| `Group.uid` | `lists.source_uid` | **provenance only** |
| `Group.prodId` | `lists.source_app` | **provenance only** |

### 1.4 The date rule, restated because it is the easiest to get wrong

```text
internal                              wire
────────────────────────────────      ─────────────────────────────────────
due_date_day = 2027-03-14             "due": "2027-03-14T00:00:00",
due_minutes  = NULL                   "showWithoutTime": true

due_date_day = 2027-03-14             "due": "2027-03-14T10:00:00"
due_minutes  = 600                    (showWithoutTime omitted → false)
```

There is no date-only type in JSCalendar. `showWithoutTime: true` with a
**non**-midnight time is legal: keep the time, render as all-day.

```text
"due": "2027-03-14T10:00:00"          ✓
"due": "2027-03-14T10:00:00Z"         ✗ reject the property, keep the task, report
"due": "2027-03-14T10:00:00+01:00"    ✗ same
"due": "2027-03-14"                   ✗ same
```

### 1.5 App-local fields that must never appear on the wire

`tasks.id`, `lists.id`, `list_id`, `sort_order`, `recurrence_mode` (except as
`lumbrecode.de:recurrenceMode`, spec 0003 RRC-705), `archived_at`,
`deleted_at`, `source_uid`, `source_app`, `imported_at`,
`reminders.notification_id`, `reminders.fired_at`, and every settings key.
CT-15 / AC-55 assert this by scanning output, not by trusting review.

---

## 2. Warning taxonomy

Every tolerated loss is a counted, typed warning (INT-114). The type is an
**enum-like sealed class with a stable identity**; the German or English text
is produced at display time. An English string is never stored or logged.

```dart
sealed class ImportWarning { const ImportWarning(); }

final class SkippedEntry          extends ImportWarning { … }  // unknown @type in entries
final class TruncatedTitle        extends ImportWarning { … }  // > 200 chars
final class ClampedValue          extends ImportWarning { … }  // percentComplete out of range
final class RejectedDateProperty  extends ImportWarning { … }  // Z or offset on start/due
final class UnsupportedRecurrence extends ImportWarning { … }  // hourly, count, until, …
final class UnresolvedParent      extends ImportWarning { … }  // relatedTo target absent
final class ContradictoryRelation extends ImportWarning { … }  // A parent-of-B and B parent-of-A
final class ExplicitNull          extends ImportWarning { … }  // null treated as absent
final class UnknownTimeZone       extends ImportWarning { … }  // id not in the database
final class UnsupportedBodyFormat extends ImportWarning { … }  // text/html or other text/*
final class DroppedOverrides      extends ImportWarning { … }  // recurrenceOverrides not kept
final class RejectedTreeViolation extends ImportWarning { … }  // repository refused the shape
final class DowngradedUpsert      extends ImportWarning { … }  // INT-142
```

Each carries the affected task's **title for display** and nothing that would
be written to a log. `"Imported 4 of 5 tasks. 1 recurring task was imported
without its repetition."` is the shape of the summary.

---

## 3. Import and export formats

### 3.1 Media types

| Payload | Media type |
|---|---|
| one task | `application/jscalendar+json;type=task` |
| a list | `application/jscalendar+json;type=group` |
| an envelope | `application/cloudevents+json` |
| a batch | `application/cloudevents-batch+json` |

File extension: `.jscalendar.json` (`.lcexchange.json` for an envelope).
Charset: always UTF-8.

Android matches the **base** media type, so the single filter
`application/jscalendar+json` covers both `;type=` parameters. A receiver must
not assume the parameter is present (INT-401 sniffs the shape instead).

### 3.2 Import pipeline

```text
intent (ACTION_SEND | ACTION_SEND_MULTIPLE)
     ▼  own platform channel, MainActivity, singleTop        ADR-0013
read the delivered URI via ContentResolver, hard 256 KiB cap while reading
     ▼
classify: plain JSCalendar | CloudEvent | batch               INT-401
     ▼
validate — envelope first, then payload, total                INT-402
     ▼
decode tolerantly, collecting typed warnings                  INT-114
     ▼
IMPORT REVIEW  (a route, no bypass, no auto-import)           INT-208, INT-309
     │ user confirms
     ▼
ONE transaction: create the list, create the tasks,
                 resolve parents within the document          INT-207
     ▼
report what was imported and what was lost                    INT-209
     ▼
consume the intent exactly once                               INT-306
```

Nothing is written before the confirmation. Nothing is half-written after a
rejection.

### 3.3 Export pipeline

```text
scope: one task | a selection | a list
     ▼
build the document (pure Dart, deterministic, testable)
     ▼
UNSKIPPABLE PREVIEW naming what leaves the device             INT-507
     │ user confirms
     ▼
write <cacheDir>/share/<name>.jscalendar.json  (app-private)  INT-504
     ▼
ShareDocument seam                                            INT-505
     ▼  share_plus 12.x
SharePlus.instance.share(
  ShareParams(files: [XFile(path, mimeType: mediaType)]))     INT-506
```

The seam type, extended in slice 0 from the template's existing `ShareText`:

```dart
final class SharePayload {
  final String fileName;    // *.jscalendar.json
  final String mediaType;   // application/jscalendar+json;type=task|group
  final String bytesUtf8;
}
typedef ShareDocument = Future<void> Function(SharePayload payload);
```

**Verified against the resolved package** (`share_plus 12.0.2`,
`share_plus_platform_interface 6.1.0`): `ShareParams` takes
`List<XFile>? files` and `List<String>? fileNameOverrides`; `XFile` is
re-exported from `package:share_plus/share_plus.dart`, so **no separate
`cross_file` dependency is needed**. The guide's 10.x
`Share.shareXFiles(...)` snippet does not compile here.

### 3.4 The envelope

```json
{
  "specversion": "1.0",
  "id": "…",
  "source": "https://lumbrecode.de/apps/todo",
  "type": "de.lumbrecode.exchange.jscalendar.import.v1",
  "time": "2026-08-25T09:12:00Z",
  "datacontenttype": "application/jscalendar+json;type=group",
  "dataschema": "https://lumbrecode.de/schemas/jscalendar-task/v1/jscalendar-task-v1.schema.json",
  "subject": "<data.uid>",
  "sourceappid": "de.lumbre.code.todo",
  "sourceversion": "3.1.0",
  "data": { "@type": "Group", "…": "…", "sequence": 1 }
}
```

Structural promise: **the envelope is strippable.** A receiver that discards
it and keeps `data` has valid JSCalendar and has lost only provenance. That
rule decides where every field goes — which is why `recurrence_mode`, if it
ever travels, goes on the **payload** as `lumbrecode.de:recurrenceMode` and
never as a CloudEvents attribute.

**Batch is not Group.** A batch means "these messages travel together"; a
`Group` means "these objects belong together". A birthday's to-do list is a
Group; three unrelated shares at once are a batch (INT-408).

### 3.5 `import.v1` versus `upsert.v1`

The one place two binding documents disagree. Analysis in the audit §4.8;
decision in INT-141..143.

| `type` | Profile meaning | This app does |
|---|---|---|
| `…import.v1` | create a new local copy, never match | import a new copy |
| `…upsert.v1` | receiver **may** create or update the matched object | import a new copy, plus a `DowngradedUpsert` warning |

Rejecting `upsert.v1` would fail golden fixture `20-task-in-envelope.json`.
Implementing the update would break the guide's most emphatic rule (§10.2).
`upsert` grants a *permission*, not an instruction, and a receiver without a
matching model may decline it — saying so in a warning is more honest than
either silently copying or refusing the document.

**The app implements no matching model at all** (INT-143): no
`(sourceappid, uid)` index, no tombstones, no sequence comparison. `sequence`
is stored and read only by the exporter.

---

### 3.6 Packing lists (guide §2.9)

A packing list from Packzeit is a v1 `Group`; nothing in the storage model is
new. What the importer must hold to:

| Wire | Storage |
|---|---|
| `Group` | one `lists` row; `title` is the list name |
| a section (parent `Task`) | a `tasks` row with `parent_task_id` null; children point at it |
| an item (sub-task) | a `tasks` row with `parent_task_id` set; **two levels, never more** |
| a flat list | root tasks without a parent |
| `progress` + `percentComplete` | stored as sent (`in-process` keeps `1..99`) |
| `keywords` `to-buy`, `last-minute`, category slug | `tags` / `task_tags`, stored verbatim (see the open question below); an unknown slug is shown as it is |
| `due` on a `last-minute` item | `due_date_day` with `show_without_time` set and `due_minutes` NULL; never promoted to a time |
| `priority` | the integer received is stored; the band is a view |
| `title` (`T-Shirt ×3`, `Socken 3 Paar`, `Wasser 1,5 l`) | stored and displayed **unchanged**; never parsed into name / amount / unit |
| `prodId` (`Group` and task) | `lists.source_app` as provenance only; no branch on it, anywhere |

A section is an ordinary parent task. Its stored `progress` is whatever the
file said; the app may recompute it with the guide's rule (§2.9.2), but must
not rely on the file's value. Several files of one trip are several lists; no
code looks at title prefixes. `lumbrecode.de:quantity` is reserved and not
emitted yet; when it is, it wins over the title for readers that know it.

**Open for slice 8:** keywords map to the user's own tags (spec 0001 §1.4). A
packing list would add `to-buy`, `last-minute` and a slug per category to a
user's tag list, with no way to tell them from tags the user made. Slice 8
decides whether such keywords are tags, a separate keyword column, or tags
flagged as imported. Recorded in
`docs/template-feedback/2026-10-09-packing-keywords-collide-with-user-tags.md`.

## 4. Versioning

- **No `schemaVersion` bump** is owned by this spec.
- **Payload version** travels in `dataschema`; **profile version** in the
  `type` suffix. There is no version field inside a JSCalendar document
  (guide §14.1) and none is invented here.
- **Contract v1 defines no LumbreCode vendor extension.** If one ever becomes
  necessary it must be namespaced (`lumbrecode.de:name`), documented in the
  contract *before* being emitted, and ignorable without loss of standard
  content.
- **A future contract version's new property is simply an unknown property**
  to this app: kept verbatim, ignored for behaviour, written back (INT-104).
  That is what makes forward compatibility a property of the design rather
  than a promise.

---

## 5. Compatibility notes

- **`.lumbrecode/` does not exist here.** The guide §15.3 says fixtures arrive
  through a baseline sync; verified absent in this repository. They are
  vendored with provenance and a checksum test (INT-601, ADR-0014).
- **`android/` is not committed.** The intent filter is a bootstrap-script
  change, in both the bash and the PowerShell path (INT-303, ADR-0013).
- **`share_plus` 12.0.2 here versus 10.1.4 in WasThereSomething** — see 3.3.
- **KI-001** — `path_provider` and `mime` are runtime-only and carry no
  analyzer constraint; resolve against the tree before adoption anyway
  (library-evaluation rule 10).
- **KI-008** — `updated` is second-precision by contract, which happens to
  match Drift's storage. It is never a sort key.
- **Determinism** requires a stable key order and stable collection ordering;
  a `Map` iteration order that depends on insertion must not leak into
  output (CT-14).

---

## 6. Test fixtures

### 6.1 Vendored golden fixtures

`.lumbrecode/schemas/` (read by directory, not vendored):

```text
jscalendar-task/v1/
  jscalendar-task-v1.schema.json
  examples/            01..15, 50, 51            (17 accepted)
                       90..96                    (7 rejected)
lumbrecode-exchange/v1/
  lumbrecode-exchange-v1.schema.json
  examples/            01..09, 20, 21            (11 accepted)
                       90..99                    (10 rejected)
PROVENANCE.md          source repo, commit hash, date, checksum manifest
```

45 fixtures total. `PROVENANCE.md` plus a checksum test makes a silent
divergence fail CI (INT-603). **A fixture change happens in both repositories
in the same change** — otherwise the contract test stops proving anything.

### 6.2 The contract-test matrix

| # | Test | Owner | Level |
|---|---|---|---|
| CT-1 | every accepted fixture validates against the schema | `task_interchange` | ci |
| CT-2 | every `9x-invalid-` fixture is rejected, typed and readable | `task_interchange` | unit |
| CT-3 | `encode(decode(fixture))` semantically equals the fixture | `task_interchange` | unit |
| CT-4 | `decode(encode(model))` equals the model | `task_interchange` | unit |
| CT-5 | recurrence round trip | `task_interchange` | property |
| CT-6 | date round trip, all four shapes | `task_interchange` | property |
| CT-7 | tree safety over 10 000 assignments | `task_interchange` | property |
| CT-8 | parent/child survives a Group round trip | app | integration |
| CT-9 | Markdown body byte-identical | `task_interchange` | unit |
| CT-10 | unknown property survives import → export | `task_interchange` | unit |
| CT-11 | a `uid` seen twice creates two objects | **app** | integration |
| CT-12 | a rejected document leaves zero rows | **app** | integration |
| CT-13 | every loss produces a counted warning | `task_interchange` | unit |
| CT-14 | determinism: byte-identical output | `task_interchange` | unit |
| CT-15 | no app-local field in any document | `task_interchange` + app | unit |
| CT-16 | every accepted `Group` fixture imports to its expected summary | `task_interchange` (decoder) + **app** (database) | integration |

CT-16 is checked twice: in the library against the decoder, and here against
the database once slice 8 lands (`test/interop/packing_list_contract_test.dart`
covers the decoder half in the template today).

CT-11 and CT-12 are the app's because they are about transactions and rows,
not about the codec.

### 6.3 Fuzz corpus

Generated, not committed: truncations at random offsets, single-byte flips,
oversized documents, 200-level nesting, duplicate member names, unpaired
surrogates, and every fixture with one random property removed. 10 000 cases;
**no input may produce an unhandled exception** (INT-604, guide §12.3).

### 6.4 App-side fixtures

- `importTwice` — the same `Group` imported twice, for CT-11.
- `importRejected` — a five-task document whose fifth entry rejects the
  document, for CT-12.
- `importCrafted` — asserted self-parent, cycle and three-level nesting, for
  AC-23.
- `importUpsert` — `20-task-in-envelope.json`, for AC-50.
- `oversized` — 256 KiB + 1 byte, for AC-21.
