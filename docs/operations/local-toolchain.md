# Local Toolchain

What a workstation needs to build this template, how to install it without
administrator rights, and the failure modes that cost the most time.

## What the template requires

| Tool | Version | Verify with |
|------|---------|-------------|
| Flutter SDK | stable, major 3 (CI resolves `3.x`) | `flutter --version` |
| Dart SDK | ships **inside** Flutter — never install separately | `dart --version` |
| Android SDK platform-tools | current | `adb version` |
| Android SDK cmdline-tools | current — needed for `emulator create` | `sdkmanager --version` |
| Android emulator + a system image | matching the AVD | `scripts/dev/emulator.sh list` |
| JDK | 17 or newer | `java -version` |
| Docker | optional, only for `scripts/build.sh` and screenshot automation | `docker info` |

The Dart constraint lives in the root `pubspec.yaml` (`environment: sdk:`).
The run scripts compare it against the Dart on `PATH` before doing anything —
see *When pub says "version solving failed"* in
[dev-scripts.md](dev-scripts.md).

## Installing on Windows without admin rights

**Flutter has no winget package.** `winget search flutter` only returns
applications *built with* Flutter; there is no `Google.Flutter` or
`Flutter.Flutter`. The two realistic user-space options are:

```powershell
# Option A - scoop (installs under %USERPROFILE%\scoop, updates via scoop)
scoop bucket add extras
scoop install extras/flutter
scoop update flutter          # later updates

# Option B - the official git clone (Flutter updates itself)
git clone -b stable https://github.com/flutter/flutter.git $HOME\flutter
# add $HOME\flutter\bin to the user PATH
flutter upgrade               # later updates
```

Pick **one** and stay with it. The rest can come from winget:

```powershell
winget install Microsoft.OpenJDK.21      # or EclipseAdoptium.Temurin.21.JDK
winget install Google.AndroidStudio      # brings SDK Manager, emulator, AVDs
```

The Android **cmdline-tools** are not installed by default: Android Studio →
SDK Manager → SDK Tools → *Android SDK Command-line Tools (latest)*. Without
them `scripts/dev/emulator.sh create` cannot work (the script says so).

> Do **not** install a standalone Dart SDK (`Google.DartSDK`) next to Flutter.
> Flutter ships its own Dart, and a second one on `PATH` shadows it — the
> result is the confusing "version solving failed" against a Dart version you
> never chose.

## Keeping it current

```bash
scripts/deps/flutter_upgrade.sh   # upgrades the SDK, then all pub dependencies
scripts/deps/audit.sh             # advisories in the resolved dependencies
```

CI asks for `flutter-version: 3.x`, so it follows patch and minor releases by
itself — upgrading locally needs no workflow change. See *Flutter version
policy* in [dev-scripts.md](dev-scripts.md).

## Failure modes worth knowing

**One SDK per tool, and only one on `PATH`.** Mixing package managers
(winget / Chocolatey / scoop / manual installers) is what produces two Flutter
or four Java entries, and the one that wins is decided by `PATH` order rather
than by intent. Check what a shell actually resolves:

```powershell
Get-Command flutter -All | ForEach-Object { $_.Source }
Get-Command dart -All | ForEach-Object { $_.Source }
```

**An SDK directory a package manager does not own.** If `flutter` runs out of a
folder without the package manager's metadata (for scoop: `install.json` next
to the SDK), updates do not reach it and `bin/cache` can hold a Dart version
that does not belong to that framework. Symptom: `flutter --version` and the
Dart version pub reports disagree.

```powershell
# scoop: does the record match what is actually in use?
scoop list flutter
(Get-Item $HOME\scoop\apps\flutter\current).Target
```

**A terminal keeps the `PATH` it started with.** After installing or updating
an SDK, open a new terminal before concluding anything from an error message.

**The Windows user `PATH` truncates at 2047 characters** when edited through
the legacy *System Properties* dialog — entries are silently cut mid-path.
Check for damage:

```powershell
$p = (Get-ItemProperty "HKCU:\Environment" -Name Path).Path
"$($p.Length) characters, $(($p -split ';' | Where-Object { $_ }).Count) entries"
$p -split ';' | Where-Object { $_ -and -not (Test-Path $_) } | ForEach-Object { "dead: $_" }
```

Use the *Environment Variables* editor (or `[Environment]::SetEnvironmentVariable`)
rather than the single-line legacy field, and delete dead entries.

**The first run after an SDK swap looks like a crash, but isn't.** Flutter/Dart
print `Building flutter tool...` to stderr the first time they run against a
new SDK (rebuilding the tool snapshot). A wrapper script that does
`& dart --version 2>&1` under `$ErrorActionPreference = "Stop"` turns that
stderr line into a terminating error — the script dies on a message that was
never a failure. Absorb the one-time build before running project scripts:

```powershell
flutter --version   # let it rebuild the tool snapshot once, outside any wrapper
```

**scoop's shim can point past `current`.** After `scoop update flutter`,
`Get-Command flutter` sometimes resolves straight into the versioned folder
(`...\flutter\3.47.1\bin`) instead of through the `current` junction, and
`flutter doctor` warns about it. Fix:

```powershell
scoop reset flutter   # relinks current -> the installed version, re-applies PATH
```

Close anything that still has `dart`/`dartvm` processes running first — scoop
refuses to reset while the SDK is in use (`flutter run`, an open IDE analysis
server, etc. all count).

**Two Android SDKs is an easy trap.** A leftover manual SDK folder and the one
Android Studio manages both satisfy `adb`/`sdkmanager` checks, so nothing
complains — until a build silently picks the stale one. Check what Android
Studio itself has configured (*Languages & Frameworks → Android SDK → Android
SDK Location*) and pin the CLI tools to the same path:

```powershell
setx ANDROID_HOME "$env:LOCALAPPDATA\Android\Sdk"
setx ANDROID_SDK_ROOT "$env:LOCALAPPDATA\Android\Sdk"
```

Open a new terminal afterwards — same PATH-caching caveat as above applies to
`setx`.

**`flutter doctor --android-licenses` may report nothing to do.** Recent
`cmdline-tools` ship a new `android` CLI that replaced `sdkmanager`; running
`--licenses` through it only prints a deprecation notice instead of the old
interactive accept flow. If `flutter doctor -v` still lists "Android license
status unknown" afterwards, check whether `<sdk>\licenses\android-sdk-license`
already exists and whether Android Studio's own SDK Manager lists the needed
components as "Installed" — Android Studio accepts licenses internally when it
installs through its GUI. Treat the doctor warning as informational until an
actual Android build proves otherwise.

## Verifying the whole setup

```bash
flutter doctor -v                 # toolchain, licences, connected devices
scripts/dev/quality_gate.sh       # format + analyze + test
scripts/dev/emulator.sh list      # AVDs the emulator can actually see
```
