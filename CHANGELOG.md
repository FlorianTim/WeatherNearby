# Changelog

All notable changes to this project will be documented in this file.

Format based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Convention for derived apps: releases are developed in **waves** (feature
batches). Inside `[Unreleased]`, group entries under `### Wave <n> — <topic>`
headings while the wave is in progress; on release, fold the waves into the
standard Added/Changed/Fixed sections of the version. This keeps large
release cycles reviewable without losing Keep-a-Changelog compatibility.

## [Unreleased]

### Dependency updates run unattended

- **Dependabot is the active update bot again (ADR-0018).**
  `.github/dependabot.yml` follows the lumbrecode-engineering `flutter`
  profile: pub for the workspace (`/`, `/apps/*`, `/packages/*`, `/services/*`), with a `git` registry for the private `flutter-libraries`; GitHub Actions; and npm for `backend/`; weekly on Monday 05:00
  Europe/Berlin, five-day cooldown, one `minor-and-patch` group, minor/patch
  security updates grouped, majors one by one. The KI-001 package set moves
  by patch only until the riverpod fix ships.
- **Three callers of shared workflows (`@v1`, lumbrecode-engineering
  v1.9.0).** `dependabot-automerge.yml` merges a green Dependabot-only pull
  request that is a security update or minor/patch throughout, gated by
  Mobile CI (pub, GitHub Actions) or Backend CI (Node) (npm), and labels everything else `needs-human`. It deploys nothing; the
  store release stays manual. `dependency-triage.yml` keeps one "Dependency
  triage" issue, including a Flutter stable newer than the pinned 3.47.1.
  `security-scan.yml` runs gitleaks and OSV-Scanner on every ready pull
  request and weekly, and `ci-gate.yml` verifies that it started.
- `ci-mobile.yml` also runs when only `pubspec.lock` changes, which is all a
  Dependabot pub update may touch.
- The workflow comments no longer claim that Renovate raises the Flutter pin.
  `.github/renovate.json5` stays as a dormant, baseline-delivered option;
  `dependency-audit.yml` stays as the CI twin of `scripts/deps/audit.sh`.
- `codeql.yml` (public repository): CodeQL for the Node backend, on
  `backend/**` and weekly. CodeQL does not support Dart, so the Flutter code
  is covered by `flutter analyze` and the security scan only.
- Needs, per repository: Dependabot alerts and security updates switched on, and `FLUTTER_LIBRARIES_TOKEN` also as a **Dependabot** secret, and secret scanning (public repository).

### Packing lists from Packzeit (plan change, no import yet)

- **Baseline 1.5.2 -> 1.6.0** adds the packing-list fixtures `52`-`54`, the
  rejected `97`, the `expected/*.summary.json` files and the blocker exchange
  fixtures. `scripts/fetch_engineering_release.py` is copied from
  `lumbrecode-engineering` (the template had none).
- **The import itself is not built.** It is slice 8 of plan 0001 and needs
  slices 2 and 3 first. Instead: spec 0004 gains INT-606..609, AC-67..70, data
  contract section 3.6 and a CT-16 row; the plan records the change.
- **New contract test `test/interop/packing_list_contract_test.dart`** compares
  every accepted `5x` fixture, found by directory, with its expected summary,
  asserts the packing conventions (sections as parents, `in-process` keeps its
  percentage, titles unchanged, keywords, date-only `due`, `prodId` ignored,
  independent lists) and whole-file rejection (501 entries, malformed JSON). Four
  skipped tests carry what needs the database.
- Five template-feedback entries; one earlier entry resolved.

### Task interchange as a dependency

- **The template depends on `flutter-libraries` instead of building
  `packages/task_interchange` (ADR-0017, supersedes ADR-0014 in part).**
  `apps/mobile_app` has one `git:` dependency pinned to `interchange-v0.1.0`
  (`jscalendar` and `ijson` ride along). `ci-mobile.yml` passes
  `FLUTTER_LIBRARIES_TOKEN` as `git-read-token` (shared workflow pinned to
  `@v1.6.0`, the first version with that input). New
  `docs/operations/local-library-development.md`; plan 0001 slice 1, spec 0004,
  the test strategy and the initializer docs now say the package is a
  dependency the initializer keeps. New contract test
  `test/interop/interchange_contract_test.dart` reads the golden fixtures from
  `.lumbrecode/schemas/` by directory (now also the `97` fixture). Seven template-feedback entries. No UI, no
  reference-app or app-shell change.

### UI test profile tuning

