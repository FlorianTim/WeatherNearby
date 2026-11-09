# Developer Scripts

Every script works from **any** directory — `scripts/lib/common.sh` and
`scripts/lib/Common.ps1` resolve the repository root from the script's own
location (no `git` required) and switch there before doing anything.

Each script exists twice with identical behaviour: `*.sh` for bash/WSL/CI and
`*.ps1` for Windows PowerShell. Pick whichever matches your shell.

For what to install on a workstation and how to keep it from drifting, see
[local-toolchain.md](local-toolchain.md).

## Quality gates

| Task | Command |
|------|---------|
| Format + analyze + test (compact) | `scripts/dev/quality_gate.sh` |
| Tests only, compact summary | `scripts/dev/test_summary.sh [path]` |
| All code generation (build_runner + l10n) | `scripts/dev/codegen.sh` |
| Full validation incl. VERSION + OpenSpec | `scripts/validate.sh` |
| Install the git hooks | `scripts/install-hooks.sh` |

## Android: device and emulator

`scripts/dev/adb.sh` wraps the adb calls you would otherwise look up every
time. The application id comes from `project.env`; the device is picked
automatically when only one is attached (otherwise pass `--device <serial>` or
set `ANDROID_SERIAL`).

```bash
scripts/dev/adb.sh devices              # what is attached, with API level
scripts/dev/adb.sh install --release    # build the APK and install it
scripts/dev/adb.sh run                  # flutter run on the resolved device
scripts/dev/adb.sh logcat               # only this app's log output
scripts/dev/adb.sh deeplink myapp://todos/42
scripts/dev/adb.sh clear                # fresh-install state, APK stays
scripts/dev/adb.sh info                 # installed version, data dir
```

Re-testing the permission rationale flow is two commands — no reinstall:

```bash
scripts/dev/adb.sh revoke POST_NOTIFICATIONS
scripts/dev/adb.sh clear
```

`scripts/dev/phone.sh` is the cable-tolerant companion for a physical phone:
every command waits for the device, restarts a stale adb server once and
retries the transient "device not found / offline" errors, so a loose USB
cable costs one retry line instead of a debugging round. Output is one line
per fact — written for agent sessions, handy for humans.

```bash
scripts/dev/phone.sh status            # serial, model, Android, app version, running?
scripts/dev/phone.sh install           # debug APK as update (data kept), then start
scripts/dev/phone.sh screenshot        # PNG into .buildlog/
scripts/dev/phone.sh pull-db           # database + short row/status summary
scripts/dev/phone.sh db-sql "select count(*) from media_entries"
scripts/dev/phone.sh logcat 300        # app errors of the last 5 minutes
scripts/dev/phone.sh backup            # shared folder -> ~/<SHARED_STORAGE_DIR>-Backup/<serial>
scripts/dev/phone.sh restore           # push back only what the device lacks
```

`backup` lists the device, then moves only the files that are missing or
differ in size in **one tar stream** over `adb exec-out` (toybox `tar -T`;
~15 MB/s on USB, versus one adb round trip per file) with a live progress
line (percent, MiB, MB/s, ETA). Sizes are verified afterwards; a dropped
cable leaves one short file, which the next run repeats. The database is
always re-pulled because it changes while the app runs — for a guaranteed
consistent copy close the app first or use the app's own export. Nothing on
the device is written (the file list goes to `/data/local/tmp`). `restore`
pushes only what the device lacks and never overwrites or deletes there.

