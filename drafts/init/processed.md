# Processing log for `drafts/init/`

One row per piece of input material, so a half-finished initialization can be
picked up later — and so "is this folder safe to delete?" has an answer that
is not a guess.

`drafts/init/` may be deleted when every row says **done** and no row's
target is still `—`.

| Material | Kind | Processed into | Status |
|---|---|---|---|
| _(nothing yet — the template ships this folder empty)_ | | | |

## Status values

| Status | Meaning |
|---|---|
| `open` | Not looked at yet |
| `in spec` | Turned into a spec or an OpenSpec entry, spec not approved yet |
| `done` | Approved spec exists, or the asset is in its final place |
| `dropped` | Deliberately not used — with a reason in the row |

## Example

| Material | Kind | Processed into | Status |
|---|---|---|---|
| `spec/requirements-v2.pdf` | requirements | `openspec/apps/mytracker.openspec.yaml`, specs `0001`–`0004` | done |
| `mockups/dashboard.png` | design | `design/mockups/` + manifest entry | done |
| `icons/app_icon_1024.png` | artwork | `apps/mobile_app/assets/images/app_icon.png` | done |
| `notes/voice-memo.md` | notes | nothing — superseded by the requirements document | dropped |