- Explicit test-only phone, compact, large-text, tablet and desktop profiles;
  finite shell/onboarding interactions with scrolling, labelled whole-content
  inspections and normal-text screenshots. Retain focused 2x accessibility
  coverage without requiring every width/locale/theme combination (spec 0009).
  No application behavior or reference-app scope change; 274 tests pass.

### Added

- **Build flavors that keep their own data (spec 0008).** `AppFlavor` now has
  `dev`, `snapshot`, `staging`, `prerelease` and `prod`, and something behind
  each: a snapshot, pre-release or staging build opens its own database file
  (`app_database_snapshot`, …) and its own preference keys, so it never reads
  the release's data. On Android a `snapshot` or `prerelease` build also gets
  its own application id suffix and launcher name and installs next to the
  release (`apply_android_branding.sh` and its PowerShell twin patch
  `build.gradle.kts` from `APP_FLAVOR`). The settings diagnostics are
  available in `snapshot` as well as in debug. A release-mode build that names
  no flavor is `prod`. The release workflow turns a tag `v1.2.0-rc.1` into a
  GitHub pre-release, and *Android Build Release* takes a `flavor`.

  Not verified: no APK was built with the Gradle patch yet, and iOS keeps one
  bundle id.

- **A menu bar and keyboard shortcuts (spec 0008, ADR-0016).** The menu is
  data (`AppMenuGroup`, `AppMenuItem`); macOS draws it natively
  (`PlatformMenuBar`), Windows, Linux and the web with a Flutter `MenuBar`,
  a phone not at all. Go to (`Alt+1`…`Alt+4`, `Ctrl+Alt+1`… on macOS), Help
  (`F1` opens the manual), `F10` opens the bar, and File → Quit (`Ctrl/Cmd+Q`)
  on a desktop. The splash, the startup error and the intro cannot be left
  through it. Flutter has no native menu on Windows and Linux.

### Changed

- **The entitlement vocabulary is now shared, not local.** `Entitlement`
  stores `pro-lifetime` and `pro-subscription` instead of the snake_case
  forms, matching `schemas/entitlement/v1` in `lumbrecode-engineering` —
  kebab-case is what every other stable identifier in those schemas uses.
  A Flutter app and a web app belonging to one product must not disagree on
  how "lifetime Pro" is spelled.

  The 3.2.1 forms still decode. Dropping them would downgrade a paying user
  to `free`, the one direction this cache must never fail in.

- **The template-feedback register moved** from a single
  `docs/operations/template-feedback.md` to `docs/template-feedback/`, one
  file per problem — the same shape the web template uses, and where the
  `capture-template-feedback` skill writes. That skill is now synchronized
  from `lumbrecode-engineering` rather than existing in one template only.

### Fixed

- `AppSettings.entitlement` decoded by iterating the enum itself instead of
  calling `Entitlement.fromStored`. Two decoders, and they drifted the moment
  the vocabulary gained a legacy mapping: the register's copy silently
  dropped it. Now it delegates.

## [3.2.1] - 2026-08-26

The **app shell**: everything a LumbreCode app has around its features. The
settings page becomes a hub, gains an in-app manual and FAQ, an in-app
privacy page that owns the destructive actions, a first-start intro that can
be replayed, and an in-app-purchase placeholder — the whole monetization
shape without a billing dependency.

Specs `0005`–`0007`, plan
`docs/delivery/implementation-plans/0002-settings-and-app-shell.md`,
decision ADR-0015. Reference behaviour: *WasThereSomething* 1.3.1, the same
source as the 3.0.0 adoption.

> **Version jump.** 3.1.0 is reserved for the To-do reference app (plan
> `0001`), which is still mid-flight on its own branch. Taking 3.1.x for the
> app shell would make two independent lines of work look sequential.

**Behaviour changes for derived apps** — three things need a manual
follow-up:

- **The splash no longer routes into the settings page.** It routes to the
  app, or — on a first start — to the new intro. `SettingsPage.onContinue`
  is gone; the page is a destination reachable from the main screen, not a
  startup step.
- **`_OptionTile` moved out of `settings_page.dart`** into
  `packages/design_system` as `AppOptionTile`. A private copy keeps working
  but should be replaced.
- **"Delete app data" moved off the settings page** onto the new privacy
  page, next to the explanation that leads a user to it — and it now has a
  sibling, "Reset settings", with a separate confirmation.

### Added

- **Settings hub** (`features/settings/`): language and appearance inline,
  everything else as navigation rows, grouped into help, data and privacy,
  Pro, support and (debug builds only) development.
