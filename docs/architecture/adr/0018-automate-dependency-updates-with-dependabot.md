# ADR-0018: Automate dependency updates with Dependabot

## Status

proposed

## Date

2026-11-26

## Decision owners

- Florian Kroschewski (repository owner)

## Related feature / spec

- lumbrecode-engineering `docs/DEPENDENCY_AUTOMATION_PLAN.md`, stage 4
  (Flutter profile, no deploy)
- flutter-app-template ADR-0018 (the template this repository was derived from)

## Related issues / PRs

- KI-001 (dependency lock drift / riverpod), KI-012 (a workflow that fails to
  start produces no check run)

## Context

Since baseline v1.5.2 the repository carried `.github/renovate.json5` and no
`dependabot.yml`. The Renovate app was never installed, so nothing has opened an
update pull request since. Dependencies and the pinned Flutter SDK
(`flutter-version: 3.47.1`) were current only when someone moved them by hand,
and the workflow comments claiming "Renovate raises this pin" described
something that did not happen.

The repository is **public**: CodeQL code scanning, secret scanning and
dependency review are free here and are switched on in the repository settings.
CodeQL does not support Dart, so `codeql.yml` covers the Node backend only. The
security scan (gitleaks, OSV-Scanner) still runs, because it is the same on
every repository and also covers `pubspec.lock`. `ci-gate.yml` exists because a
workflow that fails to start leaves the pull request looking clean (KI-012).

`lumbrecode-engineering` v1.9.0 (`@v1`) provides reusable workflows for this
(`dependabot-automerge.yml`, `dependency-triage.yml`, `security-scan.yml`) and
the `flutter` Dependabot profile.

Facts of this repository that shape the wiring:

1. **One pub workspace, one lockfile.** The root `pubspec.yaml` declares a
   `workspace:` of seven members (`apps/mobile_app`, five `packages/*`, `services/api`); `pubspec.lock` exists only at the root. Mobile CI runs
   `melos run ci`, which formats, analyzes and tests every member, so it is the
   single meaningful gate for any pub change. Its path filter did not include
   `pubspec.lock`.
2. **A private git dependency.** `apps/mobile_app` depends on
   `FlorianTim/flutter-libraries` through `git:`. Workflows triggered by
   Dependabot read only Dependabot secrets, and Dependabot itself needs
   credentials to resolve the workspace.
3. **More than one quality workflow.** Mobile CI (Flutter workspace), Backend
   CI (Dart `services/api`, a subset of what Mobile CI already runs) and
   Backend CI (Node, `backend/`, path-filtered to it). The shared auto-merge
   workflow merges on the first green run that wakes it, so a pull request
   must have exactly one gate.

## Decision

Dependabot is the active update bot. Store releases stay manual: nothing in
this chain deploys or publishes.

- **`.github/dependabot.yml`** follows the `flutter` profile: weekly, Monday
  05:00 Europe/Berlin, `cooldown: default-days: 5`, group `minor-and-patch`
  (version updates), group `security` (security updates, minor/patch), majors
  one by one, `open-pull-requests-limit: 5`, label `dependencies`.
  Ecosystems:
  - `pub` for `/`, `/apps/*`, `/packages/*`, `/services/*`, with a `git` registry `flutter-libraries` reading the
    Dependabot secret `FLUTTER_LIBRARIES_TOKEN`;
  - `github-actions` for `/`;
  - `npm` for `/backend`, between `# >>> backend` / `# <<< backend` markers so
    that `tools/remove_backend.dart` removes it with the directory (no
    `package-lock.json` is committed, so Dependabot updates the ranges in
    `package.json`);
  - `gradle` as a commented block: no `android/` project is committed, and an
    entry for a missing directory fails on every run;
  - Not listed: pip (`requirements.txt` serves the documentation renderer and
    no pull request workflow exercises it, so an update could never be gated)
    and docker (every image is a floating tag, which Dependabot cannot update).
  - `ignore`: the minor steps of the KI-001 set (drift, drift_dev,
    drift_flutter, flutter_riverpod, riverpod_annotation, riverpod_generator,
    custom_lint; riverpod_lint also patch, it is pinned for KI-002). This
    repository's `pubspec.lock` is at the same versions as the template
    (drift 2.31.0, riverpod 3.0.3, analyzer 8.4.0). Without the block the one
    `minor-and-patch` group would be red every week and hold back every other
    pub update. The block goes in the pull request that performs the KI-001
    upgrade.
