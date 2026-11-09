# Engineering Baseline Feedback: `FlorianTim/flutter-app-template`

**Target repository for this report:** `FlorianTim/lumbrecode-engineering` (private, central engineering baseline)
**Reporting repository:** `FlorianTim/flutter-app-template`
**Report date:** 2026-08-24
**Analysed tree:** branch `feat/adopt-wts-1.3.1-learnings`, based on `main` `3382a50`
**`VERSION` at analysis time:** `2.0.0`
**Working tree state:** **138 uncommitted paths** — this report describes the *working tree*, not `main`
**Method:** read-only inspection of the checked-out tree. No files changed, no commits, no network calls, no destructive commands.

---

## 0. How to read this document

Every claim is one of four kinds, and they are kept visually distinct:

| Marker | Meaning |
|---|---|
| **FACT** | Directly evidenced by a file in the tree. A path (and usually a verbatim excerpt) is given. |
| **DERIVED** | A recommendation or conclusion drawn from one or more facts. Reasoning is stated. |
| **ASSUMPTION** | Not verifiable from the working tree. Explicitly flagged, never treated as established. |
| **OPEN** | A question only a human can answer. Collected in §14. |

Two constraints were applied throughout and are worth restating for the receiving repository:

1. **No secret values appear in this document.** Secrets are referenced by name and purpose only.
2. **No privacy or legal text is assessed as legally cleared.** Where this report touches privacy policies, data-deletion pages or license lists, it describes *structure and gaps*, never legal sufficiency. Those artifacts require human legal review before publication.

---

## 1. Executive Summary

### 1.1 The one thing that matters most

**FACT.** This repository is not an ordinary application repository. It is itself a distribution mechanism — a template monorepo from which concrete LumbreCode apps are derived by an OpenSpec-driven initializer agent.

`AGENTS.md`:

```markdown
## Template identity

- Project name: **`flutter_app_template`** (repository: `flutter-app-template`).
  Melos is only the monorepo script tool — never call the project
  `melos_flutter_app_template` or similar.
- Publisher: **LumbreCode** — domain **LumbreCode.de**.
- Package/application-id schema for apps from this template:
  `de.lumbre.code.<app_slug>` (slug from the app spec, see `openspec/`).
- New apps are initialized via the template initializer agent
  (`.github/agents/template-initializer.agent.md`) driven by an OpenSpec
  entry (`openspec/apps/<app_slug>.openspec.yaml`).
  Full workflow: `docs/operations/template-initialization.md`.
```

**DERIVED.** `lumbrecode-engineering` therefore competes with an existing distribution path. Rules can flow to a new app *by template copy* or *by baseline sync*. Running both without a declared authority produces silent divergence — and the divergence is already measurable inside this single repository (see C4 in §10). **This is the decision that must be made before any file is synchronised.**

### 1.2 What is worth lifting into the baseline

**FACT**, all verified in-tree:

| Asset | Path | Why it is baseline-grade |
|---|---|---|
| Named quality-command surface | `pubspec.yaml` (melos scripts) | Stable verbs (`format:check`, `analyze`, `test`, `codegen`, `audit`, `ci`) that a workflow can call without knowing the project |
| Reusable Android release workflow | `.github/workflows/_android-release-build.yml` | Already cut as `workflow_call`, optional signing secrets, debug fallback, checksums, `if: always()` cleanup |
| OSV.dev dependency audit | `tools/audit_deps.dart` + `.github/workflows/dependency-audit.yml` | No account, no API key, no third-party service; documented trigger rationale |
| Deterministic Android `versionCode` | `scripts/release/resolve_android_version.sh` | Monotonic across beta/rc/final, Play-limit-safe, fully documented |
| Cross-cutting contracts | `docs/architecture/contracts/` (7 files) | Every rule carries a *named verification form*, not prose |
| Token-saving agent wrappers | `scripts/dev/{quality_gate,test_summary,codegen}.sh` + `.claude/skills/` | Keeps agents off raw multi-thousand-line logs |
| Normative / non-normative split | `AGENTS.md`, `.codex/config.toml` | Explicit, machine-readable, with an ADR behind it (ADR-0005) |

### 1.3 What blocks a clean synchronisation

**FACT.** Thirteen conflicts, detailed in §10. The four that must be resolved *before* the first sync:

- **C6 — Release ownership collision.** `integration-test.yml` deletes the GitHub Release that `release.yml` creates for the same tag.
- **C5 — Rules that the repository itself violates.** The ASCII-only script rule is broken by the repository's own git hooks; the shellcheck/yamllint mandate in `ci.instructions.md` is implemented nowhere.
- **C4 — Fourfold duplication of agent rules**, already diverged.
- **C2 — Three parallel skill ecosystems** with three formats and three discovery mechanisms.

### 1.4 Public-site status in one line

**FACT.** `docs/public-site/` does not exist, but the *structure* of the public pages is already normative in code (`packages/app_core/lib/src/app_links.dart`, seven pages per app). **FACT.** Content for FAQ, privacy, data-deletion and licenses exists nowhere in the repository.

### 1.5 Local agent usability without the private repository

**FACT.** All agent-relevant material is materialised in-tree: `AGENTS.md`, `.claude/skills/`, `.agents/skills/`, `.github/instructions/`, `.codex/config.toml`, plus every script. `scripts/deps/audit.sh` even ships an explicit `--offline` mode.

**DERIVED.** The baseline must preserve this property. Rules must be **vendored into each repository** (the pattern `skills-lock.json` already demonstrates), never fetched at runtime from a private repository — otherwise every agent session without organisation access breaks.

---

## 2. Repository Profile

### 2.1 Identity and shape

**FACT**, `pubspec.yaml` (root — orchestration only, no library code):

```yaml
name: flutter_app_template
publish_to: none
environment:
  sdk: ^3.12.0

workspace:
  - apps/mobile_app
  - packages/app_core
  - packages/design_system
  - packages/shared_models
  - packages/api_client
  - packages/feature_flags
  - services/api

dev_dependencies:
  melos: ^7.7.0
```

| Attribute | Value | Evidence |
|---|---|---|
| Repository type | `flutter` | Dart workspace + Flutter app is the product |
| Monorepo | yes — Dart workspace *and* Melos 7 | `pubspec.yaml:6-15` |
| Non-workspace member | `backend/` (Node 22 / Express 5) | `backend/package.json` |
| Languages | Dart/Flutter, JavaScript (ESM), Bash, PowerShell, Python (one CI step) | `.github/workflows/docs-check.yml` uses `python3 -c` |
| Dart SDK | `^3.12.0` | `pubspec.yaml`, `apps/mobile_app/pubspec.yaml`, `services/api/pubspec.yaml` |
| Flutter in CI | pinned `3.44.4` — **duplicated across 8 workflow files** | see §5.4 |
| Flutter in Docker | `ghcr.io/cirruslabs/flutter:stable` — **floating** | `docker-compose.yml:30`, `docker/Dockerfile.flutter-chrome:2` |
| Version source | `VERSION` (`2.0.0`), CI-enforced against the app pubspec | `.github/workflows/validate.yml` |
| Platforms | Android (complete), iOS (build only), Web (build + integration tests), Windows/Linux (bootstrap scripts only) | `scripts/bootstrap_*`, `.github/workflows/build-*.yml` |
| Native folders | **not committed** — generated per build | see §2.3 |

**DERIVED.** `repositoryType: "flutter"`. The Node backend is explicitly removable (`scripts/remove_backend.sh`, `tools/remove_backend.dart`) and does not justify a separate profile — at most an optional `node` add-on.

### 2.2 Application identity model

**FACT**, `project.env` — the single configuration file the bootstrap scripts source:

```bash
ORG="de.lumbre.code"
PROJECT_NAME="todoapp"

# Web slug of the app — kebab-case, used for the public pages under
# https://lumbrecode.de/apps/<WEB_SLUG>/ and for the "[app:<WEB_SLUG>]" prefix
# on support mails. Separate from PROJECT_NAME because Android application id
# segments must not contain hyphens (e.g. "was-there-something" vs
# "wastheresomething"). Mirrored in apps/mobile_app/lib/app/app_identity.dart.
WEB_SLUG="todo-app"

APP_PACKAGE="mobile_app"

# Resulting Android/iOS application id — derived, do not set separately:
#   APPLICATION_ID = "$ORG.$PROJECT_NAME"

WORKSPACE_FILE="flutter_app_template.code-workspace"
DEVCONTAINER_NAME="Flutter App Template"
```

**FACT**, `packages/app_core/lib/src/app_branding.dart` — the company-level constants that must survive app initialisation:

```dart
/// Company-level branding constants for LumbreCode template apps.
///
/// These values are template-wide and must NOT be replaced when a new app
/// is initialized from this template. App-specific branding (display name,
/// splash title, icons) is derived from the app specification instead.
abstract final class AppBranding {
  static const String companyName = 'LumbreCode';
  static const String companyDomain = 'LumbreCode.de';

  /// Base URL under which every LumbreCode app publishes its public pages.
  static const String appsBaseUrl = 'https://lumbrecode.de/apps';

  /// Full application ids follow the schema `de.lumbre.code.<app_slug>`.
  static const String basePackage = 'de.lumbre.code';
}
```

**DERIVED.** `ORG`, `appsBaseUrl` and `basePackage` are organisation-wide constants that are *duplicated between a shell file and Dart source*. These are prime candidates for a single baseline-owned manifest that both sides read — see §11.4.

### 2.3 Build environments

**FACT.** Two independent local paths, both documented:

```bash
# SDK-free (Docker Compose)
./scripts/build.sh web                     # Flutter web release build
./scripts/build.sh analyze                 # analyze mobile + API
./scripts/build.sh test                    # test mobile + API
./scripts/build.sh integration-test-report # tests + report + PDF in one go
./scripts/build.sh audit                   # scan dependencies for CVEs

# With a local Flutter SDK
melos bs && melos run ci
```

**FACT.** Native platform folders are *not* in the repository. Every Android build bootstraps them first — `.github/workflows/_android-release-build.yml`:

```yaml
      - name: Bootstrap Android platform
        run: |
          if [ ! -d apps/mobile_app/android ]; then
            bash scripts/bootstrap_android.sh
          fi

      - name: Inject release signing config
        run: dart tools/patch_android_signing.dart
```

**DERIVED.** A generic central Flutter workflow that assumes a committed `android/` directory will fail here. The bootstrap step must be modelled as an optional input (`bootstrap_android: true`).

---

## 3. Evidence and Authoritative Sources

### 3.1 The repository declares its own normativity

**FACT**, `AGENTS.md`:

```markdown
## Normative vs. non-normative sources

### Normative (authoritative for decisions)

- `docs/architecture/` — arc42, ADRs, diagrams
- `docs/architecture/contracts/` — binding cross-cutting rules
- `docs/known-issues.md` — recorded traps with retry conditions
- `docs/api/` — OpenAPI specification
- `docs/operations/` — Runbooks, release checklists
- `docs/product/` — Vision, roadmap
- `AGENTS.md` — Agent behavior rules
- `.github/copilot-instructions.md` — Copilot instructions
- `.github/instructions/` — Domain-specific instructions

### Non-normative (NEVER use unless explicitly asked)

- **`drafts/`** — All content is unfinished, exploratory, and not binding.
  Do NOT incorporate drafts into implementations, decisions, or answers.
  Exception: the user explicitly points to a specific draft file.
```

**FACT**, the same concept expressed a second time in `.codex/config.toml`:

```toml
entry_files = [
  "AGENTS.md",
  "README.md",
  ".github/copilot-instructions.md",
  "docs/architecture/arc42/01-introduction-and-goals.md",
  "docs/architecture/adr/0001-monorepo.md",
]

normative_paths = [
  "docs/architecture/",
  "docs/api/",
  "docs/operations/",
  "AGENTS.md",
  ".github/copilot-instructions.md",
  ".github/instructions/",
]

excluded_paths = [
  "drafts/",
]
```

**FACT — measurable drift.** `docs/architecture/contracts/` is listed as normative in `AGENTS.md` but is **absent** from `.codex/config.toml`'s `normative_paths` and **absent** from the normative table in `docs/operations/agent-entrypoints.md`. The same rule set exists in four places and has already diverged after a single feature branch. This is the empirical case for C4.

### 3.2 The contracts — the strongest transferable asset

**FACT**, `docs/architecture/contracts/` contains seven binding documents:

```
README.md
01-startup.md
02-database.md
03-localization.md
04-permissions.md
05-external-data-ownership.md
06-library-evaluation.md
07-accessibility.md
```

**FACT**, excerpt from `07-accessibility.md` — note that each rule names *how it is verified*, and that unmet rules are marked as unmet rather than glossed over:

```markdown
| # | Regel | Verifikation |
|---|---|---|
| 1 | **Touch-Targets ≥ 48 × 48 dp** für alle primären Aktionen | Widget-Test: `tester.getSize(find.byType(X))` |
| 2 | **Jedes Bedienelement ohne Text hat ein Label** (Semantics oder Tooltip) | Widget-Test: `find.bySemanticsLabel(...)` |
| 5 | **Textskalierung bis 2.0 ohne Overflow** | Widget-Test mit `MediaQuery(textScaler: TextScaler.linear(2))` |
...
## Stand im Template

| Regel | Stand |
|---|---|
| 7 Fokus | 🟡 Dialoge fangen den Fokus über Flutters Default; kein eigener Test |
| 11 Dynamische Inhalte | 🟡 kein Beispiel im Template |
```

**DERIVED.** The pattern "rule + named verification form + honest status table" is the single most reusable idea in this repository. It should become the required shape for every baseline contract. Note the language mix (German contracts vs. English `AGENTS.md`) — see §12.10.

### 3.3 What is *not* verifiable from the tree

**ASSUMPTION** — these live in GitHub repository settings and were deliberately not probed:

- branch protection rules on `main`
- which secrets are actually configured
- environment reviewers for `google-play-internal` / `google-play-production`
- deploy keys
- installed GitHub Apps (the presence of `.github/workflows/copilot-setup-steps.yml` and a `copilot-task.yml` issue template *suggests* the Copilot coding agent is installed, but this is inference, not evidence)

---

## 4. Existing Quality Commands

### 4.1 The complete melos script surface

**FACT**, `pubspec.yaml` — reproduced in full because this is the interface a central workflow would call. Note the inline comments: they encode real operational knowledge and should survive any migration.

