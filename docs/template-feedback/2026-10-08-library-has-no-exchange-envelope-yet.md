# `task_interchange` 0.1.0 has no Exchange (CloudEvents) envelope, so the exchange fixtures cannot be fully tested

- **Date:** 2026-10-08
- **Area:** Library
- **Severity:** `idea`
- **Template version:** 3.2.1 (commit f613988 plus uncommitted work)
- **Status:** open

## Observed

`task_interchange.dart` lists the envelope as "later". The template's contract test can only unwrap `data` of the task and group envelopes (20, 21) and check malformed JSON; the other exchange fixtures (events, batch, invalid envelopes 91 to 99) are not exercised through the library. The packing-list import (slice 8) needs envelope and batch unwrapping.

## Workaround

None; the test group name says so.

## Smallest generic change

`flutter-libraries`: an `ExchangeEnvelope` decode with the documented rejections, in the same family, before slice 8.
