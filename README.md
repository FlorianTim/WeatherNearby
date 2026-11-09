# LumbreCode Flutter App Template

A production-ready **monorepo template** for Flutter mobile apps with optional backends
(Node.js or Dart), comprehensive architecture documentation, CI/CD pipelines, and
first-class support for coding agents (Copilot, Codex, Claude).

**Publisher:** LumbreCode ([LumbreCode.de](https://LumbreCode.de)) ·
**Package schema:** `de.lumbre.code.<app_slug>` ·
**License:** MIT

## LumbreCode conventions

| Topic | Convention |
|---|---|
| Application id | `de.lumbre.code.<app_slug>` — slug from the app spec (`openspec/`) |
| New apps | Created via the template initializer agent from an OpenSpec entry — see [docs/operations/template-initialization.md](docs/operations/template-initialization.md) |
| Example app | The built-in **Todo app** is a deliberate template component (smoke test + reference). It is replaced only during app initialization with `replace_todo_app: true` |
| Splash | Two-phase splash: LumbreCode company phase (always kept, plays `lumbrecode_logo_reveal_3s_de_sequential.json` for German and `lumbrecode_logo_reveal_3s_en_sequential.json` for all other locales) → app phase (placeholder, replaced per app). Lottie animations are local assets under `apps/mobile_app/assets/animations/` — never load from URLs |
| Backend | Optional: Node.js base under `backend/` or Dart/Shelf under `services/api/` — pick one per app (or none) |
| App shell | Every app gets the same shell: a settings **hub**, a bundled manual and FAQ, a privacy page owning both destructive actions, a first-start intro, and a Pro page. Template surface — it survives `replace_todo_app` |
| Monetization | The purchase **seam** ships (gateway, entitlement cache, fail-open gates, Pro page); the billing plugin does not (ADR-0015). Recipe: [in-app-purchase-gateway.md](docs/architecture/patterns/in-app-purchase-gateway.md) |
| Privacy | Privacy-by-default: no analytics, external fonts, or tracking without opt-in decision. The privacy page states the storage promise inside the app |

## Purpose

Use this repository as a **GitHub Template** to start new Flutter projects with:

- Scalable feature-first Flutter architecture
- A finished app shell — settings, help, privacy, intro, entitlements
- Shared packages (design system, models, config)
- Optional Dart backend service
- arc42 architecture documentation with PDF generation
- Diagram rendering pipeline (draw.io, PlantUML, Mermaid)
- Versioned design artifacts
- GitHub Actions for CI, builds, docs, and releases
- Agent-friendly configuration for Copilot, Codex, and other coding assistants
- Dev Container for reproducible development
- VS Code and IntelliJ/Android Studio support

## The app shell

Everything an app has around its features, ready on day one. It is template
surface, not part of the example app: it stays when the initializer replaces
the Todo demo.

```text
splash ──▶ intro (first start only) ──▶ app ──▶ settings hub
      └──▶ app (every later start)
```

| Route | Screen | What it is |
|---|---|---|
| `/intro` | App intro | Five pages: welcome, what the app does, where the data lives, language and appearance, done. Replayable from settings. Requests **no** permission — those are asked for just-in-time by the feature that needs them |
| `/settings` | Settings hub | Language and appearance inline; help, privacy, Pro, support and (debug only) development as rows |
| `/settings/diagnostics` | Diagnostics | Read-only view of every registered setting with its raw stored value and default. **Route does not exist in a release build** |
| `/help/manual`, `/help/faq` | Manual, FAQ | Bundled Markdown per language, rendered offline |
| `/privacy` | Privacy and data | What is stored, permission overview, published documents, and the danger zone |
| `/pro` | Pro | Entitlement status and store availability. No price, no buy action |
| `/about` | About and help | External links, support mailboxes, offline licences, version |

### What a derived app replaces

- **Help content** — `apps/mobile_app/assets/help/<document>_<language>.md`.
  Keep the naming convention; an unsupported language falls back to `_en`,
  and a missing asset shows a visible error rather than an empty screen.
- **Intro copy** — the `intro*` keys in both ARB files.
- **Privacy text** — `privacyLocalBody`, and the permission list the router
  hands to `PrivacyPage` (empty in the template, so the section is omitted).
- **Nothing about the deletion actions.** "Delete app data" clears content
  and keeps settings; "Reset settings" clears the register and keeps content.
  Both confirm, and each names its own blast radius.

### Two destructive actions, deliberately separate

| Action | Clears | Keeps |
|---|---|---|
| Delete app data | every content table, children before parents, one transaction | every setting |
| Reset settings | every key in `AppSettings.all` | all content |

## Starting a new app from this template

| Step | Where |
|---|---|
| 1. Drop the app's material — description, notes, mockups, icons | `drafts/init/` |
| 2. Write the app spec | `openspec/apps/<app_slug>.openspec.yaml` |
| 3. Run the initializer: `audit` → `dry-run` → review → `apply` | [`.github/agents/template-initializer.agent.md`](.github/agents/template-initializer.agent.md) |
| 4. Check what it kept and replaced | [What is kept, adapted and replaced](docs/operations/template-initialization.md) |

Three rules the initializer follows, and the reasons they exist:

- **The app shell survives.** Only the example feature is replaced. Deleting
  the privacy page would remove the in-app data-deletion path Google Play
  requires.
- **Remove less, not more.** A leftover l10n key or an unused dependency is
  harmless; a route pointing at a deleted page is not. Libraries stay by
  default — the base set is what every app ends up needing.
- **The app starts at `0.1.0`** with an empty changelog and feature log, but
  keeps [`generated-from-template.md`](docs/operations/generated-from-template.md):
  which template version and commit it came from, on what date, and which
  template updates it has adopted since.

While the app is built, [`template-feedback.md`](docs/template-feedback/)
collects everything about the template that got in the way — that register is
what the next template version is built from.

## Tracking what shipped when

[`docs/product/feature-log.md`](docs/product/feature-log.md) lists every
feature and bugfix per version, typed and referenced. It is maintained in the
same PR as the change, not written at release time — `CHANGELOG.md` explains
why and how, the feature log answers *when*.

## Repository Structure

```
├── apps/mobile_app/       Flutter app (feature-first)
├── packages/              Reusable Dart/Flutter packages
│   ├── app_core/          Configuration & flavors
│   ├── design_system/     UI components & theme
│   ├── shared_models/     Cross-app data models
│   ├── api_client/        API abstractions
│   └── feature_flags/     Feature flag utilities
├── services/api/          Dart backend (Shelf/Router, optional)
├── backend/               Node.js backend base (Express + Zod, optional)
├── openspec/              App specs for template initialization
├── docs/                  Long-lived documentation
│   ├── architecture/      arc42, ADRs, diagrams, glossary
│   ├── product/           Vision, roadmap
│   ├── api/               OpenAPI specification
│   └── operations/        Runbooks, signing, release checklists
├── design/                Versioned mockups, screenshots, flows
├── drafts/                Non-normative sketches and experiments
├── scripts/               Build and validation scripts
├── infra/                 Infrastructure configuration
├── tools/                 Helper tools
├── .github/               Workflows, agent config, issue templates
├── .vscode/               Editor settings, tasks, launches
├── .devcontainer/         Dev Container configuration
└── .codex/                Codex agent configuration
```

## Technology Stack

| Category | Technology | Purpose |
|---|---|---|
| **App framework** | [Flutter](https://flutter.dev) 3.44+ | Cross-platform UI (mobile, web) |
| **Language** | [Dart](https://dart.dev) 3.11+ | App, packages, and backend |
| **Backend** | [Shelf](https://pub.dev/packages/shelf) + [shelf_router](https://pub.dev/packages/shelf_router) | HTTP server |
| **Monorepo: deps** | [Dart Pub Workspaces](https://dart.dev/tools/pub/workspaces) | Shared dependency resolution across all packages |
| **Monorepo: scripts** | [Melos](https://melos.invertase.dev) | Cross-package script orchestration (analyze, test, format) |
| **CI/CD** | [GitHub Actions](https://docs.github.com/en/actions) | Automated builds, tests, releases |
| **Containerization** | [Docker](https://www.docker.com) / Docker Compose | Reproducible builds without local SDK |
| **Architecture docs** | [arc42](https://arc42.org) | Structured architecture documentation |
| **Diagrams** | [PlantUML](https://plantuml.com), [draw.io](https://www.drawio.com), [Mermaid](https://mermaid.js.org) | Architecture and flow diagrams |
| **Docs PDF** | [Pandoc](https://pandoc.org) | Markdown → PDF rendering |
| **API contract** | [OpenAPI 3.x](https://swagger.io/specification/) | REST API specification |
| **Versioning** | [SemVer](https://semver.org) + [Conventional Commits](https://www.conventionalcommits.org) | Release management |
| **Testing** | flutter_test, package:test, integration_test | Unit, widget, and integration tests |

## Quick Start

### Prerequisites

- **Flutter 3.44+** (includes Dart SDK 3.12+)
- **Melos** — `dart pub global activate melos`
- **Android Studio** or Android SDK (for Android)
- **Xcode** (for iOS, macOS only)
- **Docker** (optional, for backend, docs, and diagram builds)

### 1. Create a new repo from this template

Click **"Use this template"** on GitHub, or clone and remove the `.git` folder.

### 2. Open in your editor

**VS Code** (recommended):

```
code flutter_app_template.code-workspace
```

**IntelliJ / Android Studio**:
Open the repository root as a project. IntelliJ will detect the Flutter project under `apps/mobile_app/`.

### 3. Bootstrap native projects

The template provides the Dart/Flutter structure. Generate native Android/iOS project files.
First set your org and project name in `project.env` at the repo root, then:

**macOS / Linux:**

```bash
# Both platforms at once
./scripts/bootstrap_mobile.sh

# Or individually
./scripts/bootstrap_android.sh
./scripts/bootstrap_ios.sh   # macOS only
```

**Windows (PowerShell):**

```powershell
.\scripts\bootstrap_mobile.ps1
```

### 4. Install dependencies

```bash
# Install Melos (once, globally)
dart pub global activate melos

# Bootstrap all packages in the monorepo
melos bs
```

### 5. Run

| What                 | Command                                                                                                           |
|----------------------|-------------------------------------------------------------------------------------------------------------------|
| Mobile app (VS Code) | Launch **"Flutter: mobile_app (dev)"**                                                                            |
| Mobile app (CLI)     | `cd apps/mobile_app && flutter run --dart-define=APP_FLAVOR=dev --dart-define=API_BASE_URL=http://localhost:8080` |
| Backend API          | `cd services/api && dart run bin/server.dart`                                                                     |
| Full validation      | `melos run ci` or `./scripts/validate.sh`                                                                         |
| Android device/emulator | `scripts/dev/adb.sh run`, `scripts/dev/emulator.sh start` — see [dev-scripts.md](docs/operations/dev-scripts.md) |

## Important Commands

### Monorepo (Melos)

```bash
melos bs                  # Bootstrap: install all dependencies
melos run analyze         # Analyze all packages
melos run test            # Test all packages
melos run format:check    # Check formatting
melos run format:fix      # Fix formatting
melos run ci              # Full local CI: format + analyze + test
melos run build:web       # Flutter web release build (apps/mobile_app/build/web/)
melos run audit           # Scan dependencies for known vulnerabilities
melos run audit:fix       # ... and upgrade the affected packages
```

### Developer Scripts

Every script works from any directory and exists for both bash and PowerShell.
Full reference: [docs/operations/dev-scripts.md](docs/operations/dev-scripts.md);
workstation setup: [docs/operations/local-toolchain.md](docs/operations/local-toolchain.md).

```bash
# Android device / emulator
scripts/dev/adb.sh devices            # what is attached, with API level
scripts/dev/adb.sh install --release  # build the APK and install it
scripts/dev/adb.sh logcat             # only this app's log output
scripts/dev/adb.sh clear              # fresh-install state, APK stays
scripts/dev/emulator.sh create        # create an AVD (API 35, pixel_7)
scripts/dev/emulator.sh start         # boot it AND wait until it is usable
scripts/dev/emulator.sh stop all

# Screenshots — see docs/operations/screenshots.md
scripts/dev/screenshots.sh capture 01-greeting --delay 3
scripts/dev/screenshots.sh auto       # via the screenshot integration test

# Cleaning up
scripts/dev/clean.sh                  # build/, .dart_tool/, coverage/
scripts/dev/clean.sh deep --restore   # + native caches, then melos bs
scripts/dev/clean.sh generated        # delete generated sources, re-run codegen
scripts/dev/clean.sh all --dry-run    # show what would go, delete nothing

# Dependencies & security
scripts/deps/audit.sh                 # known CVEs in the resolved tree
scripts/deps/audit.sh --fix           # ... and upgrade the affected packages
scripts/deps/upgrade_deps.sh          # upgrade everything, incl. major versions
scripts/deps/flutter_upgrade.sh       # upgrade the local Flutter SDK
```

### Local Builds (Flutter SDK, no Docker)

`build-local.ps1` mirrors the Docker-based `build.ps1` but uses the locally
installed Flutter/Dart SDK (and Melos for the quality tasks):

```powershell
.\scripts\build-local.ps1 web        # Flutter web release build
.\scripts\build-local.ps1 android    # Flutter APK release build
.\scripts\build-local.ps1 analyze    # analyze all packages
.\scripts\build-local.ps1 test       # test all packages
.\scripts\build-local.ps1 format     # check formatting
.\scripts\build-local.ps1 ci         # format + analyze + test
.\scripts\build-local.ps1 api        # start Dart API server on :8080
.\scripts\build-local.ps1 serve-web  # web dev server on http://localhost:8080
```

### Mobile App

```bash
cd apps/mobile_app
flutter analyze          # Static analysis
flutter test             # Run tests
flutter run              # Run app
```

### Backend API

```bash
cd services/api
dart format .            # Format code
dart analyze             # Static analysis
dart test                # Run tests
dart run bin/server.dart # Start server
```

### Docker Builds (no local SDK required)

All build and quality tasks are also available as Docker services.
Only Docker is needed — no local Flutter/Dart SDK installation required.

```bash
# Build
./scripts/build.sh web              # Flutter web release build
./scripts/build.sh android          # Flutter APK release build

# Quality checks
./scripts/build.sh analyze          # analyze mobile + API
./scripts/build.sh test             # unit tests mobile + API
./scripts/build.sh format           # check formatting
./scripts/build.sh ci               # format + analyze + test (full CI)

# Integration tests
./scripts/build.sh integration-test # integration tests with screenshots
./scripts/build.sh integration-web  # web integration tests (Chrome)

# Security
./scripts/build.sh audit            # scan dependencies for known CVEs

# API server
./scripts/build.sh api              # start on localhost:8080

# Windows
.\scripts\build.ps1 web             # (same subcommands as above)
```

> **Note:** Docker builds use `ghcr.io/cirruslabs/flutter:stable` (~3 GB).
> A named volume (`flutter-pub-cache`) caches downloaded packages across runs.
> After a Docker build, run `flutter pub get` locally to restore host-side `.dart_tool` paths.

### Testing & Quality

**Unit & Widget Tests:**

```bash
cd apps/mobile_app && flutter test
cd services/api && dart test
```

**Integration Tests with Screenshots:**

Both routes — driving the app by hand on a device and letting the integration
test do it — are written up in
[docs/operations/screenshots.md](docs/operations/screenshots.md).

```bash
# Everything at once (runs the test, collects into design/screenshots/)
scripts/dev/screenshots.sh auto

# Using Docker (recommended)
./scripts/build.sh integration-test      # Linux/macOS
.\scripts\build.ps1 integration-test     # Windows

# Locally with Flutter SDK
cd apps/mobile_app
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/app_screenshots_test.dart \
  -d chrome
```

**Generate Test Documentation:**

```bash
# After running integration tests
./scripts/automation/integration-test/generate_test_docs.sh   # Linux/macOS
.\scripts\automation\integration-test\generate_test_docs.ps1  # Windows

# Output: docs/testing/integration-test-report.md
```

**Web Development Server:**

```bash
./scripts/test_web_app.sh                # Linux/macOS
.\scripts\test_web_app.ps1               # Windows
# App runs on http://localhost:8080
```

See [docs/testing/README.md](docs/testing/README.md) for comprehensive testing guide.

### Documentation

Requires Docker. See [Documentation Workflows](#documentation-workflows) for details.

```bash
# Generate all docs (glossary + PDF + diagrams)
./scripts/generate.sh              # Linux/macOS
.\scripts\generate.ps1             # Windows

# Individual tasks
./scripts/generate.sh glossary
./scripts/generate.sh pdf
./scripts/generate.sh diagrams

# Cleanup Docker resources
./scripts/docker-cleanup.sh
```

### Full Validation

```bash
./scripts/validate.sh
```

## Editor Setup

### VS Code

1. Open `flutter_app_template.code-workspace`
2. Install recommended extensions (prompted automatically)
3. Use the pre-configured launch configurations and tasks

**Recommended extensions** (see `.vscode/extensions.json`):

- Dart & Flutter
- GitHub Copilot
- YAML, Docker, Markdown, Spell Checker

### IntelliJ / Android Studio

1. Open the repository root as a project
2. Configure Flutter SDK path in **Settings → Languages & Frameworks → Flutter**
3. For the mobile app: open `apps/mobile_app/` as a Flutter project
4. For the backend: open `services/api/` as a Dart project
5. Run configurations: create manually based on the commands above

**Note:** IntelliJ `.idea/` and `*.iml` files are gitignored.

### Dev Container (VS Code)

1. Install the **Remote - Containers** extension
2. Open the repo in VS Code
3. Click **"Reopen in Container"** when prompted
4. See `.devcontainer/README.md` for details on container capabilities

## Architecture

The project follows a **feature-first monorepo** pattern:

- **Feature-first Flutter**: `apps/mobile_app/lib/features/<feature>/`
- **Shared packages**: `packages/` for reusable components
- **arc42 documentation**: `docs/architecture/arc42/`
- **Architecture Decision Records**: `docs/architecture/adr/`

Key decisions (ADRs):

| ADR  | Decision                               |
|------|----------------------------------------|
| 0001 | Monorepo structure                     |
| 0002 | Feature-first Flutter architecture     |
| 0003 | SemVer + Conventional Commits          |
| 0004 | Design artifact versioning             |
| 0005 | Drafts are non-normative               |
| 0006 | Documentation source/target separation |
| 0007 | Diagram rendering pipeline             |

## Agent / Copilot / Codex Configuration

This repository is optimized for coding agents:

| File                                     | Purpose                       |
|------------------------------------------|-------------------------------|
| `AGENTS.md`                              | Root-level agent rules        |
| `.github/copilot-instructions.md`        | Copilot instructions          |
| `.github/instructions/*.instructions.md` | Domain-specific instructions  |
| `.github/agents/*.agent.md`              | Specialized agent modes       |
| `.github/skills/*/SKILL.md`              | Reusable agent workflows      |
| `.codex/config.toml`                     | Codex configuration           |
| `.mcp.json` / `.vscode/mcp.json`         | MCP servers (Google Stitch)   |
| `docs/operations/agent-entrypoints.md`   | Full map of normative sources |

**Design-to-code (Google Stitch):** the [Stitch](https://stitch.withgoogle.com)
MCP server is pre-configured for Claude Code, VS Code/Copilot, and Codex, so
agents can pull generated UI designs (screenshots, HTML, design tokens) into
`design/` and implement them via `packages/design_system`. One-time auth per
developer — see [docs/operations/stitch-mcp.md](docs/operations/stitch-mcp.md).

**Key rules for agents:**

- `drafts/` is non-normative — never use unless explicitly asked
- Use design manifests to find current versions (`design/manifests/`)
- Features marked `(ab X.Y)` are planned for future versions
- Generated files under `docs/architecture/generated/` should not be edited directly

## Generating a concrete app from this template (agent prompt)

To turn this template into a real app, drop your raw requirements — texts,
sketches, screenshots, mockup images — into `drafts/` (e.g.
`drafts/notes/` and `drafts/experiments/`), then instruct your coding agent
(Copilot, Codex, Claude) with the prompt below. Referencing `drafts/`
explicitly is the sanctioned exception to the "drafts are non-normative"
rule: the agent may read them as input, but only the specs it derives from
them become binding.

```text
Act as the LumbreCode template initializer
(.github/agents/template-initializer.agent.md) and generate a concrete app
from this template.

Input: my raw requirements are in drafts/ (Markdown texts and images).
I explicitly authorize you to read everything in drafts/ as input for this
task. The drafts stay non-normative — only the specs you derive from them
are binding.

Work in phases and stop for my review after phase 2:

1. Plan phase: read all requirement texts and images in drafts/. Derive the
   app identity (app_name, app_display_name, app_slug, platforms,
   backend_enabled) and list every requested feature. Classify each feature
   as key feature (needed for a usable first version) or follow-up feature.
   Ask me about anything unclear — never guess names or slugs.

2. Spec phase: create one OpenSpec entry
   (openspec/apps/<app_slug>.openspec.yaml, complete per openspec/README.md,
   core_features = the key features) and one feature spec per feature under
   docs/product/specs/<NNNN-feature-name>/. Split a large requirements
   document into multiple specs. Then show me the plan and the specs and
   wait for my approval.

3. Initialize: run the initializer in audit → dry-run mode, show me the
   report, and after my go run apply (replace_todo_app: true).

4. Build incrementally: implement the feature specs one by one — key
   features first, one branch and one PR per feature, small Conventional
   Commits, tests included. After each feature run melos run ci and report
   the result. Follow-up features go through the spec-first workflow in
   AGENTS.md.

Respect AGENTS.md at all times (no secrets, no external runtime services,
keep the LumbreCode splash phase, generator-based workflows).
```

## Documentation Workflows

All documentation generation runs via Docker — no local tool installs needed beyond Docker itself.

### Glossary

The glossary is maintained as CSV (`docs/architecture/glossary.csv`) and generated to Markdown.

### Diagrams

Source files in `docs/architecture/diagrams/src/` are rendered to SVG:

| Format   | Source folder   | Docker image                       |
|----------|-----------------|------------------------------------|
| draw.io  | `src/drawio/`   | `rlespinasse/drawio-export:latest` |
| PlantUML | `src/plantuml/` | `plantuml/plantuml`                |
| Mermaid  | `src/mermaid/`  | `minlag/mermaid-cli:latest`        |

### PDF

The architecture documentation is built to PDF using Pandoc (`pandoc/extra:latest`).
Configuration lives in `docs/architecture/pandoc/defaults.yaml`.

### Local Generation (Docker Compose)

A `docker-compose.yml` at the repo root defines services for all generation tasks.
Use the convenience scripts to run them:

```bash
# Run all generation tasks (glossary + PDF + diagrams)
./scripts/generate.sh              # Linux/macOS
.\scripts\generate.ps1             # Windows

# Run individual tasks
./scripts/generate.sh glossary
./scripts/generate.sh pdf
./scripts/generate.sh diagrams
```

Or invoke Docker Compose services directly:

```bash
docker compose run --rm glossary
docker compose run --rm pdf
docker compose run --rm diagrams-drawio
docker compose run --rm diagrams-plantuml
```

> **Mermaid note:** The mermaid-cli container renders one file at a time using its
> default entrypoint (required for Chrome/Puppeteer). Use `./scripts/generate.sh diagrams`
> or `sh scripts/automation/docs/render_mermaid_inner.sh` to loop over all `.mmd` files automatically.

VS Code tasks are provided for all generation commands — open the Command Palette
and run **Tasks: Run Task** to see them.

### Docker Cleanup

After building or generating docs, stop containers and remove volumes:

```bash
./scripts/docker-cleanup.sh            # Linux/macOS
.\scripts\docker-cleanup.ps1           # Windows

# Also remove the pulled Docker images
./scripts/docker-cleanup.sh --prune    # Linux/macOS
.\scripts\docker-cleanup.ps1 -Prune    # Windows
```

### CI Workflows

The same tools run automatically in GitHub Actions on `ubuntu-latest` runners
(which have Docker pre-installed):

| Workflow                | Trigger                    | What it does                             |
|-------------------------|----------------------------|------------------------------------------|
| `glossary-generate.yml` | Push to glossary CSV       | Regenerates glossary MD and commits      |
| `diagrams-build.yml`    | Push to diagram sources    | Renders diagrams, uploads as artifact    |
| `docs-build.yml`        | Push to docs / manual      | Renders diagrams + glossary + PDF build  |

CI calls the same bash scripts (`render_diagrams.sh`, `generate_glossary.sh`,
`build_docs_pdf.sh` under `scripts/automation/docs/`) that the local Docker Compose services wrap.

### Build & Quality Services (Docker Compose)

The same `docker-compose.yml` also provides Flutter build and quality-check services
using `ghcr.io/cirruslabs/flutter:stable` (includes Flutter SDK + Android SDK + Java):

| Service               | Command                        | What it does                    |
|-----------------------|--------------------------------|---------------------------------|
| `mobile-build-web`    | `./scripts/build.sh web`      | Flutter web release build       |
| `mobile-build-android`| `./scripts/build.sh android`  | Flutter APK release build       |
| `mobile-analyze`      | `./scripts/build.sh analyze`  | Flutter analyze (mobile + API)  |
| `mobile-test`         | `./scripts/build.sh test`     | Flutter/Dart test (mobile + API)|
| `mobile-format-check` | `./scripts/build.sh format`   | Check formatting (mobile + API) |
| `api-server`          | `./scripts/build.sh api`      | Start backend on port 8080      |

Run `./scripts/build.sh ci` to execute format + analyze + test in sequence.

Build artifacts appear on the host via the mounted volume:
- **Web:** `apps/mobile_app/build/web/`
- **Android APK:** `apps/mobile_app/build/app/outputs/flutter-apk/`

> **Auto-bootstrap:** The web and Android build services automatically run
> `flutter create . --platforms <platform>` if the platform directory doesn't exist yet.
> First builds take longer due to SDK/NDK downloads; subsequent runs reuse caches.

## Versioning

- **Semantic Versioning**: `major.minor.patch` (see `VERSION` file)
- **Conventional Commits**: `feat:`, `fix:`, `docs:`, `refactor:`, `ci:`, `chore:`
- **Breaking changes**: `feat!:` or `BREAKING CHANGE:` footer → major bump
- **Features**: `feat:` → minor bump
- **Fixes**: `fix:` → patch bump

See ADR-0003 for details.

## GitHub Actions

| Workflow                  | Purpose                         | Trigger               |
|---------------------------|---------------------------------|-----------------------|
| `ci-mobile.yml`           | Flutter analyze + test          | PR / push to main     |
| `ci-gate.yml`             | Asserts the gates above actually ran | **Every** PR     |
| `ci-backend.yml`          | Dart format + analyze + test    | PR / push to main     |
| `build-android.yml`       | Android release build (APK/AAB) | Manual / tag          |
| `build-ios.yml`           | iOS build (unsigned)            | Manual / tag          |
| `docs-build.yml`          | Architecture PDF                | Push to main / manual |
| `diagrams-build.yml`      | Render diagrams                 | Push to main / manual |
| `glossary-generate.yml`   | Generate glossary MD            | Push to main / manual |
| `validate.yml`            | Validate repo structure         | PR / push to main     |
| `release.yml`             | Create GitHub Release           | Tag `v*`              |
| `copilot-setup-steps.yml` | Agent environment setup         | Manual                |

> **A green PR is not proof on its own.** This repository has no branch
> protection — it needs GitHub Pro or a public repository — so no check blocks
> a merge, and a workflow that fails to *start* attaches no check at all.
> `ci-gate.yml` exists for that: it runs on every pull request and turns a
> silently missing gate into a red check. Trust green when `gate (…)` is one
> of the green ones. Background: KI-012 in `docs/known-issues.md`.

## Design Artifact Versioning

Mockups and screenshots under `design/` are versioned via manifest files.
See `design/README.md` and ADR-0004 for the full convention.

## Platform-Specific Notes

### Windows

- Use PowerShell scripts (`*.ps1`) where provided
- For bash scripts, use Git Bash or WSL
- Flutter and Dart CLI work natively on Windows

### macOS

- Required for iOS development (Xcode)
- All bash scripts work natively
- `brew install flutter` or download from flutter.dev

### Linux

- Android development works fully
- iOS development not available (requires macOS)
- All bash scripts work natively

## Next Steps After Template Creation

0. Create your app spec: copy `openspec/templates/app.openspec.yaml` to
   `openspec/apps/<app_slug>.openspec.yaml` and run the template initializer
   (see `docs/operations/template-initialization.md`) — or drop raw
   requirements into `drafts/` and use the agent prompt from
   [Generating a concrete app from this template](#generating-a-concrete-app-from-this-template-agent-prompt)
1. Set your app slug in `project.env` (`ORG` stays `de.lumbre.code`), then run `scripts/bootstrap_mobile.*`
2. Fill in `docs/product/vision.md` and `docs/product/roadmap.md`
3. Customize `docs/architecture/arc42/01-introduction-and-goals.md`
4. Update ADRs for your project-specific decisions
5. Configure GitHub Secrets for builds (see `docs/operations/ios-signing.md`)
6. Extend or replace `services/api/` with your backend

## License

MIT