```yaml
melos:
  scripts:
    format:check:
      exec: dart format --output=none --set-exit-if-changed .
      description: Check formatting in all packages (fails if unformatted files exist)

    format:fix:
      exec: dart format .

    analyze:
      steps:
        - melos run analyze:flutter
        - melos run analyze:dart

    analyze:flutter:
      exec: flutter analyze
      packageFilters:
        dependsOn: "flutter"

    analyze:dart:
      exec: dart analyze
      packageFilters:
        noDependsOn: "flutter"

    test:
      steps:
        - melos run test:flutter
        - melos run test:dart

    test:flutter:
      exec: flutter test --coverage
      packageFilters:
        dependsOn: "flutter"
        dirExists: test

    test:dart:
      exec: dart test
      packageFilters:
        noDependsOn: "flutter"
        dirExists: test

    ci:
      steps:
        - melos run format:check
        - melos run analyze
        - melos run test
      description: Run the full local CI check (format + analyze + test)

    # Matches every hosted package in pubspec.lock against the OSV.dev advisory
    # database. Exits non-zero when a dependency has a known vulnerability.
    audit:
      run: dart tools/audit_deps.dart

    audit:fix:
      run: dart tools/audit_deps.dart --fix

    # Path-based (not scope-based) so it keeps working when the app package
    # is renamed during template initialization (see project.env APP_PACKAGE).
    build:web:
      run: cd apps/mobile_app && flutter build web --release

    # Runs ALL code generation: build_runner (Drift/Freezed/Riverpod) AND
    # gen-l10n. gen-l10n is easy to forget — its output is committed, so CI
    # fails on codegen drift if it is skipped (see validate.yml/ci-mobile).
    codegen:
      steps:
        - melos run codegen:build_runner
        - melos run codegen:l10n

    codegen:build_runner:
      exec: dart run build_runner build --delete-conflicting-outputs
      packageFilters:
        dependsOn: "build_runner"

    codegen:l10n:
      run: cd apps/mobile_app && flutter gen-l10n

    codegen:watch:
      exec: dart run build_runner watch --delete-conflicting-outputs
      packageFilters:
        dependsOn: "build_runner"
```

**DERIVED.** Two design choices here are worth making baseline policy:

1. **Path-based rather than scope-based scripts** where the package name changes during initialisation. A baseline that hardcodes `--scope mobile_app` breaks on the first derived app.
2. **`codegen` bundles `build_runner` *and* `gen-l10n`.** The comment explains why: generated l10n is committed, so a partial regeneration produces a red CI with a confusing diff.

### 4.2 Command inventory with sources

| Purpose | Command | Source file |
|---|---|---|
| Format check | `melos run format:check` | `pubspec.yaml` |
| Format fix | `melos run format:fix` | `pubspec.yaml` |
| Format (app, fast) | `dart format --output=none --set-exit-if-changed lib test` | `scripts/dev/quality_gate.sh`, `scripts/pre-commit.sh` |
| Static analysis | `melos run analyze` | `pubspec.yaml` |
| Unit tests (pure Dart) | `melos run test:dart` | `pubspec.yaml` |
| Widget/unit (Flutter) | `melos run test:flutter` (`--coverage`) | `pubspec.yaml` |
| Compact test run | `bash scripts/dev/test_summary.sh [path]` | `.claude/skills/test-summary/SKILL.md` |
| Compact quality gate | `bash scripts/dev/quality_gate.sh` | `scripts/dev/quality_gate.sh` |
| Composite CI | `melos run ci` | `pubspec.yaml` |
| Full local validation | `./scripts/validate.sh` | `scripts/validate.sh` |
| Integration / E2E | `docker compose run --rm mobile-integration-test-web` | `docker-compose.yml:217` |
| Integration + report | `./scripts/build.sh integration-test-report` | `scripts/build.sh` |
| Code generation | `melos run codegen` | `pubspec.yaml` |
| Codegen drift check | `melos run codegen && git diff --exit-code` | `.github/workflows/ci-mobile.yml` |
| Production build (web) | `melos run build:web` | `pubspec.yaml` |
| Production build (Android) | `flutter build appbundle --release --dart-define=APP_FLAVOR=prod` | `_android-release-build.yml` |
| Security audit | `melos run audit` / `scripts/deps/audit.sh` | `pubspec.yaml`, `scripts/deps/audit.sh` |
| Node backend | `npm run lint` / `npm test` / `npm run format:check` | `backend/package.json` |
| Dart backend | `dart analyze && dart test` (in `services/api`) | `.codex/config.toml`, `ci-backend.yml` |
| **License check** | **— does not exist —** | — |
| **Accessibility check** | **— no entrypoint —** (tests exist inside `melos run test`) | `apps/mobile_app/test/a11y/accessibility_test.dart` |

### 4.3 The agent-facing wrappers

**FACT**, `scripts/dev/quality_gate.sh` in full — this is the pattern the baseline should standardise, because it is what keeps an agent's context from being flooded by a passing build's output:

```bash
#!/usr/bin/env bash
# Compact local quality gate: format check + analyze + tests for the mobile
# app, each step reduced to a pass/fail line (full output only on failure).
# Token-saving wrapper for agents.
#
# Usage: scripts/dev/quality_gate.sh
set -uo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/common.sh"
cd "$(app_dir)"

fail=0
log="$(mktemp)"
trap 'rm -f "$log"' EXIT

step() {
  local name="$1"; shift
  if "$@" >"$log" 2>&1; then
    echo "PASS  $name"
  else
    echo "FAIL  $name"
    sed 's/^/    /' "$log" | tail -30
    fail=1
  fi
}

step "format" dart format --output=none --set-exit-if-changed lib test
step "analyze" flutter analyze --no-pub
step "test" flutter test

if [ "$fail" -ne 0 ]; then
  echo "== QUALITY GATE FAILED =="
  exit 1
fi
echo "== QUALITY GATE PASSED =="
```

**FACT.** Each wrapper has a matching skill, e.g. `.claude/skills/quality-gate/SKILL.md`:

```markdown
---
name: quality-gate
description: Run the local quality gate (format check + analyze + tests) for
  the mobile app with compact output. Use before committing or when asked to
  verify a change is clean.
---

Run `bash scripts/dev/quality_gate.sh` (Windows:
`pwsh scripts/dev/quality_gate.ps1`).

- Each step prints one `PASS`/`FAIL` line; full output appears only for a
  failing step.
- Mirrors what the pre-commit hook and CI enforce (format, analyze, test).
- Fix any FAIL before committing; re-run to confirm `== QUALITY GATE PASSED ==`.
```

**DERIVED.** The skill is worthless without the script. If the baseline ships `.claude/skills/quality-gate/SKILL.md`, it **must** ship `scripts/dev/quality_gate.{sh,ps1}` and `scripts/lib/{common.sh,Common.ps1}` with it, or rewrite the skill to call `melos run ci` (losing the compact output that is its entire purpose). Recommendation: ship the scripts.

### 4.4 The two real gaps

#### Gap 1 — License checking does not exist

**FACT.** No workflow, no script, no tool performs license collection or compliance checking. `grep` for `license` across `pubspec.yaml`, `tools/*.dart` and `scripts/dev/*.sh` returns nothing.

**FACT.** Two license-adjacent things *do* exist:

- a runtime offline license page via `showLicensePage` in `apps/mobile_app/lib/features/about/presentation/about_page.dart`
- a planned public page, `packages/app_core/lib/src/app_links.dart`:

```dart
  /// Third-party licenses of the bundled dependencies.
  Uri get licenses => _page('licenses');
```

**DERIVED.** The URL exists, the page content has no producer. This is the largest verified gap and the strongest candidate for a new central workflow (`license-report.yml`), because it is (a) store-relevant, (b) fully mechanical, and (c) identical across every Flutter app in the organisation.

#### Gap 2 — Accessibility is contracted but has no command

**FACT.** `docs/architecture/contracts/07-accessibility.md` defines 11 verifiable rules. The implementation lives in `apps/mobile_app/test/a11y/accessibility_test.dart`, i.e. inside the ordinary `melos run test` sweep.

**DERIVED.** There is no way to answer "is a11y green?" without running the whole suite, and no CI signal distinguishes an a11y regression from any other test failure. A thin `melos run test:a11y` (path-filtered) plus a baseline skill would cost almost nothing and make the contract observable.

#### Gap 3 — A mandated check that was never implemented

**FACT.** `.github/instructions/ci.instructions.md` mandates script linting and even ships the YAML:

````markdown
## Script syntax validation

Always validate script syntax before merging or releasing. Use these steps in CI or pre-commit hooks:

- **Shell scripts (`.sh`)**: run `shellcheck` on every `.sh` file under `scripts/`.
  ```yaml
  - run: find scripts -name '*.sh' | xargs shellcheck --severity=warning
  ```
- **PowerShell scripts (`.ps1`)**: use the PS parser via `pwsh`.
  ```yaml
  - name: Validate PS1 syntax
    shell: pwsh
    run: |
      $errors = Get-ChildItem scripts -Filter *.ps1 -Recurse |
        ForEach-Object {
          $null = [System.Management.Automation.Language.Parser]::ParseFile(
            $_.FullName, [ref]$null, [ref]$e)
          $e
        }
      if ($errors) { $errors; exit 1 }
  ```
- **YAML**: use `yamllint` or the built-in YAML parser via the `validate` step.
````

**FACT.** No workflow executes any of this. The only occurrences of `shellcheck` in the repository are `# shellcheck source=` directives inside the scripts themselves:

```
scripts/bootstrap_android.sh:8:  # shellcheck source=lib/read_env.sh
scripts/bootstrap_ios.sh:8:     # shellcheck source=lib/read_env.sh
scripts/lib/common.sh:69:       # shellcheck source=read_env.sh
```

**DERIVED.** The rule already has organisational consensus (it is written down and normative); only the enforcement is missing. That makes it the *lowest-risk* first central workflow — it introduces no new policy argument.

---

## 5. Existing Workflows and Automation

### 5.1 Inventory

**FACT.** 16 workflow files (15 + 1 reusable):

| Workflow | Trigger | Baseline fit |
|---|---|---|
| `validate.yml` | `pull_request`, `push: main` | **high** (minus the OpenSpec step) |
| `ci-mobile.yml` | `pull_request`, `push: main` (paths) | **high** — best template for `flutter-ci.yml` |
| `ci-backend.yml` | `pull_request`, `push: main` (paths) | medium |
| `ci-backend-node.yml` | `pull_request`, `push: main` (paths) | medium |
| `_android-release-build.yml` | `workflow_call` | **very high** |
| `android-build-release.yml` | `workflow_dispatch` | high (thin wrapper) |
| `android-publish-play.yml` | `workflow_dispatch` | high |
| `build-android.yml` | `workflow_dispatch`, tag `android-v*` | **redundant** |
| `build-ios.yml` | `workflow_dispatch`, tag `ios-v*` | low |
| `dependency-audit.yml` | `schedule`, `workflow_dispatch`, `pull_request` | **very high** |
| `release.yml` | tag `v*` | medium (see C6) |
| `integration-test.yml` | `push: main` (paths), `workflow_dispatch` | low (see C6) |
| `docs-build.yml` | `push: main` (paths) | repo-specific |
| `diagrams-build.yml` | `push: main` (paths) | repo-specific |
| `glossary-generate.yml` | `push: main` (paths) | repo-specific (see C9) |
| `docs-check.yml` | `pull_request` (paths) | repo-specific |
| `copilot-setup-steps.yml` | `workflow_dispatch`, self-path | high |

### 5.2 The mobile CI job — the reference to generalise

**FACT**, `.github/workflows/ci-mobile.yml` in full:

```yaml
name: Mobile CI
run-name: "Mobile CI"

on:
  pull_request:
    paths:
      - "apps/mobile_app/**"
      - "packages/**"
      - ".github/**"
      - "scripts/**"
      - "pubspec.yaml"
  push:
    branches: ["main"]
    paths:
      - "apps/mobile_app/**"
      - "packages/**"
      - ".github/**"
      - "scripts/**"
      - "pubspec.yaml"

permissions:
  contents: read

jobs:
  mobile-quality:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v6

      - name: Setup Java
        uses: actions/setup-java@v5
        with:
          distribution: temurin
          java-version: "17"

      - name: Setup Flutter SDK
        uses: flutter-actions/setup-flutter@v4
        with:
          channel: stable
          version: 3.44.4
          cache: true
          cache-sdk: true

      - name: Activate Melos
        run: dart pub global activate melos

      - name: Install dependencies
        run: melos bs

      - name: Run code generation
        run: melos run codegen

      - name: Check for codegen drift
        run: |
          git diff --exit-code || {
            echo "::error::Generated sources are out of date — run 'melos run codegen' and commit the result."
            exit 1
          }

      - name: Check formatting
        run: melos run format:check

      # Composite: Flutter packages AND pure-Dart packages. Analysing only
      # the Flutter side would leave app_core, feature_flags and friends
      # unchecked on every PR.
      - name: Analyze (all packages)
        run: melos run analyze

      - name: Run tests with coverage (Flutter packages)
        run: melos run test:flutter

      - name: Run tests (pure Dart packages)
        run: melos run test:dart

      - name: Check coverage file exists
        run: test -f apps/mobile_app/coverage/lcov.info
```

**DERIVED — observations for the baseline version:**

1. `permissions: contents: read` at workflow level — good default, keep it.
2. **No `concurrency:` group.** Two pushes to a branch run to completion in parallel. Add it centrally.
3. `dart pub global activate melos` is **unpinned**; `melos: ^7.7.0` only constrains the dev dependency, not the globally activated CLI. A Melos 8 release breaks CI with zero repository changes. Pin it: `dart pub global activate melos 7.7.0`.
4. The codegen-drift check is excellent and generalises perfectly.
5. "Check coverage file exists" is a *presence* check, not a threshold. A baseline could add an optional `min_coverage` input.
6. The path filter includes `.github/**` and `scripts/**` — meaning any workflow edit re-runs the full mobile suite. Deliberate and defensible; keep as an input.

### 5.3 The reusable Android release workflow

**FACT**, `.github/workflows/_android-release-build.yml`, contract and the security-relevant steps:

```yaml
name: _Android Release Build
run-name: "Android release build"

# Reusable workflow: quality gate + signed AAB/APK build with checksums.
# Called by android-build-release.yml and android-publish-play.yml.
#
# Signing secrets are optional — without them the build falls back to the
# debug signing config (patched build.gradle.kts), so the template repo can
# run this workflow end-to-end without real keys.

on:
  workflow_call:
    inputs:
      ref:
        description: "Git ref to build (defaults to the calling ref)"
        type: string
        required: false
        default: ""
    outputs:
      version_name:
        value: ${{ jobs.build.outputs.version_name }}
      version_code:
        value: ${{ jobs.build.outputs.version_code }}
    secrets:
      ANDROID_KEYSTORE_BASE64:
        required: false
      ANDROID_KEYSTORE_PASSWORD:
        required: false
      ANDROID_KEY_ALIAS:
        required: false
      ANDROID_KEY_PASSWORD:
        required: false

permissions:
  contents: read
```

