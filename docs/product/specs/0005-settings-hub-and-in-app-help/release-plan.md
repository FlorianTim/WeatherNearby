# Release plan: Settings hub, in-app help and privacy page

Target release **3.2.1**. Slices 1–4 of
`docs/delivery/implementation-plans/0002-settings-and-app-shell.md`.

## Phase 1 — Building blocks (slice 1)

`packages/design_system` gains `AppOptionTile`, `AppSettingsSection` and
`AppSettingsTile`, plus their tests. `_OptionTile` is removed from
`settings_page.dart` in the same change, so no copy survives.

**Done when:** the design-system suite covers selection state, empty
sections and text scaling, and the existing settings tests still pass
against the extracted widget.

## Phase 2 — The hub (slice 2)

The settings page is rebuilt around the sections, the routes for the new
pages are added, and the debug-only diagnostics page ships with it. The
"Continue" button and the post-splash detour disappear; the app's main
screen keeps the entry point.

**Done when:** the hub renders every section in order, the development
section is provably absent in a release build, and the accessibility suite
covers the rebuilt page.

## Phase 3 — Help (slice 3)

`HelpDocumentPage`, the four Markdown assets, the pubspec asset entry and
the locale-fallback rule.

**Done when:** both documents render in both languages, an unsupported
language falls back to English, a missing asset shows the error text, and a
refused link scheme is reported.

## Phase 4 — Privacy and data (slice 4)

`PrivacyPage` with the four sections, the permission-overview seam, and both
destructive actions moved into it.

**Done when:** both actions confirm, do exactly what their subtitle claims,
and refresh the screens holding the removed data.

## Sequencing note

Phases 3 and 4 are independent of each other and can land in either order,
but both need phase 2 — their entry rows live on the hub, and a page nobody
can open is a page nobody reviews.

## Not part of this spec's release

The app intro (spec 0006) and the purchase placeholder (spec 0007) ship in
the same template version but have their own release plans. The hub carries
their entry rows, so their slices depend on phase 2.
