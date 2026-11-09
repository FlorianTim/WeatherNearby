# Feature: Build channels, separate data and a desktop menu

## Metadata

- **Status:** implemented (see "Not verified")
- **Target release:** next
- **Source:** the owner's request of 2026-09-30, carried over from Foldmark
  (changes 0055–0057 there)
- **Created:** 2026-10-01

## Summary

A snapshot, a pre-release and the release keep their own data and install side
by side, and the app has a menu bar with keyboard shortcuts wherever the
platform has a window.

## Problem

1. `AppFlavor` existed (`dev`, `staging`, `prod`) but only printed its name on
   an unrouted page. Nothing behaved differently, every build opened
   `app_database`, and every Android build had one application id — so a
   snapshot installed to try something replaced the release **and read its
   data**.
2. The template has no menu bar and no way to reach a screen from the
   keyboard, although `build-windows.md` documents a Windows build.

## Goals

- Five flavors — `dev`, `snapshot`, `staging`, `prerelease`, `prod` — read from
  one place (`AppFlavor` in `packages/app_core`).
- A flavor other than `dev` and `prod` keeps its **own database file and its
  own preference keys**.
- On Android a `snapshot` or `prerelease` build gets its **own application id
  suffix and launcher name**, so it installs next to the release.
- Pre-release tags (`v1.2.0-rc.1`) and a `flavor` input on the Android release
  workflow.
- A menu bar defined once, as data; drawn natively on macOS, by Flutter on
  Windows, Linux and the web, not at all on a phone.
- Keys: `Alt+1`…`Alt+4` to the screens, `F1` for the manual, `F10` to open the
  bar, `Ctrl/Cmd+Q` to quit.

## Non-goals

- A native menu on Windows and Linux: Flutter has none there (the bar is drawn
  by Flutter). See ADR-0016.
- Separate **iOS** bundle ids per flavor (needs Xcode build configurations).
- Moving data between flavors (the app's own backup does that).
- Database migrations for released versions: they start with the first
  release and are a separate decision.

## Users / Actors

Developers and testers installing builds; users of a desktop build.

## Assumptions

- Builds name their flavor with `--dart-define=APP_FLAVOR=<name>`; Android
  builds also export `APP_FLAVOR` so Gradle can read it.
- A release-mode build that names nothing is `prod`, a debug build `dev`.

## Behaviour by flavor

| Flavor | Database | Preference keys | Android id | Developer tools |
|---|---|---|---|---|
| `dev` | `app_database` | plain | plain | yes (debug) |
| `snapshot` | `app_database_snapshot` | `snapshot.` | `….snapshot` | yes |
| `staging` | `app_database_staging` | `staging.` | plain | no |
| `prerelease` | `app_database_prerelease` | `prerelease.` | `….prerelease` | no |
| `prod` | `app_database` | plain | plain | no |

`dev` keeps the plain names: a debug build is installed by the developer's
tooling over the previous debug build, and the phone scripts
(`DATABASE_FILE` in `project.env`) expect `app_database.sqlite`.

## The menu

| Menu | Entry | Key |
|---|---|---|
| File (desktop only) | Quit | `Ctrl+Q`, `Cmd+Q` on macOS |
| Go to | Tasks, Settings, Privacy, About | `Alt+1`…`Alt+4`; `Ctrl+Alt+1`… on macOS |
| Help | Manual, FAQ | `F1` for the manual |

The splash, the startup error page and the first-start intro cannot be left
through the menu: its navigating entries are disabled there.

## Not verified

- The Android Gradle patch (`apply_android_branding.sh` and its PowerShell
  twin) produced the expected `build.gradle.kts` and manifest on a fresh
  `flutter create` and is idempotent, but **no APK was built with it**: the
  Gradle daemon could not start in the sandbox of the session.
- The native macOS menu (`PlatformMenuBar`) and the Windows/Linux runners were
  not run; the Visual Studio installation was incomplete. The bar and the keys
  are covered by widget tests under a pinned platform.

## Related docs

- Requirements: `./requirements.md`
- Acceptance criteria: `./acceptance-criteria.md`
- Open questions: `./open-questions.md`
- Out of scope: `./out-of-scope.md`
- Decision: `docs/architecture/adr/0016-build-flavors-and-menu-as-data.md`
- Operations: `docs/operations/build-channels.md`