```yaml
  build:
    name: Build AAB + APK
    needs: quality
    runs-on: ubuntu-latest
    env:
      # Step-level `if:` cannot read the secrets context reliably — resolve
      # the presence check once at job level.
      HAS_KEYSTORE: ${{ secrets.ANDROID_KEYSTORE_BASE64 != '' }}
    outputs:
      version_name: ${{ steps.version.outputs.version_name }}
      version_code: ${{ steps.version.outputs.version_code }}
    steps:
      # ...
      - name: Resolve version from ref
        id: version
        run: bash scripts/release/resolve_android_version.sh "${{ inputs.ref || github.ref }}"

      - name: Write keystore + key.properties
        if: ${{ env.HAS_KEYSTORE == 'true' }}
        env:
          KEYSTORE_BASE64: ${{ secrets.ANDROID_KEYSTORE_BASE64 }}
          KEYSTORE_PASSWORD: ${{ secrets.ANDROID_KEYSTORE_PASSWORD }}
          KEY_ALIAS: ${{ secrets.ANDROID_KEY_ALIAS }}
          KEY_PASSWORD: ${{ secrets.ANDROID_KEY_PASSWORD }}
        run: |
          echo "$KEYSTORE_BASE64" | base64 -d > apps/mobile_app/android/app/upload-keystore.jks
          cat > apps/mobile_app/android/key.properties <<EOF
          storeFile=upload-keystore.jks
          storePassword=$KEYSTORE_PASSWORD
          keyAlias=$KEY_ALIAS
          keyPassword=$KEY_PASSWORD
          EOF

      - name: Build app bundle
        working-directory: apps/mobile_app
        run: |
          flutter build appbundle --release \
            --dart-define=APP_FLAVOR=prod \
            --build-name="${{ steps.version.outputs.version_name }}" \
            --build-number="${{ steps.version.outputs.version_code }}"

      - name: Generate checksums
        working-directory: apps/mobile_app
        run: |
          mkdir -p build/release-artifacts
          cp build/app/outputs/bundle/release/*.aab build/release-artifacts/ || true
          cp build/app/outputs/flutter-apk/app-release.apk build/release-artifacts/ || true
          cd build/release-artifacts
          sha256sum * > SHA256SUMS.txt
          cat SHA256SUMS.txt

      - name: Upload release artifacts
        uses: actions/upload-artifact@v7
        with:
          name: android-release-${{ steps.version.outputs.version_name }}
          path: apps/mobile_app/build/release-artifacts/

      - name: Cleanup signing material
        if: always()
        run: |
          rm -f apps/mobile_app/android/key.properties
          rm -f apps/mobile_app/android/app/upload-keystore.jks
```

**DERIVED — why this is baseline-grade, point by point:**

- Secrets are passed through `env:` rather than interpolated into `run:` text — no shell-injection surface, no accidental logging.
- `HAS_KEYSTORE` resolves the presence check once at job level, with a comment explaining *why*. Genuine hard-won knowledge.
- The debug-signing fallback means the workflow is runnable in a repository with no keys at all — exactly what a shared baseline needs for its own smoke tests.
- `Cleanup signing material` with `if: always()` runs even on failure.
- Checksums are produced next to the artifacts.

**DERIVED — what to change when centralising:** parameterise `flutter_version`, `java_version`, `app_dir`, `dart_defines` and `bootstrap_android`; add `concurrency`; pin melos.

### 5.4 The Play publish job

**FACT**, `.github/workflows/android-publish-play.yml`:

```yaml
  publish:
    name: Upload to Google Play (${{ inputs.track }})
    needs: release-build
    runs-on: ubuntu-latest
    environment: ${{ inputs.track == 'production' && 'google-play-production' || 'google-play-internal' }}
    steps:
      - name: Download release artifacts
        uses: actions/download-artifact@v7
        with:
          name: android-release-${{ needs.release-build.outputs.version_name }}
          path: release-artifacts

      - name: Derive package name from project.env
        id: pkg
        shell: bash
        run: |
          source scripts/lib/read_env.sh
          read_project_env project.env
          echo "package_name=$ORG.$PROJECT_NAME" >> "$GITHUB_OUTPUT"

      - name: Determine rollout status
        id: rollout
        shell: bash
        run: |
          track="${{ inputs.track }}"
          fraction="${{ inputs.rollout_fraction }}"
          if [ "$track" = "production" ] && [ "$fraction" != "1.0" ]; then
            echo "status=inProgress" >> "$GITHUB_OUTPUT"
            echo "fraction=$fraction" >> "$GITHUB_OUTPUT"
          else
            echo "status=completed" >> "$GITHUB_OUTPUT"
            echo "fraction=" >> "$GITHUB_OUTPUT"
          fi

      - name: Upload to Google Play
        uses: r0adkll/upload-google-play@v1
        with:
          serviceAccountJsonPlainText: ${{ secrets.PLAY_SERVICE_ACCOUNT_JSON }}
          packageName: ${{ steps.pkg.outputs.package_name }}
          releaseFiles: release-artifacts/*.aab
          track: ${{ inputs.track }}
          status: ${{ steps.rollout.outputs.status }}
          userFraction: ${{ steps.rollout.outputs.fraction }}
```

**DERIVED — the highest-risk line in the repository:**

```yaml
        uses: r0adkll/upload-google-play@v1
```

A third-party action pinned to a *movable* major tag, running in a job that holds `PLAY_SERVICE_ACCOUNT_JSON`. If that tag is repointed upstream, the credential is exposed to whatever the new code does. **Pin to a commit SHA in the baseline version.** The `environment:` approval gate mitigates but does not remove this — approval gates the *run*, not the *action contents*.

**DERIVED — nice touch worth keeping:** the package name is derived from `project.env` at run time rather than hardcoded, so the workflow survives template initialisation unchanged.

### 5.5 Dependency audit

**FACT**, `.github/workflows/dependency-audit.yml` — reproduced because the trigger rationale is the valuable part:

```yaml
name: Dependency Audit
run-name: "Dependency Audit"

# Known vulnerabilities appear in packages that were already resolved, so a
# PR-only check would never see them. The schedule is what catches an advisory
# published after the last merge; the PR trigger only guards changes to the
# dependency set itself.
on:
  schedule:
    # Mondays, 05:17 UTC - off the hour to avoid the GitHub-wide cron spike.
    - cron: "17 5 * * 1"
  workflow_dispatch:
  pull_request:
    paths:
      - "**/pubspec.yaml"
      - "pubspec.lock"
      - "tools/audit_deps.dart"
      - ".github/workflows/dependency-audit.yml"

permissions:
  contents: read

jobs:
  audit:
    runs-on: ubuntu-latest
    steps:
      # ... checkout + flutter ...
      - name: Audit resolved dependencies against OSV.dev
        id: audit
        run: dart tools/audit_deps.dart

      - name: Explain a failure
        if: failure() && steps.audit.outcome == 'failure'
        run: |
          echo "::error::A dependency has a known vulnerability. Run 'melos run audit:fix' locally, or bump the constraint listed above and commit the new pubspec.lock."
```

**FACT**, the local counterpart, `scripts/deps/audit.sh`:

```bash
# Check the resolved dependencies for known security vulnerabilities and, on
# request, pull in the fixes.
#
# Wraps tools/audit_deps.dart, which matches every hosted package in
# pubspec.lock against the OSV.dev advisory database (no account, no API key;
# only public package names and versions are sent).
#
# Usage:
#   scripts/deps/audit.sh                 # report only, exit 1 on findings
#   scripts/deps/audit.sh --fix           # report, then upgrade affected packages
#   scripts/deps/audit.sh --outdated      # also show how far behind the tree is
#   scripts/deps/audit.sh --json          # machine-readable (CI)
#   scripts/deps/audit.sh --offline       # skip the network call
```

**DERIVED.** Take this whole trio (`tools/audit_deps.dart` + workflow + wrapper) into the baseline essentially unchanged. The `--offline` flag is what makes it usable by an agent in a sandbox; the `--json` flag is what makes it usable by a central reporting job later.

### 5.6 Repository validation

**FACT**, `.github/workflows/validate.yml`:

```yaml
      - name: Check VERSION file exists
        run: test -f VERSION

      - name: Check VERSION matches app pubspec version
        run: |
          version_file="$(tr -d '[:space:]' < VERSION)"
          pubspec_version="$(grep -E '^version:' apps/mobile_app/pubspec.yaml | sed -E 's/version:[[:space:]]*//' | cut -d+ -f1)"
          if [ "$version_file" != "$pubspec_version" ]; then
            echo "::error::VERSION ($version_file) != apps/mobile_app/pubspec.yaml version ($pubspec_version)"
            exit 1
          fi

      - name: Validate OpenSpec app specifications
        run: bash scripts/validate_openspec.sh

      - name: Check required docs exist
        run: |
          for f in \
            README.md \
            AGENTS.md \
            CONTRIBUTING.md \
            SECURITY.md \
            LICENSE \
            CHANGELOG.md \
            .editorconfig \
            .gitattributes \
            docs/architecture/arc42/01-introduction-and-goals.md \
            docs/api/openapi.yaml; do
            if [ ! -f "$f" ]; then
              echo "MISSING: $f"
              exit 1
            fi
          done

      - name: Check ADR naming convention
        run: |
          # ADR files must match pattern: NNNN-<slug>.md
          # Exceptions: README.md and the ADR template (_template.md)
          for f in docs/architecture/adr/*.md; do
            name="$(basename "$f")"
            if [ "$name" = "README.md" ] || [ "$name" = "_template.md" ]; then continue; fi
            if ! echo "$name" | grep -qE '^[0-9]{4}-[a-z0-9-]+\.md$'; then
              echo "Invalid ADR filename: $name (expected NNNN-slug.md)"
              exit 1
            fi
          done
```

**DERIVED.** Three of the four checks generalise perfectly (`VERSION` consistency, required-file list, ADR naming). The OpenSpec step is template-specific. In the baseline: make the required-file list and the OpenSpec step inputs.

### 5.7 Action usage — risk review

**FACT**, complete action inventory with counts:

```
     18 actions/checkout@v6
      8 flutter-actions/setup-flutter@v4
      5 actions/upload-artifact@v7
      5 actions/setup-java@v5
      2 ./.github/workflows/_android-release-build.yml
      1 softprops/action-gh-release@v3
      1 r0adkll/upload-google-play@v1
      1 dart-lang/setup-dart@v1
      1 actions/setup-node@v4
      1 actions/download-artifact@v7
```

| Finding | Severity | Detail |
|---|---|---|
| `r0adkll/upload-google-play@v1` on a movable tag, in a job holding `PLAY_SERVICE_ACCOUNT_JSON` | **high** | Pin to SHA |
| `flutter-actions/setup-flutter@v4` (8×), `softprops/action-gh-release@v3` — third-party on tags | medium | Consider SHA pinning; at minimum, centralise so one bump fixes all repos |
| `dart pub global activate melos` unpinned (4 workflows) | medium | A major upstream release breaks CI with no repo change |
| Flutter `3.44.4` duplicated 8× | medium | Maintenance drift; the git history shows a past bulk `3.41.9 → 3.44.4` rewrite across 5 files |
| Docker uses floating `flutter:stable` while CI pins `3.44.4` | medium | Local and CI can silently diverge |
| **No `concurrency:` in any workflow** | medium | Parallel runs on the same ref |
| `actions/setup-node@v4` next to `checkout@v6` / `upload-artifact@v7` | low | Dependabot has an open PR (`dependabot/github_actions/actions/setup-node-7`) |
| `ci-backend-node.yml` uses `npm install`, not `npm ci` | low | Documented in the workflow: no lockfile is committed in the template |
| Self-contradiction: `ci.instructions.md` says "Prefer official GitHub actions" while CI uses three third-party actions | low | Either the rule or the practice needs adjusting — see C5 |

**FACT**, the `npm install` decision is deliberate and documented in `ci-backend-node.yml`:

```yaml
      # No lockfile is committed in the template; switch to `npm ci`
      # once your app commits backend/package-lock.json.
      - name: Install dependencies
        run: npm install --no-fund
```

### 5.8 Git hooks

**FACT**, `scripts/pre-commit.sh` — path-aware, fast:

```bash
# Pre-commit: fast format check only (path-aware).
#
# The slower analyze + test gate runs on PRE-PUSH (scripts/pre-push.sh), so
# commits stay fast. Formatting is cheap (~1s) and worth catching immediately.

staged="$(git diff --cached --name-only --diff-filter=ACMR || true)"

run_mobile=0
run_api=0
if [ "$force_all" -eq 1 ] || [ -z "$staged" ]; then
  run_mobile=1
  run_api=1
else
  if echo "$staged" | grep -qE '^(apps/mobile_app/.*\.(dart|arb)|apps/mobile_app/(pubspec\.yaml|analysis_options\.yaml|l10n\.yaml)|packages/.*\.dart|packages/[^/]+/pubspec\.yaml|pubspec\.yaml|analysis_options\.yaml)$'; then
    run_mobile=1
  fi
  if echo "$staged" | grep -qE '^services/api/'; then
    run_api=1
  fi
fi
```

**FACT**, `scripts/pre-push.sh` — parallel analyze + test:

```bash
# Pre-push gate: full format + analyze + test across the whole workspace.
#
# analyze and test run CONCURRENTLY (they are independent processes), so the
# test time hides under the longer analyze — the practical "Gradle-style"
# parallelism available here (flutter analyze itself has no -j; flutter test is
# already parallel; melos parallelizes across packages).
#
# Runs once per push (not per commit), so day-to-day commits stay fast.
# Emergency bypass:  git push --no-verify

melos_cmd run analyze >"$TMP/analyze.log" 2>&1 &
apid=$!
melos_cmd run test >"$TMP/test.log" 2>&1 &
tpid=$!

wait "$apid"; acode=$?
wait "$tpid"; tcode=$?
```

**DERIVED.** The commit/push split (cheap format on commit, expensive gate on push) is a good organisational default and generalises to every repository type. Ship it with `scripts/install-hooks.{sh,ps1}`.

**FACT — but see C5.** Both hook scripts violate the repository's own ASCII rule:

```bash
# scripts/pre-commit.sh
echo "✗ Formatting check failed. Run 'dart format .' and re-stage."
echo "✓ Pre-commit format check passed (analyze + test run on push)."

# scripts/pre-push.sh
echo "==> analyze + test (running in parallel)…"
echo "✓ format ok"
echo "✗ Pre-push checks failed. Fix them, or bypass once with 'git push --no-verify'."
```

---

## 6. Existing Agent Instructions and Skills

### 6.1 Inventory

**FACT:**

