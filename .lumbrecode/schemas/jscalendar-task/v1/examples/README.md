# Golden fixtures — LumbreCode Task Interchange v1

These files are the **test inputs** of the reference implementation, not
copies of them. If a fixture changes, a test changes. Documentation and
tests cannot drift.

Both apps — WasThereSomething and the LumbreCode To-do app — load the same
files. That is what makes "compatible" a test result rather than a claim.

## Naming

| Prefix | Meaning |
|---|---|
| `0x` – `1x` | single `Task` documents; **must be accepted** |
| `5x` | `Group` documents; **must be accepted** |
| `9x-invalid-` | **must be rejected** by a conforming validator |
| `expected/` | not fixtures: the expected import result of each accepted `Group` fixture |

## Accepted fixtures

| File | Covers |
|---|---|
| `01-task-minimal.json` | the smallest legal Task: `@type`, `uid`, `updated`, `title` |
| `02-task-markdown.json` | `description` + `descriptionContentType: text/markdown` |
| `03-task-start-only.json` | `start` with a time, no `due` |
| `04-task-due-date-only.json` | `due` at `T00:00:00` with `showWithoutTime: true` — the date-only form |
| `05-task-due-with-time.json` | `due` with a time and an explicit `timeZone` |
| `06-task-start-and-due.json` | both, plus `estimatedDuration` — and **not** a time block |
| `07-task-completed.json` | `progress: completed`, `percentComplete: 100`, `progressUpdated` |
| `08-task-percent-complete.json` | `progress: in-process` with a partial percentage |
| `09-task-priority.json` | `priority` and `keywords` |
| `10-task-parent.json` | a parent carrying two `child` relations |
| `11-task-subtask.json` | a child carrying one `parent` relation |
| `12-task-recurring.json` | weekly `recurrenceRules` + `recurrenceOverrides` with a completed instance and an excluded instance |
| `13-task-recurring-monthly-ordinal.json` | `interval` and `NDay.nthOfPeriod` (every other month, first Saturday) |
| `14-task-links.json` | a plain web `Link` |
| `15-task-future-attachment.json` | two `Link`s with `rel: "enclosure"` — the attachment shape, prepared for ~2.7, valid today |
| `50-group-simple.json` | a `Group` of three flat tasks |
| `51-group-nested-tasks.json` | a `Group` with a parent, two children and a sibling; both relation directions present |
| `52-group-packing-list-by-category.json` | packing list, sections "Kleidung" and "Technik" as parent tasks; `×3`, litre and pair quantities in titles; packed, partly packed and untouched items; `to-buy`; `last-minute` with a date-only `due`; category keywords; priorities `1`, `3`, omitted and `9`; both relation directions |
| `53-group-packing-list-single-set.json` | a split list ("Urlaub Italien - Medikamente"): flat, no parent tasks |
| `54-group-packing-list-by-person.json` | sections are person names and "Alle"; `last-minute` without a `due` |

## Rejected fixtures

| File | Why it must be rejected |
|---|---|
| `90-invalid-missing-type.json` | no `@type` on the top-level object |
| `91-invalid-due-with-offset.json` | `due` carries a UTC offset; `LocalDateTime` has none |
| `92-invalid-progress-value.json` | `delegated` is not in the IANA `progress` registry |
| `93-invalid-empty-title.json` | `title` must be 1..200 characters |
| `94-invalid-percent-out-of-range.json` | `percentComplete` above 100 |
| `95-invalid-group-without-entries.json` | a `Group` with an empty `entries` array |
| `96-invalid-uid-not-uuid.json` | `uid` is not a canonical RFC 4122 v4 UUID |
| `97-invalid-keyword-value-false.json` | a `keywords` value of `false`; keywords are a set, values are always `true` |

Note the difference between **schema rejection** and **tolerant reading**
(interoperability guide §5): these eight are malformed *emissions*. A
receiver reading a document from an unknown producer still keeps unknown
*properties* rather than rejecting the document.

## Expected summaries

`expected/<fixture>.summary.json` exists for **every accepted `Group`
fixture** (`50`–`54`). It is the "semantically identical" definition of
guide section 12.2 as data: what a receiver must end up with after importing
the fixture, in a form that does not depend on any language or database.

```json
{
  "summaryVersion": 1,
  "fixture": "52-group-packing-list-by-category.json",
  "kind": "group",
  "title": "Urlaub Italien",
  "tasks": [ { …node… } ]
}
```

A node:

| Key | Value |
|---|---|
| `title` | the task title |
| `description`, `descriptionContentType` | body and its type; `null` without a body; a body without a type is `text/plain` |
| `start`, `due` | `YYYY-MM-DD` for the date-only form (`showWithoutTime` at midnight), else the local date-time; `null` when absent |
| `timeZone` | IANA id or `null` |
| `progress` | the registered value; absent is `needs-action` |
| `percentComplete` | effective: the stated value, else `100` for `completed`, else `0` |
| `priority` | the **band**: `high` (1–4), `normal` (5), `low` (6–9), `none` (absent or 0) |
| `keywords` | sorted array |
| `links` | array of `href`, `rel`, `title`, `contentType`, `size`, sorted by `href` |
| `children` | nodes, same shape |

What is **not** in it: `uid`s, `prodId`, timestamps, relations (they become the
tree), and the order of `entries`. Siblings are ordered by `title` (code point
order), then by their JSON text; compare them as a set. A section's
`progress` is compared like any other value — a receiver that derives it must
use the guide's rule (§2.9.2).

Every receiving app imports each fixture and compares the result to its
summary (guide CT-16). Because the summaries sit in a sub-directory, a test
that globs only `examples/*.json` does not mistake them for fixtures; one that
globs recursively must exclude `expected/`.

The validator derives the summary from the fixture and fails if the committed
file differs. After a deliberate fixture change, review the diff, then:

```bash
python scripts/validate_interop_contracts.py --update-summaries
```

## Profile rules

JSON Schema cannot express these, so they are checked in code
(`scripts/validate_interop_contracts.py`) on every accepted `Group` fixture,
and there is deliberately **no `9x-invalid-` fixture** for them:

- at most two levels (a three-level tree is schema-valid, and is proven
  rejected by an in-memory self-test, not by a fake fixture);
- a single parent, relations resolve inside the document, both directions agree;
- for `*packing-list*` fixtures: derived section progress, `percentComplete`
  per state, `due` only on date-only `last-minute` items, and no
  `lumbrecode.de:quantity` (reserved, guide §2.9.7).

## Data in the fixtures

All names, dates and URLs are fictional (Z-007). Hosts use the reserved
`example.invalid` domain and resolve nowhere. Every UUID is fixed so the
files stay diffable and so both apps can assert on them.

## Running the validation

```bash
python -m pip install jsonschema
python scripts/validate_interop_contracts.py
```

All 20 accepted fixtures validate, all 8 `9x-invalid-` fixtures fail, and every
expected summary matches (verified 2026-10-02).

In a consuming app the same files arrive at `.lumbrecode/schemas/jscalendar-task/v1/`
through the baseline sync. The app's own suite decodes each accepted fixture,
re-encodes it, and compares the import with its summary; each `9x-invalid-`
fixture must be rejected with a readable, categorized error (spec 0037,
TSH-604, AC-03/AC-24).
