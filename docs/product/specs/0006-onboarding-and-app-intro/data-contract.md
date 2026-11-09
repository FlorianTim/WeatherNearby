# Data contract: App intro (onboarding)

## Stored data

One key, in the existing `AppSettings` register:

| Key | Type | Encoding | Default |
|---|---|---|---|
| `app.onboardingCompleted` | `bool` | `"true"` / `"false"` | `false` |

Encoding notes:

- The stored form is the literal string, never `1`/`0` and never a locale-
  dependent representation.
- `decode` returns `true` only for the exact string `"true"`. Anything
  else — an old format, a corrupted value, a value written by a newer app —
  degrades to the default, which shows the intro again. That is the safe
  direction: showing an introduction one extra time is recoverable, hiding it
  from a first-time user is not.

## Read timing

The flag is read through `KeyValueStore`, whose persistent implementation is
installed by `bootstrap()` before the first frame. `SettingDef.read` is
synchronous, so the routing decision at the end of the splash needs no
`await` and no intermediate loading state (ONB-004).

## Relationship to the other stored state

| Action | `app.onboardingCompleted` |
|---|---|
| Finish or skip the intro | set to `true` |
| Reopen from settings, then finish | stays `true` |
| Delete app data (spec 0005, SET-036) | untouched — it is a setting, not content |
| Reset settings (spec 0005, SET-037) | removed, so the next start shows the intro |

## What the intro must not write

Nothing else. It sets the flag and — on its language and appearance page —
the two settings that page owns. It creates no content rows, no sample data
and no analytics record.