| Path | Content | Format | Discovered by |
|---|---|---|---|
| `AGENTS.md` | 11,795 B, repository-wide | plain Markdown | all agents (de-facto standard) |
| `apps/mobile_app/AGENTS.md` | app scope, initializer replacement table | plain Markdown | nearest-file override |
| `services/api/AGENTS.md` | API scope, short | plain Markdown | nearest-file override |
| `.github/copilot-instructions.md` | `applyTo: "**"` | YAML frontmatter | Copilot |
| `.github/instructions/*.md` | 6 files with `applyTo` globs | YAML frontmatter | Copilot |
| `.github/agents/*.agent.md` | 4 custom agents | frontmatter with `tools:` | Copilot |
| `.github/skills/*/SKILL.md` | 10 workflow skills | **no frontmatter** | Copilot only |
| `.claude/skills/*/SKILL.md` | 3 skills | frontmatter `name` + `description` | Claude Code |
| `.agents/skills/*/SKILL.md` | 19 skills vendored from `dart-lang/skills` | frontmatter + `metadata.model` | Gemini / dart tooling |
| `skills-lock.json` | hash lock for the 19 vendored skills | JSON | sync tooling |
| `.codex/config.toml` | entry files, normative paths, checks | TOML | Codex |
| `.mcp.json`, `.vscode/mcp.json` | Stitch MCP server | JSON | MCP clients |

**FACT.** There is **no** `CLAUDE.md` and **no** `GEMINI.md`. `AGENTS.md` is treated as the de-facto standard, which a prior in-repo review noted approvingly (`drafts/notes/2026-07-04-lumbrecode-template-review.md`).

### 6.2 Three skill formats, side by side

**FACT** — `.claude/skills/codegen/SKILL.md` (frontmatter, Claude-discoverable):

```markdown
---
name: codegen
description: Regenerate all generated sources (Drift, Freezed, Riverpod AND
  l10n). Use after editing tables, models, providers or ARB files, or when
  the analyzer reports missing *.g.dart / AppLocalizations.
---

Run `bash scripts/dev/codegen.sh` (Windows: `pwsh scripts/dev/codegen.ps1`),
which calls `melos run codegen`.

- Runs build_runner (Drift/Freezed/Riverpod) **and** `flutter gen-l10n`.
- The l10n step is easy to forget — always use this wrapper rather than a
  bare `dart run build_runner build`, otherwise generated localizations go
  stale and CI fails on codegen drift.
- Commit the regenerated files together with the source change.
```

**FACT** — `.agents/skills/dart-add-unit-test/SKILL.md` (frontmatter + vendored metadata):

```markdown
---
name: dart-add-unit-test
description: Write and organize unit tests for functions, methods, and classes using `package:test`. Use when creating new logic or fixing bugs to ensure code remains correct and regression-free.
metadata:
  model: models/gemini-3.1-pro-preview
  last_modified: Fri, 24 Apr 2026 15:07:58 GMT
---
# Testing Dart and Flutter Applications
```

**FACT** — `.github/skills/flutter-feature-slice/SKILL.md` (**no frontmatter at all**):

```markdown
# Flutter Feature Slice

Use this skill when adding a new feature to the Flutter app.

## Objective

Create a new feature under `apps/mobile_app/lib/features/<feature-name>/` with a feature-first layout.
```

**FACT** — `skills-lock.json`, the vendoring mechanism for the third set:

```json
{
  "version": 1,
  "skills": {
    "dart-add-unit-test": {
      "source": "dart-lang/skills",
      "sourceType": "github",
      "skillPath": "skills/dart-add-unit-test/SKILL.md",
      "computedHash": "b4d913eb86f9a8539b5d07d453ce213c3b1557b028569eb980e1ae6707165da6"
    }
  }
}
```

**DERIVED.** Three consequences for the baseline:

1. The ten `.github/skills/` entries are **not loadable by Claude Code** — no `name`/`description` frontmatter. They are effectively Copilot-only prose. Adding frontmatter is a cheap, non-breaking fix that triples their reach.
2. A central sync that writes into `.agents/skills/` would **invalidate `skills-lock.json`**. That directory is an upstream mirror and must stay one; the baseline should standardise the *sync mechanism*, not the contents.
3. `.claude/skills/` is the only set that is both correctly formatted and repository-specific. Make it the canonical authoring location and project into the others.

### 6.3 Custom agents

**FACT**, `.github/agents/` — three generic, one template-specific:

```markdown
---
name: implementation-planner
description: Creates implementation plans, task breakdowns, and technical notes in markdown
tools: ["read", "search", "edit"]
---
```

```markdown
---
name: repository-reviewer
description: Reviews architecture fit, test coverage, CI impact, and repository hygiene
tools: ["read", "search", "edit"]
---
```

```markdown
---
name: lumbrecode-template-initializer
description: Initializes a new LumbreCode app from this template based on an OpenSpec app specification. Supports audit, dry-run and apply modes.
tools: ["read", "search", "edit", "execute"]
---
```

**DERIVED.** `implementation-planner`, `implementation-executor` and `repository-reviewer` are written without template-specific assumptions and can move to the baseline as-is. `lumbrecode-template-initializer` stays local — it is the very mechanism that competes with the baseline (C1).

### 6.4 Path-scoped instructions and their gaps

**FACT**, the `applyTo` coverage:

```
backend.instructions.md      → services/api/**/*.dart
ci.instructions.md           → .github/workflows/**/*.yml,.github/workflows/**/*.yaml
docs.instructions.md         → docs/**/*.md,docs/**/*.yaml,design/**/*.md,drafts/**/*.md
flutter.instructions.md      → apps/mobile_app/**/*.dart,packages/design_system/**/*.dart
github-issues.instructions.md→ .github/ISSUE_TEMPLATE/**
tests.instructions.md        → **/test/**/*.dart,**/test_driver/**/*.dart,**/integration_test/**/*.dart
```

**FACT — uncovered paths**, despite carrying real rules:

| Uncovered path | Rule that exists elsewhere but has no path binding |
|---|---|
| `scripts/**` | The ASCII-only rule — the sharpest rule in the repository — lives only in `AGENTS.md` and `copilot-instructions.md` |
| `tools/**/*.dart` | Nothing; yet `audit_deps.dart`, `patch_android_signing.dart` are security-adjacent |
| `backend/**` | Node conventions exist in `package.json` scripts only |
| `packages/*/lib/**` except `design_system` | `app_core`, `shared_models`, `api_client`, `feature_flags` are unscoped |
| `infra/**`, `openspec/**` | no instructions |

**DERIVED.** A baseline `scripts.instructions.md` binding the ASCII rule to `scripts/**/*.{sh,ps1}` would have surfaced the C5 violation at authoring time.

### 6.5 The `AGENTS.md` composition problem

**FACT.** Rough split of `AGENTS.md` by transferability:

| Section | Transferable? |
|---|---|
| Template identity | **no** — names the template and the initializer |
| Todo example app — preservation rule | **no** — actively harmful in a derived app |
| Generator usage (mandatory) | **yes** |
| Splash screen rules | **no** — names specific Lottie files |
| Quick orientation | partly — the ordering generalises, the paths do not |
| Repository shape | partly |
| Normative vs. non-normative sources | **yes** (structure), paths are local |
| Working style | **yes** |
| Quality gates | **yes** (structure), commands are local |
| Safety rules | **yes** |
| Writing rules (incl. ASCII) | **yes** |
| Architecture defaults | partly |
| Design artifacts | **yes** (ADR-0004 pattern) |
| Planned features (version targets) | **yes** |
| Generated files | partly |
| Key ADRs table | **no** — numbers are repo-local |
| Development workflows (Idea → Spec → Story → PR) | **yes** — the strongest process asset |
| Status model, release lanes | **yes** |
| Idea-to-code boundaries | **yes** |
| Testing and validation | **yes** |
| Dependency management | **yes** |
| Skills and agents | **yes** |

**FACT**, the preservation rule that must never be overwritten by a sync:

```markdown
## Todo example app — preservation rule

The Todo app (`apps/mobile_app/lib/features/todos/` plus its tests, routes,
providers, models and l10n keys) is a **deliberate part of the template**:
smoke test, structure/Riverpod/generator/test reference.

- Do NOT delete or replace it during general template maintenance, audits or
  dry-runs.
- It is replaced ONLY when the initializer runs in `apply` mode with a
  concrete new app spec and `replace_todo_app: true`.
- If unsure whether a file belongs to template infrastructure or the Todo
  app, mark it as unclear — do not delete it.
```

**FACT**, the process core that *should* be centralised verbatim:

```markdown
### Core rule

> Raw ideas are input.
> Feature candidates are triage results.
> Specs are decisions.
> Stories are implementation units.
> Pull requests are the review boundary.
>
> Agents may triage and plan from raw ideas but may only implement code
> from approved stories or explicit Copilot task issues.
```

**DERIVED — the mechanism.** Do not replace `AGENTS.md`. Sync `AGENTS.baseline.md` and inject it into a marked region:

```markdown
<!-- lumbrecode-baseline:start version=1.4.0 -->
... content owned by lumbrecode-engineering, replaced idempotently on sync ...
<!-- lumbrecode-baseline:end -->
```

Everything outside the markers stays repository-owned. A sync script replaces only the marked block and fails loudly if the markers are missing or unbalanced.

### 6.6 `.codex/config.toml` is already stale

**FACT:**

```toml
[checks]
mobile = "cd apps/mobile_app && flutter analyze && flutter test"
backend = "cd services/api && dart analyze && dart test"
backend_node = "cd backend && npm run lint && npm test"
format = "cd services/api && dart format --output=none --set-exit-if-changed ."
```

**DERIVED.** The rest of the repository has moved to `melos run ci` and `scripts/dev/quality_gate.sh`; this file still points at raw per-directory commands, and `format` only covers `services/api`. It is a fourth copy of knowledge that drifted. Under the baseline, `.codex/config.toml` should be reduced to pointers plus a single `checks` entry that calls the wrapper script.

### 6.7 Local agent readiness

**FACT.** Every input an agent needs is in the tree: instructions, skills, scripts, contracts, known-issues. `scripts/deps/audit.sh --offline` exists specifically for network-less operation. `melos run ci` and `scripts/dev/quality_gate.sh` require no external service.

**Verdict: `localAgentReady: true`** — and this is a property to protect, not merely observe.

**DERIVED — design rule for `lumbrecode-engineering`:**

> Baseline artifacts are **materialised into the consuming repository** by a sync job and committed there. No agent-facing rule, skill or script may be fetched at runtime from the private baseline repository.

Rationale, from the evidence: contributors and agents work offline and in sandboxes (`--offline`, Docker-based builds, devcontainer); a private-repo runtime dependency would break every session without organisation credentials, including Dependabot PRs and forks.

---

## 7. Public-Site Readiness

### 7.1 Current state

**FACT.** `docs/public-site/` **does not exist**. `docs/` contains exactly:

```
docs/
├── api/                 openapi.yaml
├── architecture/        adr/ arc42/ canvas/ contracts/ diagrams/ generated/
│                        glossary.csv pandoc/ patterns/ architecture_plan.md
├── delivery/            agent-prompts.md examples/ implementation-plans/
│                        reviews/ stories/
├── ideas/               README.md flutter_template_change.md simple/ triage/
│                        wts-1.3.1-adoption-delta.md
├── known-issues.md
├── operations/          17 files (build-*, release-checklist, runbooks/, ...)
├── product/             feature-candidates.md glossary.md product-brief.md
│                        requirements.md roadmap.md specs/ vision.md
└── testing/             README.md generated/ integration-test-report.md
                         manual-test-plans/
```

### 7.2 The page structure is already normative — in code

**FACT**, `packages/app_core/lib/src/app_links.dart` — this is the authoritative definition of what the public site must contain for every app:

````dart
/// External web links and support mail addresses for one app.
///
/// Every LumbreCode app publishes the same set of pages under
/// `https://lumbrecode.de/apps/<slug>/`, so all links are derived from a
/// single [slug] instead of being listed one by one:
///
/// ```dart
/// const links = AppLinks(slug: 'todo-app');
/// links.privacyPolicy; // https://lumbrecode.de/apps/todo-app/privacy/
/// ```
class AppLinks {
  const AppLinks({required this.slug})
    : assert(slug != '', 'slug must not be empty');

  final String slug;

  /// Landing page of the app.
  Uri get website => _page(null);

  /// Support / help page.
  Uri get support => _page('support');

  /// Frequently asked questions.
  Uri get faq => _page('faq');

  /// Privacy policy. Store listings link here.
  Uri get privacyPolicy => _page('privacy');

  /// Account / data deletion request page. Required by the app stores.
  Uri get dataDeletion => _page('data-deletion');

  /// Public release notes.
  Uri get changelog => _page('changelog');

  /// Third-party licenses of the bundled dependencies.
  Uri get licenses => _page('licenses');

  Map<String, Uri> get all => {
    'website': website,
    'support': support,
    'faq': faq,
    'privacy': privacyPolicy,
    'data-deletion': dataDeletion,
    'changelog': changelog,
    'licenses': licenses,
  };

  /// `<appsBaseUrl>/<slug>/` for [page] `null`, else `.../<slug>/<page>/`.
  ///
  /// The trailing slash is part of the canonical URL — without it the site
  /// answers with a redirect.
  Uri _page(String? page) {
    final path = page == null ? '$slug/' : '$slug/$page/';
    return Uri.parse('${AppBranding.appsBaseUrl}/$path');
  }
}
````

**FACT**, the shared mailbox model in the same file:

```dart
/// Company-wide support mailboxes.
///
/// The addresses are LumbreCode-wide and identical for every app — apps are
/// told apart by the `[app:<slug>]` subject prefix that [AppLinks.mailto]
/// adds, so incoming mail can be filtered per app.
enum SupportMailbox {
  support('support@lumbrecode.de'),
  feedback('feedback@lumbrecode.de'),
  bugs('bugs@lumbrecode.de'),
  privacy('privacy@lumbrecode.de'),
  security('security@lumbrecode.de'),
  contact('contact@lumbrecode.de'),
  legal('legal@lumbrecode.de');
  // ...
}
```

**DERIVED.** Seven pages × N apps, plus seven shared mailboxes. The site's information architecture is settled; only content production is missing. That makes `public-site` a *generation* problem, not a design problem — which is exactly what a central baseline is good at.

### 7.3 Content readiness matrix

