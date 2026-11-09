# Packing-list keywords have no home that is not the user's tag list

- **Date:** 2026-10-09
- **Area:** Spec 0001 / 0004 data model
- **Severity:** `question`
- **Template version:** 3.2.1 (commit f613988 plus uncommitted work); baseline 1.5.2 -> 1.6.0
- **Status:** open, deferred to slice 8

## Observed

Spec 0004 maps `keywords` to `task_tags` / `tags`, and spec 0001 makes tags the user's own, name-unique, editable vocabulary. A Packzeit list carries `to-buy`, `last-minute` and a category slug (`clothing`, `health_medication`, ...) per item. Importing one list would put those into the user's tag list, indistinguishable from tags they made, and "unknown slugs are shown as they are" (guide 2.9.3) means the vocabulary is open-ended.

## Workaround

None needed yet (no import). Recorded as an open design question in spec 0004 data contract §3.6 and in the plan change in plan 0001.

## Smallest generic change

Decide in slice 8: (a) tags, accepted as-is; (b) a keyword column kept apart from tags and shown read-only; (c) tags flagged `imported`. Either way the guide should say whether a receiver is expected to give `to-buy` and `last-minute` any behaviour or only to keep them.

## Check that would catch a recurrence

AC-68 (stored verbatim) plus a test that importing a packing list does not change the tag count shown in the user's tag manager, if (b) or (c) is chosen.
