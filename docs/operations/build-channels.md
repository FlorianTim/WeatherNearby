# Build channels (flavors)

Spec: `docs/product/specs/0008-build-channels-and-desktop-menu/`. Decision:
ADR-0016.

A build names its flavor with `--dart-define=APP_FLAVOR=<name>`; Android builds
also export `APP_FLAVOR` so Gradle can read it. Everything that differs by
build asks `AppFlavor.current` (`packages/app_core`).

| Flavor | Used for | Database | Preference keys | Android id and name |
|---|---|---|---|---|
| `dev` | `flutter run`, debug builds | `app_database` | plain | plain |
| `snapshot` | a branch, to try things out | `app_database_snapshot` | `snapshot.` | `….snapshot`, `<name> (Snapshot)` |
| `staging` | a staging backend | `app_database_staging` | `staging.` | plain |
| `prerelease` | a release candidate, tested before release | `app_database_prerelease` | `prerelease.` | `….prerelease`, `<name> (Pre-release)` |
| `prod` | the release | `app_database` | plain | plain |

A release-mode build that names nothing is `prod`, a debug build is `dev`.
`snapshot` shows the developer tools (settings diagnostics); the others do not.

## Building

```bash
# snapshot, installs next to the release
APP_FLAVOR=snapshot flutter build apk --release --dart-define=APP_FLAVOR=snapshot

# pre-release candidate
APP_FLAVOR=prerelease flutter build appbundle --release --dart-define=APP_FLAVOR=prerelease
```

PowerShell: `$env:APP_FLAVOR = 'snapshot'; flutter build apk --release --dart-define=APP_FLAVOR=snapshot`.

Both parts are needed: `--dart-define` names the data, the environment variable
names the Android application id and launcher name. The Gradle part is added to
`android/app/build.gradle.kts` by the bootstrap
(`scripts/lib/apply_android_branding.sh`, `Apply-AndroidBranding.ps1`); run the
bootstrap again on an existing `android/` folder to add it (it is idempotent).

## CI

- **Android:** *Android Build Release* has a `flavor` input (`prod`,
  `prerelease`, `snapshot`); the reusable `_android-release-build.yml` takes
  the same input and passes it to Dart and Gradle.
- **Release:** a tag `v1.2.0` is the release; `v1.2.0-rc.1` creates a GitHub
  **pre-release**. The numbers before the first hyphen must equal `VERSION`.

## Phone scripts

`scripts/dev/phone.sh` reads `DATABASE_FILE` from `project.env`. For a flavor
the file is `app_database_<flavor>.sqlite`; set `DATABASE_FILE` accordingly when
backing up a snapshot or pre-release install.

## Not covered

iOS: the bundle id is not changed per flavor (it needs Xcode build
configurations), so a snapshot replaces the release app on an iPhone — though
not its data.