| Required content | Target URL | Authoritative source in repo | Status |
|---|---|---|---|
| Manifest | — | `project.env` (`WEB_SLUG`, `PROJECT_NAME`, `ORG`), `openspec/apps/<slug>.openspec.yaml`, `apps/mobile_app/lib/app/app_identity.dart`, `VERSION` | **derivable** — but spread across 4 files |
| FAQ (DE) | `/faq/` | none | **missing** |
| FAQ (EN) | `/faq/` | none | **missing** |
| Privacy (DE) | `/privacy/` | none — only ARB key `aboutPrivacy`, mailbox `privacy@`, and patterns in `docs/architecture/patterns/{permissions,backup-restore}.md` | **missing** |
| Privacy (EN) | `/privacy/` | as above | **missing** |
| Guides | `/support/` | `docs/operations/workflow-guide-{de,en}.md` are **developer** guides, not end-user docs | **missing** |
| Roadmap | — | `docs/product/roadmap.md`, release lanes in `AGENTS.md` | **derivable** — contains internal prioritisation |
| Changelog | `/changelog/` | `CHANGELOG.md` (Keep-a-Changelog format) | **derivable** — but written for developers |
| Licenses | `/licenses/` | no producer (see §4.4 Gap 1) | **missing** |
| Data deletion | `/data-deletion/` | none | **missing** — store-required, self-documented as such |
| Public assets | — | `design/` (manifest-versioned per ADR-0004), `apps/mobile_app/assets/branding/`, screenshots from `integration_test/app_screenshots_test.dart` | **derivable** |

**FACT**, the changelog is currently developer-facing — `CHANGELOG.md` mixes user-visible and internal changes, e.g. an entry referencing the app-links URL scheme itself:

```markdown
  (`https://lumbrecode.de/apps/<slug>/{,support,faq,privacy,data-deletion,changelog,licenses}`),
```

**DERIVED.** A public changelog needs a filter (e.g. only `feat:`/`fix:` with a `user-visible` marker), not a straight copy.

### 7.4 Stale and contradictory sources

**FACT.** `docs/ideas/wts-1.3.1-adoption-delta.md` explicitly supersedes an earlier document and flags its own filing problem:

```markdown
> **Vorgänger:** `docs/ideas/flutter_template_change.md` (403 Zeilen, aus
> der 1.3-Ära, 2026-07-15). Dessen Stand ist in Abschnitt 2 abgeglichen.
>
> **Ablage:** neben dem Vorgänger in `docs/ideas/`. Wenn das Dokument
> normativ werden soll, gehört es nach
> `docs/delivery/implementation-plans/`.
```

**DERIVED.** A document in `docs/ideas/` is **non-normative by rule**, yet this one describes changes that are already implemented on the current branch. Anyone reading `flutter_template_change.md` first gets an outdated picture. Resolve by moving the delta to `docs/delivery/implementation-plans/` and marking the predecessor as superseded.

### 7.5 Content that must not become public

**FACT** — based on the repository's own normativity model and content:

| Path | Reason |
|---|---|
| `drafts/**` | Explicitly non-normative; includes internal critique (`drafts/notes/2026-07-04-lumbrecode-template-review.md`) |
| `docs/ideas/**` | Raw ideas, triage state, unfiltered feature thinking |
| `docs/delivery/reviews/**` | Internal review records |
| `docs/operations/android-release-secrets.md`, `ios-signing.md` | Procedures, not values — but they map the signing surface |
| `docs/known-issues.md` | Internal traps and workarounds |
| `docs/architecture/**` | arc42/ADR internals |
| `.claude/settings.local.json` | Machine-local, currently committed (see §9.4) |

### 7.6 Required human approvals

**Not assessed as legally cleared by this report.** The following require human — in part legal — review before any publication, and the sync workflow must be able to *block* on them:

1. **Privacy policy DE/EN** — no source text exists. Current factual basis (no analytics in the product code, §9.3) is favourable but must be re-verified at generation time, since `docs/product/roadmap.md` contains analytics as a roadmap item.
2. **Data-deletion page and the process behind it** — store-required; requires an actual operational process, not only a page.
3. **License list** — needs a producing mechanism first, then a completeness check.
4. **Public roadmap** — carries commitment implications; internal lane labels (`now`, `next`, `someday`) should not be published verbatim.

**DERIVED.** Model approval as machine-readable state so `public-site-sync.yml` can gate on it, e.g. front-matter per page:

```yaml
---
page: privacy
locale: de
approval:
  status: pending        # pending | approved
  approved_by: ""        # human, never an agent
  approved_at: ""
  review_scope: legal
---
```

The sync job publishes only pages with `status: approved` and fails visibly — not silently — on the rest.

---

## 8. Release and Branch Model

### 8.1 Facts

| Aspect | State | Evidence |
|---|---|---|
| Default branch | `main` | `origin/HEAD -> origin/main` |
| Protection | described as protected | `CONTRIBUTING.md`: "`main` is the protected integration branch." **ASSUMPTION** that it is actually enforced |
| Working branches | short-lived feature branches, PR-only | `CONTRIBUTING.md`; in practice `feat/*` + 11 Dependabot branches |
| Release branches | `release/<maj.min>/<semver>` **conceptually** | `scripts/release/resolve_android_version.sh`, `android-build-release.yml` — **no such branch exists in the repository** |
| Tags | `v0.1.0`, `v2.0.0` | `git tag`. Patterns `android-v*` / `ios-v*` are declared as triggers but **no such tags exist** |
| Versioning | SemVer, single source `VERSION`, CI-enforced | `validate.yml`, `scripts/validate.sh`, ADR-0003 |
| Conventional Commits | yes, with a version-effect table | `CONTRIBUTING.md` |
| Beta/stable channels | `-beta.N` / `-rc.N` in the versionCode scheme + Play tracks `internal`/`production` | see below |
| Artifacts | AAB + APK + `SHA256SUMS.txt`; GitHub Release from CHANGELOG; handbook PDFs + screenshot ZIP | §5.3, §5.5 |
| Store deployment | Google Play only | `android-publish-play.yml` |
| iOS deployment | **none** | `build-ios.yml` builds only if a native project exists |
| Web hosting | **none** | no Pages/deploy workflow anywhere |

### 8.2 The version-resolution contract

**FACT**, `scripts/release/resolve_android_version.sh` — the whole channel model is encoded here:

```bash
# Resolve Android versionName + monotonic versionCode from a git ref.
#
# Accepted refs:
#   release/<maj.min>/<semver>   e.g. release/1.3/1.3.0-rc.1
#   v<semver> / refs/tags/v<semver>
#   <semver>                     e.g. 1.3.0-beta.2
#
# versionCode = major*10000000 + minor*100000 + patch*1000 + pre
#   pre: beta.N -> N (1..499), rc.N -> 500+N (N 1..498), final -> 999
#   => 1.3.0-beta.1 < 1.3.0-rc.1 < 1.3.0 and the Play limit (2.1e9) is
#      never reached (max 21x.xx.xx -> ~214 major versions).
#
# Output (stdout, and $GITHUB_OUTPUT when set):
#   version_name=<semver>
#   version_code=<int>

ref="${1:-$(git rev-parse --abbrev-ref HEAD)}"

case "$ref" in
  refs/tags/v*) semver="${ref#refs/tags/v}" ;;
  refs/heads/*) semver="${ref#refs/heads/}"; semver="${semver##*/}" ;;
  release/*/*)  semver="${ref##*/}" ;;
  v[0-9]*)      semver="${ref#v}" ;;
  *)            semver="$ref" ;;
esac

if [[ ! "$semver" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)(-(beta|rc)\.([0-9]+))?$ ]]; then
  echo "ERROR: '$ref' does not resolve to a semver (got '$semver')." >&2
  echo "Expected release/<maj.min>/<semver>, v<semver> or <semver>." >&2
  exit 1
fi
```

**DERIVED.** This is directly reusable across every LumbreCode Android app and is one of the few pieces here with a *proof obligation baked into the comment* (monotonicity, Play limit). Take it verbatim.

**OPEN.** The `release/<maj.min>/<semver>` branch model is supported by the tooling but unused in this repository. It may be inherited from the app *WasThereSomething* (referenced throughout `docs/ideas/wts-1.3.1-adoption-delta.md`). See Q4 in §14.

### 8.3 Release note generation

**FACT**, `.github/workflows/release.yml`:

```yaml
on:
  push:
    tags:
      - "v*"

permissions:
  contents: write

jobs:
  release:
    steps:
      - name: Validate tag matches VERSION
        run: |
          TAG="${GITHUB_REF#refs/tags/v}"
          VERSION="$(cat VERSION)"
          if [ "$TAG" != "$VERSION" ]; then
            echo "ERROR: Tag v$TAG does not match VERSION file ($VERSION)"
            exit 1
          fi

      - name: Generate release notes from CHANGELOG
        id: notes
        run: |
          VERSION="$(cat VERSION)"
          NOTES=$(awk "/^## \[$VERSION\]/{flag=1; next} /^## \[/{flag=0} flag" CHANGELOG.md)
          if [ -z "$NOTES" ]; then
            NOTES="Release v$VERSION"
          fi
          echo "notes<<EOF" >> "$GITHUB_OUTPUT"
          echo "$NOTES" >> "$GITHUB_OUTPUT"
          echo "EOF" >> "$GITHUB_OUTPUT"

      - name: Create GitHub Release
        uses: softprops/action-gh-release@v3
        with:
          name: "v${{ steps.version.outputs.version }}"
          body: ${{ steps.notes.outputs.notes }}
          draft: false
          prerelease: false
```

**DERIVED.** `prerelease: false` is hardcoded, but the version scheme explicitly supports `-beta.N` / `-rc.N`. A `v1.3.0-rc.1` tag would publish as a *final* release. Fix in the baseline:

```yaml
prerelease: ${{ contains(steps.version.outputs.version, '-') }}
```

### 8.4 When to synchronise the public site

**DERIVED**, from the evidence:

- `CHANGELOG.md` and `VERSION` are only guaranteed consistent at the tag — `release.yml` enforces `tag == VERSION`.
- A store rejection after publication would leave a public page advertising a version nobody can install.
- The version scheme already distinguishes prereleases mechanically.

**Recommendation:** trigger on `release: published` **and** a successful `android-publish-play` run against `production`, i.e. `workflow_run` chaining; skip whenever `version_name` contains `-` (prerelease). Default `dry_run: true` until the approval-state mechanism from §7.6 is in place.

---

## 9. Security and Privacy Observations

### 9.1 Secrets — names and purpose only

**FACT**, complete `secrets.*` reference list across all workflows:

```
_android-release-build.yml:77   HAS_KEYSTORE: ${{ secrets.ANDROID_KEYSTORE_BASE64 != '' }}
_android-release-build.yml:121  KEYSTORE_BASE64: ${{ secrets.ANDROID_KEYSTORE_BASE64 }}
_android-release-build.yml:122  KEYSTORE_PASSWORD: ${{ secrets.ANDROID_KEYSTORE_PASSWORD }}
_android-release-build.yml:123  KEY_ALIAS: ${{ secrets.ANDROID_KEY_ALIAS }}
_android-release-build.yml:124  KEY_PASSWORD: ${{ secrets.ANDROID_KEY_PASSWORD }}
android-publish-play.yml:85     serviceAccountJsonPlainText: ${{ secrets.PLAY_SERVICE_ACCOUNT_JSON }}
```

| Secret name | Scope | Purpose |
|---|---|---|
| `ANDROID_KEYSTORE_BASE64` | repository / environment | base64 of the upload keystore |
| `ANDROID_KEYSTORE_PASSWORD` | repository / environment | keystore password |
| `ANDROID_KEY_ALIAS` | repository / environment | key alias |
| `ANDROID_KEY_PASSWORD` | repository / environment | key password |
| `PLAY_SERVICE_ACCOUNT_JSON` | environment (publish) | Google Play service account |
| `github.token` | automatic | GitHub Release creation in `integration-test.yml` |

**FACT**, documented in `docs/operations/android-release-secrets.md` with setup commands (values never in the repo):

```bash
base64 -w0 upload-keystore.jks | gh secret set ANDROID_KEYSTORE_BASE64
gh secret set ANDROID_KEYSTORE_PASSWORD   # prompts for the value
gh secret set ANDROID_KEY_ALIAS --body "upload"
gh secret set ANDROID_KEY_PASSWORD
gh secret set PLAY_SERVICE_ACCOUNT_JSON < service-account.json
```

**FACT.** **No `vars.*` reference exists anywhere in the repository.**

**FACT.** GitHub Environments used as approval gates: `google-play-internal`, `google-play-production`.

**ASSUMPTION.** Whether these secrets are actually populated cannot be determined from the tree. The workflow is explicitly designed to run without them (debug-signing fallback), which suggests the template repository has none set.

### 9.2 External services and network egress

| Service | Where | Note |
|---|---|---|
| OSV.dev | `tools/audit_deps.dart` | "no account, no API key; only public package names and versions are sent" (documented in `scripts/deps/audit.sh`) |
| Google Play API | `android-publish-play.yml` | third-party action holds the credential |
| `ghcr.io/cirruslabs/flutter:stable` | `docker-compose.yml`, `docker/Dockerfile.flutter-chrome` | floating tag |
| Google Stitch MCP | `.mcp.json`, `.vscode/mcp.json`, `.codex/config.toml` | see below |

**FACT**, `.mcp.json`:

```json
{
  "mcpServers": {
    "stitch": {
      "command": "npx",
      "args": ["-y", "@_davideast/stitch-mcp", "proxy"]
    }
  }
}
```

**DERIVED.** `npx -y` fetches an **unpinned** package from npm on every start, in a developer/agent context. For a baseline this is a supply-chain decision that deserves an explicit version. Auth is via `STITCH_API_KEY` (documented in `docs/operations/stitch-mcp.md`), and `AGENTS.md` already constrains how Stitch output may be used:

```markdown
- Designs pulled via the Google Stitch MCP server land in `design/`
  (screenshot + HTML export + manifest entry) and are design references
  only — re-implement them as Flutter widgets via `packages/design_system`,
  never port the generated HTML.
```

### 9.3 Analytics, telemetry and personal data

**FACT.** A case-insensitive search for `firebase|analytics|crashlytics|sentry|telemetry|posthog` across `apps/`, `packages/`, `services/`, `docs/` and `.github/` matches **documentation only**:

```
docs/architecture/arc42/03-context-and-scope.md
docs/operations/build-web.md
docs/operations/workflow-guide-de.md
docs/operations/workflow-guide-en.md
docs/product/roadmap.md
.github/agents/template-initializer.agent.md
```

No analytics SDK appears in any `pubspec.yaml` or Dart source.

**DERIVED.** For a privacy policy this is the correct, evidenced starting position: *the template collects nothing*. It changes the moment a roadmap item is implemented — so the privacy page generation must re-verify this fact at build time rather than trusting a one-off statement. A mechanical check (grep for known SDK package names in the resolved `pubspec.lock`) belongs in `public-site-sync.yml`.

**FACT.** No personal data in tests or logs. The only mail addresses in test code are the organisation's functional mailboxes:

```
apps/mobile_app/test/core/errors_test.dart:39            expect(uri.path, 'bugs@lumbrecode.de');
apps/mobile_app/test/features/about/about_page_test.dart:114  expect(uri.path, 'bugs@lumbrecode.de');
apps/mobile_app/test/features/about/about_page_test.dart:132  expect(launched.single.path, 'feedback@lumbrecode.de');
apps/mobile_app/test/features/splash/startup_error_page_test.dart:99  expect(uri.path, 'bugs@lumbrecode.de');
```

No fixtures with real names, no plaintext logs containing user data.

### 9.4 Finding: a machine-local settings file is committed

**FACT.** `.claude/settings.local.json` is tracked by git and **not** covered by `.gitignore`:

```
$ git ls-files .claude/
.claude/settings.local.json
.claude/skills/codegen/SKILL.md
.claude/skills/quality-gate/SKILL.md
.claude/skills/test-summary/SKILL.md

