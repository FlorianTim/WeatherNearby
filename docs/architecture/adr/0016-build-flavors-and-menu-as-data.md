# ADR-0016: Build flavors keep their own data; the menu is data

## Status

accepted

## Date

2026-10-01

## Decision owners

- Template maintainers

## Related feature / spec

- `docs/product/specs/0008-build-channels-and-desktop-menu/`

## Related issues / PRs

- Carried over from Foldmark (changes 0055–0057), where the same decisions
  were taken for the web and Tauri template.

## Context

A snapshot installed to try a branch, a release candidate and the release are
three different builds of one app. Until now they differed only in a number:
one `app_database`, one application id on Android. Installing a snapshot
replaced the release and opened its data. `AppFlavor` existed, but nothing
read it.

The template also had no menu or keyboard layer, although it documents a
Windows build and the web build runs on desktops.

## Decision

1. **One `AppFlavor` decides everything that differs by build** — developer
   tools, file names, key prefixes, the launcher name. It lives in
   `packages/app_core` (pure Dart) and is read from `APP_FLAVOR`; an unnamed
   release-mode build is `prod`, an unnamed debug build `dev`.
2. **Data is named by flavor.** `snapshot`, `staging` and `prerelease` get a
   suffixed database file and prefixed preference keys; `dev` and `prod` keep
   the plain names. On Android the application id and name differ too, so the
   builds install side by side.
3. **A menu is data**: groups of items and one command handler. Renderers:
   `PlatformMenuBar` on macOS, a Flutter `MenuBar` on Windows, Linux and the
   web, none on a phone. The keys are bound by the host, so they work with the
   bar closed and without a bar.

## Alternatives considered

| Alternative | Pro | Contra |
|-------------|-----|--------|
| Gradle product flavors (`flavorDimensions`) | Standard Android way, per-flavor resources | `android/` is generated and never committed; a patch script would have to create a whole flavor block, and iOS needs a second mechanism anyway |
| Environment variable read by Gradle (chosen) | Small patch to `defaultConfig`, same variable as Dart | Not visible in the Android project structure; needs the variable set for every build |
| Only a different database name | No build changes | Snapshot still replaces the release app on the device |
| A native menu on Windows/Linux through platform channels | True native look | A platform channel and a C++/GTK implementation per OS for one menu bar |
| Menu built per screen | Each screen decides | Entries and keys drift; no single place for shortcuts |

## Consequences

### Positive

- A snapshot and the release never open each other's data.
- The next flavor is one enum value and one `when` branch.
- Menu entries, labels and keys have one definition; a new screen adds one
  entry.

### Negative / trade-offs

- Windows and Linux get a Flutter-drawn bar, not a native one.
- The Android patch edits generated Gradle code textually; a Flutter
  template change could make it stop matching (it then warns and leaves the
  file alone).
- iOS is not covered: a snapshot still replaces the release app there, though
  not its data.

## Follow-up

- Verify the patch with a real Android build per flavor; decide iOS.
