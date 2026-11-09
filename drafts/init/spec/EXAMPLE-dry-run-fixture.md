# Water Log — minimal app brief (template-internal fixture)

> **This is not a real app.** It is the smallest complete input the template
> initializer accepts, kept so the `dry-run` mode can be rehearsed against the
> real classification table without inventing a spec each time.
>
> **Delete this file when real input arrives.** It exists only in the template
> repository; a derived app has no reason to keep it.
>
> The rehearsal it drives is written up in
> `docs/delivery/reviews/2026-08-27-initializer-dry-run.md`.

## The app

Water Log records how much water you drink during the day. One screen: a
running total for today, a few buttons to add a glass, and a list of the last
seven days. Nothing is uploaded, nothing is shared, there is no account.

## Identity

| Field | Value |
|---|---|
| Display name | Water Log |
| Slug | `waterlog` |
| Web slug | `water-log` |
| Package | `de.lumbre.code.waterlog` |
| Platforms | Android |
| Backend | none |

## Key features

1. **Today's intake** — add a drink in one tap, see the day's total.
2. **The last seven days** — one row per day with its total.

## Constraints

- Everything stays on the device; no analytics, no crash reporting, no network.
- The app holds no runtime permission, so the privacy page's permission
  section stays empty.

## Deliberately minimal

One entity, one screen, no backend, no permissions, no branding assets. A
richer brief would exercise the plan & spec phase; this one exercises only the
part the rehearsal is about — what the initializer keeps and what it deletes.