$ git check-ignore -v .claude/settings.local.json
(no output — not ignored)
```

**FACT.** It contains no secrets, but it does contain a machine-local permission allowlist with absolute Windows paths, a user directory name and a session UUID (path redacted here):

```json
{
  "permissions": {
    "allow": [
      "PowerShell(git rm apps/mobile_app/assets/animations/lumbrecode_splash_placeholder.json)",
      "PowerShell(powershell.exe -NoProfile -ExecutionPolicy Bypass -File \"C:\\Users\\<redacted>\\AppData\\Local\\Temp\\claude\\<repo>\\<session-uuid>\\scratchpad\\parse_check.ps1\")",
      "WebSearch",
      "WebFetch(domain:github.com)",
      "PowerShell(cd \\(git rev-parse --show-toplevel\\); melos bs)"
    ]
  }
}
```

**FACT.** There is **no** `.claude/settings.json` (the shared, intended-to-be-committed counterpart).

**DERIVED.** Add `.claude/settings.local.json` to `.gitignore`, remove it from tracking, and introduce a shared `.claude/settings.json` — which is then a natural baseline sync target. Leaving both files in place would set a confusing precedent for every repository the baseline touches.

### 9.5 Security practices worth promoting to policy

**FACT**, from `AGENTS.md`:

```markdown
## Safety rules

- Never commit secrets, certificates, provisioning profiles, API keys, or passwords.
- Never hardcode production endpoints in example code.
- Prefer placeholders and documented secret names.
- Do not delete user-authored drafts or design assets unless explicitly asked.
```

Plus, evidenced in the workflows: `permissions: contents: read` as the default; secrets via `env:` not string interpolation; `if: always()` cleanup of signing material; no `pull_request_target` anywhere in the repository; `SECURITY.md` present with `security@lumbrecode.de`.

---

## 10. Conflicts with the Proposed Baseline

### C1 — Two competing distribution mechanisms

**Evidence:** `AGENTS.md` "Template identity", `.github/agents/template-initializer.agent.md`, `docs/operations/template-initialization.md`.

**Impact:** Undefined authority. When a derived app needs a rule, does it come from the template copy it was born with, or from a baseline sync? Both paths will exist simultaneously unless one is declared subordinate.

**Recommendation:** Declare the baseline authoritative for *cross-repository* concerns (CI, release, security, agent process rules) and the template authoritative for *Flutter-app-shape* concerns (structure, example app, initialisation). Write this split down in the baseline README as the first section.

---

### C2 — Three skill ecosystems

**Evidence:** §6.2. `.github/skills/` (10, no frontmatter), `.claude/skills/` (3, frontmatter), `.agents/skills/` (19, hash-locked to `dart-lang/skills`).

**Impact:** A central sync into `.agents/skills/` invalidates `skills-lock.json`. `.github/skills/` content is invisible to Claude Code. Names could collide across the three namespaces.

**Recommendation:** `.claude/skills/` canonical → project into the others; `.agents/skills/` stays a pure upstream mirror; add frontmatter to `.github/skills/`.

---

### C3 — `AGENTS.md` is majority repository-specific

**Evidence:** §6.5 section table. Todo preservation, splash/Lottie rules, OpenSpec, ADR table.

**Impact:** A whole-file sync deletes a safety rule that exists to stop agents from destroying the template's reference implementation.

**Recommendation:** marker-based section sync (§6.5), never file replacement.

---

### C4 — Fourfold rule duplication, already diverged

**Evidence:** the same rules in `AGENTS.md`, `.github/copilot-instructions.md`, `.codex/config.toml`, `docs/operations/agent-entrypoints.md`; `docs/architecture/contracts/` present in one, missing from three.

**Illustration** — the drafts rule, written three times:

```markdown
# AGENTS.md
- **`drafts/`** — All content is unfinished, exploratory, and not binding.
  Do NOT incorporate drafts into implementations, decisions, or answers.
  Exception: the user explicitly points to a specific draft file.
```

```markdown
# .github/copilot-instructions.md
## Drafts are non-normative
- Content under `drafts/` is exploratory and unfinished.
- Do NOT use drafts for implementation, decisions, or answers.
- Exception: the user explicitly points to a specific draft file.
```

```toml
# .codex/config.toml
excluded_paths = [
  "drafts/",
]
```

**Impact:** Syncing one file immediately contradicts the other three.

**Recommendation:** one prose source (`AGENTS.md`), machine formats derived or reduced to pointers. Ideally the baseline *generates* `.codex/config.toml` and `copilot-instructions.md` from a single YAML rule set.

---

### C5 — Rules the repository violates itself

**Evidence A**, the rule (`AGENTS.md`, and near-verbatim in `copilot-instructions.md`):

```markdown
- In `.sh` and `.ps1` scripts, use only ASCII characters in string literals. No embedded Unicode symbols or emoji — they break on Windows PowerShell and non-UTF-8 shells. Use `[char]0xNNNN` in PowerShell or `printf '\uNNNN'` in bash when a symbol is required.
```

**Evidence B**, the violation (`scripts/pre-commit.sh`, `scripts/pre-push.sh`):

```bash
echo "✗ Formatting check failed. Run 'dart format .' and re-stage."
echo "✓ Pre-commit format check passed (analyze + test run on push)."
echo "==> analyze + test (running in parallel)…"
```

**Evidence C**, the unimplemented mandate (`ci.instructions.md`, §4.4 Gap 3).

**Impact:** A baseline that enforces the written rules turns the repository red on the first run — which will be read as "the baseline is broken", not "the repository was non-compliant".

**Recommendation:** fix both sides *before* the first sync. Either narrow the rule (e.g. "no emoji; `✓`/`✗` permitted where UTF-8 output is guaranteed") or clean the two hook scripts. Then land `script-lint.yml` so it cannot regress.

---

### C6 — Release ownership collision (highest operational severity)

**Evidence A**, `release.yml` — creates the release on tag `v*`:

```yaml
on:
  push:
    tags:
      - "v*"
# ...
      - name: Create GitHub Release
        uses: softprops/action-gh-release@v3
        with:
          name: "v${{ steps.version.outputs.version }}"
          body: ${{ steps.notes.outputs.notes }}   # from CHANGELOG.md
```

**Evidence B**, `integration-test.yml` — on `push: main`, **deletes and recreates the same release**:

```yaml
on:
  workflow_dispatch:
  push:
    branches: ["main"]
    paths:
      - "apps/mobile_app/integration_test/**"
      - "VERSION"
# ...
      - name: Create or update GitHub Release
        env:
          GH_TOKEN: ${{ github.token }}
        run: |
          VERSION="${{ steps.version.outputs.version }}"
          TAG="v${VERSION}"
          # Delete existing release to overwrite (keeps the git tag)
          gh release delete "$TAG" --yes 2>/dev/null || true
          sleep 3
          gh release create "$TAG" \
            --title "Handbook ${TAG}" \
            --notes "Auto-generated integration test handbooks for version ${VERSION}." \
            docs/testing/generated/handbook-*.pdf \
            docs/testing/generated/screenshots-v${VERSION}.zip
```

**Impact:** Order-dependent loss. If the integration-test workflow runs after `release.yml` for the same `VERSION`, the CHANGELOG-derived release notes are replaced by `"Auto-generated integration test handbooks for version X"`, and any assets attached by the release workflow disappear. The `|| true` and `sleep 3` show this was known to be racy.

**Recommendation (concrete):** replace delete-and-recreate with an idempotent upload:

```yaml
      - name: Attach handbook assets to the release
        env:
          GH_TOKEN: ${{ github.token }}
        run: |
          VERSION="${{ steps.version.outputs.version }}"
          TAG="v${VERSION}"
          # Create only if missing; never delete an existing release.
          gh release view "$TAG" >/dev/null 2>&1 || \
            gh release create "$TAG" --title "v${VERSION}" --notes "Release ${TAG}"
          gh release upload "$TAG" \
            docs/testing/generated/handbook-*.pdf \
            "docs/testing/generated/screenshots-v${VERSION}.zip" \
            --clobber
```

---

### C7 — Toolchain version duplication

**Evidence:** `version: 3.44.4` in eight workflow files; `flutter:stable` in three Docker files; `dart pub global activate melos` unpinned in four workflows.

**Impact:** Bulk-edit maintenance (the git history shows a previous `3.41.9 → 3.44.4` sweep across five files), plus a silent local/CI divergence.

**Recommendation:** `flutter_version` as a workflow input with one organisational default; pin the Docker tag to the same version; `dart pub global activate melos <version>`.

---

### C8 — No concurrency control

**Evidence:** `grep -rn "concurrency" .github/workflows/` returns nothing.

**Impact:** Duplicate parallel runs; for `glossary-generate.yml` (which pushes) also a race.

**Recommendation:** ship centrally:

```yaml
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: ${{ github.event_name == 'pull_request' }}
```

---

### C9 — A workflow pushes directly to `main`

**Evidence**, `glossary-generate.yml`:

```yaml
permissions:
  contents: write
# ...
      - name: Commit updated glossary
        if: steps.diff.outputs.changed == 'true'
        run: |
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          git add docs/architecture/arc42/12-glossary.md
          git commit -m "docs: regenerate glossary from CSV"
          git pull --rebase
          git push
```

**Impact:** Conflicts with a "every change goes through a PR" baseline rule, and with branch protection if enforced. **ASSUMPTION** — protection state unknown.

**Recommendation:** convert to a PR-opening job, or record an explicit, documented exception in the baseline.

---

### C10 — Native folders are generated, not committed

**Evidence:** §2.3. Every Android build runs `scripts/bootstrap_android.sh` and `tools/patch_android_signing.dart`.

**Impact:** A generic central Flutter build workflow fails here.

**Recommendation:** `bootstrap_android: <bool>` and `patch_signing_tool: <path>` as inputs, both defaulting to off for ordinary app repositories.

---

### C11 — Repo-specific assertions inside otherwise generic workflows

**Evidence:** `validate.yml` runs `bash scripts/validate_openspec.sh` and asserts `docs/architecture/arc42/01-...` and `docs/api/openapi.yaml` exist; `docs-check.yml` asserts `docs/ideas/simple/ideas.md` and the spec templates exist:

```yaml
      - name: Check idea inbox exists
        run: test -f docs/ideas/simple/ideas.md

      - name: Check processed-index is valid YAML
        run: |
          python3 -c "
          import yaml, sys
          ...
          "
```

**Impact:** Meaningless or wrong for repositories that do not use the idea-inbox workflow.

**Recommendation:** make the required-file list and each structural check an input with sane defaults.

---

### C12 — Committed machine-local agent settings

**Evidence:** §9.4.

**Impact:** A centrally distributed `.claude/settings.json` would sit next to a versioned `settings.local.json`, teaching the wrong pattern to every consuming repository.

---

### C13 — Unstable working tree at analysis time

**Evidence:** 138 uncommitted paths on `feat/adopt-wts-1.3.1-learnings`; `docs/ideas/wts-1.3.1-adoption-delta.md` describes waves 1–4 as implemented on this branch:

```markdown
Branch `feat/adopt-wts-1.3.1-learnings` (von `main` `3382a50`).
Quality Gate grün: `melos run analyze` ohne Befund, **119 Flutter-Tests** und
**34 Dart-Tests** bestanden, `format:check` sauber, Codegen idempotent.
(Ausgangsstand auf `main`: 60 Flutter-Tests.)
```

**Impact:** Any diff-based sync evaluation against `main` is currently incomplete.

**Recommendation:** merge or close the branch before starting the migration.

---

## 11. Recommended Shared Components

**Recommended profile: `flutter`** (optional `node` add-on for `backend/`).

### 11.1 Central workflows

All as `workflow_call` — the pattern `_android-release-build.yml` already proves out here.

| Workflow | Derived from | Required inputs |
|---|---|---|
| `flutter-ci.yml` | `ci-mobile.yml` | `flutter_version`, `melos_version`, `java_version`, `app_dir`, `run_codegen_drift_check`, `coverage_path`, `min_coverage` |
| `flutter-android-release.yml` | `_android-release-build.yml` | `ref`, `flutter_version`, `java_version`, `app_dir`, `bootstrap_android`, `dart_defines` |
| `flutter-android-publish.yml` | `android-publish-play.yml` | `track`, `rollout_fraction`, `environment_name`, `package_name_source` |
| `dependency-audit.yml` | `dependency-audit.yml` + `tools/audit_deps.dart` | `schedule_cron`, `audit_tool_path`, `fail_on_findings` |
| `repo-validate.yml` | `validate.yml` minus OpenSpec | `version_file`, `app_pubspec_path`, `required_files`, `check_adr_naming` |
| `script-lint.yml` | **new** — implements `ci.instructions.md` | `shell_paths`, `ps_paths`, `severity` |
| `license-report.yml` | **new** — closes the largest gap | `app_dir`, `output_path`, `allowlist`, `fail_on_unknown` |
| `public-site-sync.yml` | **new** — approval-gated | `site_repo`, `slug`, `version`, `dry_run` |

### 11.2 Skeletons for the two new workflows

**`script-lint.yml`** — implements a rule this repository already agreed to:

```yaml
name: Script Lint
on:
  workflow_call:
    inputs:
      shell_paths:
        type: string
        default: "scripts"
      ps_paths:
        type: string
        default: "scripts"
      severity:
        type: string
        default: "warning"

