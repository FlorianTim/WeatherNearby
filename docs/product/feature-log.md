# Feature log

One line per feature and per bugfix, newest version first. **What shipped
when**, scannable — the changelog explains *why* and *how*, this answers
*when*.

Maintained continuously, not written at release time: every change that adds
or fixes something user-visible or developer-visible adds its row in the same
PR. See "Feature log" in `AGENTS.md`.

## Legend

| Type | Meaning |
|---|---|
| ✨ | Feature — something new you can use |
| 🐛 | Bugfix — something that was broken |
| ♻️ | Change — existing behaviour works differently |
| 🧱 | Foundation — structure, rules, tooling; no user-visible surface |

Status is `shipped` unless the version is still in progress.

---

## Unreleased

| Type | Area | What | Reference |
|---|---|---|---|
| 🧱 | Dependencies | Dependabot is the active bot (pub workspace (`/`, `/apps/*`, `/packages/*`, `/services/*`), with a `git` registry for the private `flutter-libraries`; GitHub Actions; npm for `backend/`; weekly, 5-day cooldown); green minor/patch and security updates merge automatically, majors get `needs-human`; nightly triage issue incl. Flutter stable; gitleaks/OSV scan verified by the CI gate; no deploy | ADR-0018 |
| 🧱 | CI | `ci-mobile.yml` is back on the moving `@v1` of the shared Flutter workflow; baseline 1.7.0 is the template's baseline | KI-012 |
| ♻️ | App shell | The to-do list is the main screen; the greeting demo page and the unrouted starter page `features/home/` are removed. Settings and About open from the to-do app bar | ADR-0011 |
| 🐛 | Android build | `buildFeatures { resValues = true }` is added by `apply_android_branding.sh`; AGP 9 rejected the generated `resValue` | — |
| ✨ | Build | Flavors `dev`, `snapshot`, `staging`, `prerelease`, `prod`: own database file and preference keys per flavor; Android id suffix and name for snapshot and pre-release | spec 0008 |
| ✨ | Build | Tag `v1.2.0-rc.1` creates a GitHub pre-release; *Android Build Release* takes a `flavor` | spec 0008 |
| ♻️ | Settings | The diagnostics are reachable in snapshot builds as well as in debug | spec 0008 |
| ✨ | Menu | Menu bar (native on macOS, Flutter-drawn on Windows/Linux/web, none on phones) with Go to, Help and File → Quit | spec 0008, ADR-0016 |
| ✨ | Keyboard | `Alt+1`…`4` to the screens, `F1` manual, `F10` opens the bar, `Ctrl/Cmd+Q` quits | spec 0008 |
| ✨ | About | The about page names the flavor for every build but the release | spec 0008 |
| 🐛 | Integration CI | Pull requests validate bounded screenshot flows and retain test artifacts without publishing | ADR-0016 |
| 🐛 | Windows analysis | Keep the legacy `custom_lint` client on locked `riverpod_lint` 3.0.3 and isolate its temporary files per run | KI-002 |
| ♻️ | Monetization | Entitlement values switched to the shared kebab-case vocabulary; the 3.2.1 forms still decode | `schemas/entitlement/v1` |
| ♻️ | Template feedback | Register moved to `docs/template-feedback/`, one file per problem, written by the shared skill | — |
| 🐛 | Settings | `AppSettings.entitlement` had its own decoder, which drifted from `Entitlement.fromStored` and dropped the legacy mapping | — |
| 🐛 | Initialization | The keep/replace table pointed at todo tables in `lib/core/database/` that are not there, and missed five shell call sites into the example feature — including the privacy page's data deletion | Review `2026-08-27` |
| ♻️ | Initialization | `dry-run` now reports a reference check next to the deletion list; `apply` rewires the shell before deleting | Review `2026-08-27` |
| 🧱 | Initialization | First dry-run rehearsal, with a minimal fixture spec and five feedback entries | `drafts/init/spec/` |
| 🧱 | CI | `ci-gate.yml` asserts on every PR that the gating workflows actually produced a run — a workflow that fails to start attaches no check and leaves the PR looking clean | KI-012 |
| 🧱 | Dependencies | `task_interchange` consumed from `flutter-libraries` by tag (`interchange-v0.1.0`) instead of an in-repo package; CI access, local-development guide and a contract test over the baseline golden fixtures | ADR-0017, plan 0001 slice 1, spec 0004 |
| 🧱 | Interop | Baseline 1.6.0 adopted; CT-16 contract test over every accepted `Group` fixture (packing lists `52`-`54` included), found by directory; packing-list conventions and whole-file rejection asserted at the decoder | spec 0004 INT-606..609, AC-67..70 |
| 🧱 | Interop | Packing-list import (Packzeit) planned into slice 8 — **not built**; four skipped obligations carry the database half | plan 0001 plan change 2026-10-09 |
| ♻️ | CI | The gate handles a workflow without a path filter via `--expect-always`, so the same script serves both templates | `verify_ci_gate.py` |

## 3.2.1 — App shell (2026-08-26)

Specs 0005–0007 · plan `0002-settings-and-app-shell.md` · ADR-0015