- **Settings diagnostics** — a read-only view over `AppSettings.all` showing
  each key, its raw stored value and its default. The route and the row do
  not exist in a release build.
- **In-app help** (`features/help/`): a bundled manual and FAQ per language,
  rendered offline through `AppMarkdownView`, with an English fallback for
  unsupported languages and a visible error for a missing asset. Links
  inside a document go through the scheme-allowlisted launcher seam.
- **Privacy and data page** (`features/privacy/`): what the app stores, a
  permission overview the app fills in (empty in the template, so the
  section is omitted), the published legal documents, a privacy-contact
  mail, and both destructive actions in a danger zone.
- **`resetAllSettings()`** — clears every key in the register, defined over
  `AppSettings.all` so a setting added later is covered automatically.
- **App intro** (`features/onboarding/`): a five-page pager on first start —
  welcome, what the app does, where the data lives, language and appearance,
  and a closing page — replayable from settings. Requests no permission, by
  contract. A failing settings write still lets the user out.
- **In-app purchase placeholder** (`features/monetization/`):
  `PurchaseGateway` with a store-less default and a deterministic fake, a
  cached entitlement plus verification timestamp, `featureUnlocked(key)`
  over the existing fail-open `FeatureGates`, and a Pro page that shows the
  state and sells nothing. **No billing dependency** — a guardrail test
  asserts none is imported anywhere (ADR-0015).
- **Shared widgets** in `packages/design_system`: `AppOptionTile`,
  `AppSettingsSection` (renders nothing when empty) and `AppSettingsTile`.
- Three settings in the register: `app.onboardingCompleted`,
  `billing.entitlement`, `billing.checkedAt`.
- `SettingDescriptor.encodedDefault`, so a diagnostics view can name a
  default without knowing the value type.
- **ADR-0015** and the recipe
  `docs/architecture/patterns/in-app-purchase-gateway.md`.
- **One source for the manual, the FAQ and the screenshots.**
  `docs/public-site/` is authored once and rendered twice: onto the public
  website and into `apps/mobile_app/assets/help/`, which becomes generated
  output. `scripts/dev/quality_gate.sh|ps1` and `scripts/validate.sh` gained
  a `help` step that fails when a generated file was edited by hand.
- **`.lumbrecode/`** — the synchronized baseline from
  `lumbrecode-engineering`: the shared screenshot schemas, the canonical
  screen profiles and the help renderer, committed per the baseline model.
- **KI-011** — a Docker-based Flutter task rewrites the host's
  `package_config.json` with container paths, after which the analyzer
  reports thousands of broken imports in files nobody touched. Recorded with
  the one-line fix, because the symptom points nowhere near the cause.
- **`help-generate.yml`** — the bundled help is rendered on `main` and
  committed back, the way the glossary already is. `integration-test.yml`
  now collects the captured screenshots into `design/screenshots/` and
  commits them too, so a document can reference an image that CI produced.
  Documentation is generated in the workflows, not on a developer machine.

### Changed

- The screenshot integration flow drove the pre-3.2.1 app: it expected the
  settings page after the splash and a "Continue" button, neither of which
  exists any more. It now drives the shell — intro, settings hub, privacy —
  and its shot ids match `docs/public-site/screenshots.yaml`. Finders are
  icons and widget types rather than text, because a fresh install follows
  the system language and CI's locale is not ours to predict.
- Screen profiles moved from
  `scripts/automation/integration-test/profiles.json` to
  `docs/public-site/screenshot-profiles.json` — a shared contract the web
  template's Playwright capture reads too, so both stacks render at the same
  sizes and write into the same `design/screenshots/<profile>/` layout. The
  runner passes `SCREEN_WIDTH`/`SCREEN_HEIGHT` in as dart-defines, so
  `app_screenshots_test.dart` no longer carries its own copy of the sizes.
- The greeting page's app-bar action opens settings instead of switching the
  language; `l10n.changeLanguage` is replaced by `l10n.settingsOpen`.
- `TestAppHarness` seeds the intro as completed and accepts
  `extraOverrides`, so a test can replace a default override without
  rebuilding the list.
- The accessibility suite covers the rebuilt hub **and** the privacy page —
  touch targets, text scaling, and selection and warning states that never
  depend on colour alone.
- **`docs/product/feature-log.md`** — every feature and bugfix per version,
  typed and referenced, maintained in the same PR as the change. Populated
  retroactively for 2.0.0, 3.0.0, 3.1.0 (in progress) and 3.2.1.