permissions:
  contents: read

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: ${{ github.event_name == 'pull_request' }}

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6

      - name: shellcheck
        run: |
          find ${{ inputs.shell_paths }} -name '*.sh' -print0 \
            | xargs -0 -r shellcheck --severity=${{ inputs.severity }}

      - name: PowerShell parser
        shell: pwsh
        run: |
          $failed = $false
          Get-ChildItem '${{ inputs.ps_paths }}' -Filter *.ps1 -Recurse | ForEach-Object {
            $e = $null
            $null = [System.Management.Automation.Language.Parser]::ParseFile($_.FullName, [ref]$null, [ref]$e)
            if ($e) { $e; $failed = $true }
          }
          if ($failed) { exit 1 }

      # Enforces the repository's own ASCII rule for script string literals.
      - name: ASCII-only check for shell and PowerShell scripts
        run: |
          if LC_ALL=C grep -rnP '[^\x00-\x7F]' --include='*.sh' --include='*.ps1' ${{ inputs.shell_paths }}; then
            echo "::error::Non-ASCII characters found in script files (see AGENTS.md 'Writing rules')."
            exit 1
          fi

      - name: yamllint
        run: |
          pipx install yamllint
          yamllint .github/workflows
```

> **Note:** the ASCII step currently fails on `scripts/pre-commit.sh` and `scripts/pre-push.sh` (C5). Land it with `continue-on-error: true`, fix the two scripts, then make it blocking.

**`license-report.yml`** — closes Gap 1 and feeds `/licenses/`:

```yaml
name: License Report
on:
  workflow_call:
    inputs:
      app_dir:
        type: string
        default: "apps/mobile_app"
      flutter_version:
        type: string
        required: true
      output_path:
        type: string
        default: "docs/public-site/licenses.md"
      fail_on_unknown:
        type: boolean
        default: true

permissions:
  contents: read

jobs:
  licenses:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
      - uses: flutter-actions/setup-flutter@v4
        with:
          channel: stable
          version: ${{ inputs.flutter_version }}
          cache: true

      - name: Resolve dependencies
        working-directory: ${{ inputs.app_dir }}
        run: flutter pub get

      # Reuses the pubspec.lock parsing that tools/audit_deps.dart already does,
      # so license collection and vulnerability scanning share one source of truth.
      - name: Collect third-party licenses
        run: dart tools/collect_licenses.dart --output "${{ inputs.output_path }}" \
               ${{ inputs.fail_on_unknown && '--fail-on-unknown' || '' }}

      - name: Upload license report
        uses: actions/upload-artifact@v7
        with:
          name: license-report
          path: ${{ inputs.output_path }}
