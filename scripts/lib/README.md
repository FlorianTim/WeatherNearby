# scripts/lib

Shared functions for the scripts under `scripts/`. Sourcing one of the two
`common` files is the first line of every script — see
`docs/operations/dev-scripts.md` for the full picture.

## Files

### `common.sh` / `Common.ps1`

The foundation every script builds on. **Sourcing changes the working directory
to the repository root**, so relative paths inside a script mean the same thing
no matter where the user invoked it from. The root is derived from the script's
own location, so the scripts also work in an exported copy without `.git`.

**Usage:**

```bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/common.sh"
```

```powershell
$ErrorActionPreference = "Stop"
. "$PSScriptRoot\..\lib\Common.ps1"
$RepoRoot = Enter-RepoRoot
try { ... } finally { Exit-RepoRoot }
```

`Exit-RepoRoot` in a `finally` block is not optional on the PowerShell side:
`.ps1` scripts run inside the caller's session, so a location change would leak
into the user's shell.

| bash | PowerShell | Purpose |
|------|------------|---------|
| `$REPO_ROOT`, `$INVOCATION_DIR` | `Get-RepoRoot`, `Enter-RepoRoot`/`Exit-RepoRoot` | Location handling |
| `step`, `ok`, `warn`, `info`, `die` | `Write-Step`, `Write-Ok`, `Write-Warn`, `Write-Info`, `Write-Fail` | Consistent logging |
| `have`, `require_cmd` | `Test-Cmd` | Tool availability |
| `confirm` | `Confirm-Action` | Yes/no prompt (`ASSUME_YES=1` / `-Yes` to skip) |
| `app_dir` | `Get-AppDir` | Path of the Flutter app |
| `load_project_env`, `application_id` | `Get-ProjectEnv`, `Get-ApplicationId` | `project.env` values |
| `melos_cmd` | `Invoke-Melos` | Melos, global or via `dart run` |
| `adb_bin`, `adb_device` | `Get-AdbPath`, `Get-AdbDevice` | adb path and target serial |
| `android_sdk_root`, `emulator_bin`, `avdmanager_bin`, `sdkmanager_bin` | (in `scripts/dev/emulator.ps1`) | Android SDK binaries |

---

### `Read-ProjectEnv.ps1` / `read_env.sh`

Read and validate `project.env`. Usually reached indirectly through
`load_project_env` / `Get-ProjectEnv` in the common files.

**Returns:** `ORG`, `PROJECT_NAME`, `APP_PACKAGE` (defaulted for older
`project.env` files).

**Used by:** `bootstrap_android.sh`, `bootstrap_ios.sh`, `bootstrap_web.sh`,
`bootstrap_mobile.ps1`, and `common.sh` / `Common.ps1`.

---

### `bootstrap_platforms.sh` / `Bootstrap-Platforms.ps1`

Regenerate the Flutter platform folders (`android/`, `ios/`, `web/`, …) safely,
via a throw-away `flutter create` in a temp directory. Never runs
`flutter create . --overwrite` inside the app — that would destroy
`pubspec.yaml` and friends.

---

### `apply_android_branding.sh` / `Apply-AndroidBranding.ps1`

Restore the Android-only branding resources (launch screen, backup rules) that
`flutter create` does not produce. Called from the platform bootstrap.

## Benefits

- **DRY**: one implementation of root resolution, logging, and tool lookup
- **Consistency**: every script behaves the same way and can be run from anywhere
- **Robustness**: no dependency on `git` being present or on the caller's cwd
