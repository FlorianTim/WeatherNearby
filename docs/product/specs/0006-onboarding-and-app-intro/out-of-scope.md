# Out of scope: App intro (onboarding)

| Excluded | Why |
|---|---|
| **Requesting permissions during the intro** | Forbidden, not merely excluded. The permissions contract requires just-in-time requests by the feature that needs them; an up-front batch is the pattern that produces permanent denials. |
| **A guided setup assistant** | The reference app has one because it has something to set up (calendars, sources). The template has nothing to configure, and a setup assistant with no steps is worse than none. Revisit when a derived app needs it. |
| **Feature tours / coach marks** on real screens | A different mechanism with different state (per-feature "seen" flags) and a much larger maintenance surface. |
| **Animations or Lottie content in the intro** | The splash already owns the branded animation. A second animated surface doubles the assets a derived app has to replace. |
| **A "what's new" screen after an update** | Needs a version-comparison rule and per-version content. Separate feature, separate spec. |
| **Deep-linking into a specific intro page** | No caller needs it. |
| **Analytics on how far a user got** | The template has no telemetry, and adding a first consumer inside the intro would decide that question by accident. |
| **Localized illustrations** | Icons carry the pages; illustrations are per-app design work. |

## Deliberately different from the reference app

- **Reopening shows the intro now**, instead of resetting a flag so it
  appears on the next start (see `ux.md`). Same intent, immediate result,
  testable without a restart.
- **The intro carries the language and appearance choice.** The reference app
  keeps that in settings only. The template's first-run flow has always let a
  user pick a language before anything else, and this is where that goes.