```

**DERIVED.** `tools/collect_licenses.dart` does not exist yet. It should be written **in the baseline repository** and vendored, exactly as `audit_deps.dart` is vendored today — same `pubspec.lock` parsing, same output conventions.

### 11.3 Central skills

Format: frontmatter with `name` + `description` (the `.claude/skills/` shape, which is already correct).

| Skill | Origin | Note |
|---|---|---|
| `quality-gate` | `.claude/skills/quality-gate/` | ship with `scripts/dev/quality_gate.{sh,ps1}` |
| `test-summary` | `.claude/skills/test-summary/` | ship with `scripts/dev/test_summary.{sh,ps1}` |
| `codegen` | `.claude/skills/codegen/` | ship with `scripts/dev/codegen.{sh,ps1}` |
| `dependency-audit` | new, wraps `scripts/deps/audit.sh` | mention `--offline` explicitly |
| `release-prepare` | from `.github/skills/release-checklist/` + `docs/operations/release-checklist.md` | add frontmatter |
| `adr-write` | from `docs/architecture/adr/_template.md` + `CONTRIBUTING.md` triggers | |
| `a11y-check` | new, from `contracts/07-accessibility.md` | needs the `test:a11y` script first |

### 11.4 Files to synchronise

```
.github/workflows/<central workflows>.yml
.github/instructions/{ci,tests,docs,scripts}.instructions.md
.github/agents/{planner,implementer,reviewer}.agent.md
.claude/skills/{quality-gate,test-summary,codegen,dependency-audit}/SKILL.md
.claude/settings.json                       # new, shared
scripts/dev/{quality_gate,test_summary,codegen}.{sh,ps1}
scripts/lib/{common.sh,Common.ps1}
scripts/{pre-commit.sh,pre-push.sh,install-hooks.sh,install-hooks.ps1}
scripts/release/resolve_android_version.sh
tools/audit_deps.dart
tools/collect_licenses.dart                 # new
docs/architecture/contracts/*.md            # as the baseline contract standard
.editorconfig
.gitattributes
AGENTS.baseline.md                          # injected into AGENTS.md markers
lumbrecode.manifest.yaml                    # new, see below
```

**DERIVED — the manifest.** `ORG`, `appsBaseUrl`, `basePackage` and the mailbox list are currently duplicated between `project.env` (shell) and Dart source (`AppBranding`, `SupportMailbox`). One baseline-owned manifest should be the source, with both sides generated or checked against it:

```yaml
# lumbrecode.manifest.yaml — owned by lumbrecode-engineering
organisation:
  name: LumbreCode
  domain: LumbreCode.de
  base_package: de.lumbre.code
  apps_base_url: https://lumbrecode.de/apps
mailboxes:
  support:  support@lumbrecode.de
  feedback: feedback@lumbrecode.de
  bugs:     bugs@lumbrecode.de
  privacy:  privacy@lumbrecode.de
  security: security@lumbrecode.de
  contact:  contact@lumbrecode.de
  legal:    legal@lumbrecode.de
public_pages: [website, support, faq, privacy, data-deletion, changelog, licenses]
toolchain:
  flutter: "3.44.4"
  melos: "7.7.0"
  java: "17"
  dart_sdk: "^3.12.0"
```

A cheap CI check (`grep`/parse the Dart constants against the manifest) then catches drift without a code generator.

### 11.5 Required secret names

Central documentation, per-repository configuration:

```
ANDROID_KEYSTORE_BASE64
ANDROID_KEYSTORE_PASSWORD
ANDROID_KEY_ALIAS
ANDROID_KEY_PASSWORD
PLAY_SERVICE_ACCOUNT_JSON
```

Plus, for public-site sync: a write credential for the site repository. **Recommendation:** a GitHub App with a narrowly scoped contents-write permission rather than a PAT. Proposed name if a token is used anyway: `PUBLIC_SITE_TOKEN`.

---

## 12. Repository-Specific Exceptions

These stay out of the sync, with the reason for each:

1. **Todo-app preservation rule** — `AGENTS.md`, `apps/mobile_app/AGENTS.md`, `.github/copilot-instructions.md`. A safety rule protecting the reference implementation.
2. **Splash rules incl. Lottie filenames** — `lumbrecode_logo_reveal_3s_{de,en}_sequential.json`, plus the prohibition on loading splash animations from external URLs.
3. **The initializer replacement table** in `apps/mobile_app/AGENTS.md` (which file is replaced / deleted / adapted / kept during `apply`).
4. **OpenSpec** — `openspec/`, `scripts/validate_openspec.sh`, the `Validate OpenSpec` step, the `spec-promotion.yml` issue template.
5. **Template initializer** — `.github/agents/template-initializer.agent.md`, `tools/apply_project_naming.dart`, `project.env`, `scripts/lib/read_env.sh` / `Read-ProjectEnv.ps1`.
6. **Documentation pipeline** — `docs-build.yml`, `diagrams-build.yml`, `glossary-generate.yml`, `docs/architecture/pandoc/`, `scripts/automation/docs/`. arc42 + PlantUML + Draw.io + Mermaid + Pandoc is a deep, repo-specific stack.
7. **Integration-test handbook pipeline** — `integration-test.yml`, `scripts/automation/integration-test/` incl. `profiles.json`. Docker-heavy and built around template screenshots.
8. **`.agents/skills/` (19 vendored skills)** — upstream mirror of `dart-lang/skills` with `skills-lock.json`. Standardise the *mechanism*, not the content.
9. **Node backend** — `backend/`, `ci-backend-node.yml`. Explicitly removable.
10. **Document language** — `AGENTS.md`, `README.md` and instructions are English; the contracts (`docs/architecture/contracts/`), `release-checklist.md` and the delta document are German. `AGENTS.md` sanctions this:

    ```markdown
    ## Writing rules
    - Keep code and technical instructions in English.
    - Product notes and architecture docs may be German when that matches the existing file.
    ```

    **DERIVED.** If the contracts move to the baseline as a shared standard, their language must be decided deliberately — a mixed-language baseline is harder for agents and for new contributors than a mixed-language single repository.
11. **`build-android.yml` / `build-ios.yml`** — better consolidated into the central workflows or removed than synchronised.

---

## 13. Migration Plan

Ordered by risk and dependency. Each step has a checkable exit condition.

### Step 0 — Stabilise the tree
Merge or close `feat/adopt-wts-1.3.1-learnings`. With 138 open paths every sync evaluation runs against a moving target (C13).
**Exit:** `git status` clean, `./scripts/validate.sh` green on `main`.

### Step 1 — Resolve the repository's internal contradictions
- **C6:** replace delete-and-recreate in `integration-test.yml` with `gh release upload --clobber` (patch in §10/C6).
- **C5:** reconcile the ASCII rule with `scripts/pre-commit.sh` and `scripts/pre-push.sh`.
- **C12:** untrack `.claude/settings.local.json`, add it to `.gitignore`.
- **§8.3:** make `prerelease:` dynamic in `release.yml`.
**Exit:** a test tag produces exactly one release with CHANGELOG notes *and* handbook assets.

### Step 2 — Collapse the rule duplication (C4)
`AGENTS.md` stays the prose source. `.codex/config.toml` and `docs/operations/agent-entrypoints.md` become pointers. Add `docs/architecture/contracts/` to every normative list. Refresh the stale `[checks]` block in `.codex/config.toml`.
**Exit:** no rule appears verbatim in more than one file.

### Step 3 — Introduce the marker mechanism (C3)
Add `<!-- lumbrecode-baseline:start -->` / `:end` to `AGENTS.md`; populate `AGENTS.baseline.md` from the transferable sections in §6.5.
**Exit:** a `--dry-run` sync produces no diff outside the markers.

### Step 4 — Unify the skill model (C2)
`.claude/skills/` canonical; add frontmatter to the ten `.github/skills/` files; leave `.agents/skills/` untouched. Add the missing path instructions (`scripts/**`, `tools/**`, `backend/**`, `packages/*/lib/**`).
**Exit:** all three agent runtimes resolve the same three core skills.

### Step 5 — Land the two new, non-breaking workflows
`script-lint.yml` and `license-report.yml` first — they are additive and close the two verified gaps. Start with `continue-on-error: true`, then make blocking.
**Exit:** both green on `main`; `/licenses/` has a producer.

### Step 6 — Centralise `flutter-ci.yml`
Convert `ci-mobile.yml` into a call. Add `concurrency`, pin melos, parameterise `flutter_version`.
**Exit:** identical check depth as today; `3.44.4` appears in exactly one place.

### Step 7 — Centralise the release workflows
Lift `_android-release-build.yml` into the baseline; reduce the local file to a call; delete `build-android.yml`. Pin `r0adkll/upload-google-play` to a SHA.
**Exit:** an `-rc.N` build reaches Play track `internal` end to end.

### Step 8 — Public site, last
Create `docs/public-site/` with the three derivable artifacts (manifest, changelog, assets). Add FAQ, privacy DE/EN, data-deletion and licenses as **approval-blocked placeholders** with the front-matter from §7.6 — not as generated text. Wire `public-site-sync.yml` to `release: published`, environment-gated, `dry_run: true` by default, skipping prereleases.
**Exit:** a dry run for `v2.0.0` lists the full page set and reports the four approval-blocked pages as blocked, not published.

---

## 14. Open Questions

1. **Authority (C1):** is `lumbrecode-engineering` the source for derived apps, or does the template remain so? Who syncs whom?
2. **Direction for this repository:** is `flutter-app-template` a *consumer* of the baseline, or the place where baseline changes originate and flow back?
3. **Branch protection on `main`:** enforced? If so, how is the direct push in `glossary-generate.yml` currently permitted? (Not determinable from the tree.)
4. **`release/<maj.min>/<semver>`:** binding model or an artefact inherited from *WasThereSomething*? No such branch exists here.
5. **iOS:** should the baseline provide a signing + TestFlight path, or does iOS stay build-only for now?
6. **Web hosting:** where does `lumbrecode.de` run? Without that target `public-site-sync.yml` cannot be specified.
7. **License output format:** what does `/licenses/` expect — generated HTML, JSON, or maintained Markdown?
8. **Approval process:** who approves privacy and data-deletion texts, and how is the approval recorded machine-readably so the sync job can gate on it?
9. **Stitch MCP:** pin `@_davideast/stitch-mcp` to a version in the baseline?
10. **`.agents/skills/`:** is the vendoring mechanism (`skills-lock.json`) standardised centrally, and who refreshes the upstream hashes?
11. **Contract language:** if `docs/architecture/contracts/` becomes a shared standard — German or English?
12. **Coverage policy:** `ci-mobile.yml` only checks that `lcov.info` exists. Should the baseline enforce a threshold, and at what level?

---

## 15. Machine-readable summary

```json
{
  "repository": "FlorianTim/flutter-app-template",
  "repositoryType": "flutter",
  "analysedRef": "feat/adopt-wts-1.3.1-learnings",
  "baseCommit": "3382a50",
  "version": "2.0.0",
  "workingTreeDirtyPaths": 138,
  "qualityCommands": [
    { "purpose": "format", "command": "melos run format:check", "source": "pubspec.yaml" },
    { "purpose": "format-fix", "command": "melos run format:fix", "source": "pubspec.yaml" },
    { "purpose": "analyze", "command": "melos run analyze", "source": "pubspec.yaml" },
    { "purpose": "unit-test", "command": "melos run test:dart", "source": "pubspec.yaml" },
    { "purpose": "widget-test", "command": "melos run test:flutter", "source": "pubspec.yaml" },
    { "purpose": "test-compact", "command": "bash scripts/dev/test_summary.sh", "source": ".claude/skills/test-summary/SKILL.md" },
    { "purpose": "quality-gate", "command": "bash scripts/dev/quality_gate.sh", "source": "scripts/dev/quality_gate.sh" },
    { "purpose": "integration-test", "command": "docker compose run --rm mobile-integration-test-web", "source": "docker-compose.yml" },
    { "purpose": "codegen", "command": "melos run codegen", "source": "pubspec.yaml" },
    { "purpose": "codegen-drift", "command": "melos run codegen && git diff --exit-code", "source": ".github/workflows/ci-mobile.yml" },
    { "purpose": "ci", "command": "melos run ci", "source": "pubspec.yaml" },
    { "purpose": "full-validate", "command": "./scripts/validate.sh", "source": "scripts/validate.sh" },
    { "purpose": "build-web", "command": "melos run build:web", "source": "pubspec.yaml" },
    { "purpose": "build-android", "command": "flutter build appbundle --release --dart-define=APP_FLAVOR=prod", "source": ".github/workflows/_android-release-build.yml" },
    { "purpose": "security-audit", "command": "melos run audit", "source": "pubspec.yaml" },
    { "purpose": "security-audit-local", "command": "scripts/deps/audit.sh [--fix|--json|--offline]", "source": "scripts/deps/audit.sh" },
    { "purpose": "backend-node", "command": "npm run lint && npm test", "source": "backend/package.json" },
    { "purpose": "backend-dart", "command": "dart analyze && dart test", "source": ".github/workflows/ci-backend.yml" },
    { "purpose": "license-check", "command": null, "source": null, "status": "missing" },
    { "purpose": "accessibility-check", "command": null, "source": "apps/mobile_app/test/a11y/accessibility_test.dart", "status": "tests-only-no-entrypoint" }
  ],
  "existingAutomation": [
    { "file": ".github/workflows/validate.yml", "trigger": "pull_request, push:main", "reusable": "partial" },
    { "file": ".github/workflows/ci-mobile.yml", "trigger": "pull_request, push:main (paths)", "reusable": "high" },
    { "file": ".github/workflows/ci-backend.yml", "trigger": "pull_request, push:main (paths)", "reusable": "medium" },
    { "file": ".github/workflows/ci-backend-node.yml", "trigger": "pull_request, push:main (paths)", "reusable": "medium" },
    { "file": ".github/workflows/_android-release-build.yml", "trigger": "workflow_call", "reusable": "very-high" },
    { "file": ".github/workflows/android-build-release.yml", "trigger": "workflow_dispatch", "reusable": "high" },
    { "file": ".github/workflows/android-publish-play.yml", "trigger": "workflow_dispatch", "reusable": "high" },
    { "file": ".github/workflows/build-android.yml", "trigger": "workflow_dispatch, tag:android-v*", "reusable": "redundant" },
    { "file": ".github/workflows/build-ios.yml", "trigger": "workflow_dispatch, tag:ios-v*", "reusable": "low" },
    { "file": ".github/workflows/dependency-audit.yml", "trigger": "schedule:17 5 * * 1, workflow_dispatch, pull_request", "reusable": "very-high" },
    { "file": ".github/workflows/release.yml", "trigger": "tag:v*", "reusable": "medium" },
    { "file": ".github/workflows/integration-test.yml", "trigger": "push:main (paths), workflow_dispatch", "reusable": "low" },
    { "file": ".github/workflows/docs-build.yml", "trigger": "push:main (paths)", "reusable": "repo-specific" },
    { "file": ".github/workflows/diagrams-build.yml", "trigger": "push:main (paths)", "reusable": "repo-specific" },
    { "file": ".github/workflows/glossary-generate.yml", "trigger": "push:main (paths)", "reusable": "repo-specific" },
    { "file": ".github/workflows/docs-check.yml", "trigger": "pull_request (paths)", "reusable": "repo-specific" },
    { "file": ".github/workflows/copilot-setup-steps.yml", "trigger": "workflow_dispatch, push/pr self", "reusable": "high" },
    { "file": ".github/dependabot.yml", "trigger": "weekly", "ecosystems": ["github-actions", "pub", "docker", "npm"] },
    { "file": "scripts/pre-commit.sh", "trigger": "git hook (path-aware format)", "reusable": "high" },
    { "file": "scripts/pre-push.sh", "trigger": "git hook (parallel analyze+test)", "reusable": "high" }
  ],
  "actionsInUse": {
    "actions/checkout@v6": 18,
    "flutter-actions/setup-flutter@v4": 8,
    "actions/upload-artifact@v7": 5,
    "actions/setup-java@v5": 5,
    "softprops/action-gh-release@v3": 1,
    "r0adkll/upload-google-play@v1": 1,
    "dart-lang/setup-dart@v1": 1,
    "actions/setup-node@v4": 1,
    "actions/download-artifact@v7": 1
  },
  "publicSite": {
    "exists": false,
    "pageSet": ["website", "support", "faq", "privacy", "data-deletion", "changelog", "licenses"],
    "authoritativeSources": [
      "packages/app_core/lib/src/app_links.dart",
      "packages/app_core/lib/src/app_branding.dart",
      "project.env",
      "openspec/apps/todoapp.openspec.yaml",
      "apps/mobile_app/lib/app/app_identity.dart",
      "CHANGELOG.md",
      "VERSION",
      "docs/product/roadmap.md",
      "design/manifests/"
    ],
    "missingContent": [
      "faq-de", "faq-en",
      "privacy-de", "privacy-en",
      "data-deletion",
      "licenses",
      "end-user-guides",
      "public-manifest",
      "public-asset-set"
    ],
    "legalReviewRequired": ["privacy-de", "privacy-en", "data-deletion", "licenses", "roadmap"],
    "mustNotBePublic": ["drafts/", "docs/ideas/", "docs/delivery/reviews/", "docs/known-issues.md", "docs/operations/android-release-secrets.md", "docs/operations/ios-signing.md", ".claude/settings.local.json"]
  },
  "recommendedProfile": "flutter",
  "conflicts": [
    { "id": "C1", "severity": "strategic", "summary": "template-initializer vs. central sync: two competing distribution mechanisms" },
    { "id": "C2", "severity": "high", "summary": "three skill ecosystems (.github/skills without frontmatter, .claude/skills, .agents/skills hash-locked)" },
    { "id": "C3", "severity": "high", "summary": "AGENTS.md is majority repository-specific; whole-file sync would delete safety rules" },
    { "id": "C4", "severity": "high", "summary": "same rules duplicated in 4 files; already diverged on docs/architecture/contracts/" },
    { "id": "C5", "severity": "high", "summary": "ASCII rule violated by own git hooks; shellcheck/yamllint mandated in ci.instructions.md but never implemented" },
    { "id": "C6", "severity": "high", "summary": "integration-test.yml runs 'gh release delete --yes' on the release that release.yml creates for the same tag" },
    { "id": "C7", "severity": "medium", "summary": "flutter 3.44.4 duplicated in 8 workflows; docker floating stable; melos unpinned in CI" },
    { "id": "C8", "severity": "medium", "summary": "no concurrency groups in any workflow" },
    { "id": "C9", "severity": "medium", "summary": "glossary-generate.yml commits and pushes directly to main" },
    { "id": "C10", "severity": "medium", "summary": "native android/ios folders not committed; builds require scripts/bootstrap_android.sh" },
    { "id": "C11", "severity": "medium", "summary": "validate.yml and docs-check.yml assert template-specific structure" },
    { "id": "C12", "severity": "low", "summary": ".claude/settings.local.json is committed and not gitignored; .claude/settings.json missing" },
    { "id": "C13", "severity": "process", "summary": "138 uncommitted paths at analysis time" }
  ],
  "recommendations": [
    "Declare baseline vs. template authority before syncing anything (C1)",
    "Fix the release ownership collision with 'gh release upload --clobber' (C6)",
    "Reconcile the ASCII rule with scripts/pre-commit.sh and scripts/pre-push.sh (C5)",
    "Collapse the fourfold rule duplication to one prose source with generated machine formats (C4)",
    "Use marker-based section sync into AGENTS.md, never file replacement (C3)",
    "Make .claude/skills the canonical skill location; add frontmatter to .github/skills; leave .agents/skills as an upstream mirror (C2)",
    "Promote _android-release-build.yml to the central Android release workflow largely unchanged",
    "Add license-report.yml plus tools/collect_licenses.dart — the largest verified gap, store-relevant",
    "Add script-lint.yml implementing the rules already written in ci.instructions.md",
    "Pin r0adkll/upload-google-play to a commit SHA; pin melos in CI; pin the stitch MCP package version",
    "Parameterize flutter_version, melos_version, java_version, app_dir and bootstrap_android as workflow inputs",
    "Add concurrency groups to all central workflows",
    "Make release.yml 'prerelease' dynamic based on a semver prerelease suffix",
    "Add path instructions for scripts/**, tools/**, backend/**, packages/*/lib/**",
    "Gitignore .claude/settings.local.json; introduce a shared .claude/settings.json",
    "Ship scripts/dev/*.{sh,ps1} together with the skills that call them",
    "Introduce lumbrecode.manifest.yaml as the single source for org constants and toolchain versions",
    "Sync baseline artifacts materialized into each repository — never fetch rules at runtime from the private repo",
    "Trigger public-site sync on release:published of a final semver only, behind an environment approval gate",
    "Do not auto-generate privacy, data-deletion, FAQ or license pages; ship approval-blocked placeholders",
    "Re-verify the 'no analytics' fact mechanically at public-site build time"
  ],
  "requiredWorkflowInputs": {
    "flutter_version": "3.44.4",
    "melos_version": "7.7.0",
    "java_version": "17",
    "dart_sdk_constraint": "^3.12.0",
    "app_dir": "apps/mobile_app",
    "version_file": "VERSION",
    "coverage_path": "apps/mobile_app/coverage/lcov.info",
    "min_coverage": null,
    "bootstrap_android": true,
    "run_codegen_drift_check": true,
    "run_openspec_validation": true,
    "dart_defines": "APP_FLAVOR=prod",
    "play_track": "internal|production",
    "rollout_fraction": "1.0",
    "web_slug": "todo-app",
    "org_prefix": "de.lumbre.code",
    "apps_base_url": "https://lumbrecode.de/apps"
  },
  "requiredSecretNames": [
    "ANDROID_KEYSTORE_BASE64",
    "ANDROID_KEYSTORE_PASSWORD",
    "ANDROID_KEY_ALIAS",
    "ANDROID_KEY_PASSWORD",
    "PLAY_SERVICE_ACCOUNT_JSON"
  ],
  "proposedNewSecretNames": ["PUBLIC_SITE_TOKEN"],
  "localAgentReady": true,
  "confidence": "high",
  "confidenceCaveats": [
    "Branch protection, configured secrets, environment reviewers, deploy keys and GitHub App installations are repository settings and were not verifiable from the working tree.",
    "The analysed tree is feat/adopt-wts-1.3.1-learnings with 138 uncommitted paths, not main.",
    "No privacy, data-deletion or license content is assessed as legally cleared."
  ]
}
```

---

## Appendix A — Agent and instruction file inventory

```
AGENTS.md                                     11,795 B  repository-wide rules
apps/mobile_app/AGENTS.md                               app scope + initializer table
services/api/AGENTS.md                                  API scope
.github/copilot-instructions.md                         applyTo: "**"
.github/instructions/backend.instructions.md            services/api/**/*.dart
.github/instructions/ci.instructions.md                 .github/workflows/**
.github/instructions/docs.instructions.md               docs/**, design/**, drafts/**
.github/instructions/flutter.instructions.md            apps/mobile_app/**, packages/design_system/**
.github/instructions/github-issues.instructions.md      .github/ISSUE_TEMPLATE/**
.github/instructions/tests.instructions.md              **/test/**, **/test_driver/**, **/integration_test/**
.github/agents/planner.agent.md                         implementation-planner
.github/agents/implementer.agent.md                     implementation-executor
.github/agents/reviewer.agent.md                        repository-reviewer
.github/agents/template-initializer.agent.md            lumbrecode-template-initializer
.github/skills/*/SKILL.md                          10   NO frontmatter
.claude/skills/{codegen,quality-gate,test-summary}/ 3   frontmatter OK
.agents/skills/*/SKILL.md                          19   vendored from dart-lang/skills
skills-lock.json                                        hash lock for the 19
.codex/config.toml                                      entry_files, normative_paths, checks
.mcp.json / .vscode/mcp.json                            Stitch MCP
docs/operations/agent-entrypoints.md                    4th copy of the normative map
docs/delivery/agent-prompts.md                          prompt collection
docs/operations/agent-request-template.md               request template
(absent)  CLAUDE.md, GEMINI.md                          AGENTS.md is the de-facto standard
(absent)  .claude/settings.json                         only settings.local.json exists — and it is committed
```

## Appendix B — Script inventory

```
scripts/
├── build.sh / build.ps1 / build-local.ps1          Docker-based build entrypoints
├── validate.sh / validate.ps1                      VERSION + OpenSpec + format + analyze + test
├── validate_openspec.sh / .ps1                     OpenSpec schema validation
├── pre-commit.sh                                   path-aware format gate
├── pre-push.sh                                     parallel analyze + test gate
├── install-hooks.sh / .ps1                         hook installation
├── bootstrap*.{sh,ps1}                             native platform bootstrap (android/ios/web/linux/mobile)
├── generate.{sh,ps1}                               codegen entrypoint
├── run_android.{sh,ps1} / run_web.{sh,ps1}         run helpers
├── remove_backend.{sh,ps1}                         optional backend removal
├── docker-cleanup.{sh,ps1}                         docker housekeeping
├── test_web_app.{sh,ps1}                           web smoke
├── dev/
│   ├── quality_gate.{sh,ps1}                       compact PASS/FAIL gate  ← agent-facing
│   ├── test_summary.{sh,ps1}                       compact test output     ← agent-facing
│   ├── codegen.{sh,ps1}                            melos run codegen       ← agent-facing
│   ├── clean.{sh,ps1}, adb.{sh,ps1}, emulator.{sh,ps1}, screenshots.{sh,ps1}
├── deps/
│   ├── audit.{sh,ps1}                              OSV.dev audit wrapper (--fix/--json/--offline)
│   ├── upgrade_deps.{sh,ps1}, flutter_upgrade.{sh,ps1}
├── release/
│   └── resolve_android_version.sh                  semver → versionName + monotonic versionCode
├── lib/
│   ├── common.sh / Common.ps1                      repo-root switch, melos_cmd, app_dir, require_cmd
│   ├── read_env.sh / Read-ProjectEnv.ps1           project.env reader
│   ├── bootstrap_platforms.sh / Bootstrap-Platforms.ps1
│   └── apply_android_branding.sh / Apply-AndroidBranding.ps1
├── automation/
│   ├── docs/                                       glossary, diagrams, PDF pipeline
│   └── integration-test/                           test docs, PDF report, profiles.json
└── bootstrap/android-res/                          launch screen resources

tools/
├── audit_deps.dart                                 OSV.dev matching against pubspec.lock
├── apply_project_naming.dart                       template initialisation renaming
├── patch_android_signing.dart                      injects the release signing config
└── remove_backend.dart                             backend removal
```

**FACT**, every script starts from the repository root by convention — `AGENTS.md`:

```markdown
- Keep build/validation scripts in `scripts/`; every script starts by sourcing
  `scripts/lib/common.sh` (or dot-sourcing `scripts/lib/Common.ps1`), which
  switches to the repository root — see `docs/operations/dev-scripts.md`.
```

---

*End of report. Read-only analysis: no files in the analysed tree were modified, no commits or pull requests were created, no secret values are reproduced, and no privacy or legal text is assessed as legally cleared.*