- **`dependabot-automerge.yml`** listens to `workflow_run` of "Mobile CI" and
  "Backend CI (Node)", and routes by Dependabot's branch name: npm branches
  (`dependabot/npm_and_yarn/...`) are gated by Backend CI (Node), everything
  else by Mobile CI. `scope: security-and-minor-patch`, `allow-major: false`,
  no `deploy-workflow`. Anything not eligible gets `needs-human` and one
  comment. "Backend CI" (Dart) is not a gate: Mobile CI already runs the same
  format, analyze and tests over `services/api`.
- **`ci-mobile.yml`** adds `pubspec.lock` to its path filter, so every
  Dependabot pub pull request runs the gate.
- **`dependency-triage.yml`** runs nightly with `ecosystem: pub`,
  `lockfiles: --lockfile=pubspec.lock`, `toolchain-check: flutter`, and keeps
  one "Dependency triage" issue: alerts without a fix, OSV findings,
  `needs-human` pull requests, `flutter-version:` pins behind the newest
  stable. Raising the SDK pin is a separate reviewed pull request; the
  workflow comments say so instead of naming Renovate.
- **`security-scan.yml`** runs gitleaks over the full history and OSV-Scanner
  on `pubspec.lock` on every ready pull request and weekly. It is registered
  in `ci-gate.yml` with `--expect-always`, so a scan that fails to start is a
  red check.
- **`dependency-audit.yml` stays.** It checks the same `pubspec.lock` against
  OSV.dev through `tools/audit_deps.dart`, the tool developers run locally.
  Retiring it is a separate decision once the triage issue has proven
  equivalent coverage.
- **`.github/renovate.json5` stays dormant.** The baseline delivers it; a
  local deletion would show as a conflict on the next sync. Switching to
  Renovate means installing the app and removing the version updates from
  `dependabot.yml` in the same change.
- **`codeql.yml`** (public repository): CodeQL for `javascript-typescript` on
  `backend/**` and weekly. Dart is not supported by CodeQL and is not
  scanned by it.

## Alternatives considered

| Alternative | Pro | Contra |
|-------------|-----|--------|
| Install Renovate instead | Config already present; one file covers every ecosystem and the SDK pin | Fleet standard is Dependabot; Renovate automerge on Free needs `platformAutomerge: false` and a second bot identity; not installed anywhere |
| Replace `dependency-audit.yml` by `security-scan.yml` | One OSV check instead of two | Loses the CI twin of the local audit tool; saves about one runner minute a week |

## Consequences

### Positive

- Minor and patch updates and security fixes land without a person, but only
  after the gate went green on the commit that is merged. The cooldown moves
  the first encounter with a broken release into the update pull request.
- One issue per repository tells the owner what needs a decision.
- A Flutter SDK behind stable becomes visible instead of silently ageing.

### Negative

- `FLUTTER_LIBRARIES_TOKEN` has to exist as a **Dependabot** secret as well
  (Settings -> Secrets and variables -> Dependabot): Dependabot's own
  resolution and Dependabot-triggered Mobile CI runs read only Dependabot
  secrets. Without it every Dependabot run is red and every pull request is
  labelled `needs-human`.
- The KI-001 `ignore` list has to be removed deliberately when riverpod ships
  the fix; until then those packages move by patch only.
- A Dependabot branch that receives a human or agent commit is no longer
  merged automatically.
- The callers depend on lumbrecode-engineering v1.9.0 at `@v1`. Before that
  release, `security-scan.yml` fails to start on every pull request and
  `ci-gate.yml` reports it; merge this change only after `v1` moved.

## Test and validation impact

- `ci-gate.yml` verifies Mobile CI and Security scan on every pull request.
- The first Dependabot run (Insights -> Dependency graph -> Dependabot) has to
  be checked by a person: whether the pub workspace members resolve with the
  `git` registry, and whether member directories produce duplicate pull requests. If
  they do, reduce the pub `directories` to `/`.

## Follow-up tasks

- Owner: enable Dependabot alerts and security updates; add
  `FLUTTER_LIBRARIES_TOKEN` as a Dependabot secret; watch the repository
  (Custom -> Issues, Pull requests). Public repository: also enable secret scanning (with push
  protection) and, if wanted, dependency review; keep CodeQL default setup off
  while `codeql.yml` is in use (the two conflict).
- Raise the Flutter pin from 3.47.1 when the triage issue reports it.
- Decide about `dependency-audit.yml` after a few triage cycles.

## References

- lumbrecode-engineering: `docs/DEPENDENCY_AUTOMATION_PLAN.md`,
  `docs/DEPENDABOT_AUTOMATION.md`, `docs/DEPENDENCY_UPDATES.md`
- `docs/known-issues.md` KI-001, KI-002, KI-012
- flutter-app-template ADR-0018