- **Initialization is now a careful replacement, not a reset.**
  `docs/operations/template-initialization.md` gained the canonical
  "What is kept, adapted and replaced" table — every path under
  `apps/mobile_app/lib/` is classified, the default is *keep*, and
  `replace_todo_app: true` authorises replacing the example feature only.
  `.github/agents/template-initializer.agent.md` mirrors it, deletes by
  explicit path rather than folder sweep, and verifies the shell survived
  before running the gate. `AGENTS.md` gained an "App shell — preservation
  rule" section; `.github/copilot-instructions.md` and
  `openspec/templates/app.openspec.yaml` carry the same boundary.
- **Store readiness** is checkable: `docs/operations/release-checklist.md`
  and the `release-checklist` skill list what a Play submission needs from
  the shell — the in-app deletion path, the published legal pages, a
  privacy text that still matches reality, no price without a working
  billing adapter, and no development section in a release build.
- **`drafts/init/`** is the new input folder for a derived app — spec,
  notes, mockups, icons, resources. It is the one part of `drafts/` the
  initializer reads, and the one part that survives the cleanup; it is
  retired only when `drafts/init/processed.md` shows everything processed.
- **A generated app starts at `0.1.0`** with an empty changelog and feature
  log, and keeps `docs/operations/generated-from-template.md`: template
  version, template commit, generation date, what was replaced versus kept,
  plus a table for template updates adopted later.
- **`docs/template-feedback/`** — the register of what the
  template got wrong, filled in while an app is generated and built.
  Its first four rows are the findings from this release's own review.
- **Documentation cleanup is classified too:** the example-app specs, plans,
  stories and `docs/ideas/` go; the contracts, patterns, known-issues,
  `docs/operations/` and the shell specs 0005–0007 stay; arc42 keeps its
  structure and gets the app's content.
- **"Remove less, not more"** is now a written rule: a leftover l10n key or
  an unused dependency is harmless, a dangling route is not. Libraries stay
  by default — only the backend packages are removable, and only on an
  explicit `backend_enabled: false`.

### Fixed

- The initializer documentation claimed
  `remove_backend.sh --with-packages` removes `packages/feature_flags`. It
  removes `packages/api_client` and `packages/shared_models`; `feature_flags`
  is deliberately kept — and since 3.2.1 `apps/mobile_app` depends on it
  directly, so following the stale instruction would have broken the build.
- `lib/features/home/` (an unrouted leftover of the original starter
  scaffold) is now classified instead of being an unlabelled folder the
  initializer had to guess about.

## [3.0.0] - 2026-08-24

Adoption of the *WasThereSomething 1.3.1* learnings (waves 1–4 plus the
follow-up work, see `docs/ideas/wts-1.3.1-adoption-delta.md`). The template
gains its written rules — seven architecture contracts and a known-issues
register — and the code that makes them checkable: a startup coordinator with
a recovery screen, a settings register, a permission flow, time and id seams,
and an accessibility test suite. The app's test suite went from 60 to 120
tests, alongside 34 Dart tests in the packages.

**Breaking for derived apps** — three renames/removals need a manual follow-up:

- `splashWarmupTasksProvider` and `features/splash/application/splash_warmup.dart`
  are gone. Register startup work as a `StartupTask` in
  `core/startup/startup_providers.dart` and state its `StartupPolicy`.
- `localeProvider` now holds `Locale?`; `null` means "follow the system
  language" and is the new default. Code that assumed a non-null locale, and
  any persisted value, has to handle that.
- `scripts/remove_backend.*  --with-packages` now removes `shared_models`
  instead of `feature_flags` — entitlements are a store concern, not a
  backend one.

### Added

- **Architecture contracts** (`docs/architecture/contracts/`): startup,
  database, localization, permissions, external data ownership, library
  evaluation, accessibility. Each rule has a verification form, and each
  contract carries a "Stand im Template" table so unmet rules do not read as
  met ones
- **`docs/known-issues.md`** — KI-001 … KI-010, each with cause, workaround
  and the trigger that makes it re-checkable
- **Pattern catalogue** (`docs/architecture/patterns/`): platform gateways,
  capability modules, permissions, external source sync, backup/restore.
  Guiding decision: what needs no new dependency becomes code in the
  template, what brings a dependency, a manifest entry or a store
  declaration stays a recipe