Which folders are covered is configured in `project.env`:
`SHARED_STORAGE_DIR` (the app's folder under the shared root),
`DATABASE_FILE` and `BACKUP_PATHS` (paths inside that folder, default
`db media`). `PHONE_SERIAL`, `PHONE_TIMEOUT`, `PHONE_SHARED_ROOT` and
`PHONE_BACKUP_PATHS` override per call. On Windows run it from Git Bash
(`bash` in PowerShell is WSL, which cannot see the SDK's adb).

`scripts/dev/emulator.sh` covers the AVD lifecycle without Android Studio:

```bash
scripts/dev/emulator.sh list                          # AVDs and their state
scripts/dev/emulator.sh create --api 35 --device pixel_7
scripts/dev/emulator.sh start template-api35          # boots AND waits
scripts/dev/emulator.sh start --wipe                  # factory reset first
scripts/dev/emulator.sh start --headless              # no window (CI)
scripts/dev/emulator.sh stop all
```

`start` does not return before `sys.boot_completed` **and** the package manager
answer — the usual cause of "installation failed" right after a cold boot is
installing into a device that is not finished booting.

`create` needs the SDK Command-line Tools (Android Studio → SDK Manager → SDK
Tools → *Android SDK Command-line Tools*). Everything else only needs
platform-tools and the emulator.

`scripts/run_android.sh device|emulator` remains the one-liner that combines
picking a target and `flutter run`.

## Screenshots

See [screenshots.md](screenshots.md) for the full walkthrough.

```bash
scripts/dev/screenshots.sh capture 01-greeting --delay 3
scripts/dev/screenshots.sh auto      # via the screenshot integration test
scripts/dev/screenshots.sh list
```

## Cleaning up

```bash
scripts/dev/clean.sh                  # build/, .dart_tool/, coverage/
scripts/dev/clean.sh deep --restore   # + native caches, then melos bs
scripts/dev/clean.sh generated        # delete generated sources, re-run codegen
scripts/dev/clean.sh docker           # compose down, drop volumes
scripts/dev/clean.sh all --dry-run    # show what would go, delete nothing
```

`generated` is the one to reach for when the analyzer complains about stale
`*.g.dart` files: it deletes every generated source and regenerates from
scratch. It asks before deleting, because those files are committed.

## Dependencies and security

```bash
scripts/deps/audit.sh                 # known CVEs in the resolved tree
scripts/deps/audit.sh --fix           # ... and upgrade the affected packages
scripts/deps/audit.sh --outdated      # + how far behind everything is
melos run audit                       # same check through melos
scripts/deps/upgrade_deps.sh          # upgrade everything, incl. major versions
scripts/deps/flutter_upgrade.sh       # upgrade the local Flutter SDK
```

The audit matches every hosted package in `pubspec.lock` against
[OSV.dev](https://osv.dev) — no account, no API key. Only public package names
and versions leave the machine. Exit code `1` means findings, `2` means the
audit could not run (use `--offline` to skip the network call).

The same check runs in CI weekly and on every PR that touches a `pubspec.yaml`
(`.github/workflows/dependency-audit.yml`), so an advisory published *after*
the last merge still reaches you.

Native Android dependencies are outside pub's view and therefore outside this
audit — check them with Gradle in `apps/mobile_app/android`.

## Flutter version policy

The workflows ask `subosito/flutter-action@v2` for `flutter-version: 3.x` on
the `stable` channel. Patch **and** minor releases therefore reach CI without a
repo change; only a major bump is a deliberate edit. There is no version number
duplicated across the workflow files any more.

`scripts/deps/flutter_upgrade.sh` consequently no longer rewrites any pin - it
upgrades the local SDK and says how CI relates to it. If someone re-pins an
exact `flutter-version: x.y.z`, the script detects that and keeps rewriting it,
so a pin and the local SDK cannot drift apart unnoticed.

Local drift is caught separately: the run scripts compare the Dart SDK on PATH
against the `sdk:` constraint in `pubspec.yaml` (see the section below).

## Docker-based builds

`scripts/build.sh <target>` runs the whole toolchain in containers, so no local
Flutter SDK is needed: `web`, `android`, `analyze`, `test`, `format`, `ci`,
`integration-test`, `integration-web`, `audit`, `upgrade-deps`,
`flutter-upgrade`, `api`.

## When pub says "version solving failed"

```
The current Dart SDK version is 3.11.5.
Because flutter_app_template requires SDK version ^3.12.0, version solving failed.
```

That is almost never a dependency problem. It means the `dart` in *that shell*
is older than the workspace requires - typically a terminal that was opened
before the SDK was updated and still carries its original `PATH`. Open a fresh
terminal and check what it resolves to:

```powershell
(Get-Command flutter).Source
flutter --version
```

The run and install scripts (`run_web`, `run_android`, `test_web_app`,
`adb install`/`run`) check this up front via `require_dart_sdk` /
`Assert-DartSdk` and name both versions plus the resolved SDK path, instead of
letting pub fail with the message above. If the SDK really is too old:

```bash
scripts/deps/flutter_upgrade.sh    # upgrades the local Flutter SDK
```

## Writing a new script

Start from the shared helper so the new script inherits root-relative paths,
consistent logging and the tool lookups:

```bash
#!/usr/bin/env bash
# One-line purpose, then the usage block.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/common.sh"

step "Doing the thing"
require_cmd flutter "Install the Flutter SDK."
ok "done"
```

```powershell
$ErrorActionPreference = "Stop"
. "$PSScriptRoot\..\lib\Common.ps1"
$RepoRoot = Enter-RepoRoot
try {
  Write-Step "Doing the thing"
  Write-Ok "done"
}
finally { Exit-RepoRoot }
```

`Exit-RepoRoot` in a `finally` block matters on Windows: `.ps1` scripts run
inside the caller's session, so a location change would otherwise leak into the
user's shell.

## Android builds on a locked-down Windows host

`scripts/build-local.ps1 android`, `scripts/run_android.ps1` and
`scripts/run_android.sh` call `Use-AndroidBuildWorkarounds` /
`android_build_workarounds` (scripts/lib) before Gradle starts. They fix two
host problems seen on corporate Windows laptops, process-locally and only on
Windows: JDK 16+ needs a directory for AF_UNIX socket files that endpoint
security may refuse under `%LOCALAPPDATA%` (symptom: every Gradle start dies
with "Unable to establish loopback connection"), and a Scoop
`GRADLE_USER_HOME` reached through directory junctions breaks Kotlin DSL
script compilation ("Unresolved reference"). For a bare `flutter build apk`
in your own shell: `. .\scripts\lib\Common.ps1; Use-AndroidBuildWorkarounds`.