| Type | Area | What | Reference |
|---|---|---|---|
| ✨ | Settings | Settings page became a hub: sections for help, data and privacy, Pro, support, development | SET-001…006 |
| ✨ | Settings | Debug-only diagnostics page over the settings register | SET-050…052 |
| ✨ | Help | Bundled manual and FAQ per language, offline, English fallback | SET-020…025 |
| ✨ | Privacy | In-app privacy page: storage promise, permission overview, legal links, danger zone | SET-030…039 |
| ✨ | Privacy | "Reset settings" as a second destructive action, separate from "Delete app data" | SET-037 |
| ✨ | Onboarding | Five-page first-start intro, replayable from settings, requests no permission | ONB-001…042 |
| ✨ | Monetization | Purchase seam, entitlement cache, `featureUnlocked(key)`, Pro page — no billing dependency | IAP-001…041 |
| ✨ | Design system | `AppOptionTile`, `AppSettingsSection`, `AppSettingsTile` | SET-060…062 |
| ♻️ | Startup | Splash routes to the app (or the intro), no longer into settings | ONB-001…004 |
| ♻️ | Settings | "Delete app data" moved from the hub to the privacy page | spec 0005, Q1 |
| ♻️ | Greeting | App-bar action opens settings instead of switching the language | — |
| 🧱 | Settings | `app.onboardingCompleted`, `billing.entitlement`, `billing.checkedAt` in the register; `resetAllSettings()` | — |
| 🧱 | Initialization | Canonical keep/adapt/replace table; every path under `lib/` classified; deletion by explicit path | — |
| 🧱 | Release | Store-readiness checks for the shell in the release checklist | — |
| ✨ | Documentation | One source for manual and FAQ: `docs/public-site/` renders to the site and to the bundled help | `render_app_help.py` |
| 🧱 | Documentation | `help` step in both quality gates and in `validate.sh`; a hand-edited generated file now fails | — |
| ♻️ | Testing | Screen profiles moved to `docs/public-site/screenshot-profiles.json`, shared with the web template; sizes injected as dart-defines | — |
| 🧱 | CI | Documentation is generated in the workflows: `help-generate.yml` renders the bundled help, `integration-test.yml` commits the captured screenshots back | — |
| 🧱 | Known issues | KI-011: a Docker Flutter run clobbers the host package config; the analyzer then blames untouched files | — |
| 🐛 | Testing | The screenshot integration flow still drove the pre-3.2.1 app — settings after the splash, a "Continue" button — and produced none of the declared shot ids | — |
| 🐛 | CI | `integration-test.yml` filtered on the removed `scripts/automation/integration-test/profiles.json` | — |
| 🧱 | Baseline | `.lumbrecode/` — synchronized schemas and tooling from the engineering repository | — |
| 🐛 | Initialization | Docs claimed `remove_backend --with-packages` removes `feature_flags`; it does not, and the app depends on it | — |
| 🐛 | Initialization | `lib/features/home/` was unclassified — an unrouted starter leftover the initializer had to guess about | — |

## 3.1.0 — To-do reference app (in progress)

Specs 0001–0004 · plan `0001-todo-reference-app.md` · ADR-0011…0014

| Type | Area | What | Reference |
|---|---|---|---|
| 🧱 | Foundations | Slice 0: time converters, uuid4, URL and share seams, undo snackbar, Markdown renderer and editor, database contract | plan `0000` |
| | | _Slices 1–13 pending_ | |

## 3.0.0 — WasThereSomething 1.3.1 adoption (2026-08-24)

`docs/ideas/wts-1.3.1-adoption-delta.md`

| Type | Area | What |
|---|---|---|
| 🧱 | Architecture | Seven contracts (startup, database, localization, permissions, external data, library evaluation, accessibility) |
| 🧱 | Architecture | `docs/known-issues.md` — KI-001…009 |
| ✨ | Startup | Startup coordinator with blocking/guarded/fire-and-forget policies |
| ✨ | Startup | Recovery screen for fatal startup failures, with retry and error report |
| ✨ | Settings | `SettingDef` register; locale and theme migrated onto it |
| ✨ | Settings | Theme mode as a persisted setting |
| ✨ | Permissions | Just-in-time permission flow with rationale and permanently-denied handling |
| ✨ | Data | `wipeAllData()` — transactional, children before parents |
| ✨ | About | Offline licence page from `LicenseRegistry` |
| ✨ | Monetization | `Entitlement` and fail-open `FeatureGates` in `packages/feature_flags` |
| 🧱 | Core | `generateId()`, `Clock`/`SystemClock` seams |
| 🐛 | Database | `PRAGMA foreign_keys = ON` in `beforeOpen`; downgrade guard |
| ♻️ | Localization | System language is the default; `localeProvider` holds `Locale?` |
| 🧱 | Testing | Accessibility test suite; 60 → 120 app tests |

## 2.0.0 — Branding and app links (2026-08-??)

| Type | Area | What |
|---|---|---|
| ✨ | Branding | LumbreCode icon set as the template default |
| ✨ | Core | External links and support mailboxes derived from one app slug |
| 🧱 | Hooks | Path-aware pre-commit; parallel pre-push |

---

## For a derived app

This file is **reset** when a new app is generated: the template's history is
not the app's history. The new app starts its own log at its first version,
and records which template version it came from — see
`docs/operations/generated-from-template.md`.

## Unreleased (in progress)

| Type | Area | Feature | Reference |
|---|---|---|---|
| ♻️ | UI testing | Explicit profiles, finite shell interaction surfaces and focused accessibility guidance | spec 0009, plan 0003 |