- **`StartupCoordinator`** (`core/startup/`) with three declared policies —
  `blocking` (sequential, a failure is fatal), `guarded` (parallel,
  degrades), `fireAndForget` — plus a localized **recovery screen** on route
  `/startup-error` with retry and a prefilled bug report. Failures are
  written to the debug console; the screen itself shows only the task name,
  never an exception or stack trace
- **`SettingDef` register** (`core/settings/`): key, default and codec of
  every setting in one place, `AppSettings.all` makes the set enumerable.
  Locale and theme mode are migrated onto it
- **Theme mode as a persisted setting** (`themeModeProvider`), selectable on
  the settings page next to the language, each with a "system" option
- **`core/permissions/`** — `PermissionGateway` with a distinct
  `permanentlyDenied` state, `ensurePermission(...)` (status → granted? →
  permanently denied? → rationale → request) and the rationale sheets. The
  test fake records the call order, so tests prove the sequence, not just the
  result. No new dependency
- **`generateId()`** (128-bit hex, no UUID package) and **`Clock`/`SystemClock`**
  as a time seam; both are used in the todo notifier and the greeting page
  instead of `DateTime.now()`
- **`AppDatabase.wipeAllData()`** — transactional, children before parents —
  with a settings entry and confirmation dialog. Scope is the database only;
  the subtitle says that language and appearance survive
- **`Entitlement` and `FeatureGates`** (fail-open) in `feature_flags`
- **Accessibility test suite** (`test/a11y/`, 8 tests): touch targets ≥ 48 dp,
  text scaling 2.0 without overflow, semantics labels, selection never by
  colour alone, no interaction that only works as a swipe
- **Encapsulation guardrail** — `expectPackageEncapsulated(...)` plus a
  worked example that pins `lottie` to the splash directory
- **Android bootstrap resources** (`scripts/bootstrap/android-res/`): splash
  colours and themes for `values`, `values-night`, `values-v31`,
  `values-night-v31` and both `launch_background.xml` variants, copied in
  after `flutter create`. The script also sets `android:allowBackup="false"`,
  turning the platform default into a decision
- **Developer scripts**, `.sh` and `.ps1` with identical behaviour and a
  shared root resolver (`scripts/lib/common.sh`, `Common.ps1`): `adb`,
  `emulator`, `clean`, `screenshots`, `deps/audit`
- **`tools/audit_deps.dart`** — resolved dependencies checked against the
  OSV.dev advisory database, plus a weekly `Dependency Audit` workflow
- **Web database assets**: `web/sqlite3.wasm`, `web/drift_worker.js` and
  `tool/sync_web_database_assets.dart`, which regenerates both from the
  resolved drift version
- Operations docs: `dev-scripts.md`, `local-toolchain.md`, `screenshots.md`

### Changed

- **The splash runs fullscreen** and draws no title of its own: company and
  app name are part of the Lottie files. `BoxFit.contain` — `cover` would
  crop the name on differing aspect ratios — the letterbox carries the same
  `#070A10` as the native Android splash, and each phase exposes its name as
  a semantics label. The app placeholder animation is now a 1080 × 1920
  canvas
- **The system language is the default.** `localeProvider` holds `Locale?`,
  `null` follows the system; the settings page offers it explicitly
- `MaterialApp.title` comes from `AppIdentity.displayName`
- **`PRAGMA foreign_keys = ON`** in `beforeOpen` — declared references are
  only enforced when the pragma is set on every connection
- **Downgrade guard**: opening a database whose schema is newer than the
  build aborts with a readable message instead of failing deep inside a
  feature
- The about page shows an offline license page (`showLicensePage`); the web
  page remains as an addition
- CI analyses every package and runs the Dart test suites
- `TestAppHarness` seeds language *and* clock, so no test depends on the CI
  machine's locale or wall clock
- `AGENTS.md` lists the contracts and the known-issues register as normative
  sources

### Removed

- `splashWarmupTasksProvider` and `features/splash/application/splash_warmup.dart`
  — absorbed by `StartupCoordinator`, whose policies make explicit what the
  warmup registry left to whoever wrote the `await`

### Fixed

- **The app could not start on web.** `driftDatabase()` was called without
  `DriftWebOptions`, which throws in the browser: the blocking startup task
  `database` failed on every launch, and the recovery screen's retry could
  not change that because nothing about the failure was transient
- Screen readers announced the language rows as "Deutsch DE" — `ListTile`
  merges title and trailing into one node; the language code is now excluded
- The Android launch background was only branded in `drawable/`, while
  `drawable-v21/` wins on every device from API 21 (KI-010)

