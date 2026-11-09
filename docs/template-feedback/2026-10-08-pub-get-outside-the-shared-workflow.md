# Six workflows run `flutter pub get` themselves and will fail on a private git dependency

- **Date:** 2026-10-08
- **Area:** CI
- **Severity:** `friction`
- **Template version:** 3.2.1 (commit f613988 plus uncommitted work)
- **Status:** open

## Observed

Only `ci-mobile.yml` goes through the shared workflow. `build-android.yml`, `_android-release-build.yml`, `build-ios.yml`, `dependency-audit.yml`, `copilot-setup-steps.yml` run `flutter pub get` directly, and `integration-test.yml` runs it inside Docker. None has credentials for `flutter-libraries`. They will fail once the dependency lands on a branch they build; nothing in the consuming docs mentions them.

## Workaround

None applied (out of this change's scope). Listed in `docs/operations/local-library-development.md`.

## Smallest generic change

A composite action in `lumbrecode-engineering` (`setup-private-git-deps`) that takes the token and does the `insteadOf` rewrite, used by the shared workflow and by consumers' own workflows; for Docker, pass the token as a build secret or mount a prepared pub cache.

## Check that would catch a recurrence

A scripted check that every workflow containing `pub get` also contains the rewrite step when `pubspec.yaml` has a `git:` dependency.
