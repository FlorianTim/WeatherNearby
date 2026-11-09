# The first `flutter pub get` after adding the dependency emptied the committed generated l10n folder

- **Date:** 2026-10-08
- **Area:** Tooling
- **Severity:** `papercut`
- **Template version:** 3.2.1 (commit f613988 plus uncommitted work)
- **Status:** observed once, restored with git, cause unverified

## Observed

After adding the git dependency and running `flutter pub get` and `melos bs`, `git status` showed `apps/mobile_app/lib/core/l10n/generated/app_localizations*.dart` deleted (the folder was empty). Re-running `melos bs` and `flutter test` later did not repeat it. Possibly the Flutter tool's l10n step on a changed dependency set; not reproduced.

## Workaround

`git checkout -- apps/mobile_app/lib/core/l10n/generated`.

## Smallest generic change

None yet; if it recurs, run `flutter gen-l10n` as part of the documented bootstrap and add a "no tracked file deleted" check to `quality_gate.sh`.