## [2.0.0] - 2026-07-31

First release of the LumbreCode-branded template. Everything below has
accumulated since `0.1.0`, which was the unbranded Flutter scaffolding.

### Added

- External links and support contacts (`AppLinks`, `SupportMailbox` in
  `app_core`): every public page is derived from a single web slug
  (`https://lumbrecode.de/apps/<slug>/{,support,faq,privacy,data-deletion,changelog,licenses}`),
  and mails to the shared LumbreCode mailboxes are tagged `[app:<slug>]` in
  the subject so they can be sorted per app. New `WEB_SLUG` in `project.env`
  as the single source, mirrored in `AppIdentity`
- "About & help" page (`features/about`) reachable from the app bar: web
  links, legal links and five support mailboxes; the bug-report entry
  prefills app version, device and the last uncaught error
- LumbreCode template identity: package schema `de.lumbre.code.<app_slug>`,
  branding constants in `app_core` (`AppBranding`)
- Two-phase splash screen (LumbreCode company phase → app phase) with local
  Lottie placeholder assets and an `initialization` hook
- `openspec/` app specification structure for template initialization
- Template initializer agent (`.github/agents/template-initializer.agent.md`)
  with audit / dry-run / apply modes
- Optional Node.js backend base under `backend/` (Express 5, Zod, node:test)
  with CI workflow and Dependabot coverage
- `docs/operations/template-initialization.md` (new-app checklist)
- Official LumbreCode logo reveal animation
  (`lumbrecode_logo_reveal_lottie.json`) used by the company splash phase
- Official LumbreCode app icon set as the template default: editable masters
  in `design/source/branding/` (manifest `design/manifests/lumbrecode-icon.yaml`),
  generator inputs in `apps/mobile_app/assets/branding/`, web favicons and PWA
  icons in `apps/mobile_app/web/`. `flutter_launcher_icons` is now an actual
  dev dependency and is configured with the brand background (`#070A10`),
  an adaptive foreground and an Android 13+ monochrome layer
- Plan & spec phase for large requirements documents: one OpenSpec entry plus
  multiple feature specs, built incrementally (key features first, one
  branch/PR per feature) — documented in
  `docs/operations/template-initialization.md` and the initializer agent
- README section "Generating a concrete app from this template" with a
  copy-paste agent prompt that consumes requirements from `drafts/`
- `melos run build:web` script and `scripts/build-local.ps1` — local
  (SDK-based) counterpart of the Docker `build.ps1` wrapper
- Google Stitch MCP server pre-configured for Claude Code (`.mcp.json`),
  VS Code/Copilot (`.vscode/mcp.json`) and Codex (`.codex/config.toml`);
  design-to-code workflow documented in `docs/operations/stitch-mcp.md`

### Changed

- Splash screen fallbacks (shown when a Lottie asset cannot be loaded) now use
  the brand icon PNGs instead of the Material `flutter_dash` /
  `local_fire_department` glyphs
- `FeedbackMailBuilder` takes an `AppLinks` + `SupportMailbox` instead of a
  raw recipient string, so subject tagging and URI encoding live in one place
- `project.env` defaults to `ORG="de.lumbre.code"` / `PROJECT_NAME="todoapp"`
- Todo example app documented as a preserved template component
- CI workflows hardened with `permissions: contents: read`
- `apps/mobile_app/AGENTS.md` updated (Riverpod standard, `///` doc comments,
  initializer-driven replacement table)
- SECURITY.md expanded (privacy-by-default, OWASP baselines, logging rules)

### Removed

- Accidental `flutter create` leftovers in `services/api/` (`web/`,
  `windows/`, `.metadata`)
- `lumbrecode_splash_placeholder.json` — superseded by the official
  `lumbrecode_logo_reveal_lottie.json`

## [0.1.0] - 2026-04-03

### Added

- Repository scaffolding as Flutter app template
- Initial monorepo structure with `apps/`, `packages/`, `services/`, `docs/`
- Flutter mobile app with feature-first architecture
- Dart backend service with Shelf/Router
- arc42 architecture documentation template
- ADR framework with initial decisions
- GitHub Actions for mobile CI, backend CI, Android/iOS builds
- VS Code workspace configuration
- Dev Container for reproducible development
- Agent/Copilot/Codex configuration
- Design artifact versioning system
- Glossary CSV with Markdown generation
- Diagram rendering pipeline (draw.io, PlantUML, Mermaid)
- PDF rendering pipeline for architecture docs
