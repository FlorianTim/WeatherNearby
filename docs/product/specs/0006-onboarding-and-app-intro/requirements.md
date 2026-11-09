# Requirements: App intro (onboarding)

Prefix `ONB-`.

## When it is shown

| ID | Requirement |
|---|---|
| ONB-001 | The intro MUST be shown after the splash when `app.onboardingCompleted` is not `true`. |
| ONB-002 | It MUST NOT be shown when the flag is `true`. |
| ONB-003 | A fatal startup failure MUST take precedence: the recovery screen wins over the intro. |
| ONB-004 | The routing decision MUST be synchronous at the moment the splash finishes — no additional loading screen between splash and intro. |
| ONB-005 | The intro MUST be reopenable from the settings hub at any time, whatever the flag says. |

## Content

| ID | Requirement |
|---|---|
| ONB-010 | The intro MUST have at least a welcome page, a data-handling page and a closing page. |
| ONB-011 | One page MUST let the user choose language and appearance, using the same option tiles as the settings hub. |
| ONB-012 | Changing the language on that page MUST take effect immediately, including on the intro itself. |
| ONB-013 | The intro MUST NOT request any runtime permission (permissions contract: just-in-time, by the feature that needs it). |
| ONB-014 | Every page MUST be readable without scrolling on a phone-sized surface at the default text scale, and MUST scroll rather than overflow at larger scales. |

## Interaction

| ID | Requirement |
|---|---|
| ONB-020 | "Skip" MUST be available on every page and MUST have the same effect as finishing. |
| ONB-021 | The last page's primary action MUST be labelled as a start action, not as "next". |
| ONB-022 | A page indicator MUST show how many pages there are and which one is active. |
| ONB-023 | The indicator MUST NOT be the only cue: the primary button label changes on the last page. |
| ONB-024 | Swiping MUST move between pages, and the buttons MUST stay in sync with a swipe. |

## Persistence

| ID | Requirement |
|---|---|
| ONB-030 | Finishing or skipping MUST persist `app.onboardingCompleted = true`. |
| ONB-031 | If persisting fails, the user MUST still leave the intro. The worst acceptable outcome is seeing it again next start. |
| ONB-032 | Reopening the intro from settings MUST NOT clear the flag, and finishing it again MUST NOT change anything else. |
| ONB-033 | "Reset settings" (spec 0005, SET-037) MUST clear the flag, so the next start shows the intro again. |

## Accessibility

| ID | Requirement |
|---|---|
| ONB-040 | Skip and the primary action MUST be at least 48 dp tall. |
| ONB-041 | The page indicator MUST be excluded from semantics or carry a meaningful label — a row of dots read out as dots is noise. |
| ONB-042 | Icons on the pages are decorative and MUST NOT be announced. |
