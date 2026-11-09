# Golden fixtures — LumbreCode Exchange v1

These files are the **test inputs** of the reference implementation, not
copies of them. If a fixture changes, a test changes.

## Naming

| Prefix | Meaning |
|---|---|
| `0x` | event hand-offs; **must be accepted** |
| `2x` | task and task-list hand-offs; **must be accepted** |
| `3x` | blockers: appointments that block vacation planning; **must be accepted** |
| `9x-invalid-` | **must be rejected** by a conforming receiver |
| `91x-invalid-` | the same, continued: `90`–`99` are used up, so further rejected fixtures take three digits, still starting with `9` |
| `expected/` | not fixtures: the expected summary of each accepted fixture |

## Accepted

| File | Covers |
|---|---|
| `01-time-off-planned.json` | one-day period, `tentative` / `planned` |
| `02-time-off-approved.json` | the same kind at a higher `sequence`, `confirmed` / `approved` |
| `03-trip-planned.json` | a multi-day trip, not yet booked |
| `04-trip-booked.json` | the same trip, confirmed |
| `05-trip-booked-seq4-updated.json` | `sequence` 4 — the update-instead-of-duplicate case |
| `06-trip-cancelled.json` | `cancelled` in both `status` and the statusCategory |
| `07-batch-three-events.json` | three items in one batch, mixed types |
| `08-public-holiday.json` | a public holiday |
| `09-unknown-type-and-extensions.json` | **forward compatibility**: an unknown event-type URI, unknown envelope attributes and an unknown payload property — all accepted and preserved |
| `20-task-in-envelope.json` | a JSCalendar `Task` travelling in the envelope |
| `21-task-group-in-envelope.json` | a whole `Group` of tasks in the envelope |
| `30-blocker-tentative.json` | a blocker (`lumbrecode.de:blocksTimeOff: true`), `tentative` |
| `31-blocker-pending.json` | a blocker, `pending` — valid; `status` is `tentative` |
| `32-blocker-confirmed.json` | a blocker, `confirmed` |
| `33-blocker-update-seq2.json` | the uid of `30` at `sequence` 2, now confirmed and longer: an update |
| `34-blocker-cancelled.json` | the uid of `31` at `sequence` 2, `cancelled`: how a deleted event is withdrawn |
| `35-appointment-without-marker.json` | an event **without** the marker: a vacation planner ignores it |
| `36-blocker-mark-withdrawn.json` | the uid of `32` at `sequence` 2 with `blocksTimeOff: false`: the mark is withdrawn, the event stays |
| `37-batch-blockers-and-unmarked.json` | a batch of three blockers and one unmarked event |
| `38-blocker-epoch-millis-sequence.json` | a blocker as the real Packzeit exporter writes it (`sourceappid` `de.lumbre.code.packzeit`): `sequence` is the edit time in epoch milliseconds (`1785576615000`, above 2^32), no event type |
| `39-blocker-epoch-millis-sequence-update.json` | the uid of `38` one week later at a higher epoch-millisecond `sequence`, now `P7D`: an update must still win; a receiver must not read `sequence` as a 32-bit integer |

## Rejected

| File | Why |
|---|---|
| `90-invalid-malformed-json.json` | truncated JSON |
| `91-invalid-specversion.json` | `specversion` other than `1.0` |
| `92-invalid-unknown-type.json` | a `type` outside the known set |
| `93-invalid-source-is-object.json` | `source` must be a URI, not an object |
| `94-invalid-unknown-status-category.json` | `statusCategory` outside the closed vocabulary |
| `95-invalid-missing-dataschema.json` | `dataschema` is mandatory in this profile |
| `96-invalid-payload-without-sequence.json` | an exchanged payload must carry `sequence` |
| `97-invalid-payload-start-with-z.json` | `start` is a `LocalDateTime`; offsets and `Z` are not allowed |
| `98-invalid-unknown-datacontenttype.json` | `datacontenttype` outside the known set |
| `99-invalid-batch-duplicate-uids.json` | the same `data.uid` twice in one batch |
| `910-invalid-blocker-marker-not-boolean.json` | `lumbrecode.de:blocksTimeOff` must be a boolean |
| `911-invalid-blocker-batch-update-and-cancel-same-uid.json` | the old state and its cancellation of one uid in one batch is a duplicate `uid` (`99`'s rule): a producer sends only the latest state |

## Expected summaries

`expected/<fixture>.summary.json` exists for **every accepted fixture**: the
result a receiver must reach after reading it, as language-neutral data. The
validator derives the summary and fails if the committed file differs; after a
deliberate change, review the diff and run
`python scripts/validate_interop_contracts.py --update-summaries`.

```json
{
  "summaryVersion": 1,
  "fixture": "33-blocker-update-seq2.json",
  "messages": [
    { "type": "…upsert.v1", "sourceappid": "…", "data": { …payload… } }
  ]
}
```

`messages` is compared as a set (batch order carries no meaning). `type` and
`sourceappid` are in it because the matching key is `(sourceappid, uid)`.
A payload is one of:

| `kind` | Keys |
|---|---|
| `event` | `uid`, `sequence` (the revision half of the matching key), `title`, `description`, `start` (`YYYY-MM-DD` when date-only), `duration`, `statusCategory` (effective: the vendor value, else derived from `status`), `statusCode`, `eventTypes` (sorted URIs), `blocksTimeOff` (absent is `false`) |
| `group` / `task` | as in the task fixtures' README, nested under `data` |

What a vacation planner does with a blocker follows from the summary:
import iff `blocksTimeOff` is `true` — see `docs/LUMBRECODE_EXCHANGE.md`.

## Two kinds of strictness

Do not confuse them:

- **Emission** is strict. The standalone task and event schemas close
  `additionalProperties`, so a conforming producer writes only defined
  properties.
- **Reception** is tolerant. An unknown *property* inside a payload is kept
  verbatim, never a reason to reject — which is why
  `09-unknown-type-and-fields.json` must be accepted.

The validator applies exactly this split: payloads inside an envelope are
validated in relaxed mode, standalone fixtures in strict mode.

## Data

All names, dates and identifiers are fictional. No fixture contains real
personal data.

## Running

```bash
python -m pip install jsonschema
python scripts/validate_interop_contracts.py
```
