# The moving `@v1` tag of the shared Flutter workflow does not carry `git-read-token`

- **Date:** 2026-10-08
- **Area:** CI
- **Severity:** `friction`
- **Template version:** 3.2.1 (commit f613988 plus uncommitted work)
- **Status:** resolved 2026-10-22 (the moving `@v1` tag advanced to v1.7.0 and declares `git-read-token`; `ci-mobile.yml` is back on `@v1`)

## Observed

`docs/GITHUB_ACTIONS_ACCESS.md` (and `flutter-libraries/docs/consuming.md`) say to pass `secrets: git-read-token:` to `flutter-quality.yml@v1`. `git ls-remote` shows `v1` still at `d158b1d` (= v1.5.2), whose workflow declares no such secret; `v1.6.0` does. Passing an undeclared secret makes the call fail to start, which leaves no check run and a clean-looking PR (KI-012).

## Workaround

`ci-mobile.yml` uses `@v1.6.0` with a comment. The `ci-gate` check still protects against a silent miss.

## Smallest generic change

`lumbrecode-engineering`: advance `v1` to a release containing the input (after review), and say in `GITHUB_ACTIONS_ACCESS.md` from which version the input exists. Then return the template to `@v1`.

## Check that would catch a recurrence

A release checklist item in `lumbrecode-engineering`: when a documented consumer snippet needs a new input, the moving major tag must already include it.
