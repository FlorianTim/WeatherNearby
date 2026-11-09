# The template was told to pin a tag that did not exist yet

- **Date:** 2026-10-08
- **Area:** Dependencies / release
- **Severity:** `blocker`
- **Template version:** 3.2.1 (commit f613988 plus uncommitted work)
- **Status:** resolved 2026-10-08 — tag now at `59798a3`; lock regenerated against the real remote

## Observed

The task was to depend on `task_interchange` at `interchange-v0.1.0`. `git ls-remote --tags` on `flutter-libraries` shows **no tag at all**, and `main` does not contain the packages: they exist only on `feat/move-task-interchange` (PR #2, `7ce4516`). A pinned `ref` that cannot be fetched makes `flutter pub get` fail for everyone, CI included.

## Root cause

The prompt and `docs/consuming.md` describe the post-release state; the release (merge, then tag) had not happened. Nothing in either repository says which step is next.

## Workaround

`pubspec.yaml` carries the intended `ref: interchange-v0.1.0`. Resolution, tests and the committed `pubspec.lock` were produced against a scratch clone of `7ce4516` with a *local* tag of that name (git `insteadOf` via environment variables, no global config touched, `flutter-libraries` unchanged). The lock therefore records `resolved-ref: 7ce4516...`. **If the human tags a different commit** (for example the merge commit of PR #2), regenerate the lock with `flutter pub get`.

## Smallest generic change

`flutter-libraries/docs/releasing.md`: state the order (merge, tag, only then adopt in consumers) and add a check to the consumer prompt/skill that `git ls-remote --tags <url> <tag>` returns the tag before the pin is written.

## Check that would catch a recurrence

A CI step in the template: `git ls-remote --exit-code --tags` for every `ref:` of a tag-pinned git dependency.

## Follow-up

The tag was then pushed (commit `59798a3`, not `7ce4516`). `flutter pub get` alone kept the old `resolved-ref` because the lock still satisfied the tag name; the lock moved only with `flutter pub upgrade task_interchange jscalendar ijson`. Worth a line in `docs/consuming.md`: after a tag bump or a re-pointed tag, run `pub upgrade` for the whole family. Resolution against the real remote took ~10 s; contract test 71 passed, 1 skipped.
