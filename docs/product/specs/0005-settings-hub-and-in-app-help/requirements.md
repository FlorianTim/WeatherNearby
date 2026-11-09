# Requirements: Settings hub, in-app help and privacy page

Prefix `SET-`. **MUST** is binding, **SHOULD** is a strong default a derived
app may override with a reason.

## Hub structure

| ID | Requirement |
|---|---|
| SET-001 | The settings page MUST be reachable at any time from the app's main screen and MUST NOT be part of the startup path. |
| SET-002 | The page MUST NOT carry a "Continue"/wizard action. Navigation back is the system back affordance. |
| SET-003 | Options that a user changes often — language and appearance — MUST be settable on the hub itself, without a further tap into a sub-page. |
| SET-004 | Everything else MUST be a row that opens a dedicated page, so the hub stays scannable as the app grows. |
| SET-005 | Rows MUST be grouped under section headings. The order is: language, appearance, help, data and privacy, Pro, support, development. |
| SET-006 | A section whose rows are all unavailable MUST NOT render its heading. |

## Language and appearance

| ID | Requirement |
|---|---|
| SET-010 | "Follow the device" MUST be the first option and the default of both settings (localization contract). |
| SET-011 | Language names MUST be shown in their own language ("Deutsch", not "German"). |
| SET-012 | The selected state MUST be conveyed by an icon **and** a container colour, never by colour alone (accessibility contract, rule 9). |

## Help

| ID | Requirement |
|---|---|
| SET-020 | The app MUST bundle a user manual and an FAQ as Markdown assets and render them in-app. No network access. |
| SET-021 | Assets MUST follow `assets/help/<document>_<languageCode>.md`. |
| SET-022 | An unsupported app language MUST fall back to the English asset rather than failing. |
| SET-023 | A missing or unreadable asset MUST show a readable error message, never a raw exception or an empty screen. |
| SET-024 | Links inside a help document MUST open through the scheme-allowlisted launcher seam. A refused scheme MUST report why. |
| SET-025 | Help documents MUST NOT be reachable only from help — the About page's existing external FAQ link stays, as the online counterpart. |

## Data and privacy

| ID | Requirement |
|---|---|
| SET-030 | An in-app privacy page MUST state, in the app's language, what the app stores and where. |
| SET-031 | The page MUST render an overview of the permissions the app holds, with the current state per permission. |
| SET-032 | When the app declares no permissions, the overview MUST be omitted — not rendered empty. |
| SET-033 | The page MUST link the published privacy policy and the published data-deletion page, derived from `AppIdentity.links`. |
| SET-034 | The page MUST offer a prefilled mail to the privacy mailbox, carrying app version and language only — never personal data. |
| SET-035 | The page MUST own the destructive actions, in a visually separated danger section. |
| SET-036 | **Delete app data** MUST clear the content database only, and its subtitle MUST say that settings survive. |
| SET-037 | **Reset settings** MUST clear every key in the `AppSettings` register and MUST NOT touch content. |
| SET-038 | Each destructive action MUST confirm first, and the dialog MUST name the consequence instead of asking "are you sure?". |
| SET-039 | After a successful destructive action the app MUST confirm it happened, and screens holding the removed data MUST refresh. |

## Support

| ID | Requirement |
|---|---|
| SET-040 | The hub MUST link the existing About page (external links, support mailboxes, licences, version). |
| SET-041 | A "report the last error" row MUST be shown **only** while an uncaught error is buffered, and MUST open a prefilled bug mail. |

## Development

| ID | Requirement |
|---|---|
| SET-050 | A diagnostics page MUST list every setting in the register with its key, its raw stored value and its default. |
| SET-051 | The diagnostics row and route MUST NOT exist in release builds. |
| SET-052 | Diagnostics MUST be read-only. Changing a value is a settings action, not a diagnostic one. |

## Shared widgets

| ID | Requirement |
|---|---|
| SET-060 | The selectable option card and the hub section/row widgets MUST live in `packages/design_system`, not in the example app. |
| SET-061 | They MUST take their colours and text styles from the ambient `Theme`, with no hardcoded value. |
| SET-062 | They MUST render without overflow at `TextScaler.linear(2.0)` on a phone-sized surface. |
