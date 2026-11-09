# `AppFlavor` existed, but no build behaved differently and no workflow could name a pre-release

- **Date:** 2026-10-01
- **Area:** Build / release
- **Severity:** `friction`
- **Template version:** 3.2.1
- **Status:** resolved in spec 0008

## Observed

`AppFlavor` (`dev`, `staging`, `prod`) was parsed from `APP_FLAVOR` and printed
by an unrouted page. Nothing read it: every build opened `app_database`, every
Android build had one application id, the settings diagnostics were gated on
`kReleaseMode` instead of the flavor, and `release.yml` accepted only
`v<VERSION>` and always published a full release. A snapshot installed to try a
branch replaced the release app and opened its data.

## Root cause

The flavor was added as configuration, not as behaviour, and nothing in the
template needed a second flavor yet. The first need — a tester with the release
installed — surfaced in a web app (Foldmark) and was solved there first.

## Change made

`AppFlavor` gained `snapshot` and `prerelease`, `resolve`, `databaseName`,
`preferencePrefix` and `showsDeveloperTools`; the database and the keys use
them; the Android bootstrap patches the application id; `release.yml` and the
Android release workflow take a pre-release. See
`docs/operations/build-channels.md`.

## What would catch a recurrence

A template test that fails when a flavor value has no behaviour (`AppFlavor`'s
tests list the data names and the developer-tools flag for every value).
