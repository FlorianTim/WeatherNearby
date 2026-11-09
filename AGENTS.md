# Repository agent instructions

## Scope

These instructions apply to the whole repository unless a nearer `AGENTS.md` overrides them.

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
- Large requirements documents are never implemented directly: a plan &
  spec phase splits them into one OpenSpec entry plus multiple feature
  specs, built incrementally (key features first, one branch/PR per
  feature). See "Large specifications" in
  `docs/operations/template-initialization.md`.

## Reference app — preservation rule

The template ships **one example app**, and it is a deliberate part of the
template. Do NOT delete, replace or simplify it during general template
maintenance, audits or dry-runs.

### What the reference app is for

It is the template's **proving ground**, not a smoke test.

A template has to absorb a Flutter release, a Drift major, a Riverpod change
or a new standard *before* a productive app inherits the damage. That only
works if the example app has enough surface to actually break: foreign keys,
multi-table transactions, type converters, chained migrations, a real
permission flow, local notification scheduling, a platform receive boundary,
an external data contract with golden fixtures, swipe actions with accessible
alternatives, and two languages.

**This is why it is more complicated than a demo needs to be.** If you find
yourself wanting to simplify it back into a three-field checklist, read
ADR-0011 first — that simplification is the thing the rule exists to prevent.

### The rules

- Do NOT delete or replace it during general maintenance, audits or dry-runs.
- Do NOT reduce its scope to make something else easier. Anything it does that
  is *general* belongs in `packages/` or `core/` — extracted in the change
  that introduces it, never "later".
- It is replaced ONLY when the initializer runs in `apply` mode with a
  concrete new app spec and `replace_todo_app: true`.
- If unsure whether a file belongs to template infrastructure or to the
  reference app, mark it as unclear — do not delete it.

### Current state (template 3.2.1)

- **The app shell around it (3.2.1):** settings hub, in-app help, privacy
  page, first-start intro and the purchase placeholder are **template
  surface**, not part of the reference app. They stay when the initializer
  replaces the example app. Specs 0005–0007, plan
  `docs/delivery/implementation-plans/0002-settings-and-app-shell.md`.
- **Today (3.2.1):** the reference app is the Todo demo,
  `apps/mobile_app/lib/features/todos/` plus its tests, routes, providers,
  models and l10n keys.
- **From 3.1.0:** it is the To-do reference app
  (`openspec/apps/todo.openspec.yaml`, specs 0001–0004), which replaces the
  demo through the documented path — an OpenSpec entry with
  `replace_todo_app: true`, retired in the last slice of
  `docs/delivery/implementation-plans/0001-todo-reference-app.md`.
- Until that slice lands, **the demo is still the reference app** and is
  protected by this rule unchanged. 3.1.0 remains reserved for it; the app
  shell took 3.2.1 so the two lines of work do not look sequential.

See ADR-0011 for the decision and its alternatives.

## App shell — preservation rule

Separate from the reference app, and protected separately.

Since 3.2.1 the example app ships a finished **shell**: settings hub,
first-start intro, in-app manual and FAQ, privacy page, Pro page, about page,
plus the `core/` modules behind them. It is **template surface, not example
code** — a derived app inherits it working and keeps it.

| Path | Rule |
|---|---|
| `lib/features/{settings,onboarding,help,privacy,monetization,about}/` | never delete |
| `lib/core/{settings,startup,permissions,platform,errors,storage,domain,utils,menu}/` | never delete |
| `lib/app/menu/`, `lib/app/developer_tools.dart` | never delete; the Go to entry for the example feature is per-app |
| `lib/core/database/` | never delete; only the example tables are replaceable |
| `assets/help/` | keep the `<document>_<language>.md` files; rewrite the prose per app |
| `packages/feature_flags` | never delete — `features/monetization/` depends on it |

- `replace_todo_app: true` authorises replacing the **example feature**
  (`features/todos/`, `features/greeting/` and their tables, tests and l10n
  keys). It does not authorise clearing `apps/mobile_app/`.
- What is per-app here is **content**: the help Markdown, the `intro*` keys,
  `privacyLocalBody`, and the permission list handed to `PrivacyPage`.
  Rewrite those; never rebuild the pages.
- **Store-critical:** `features/privacy/` is the in-app data-deletion path
  Google Play requires. Deleting it removes a release blocker's answer.
- Delete by explicit path, never by folder sweep.

The binding table is
`docs/operations/template-initialization.md` → "What is kept, adapted and
replaced"; `.github/agents/template-initializer.agent.md` mirrors it.

## Generator usage (mandatory)

Use generator-based workflows whenever the repository has the corresponding
generator configured:

- Use `riverpod_annotation` for new Riverpod providers instead of manually
  writing provider boilerplate.
- Use Freezed and `json_serializable` for immutable models, DTOs and union
  states.
- Use Drift codegen for database tables/DAOs.
- Do not manually edit generated files (`*.g.dart`, `*.freezed.dart`,
  `lib/core/l10n/generated/`).
- After changing annotated Dart files, run:
  `dart run build_runner build --delete-conflicting-outputs`
  (repo-wide: `melos run codegen`).
- After changing ARB files, run `flutter gen-l10n`.

## Splash screen rules

- The app uses a two-phase splash: company phase (**LumbreCode**, always
  kept) then app phase (app name from l10n / app spec).
- Lottie animations are LOCAL assets under
  `apps/mobile_app/assets/animations/` — the company phase plays the
  official localized logo reveal
  (`lumbrecode_logo_reveal_3s_de_sequential.json` for German,
  `lumbrecode_logo_reveal_3s_en_sequential.json` otherwise; official,
  always kept); the app phase placeholder is replaced per app. Never load
  splash animations from external URLs.
- App initialization work belongs in the splash `initialization` hook
  (see `lib/features/splash/presentation/splash_page.dart`).

## Quick orientation

1. Read this file first.
2. Then `README.md` for project overview.
3. Then `docs/known-issues.md` — traps that already cost real debugging time.
   **Read it before any dependency upgrade or "weird" test failure.**
4. Then `docs/architecture/contracts/` — the binding rules per cross-cutting
   area (startup, database, localization, permissions, external data
   ownership, library evaluation, accessibility).
5. Then `.github/copilot-instructions.md` for Copilot-specific rules.
6. Then `docs/operations/agent-entrypoints.md` for a full map of normative sources.

## Repository shape

- Treat the repo root as orchestration only.
- Keep executable products inside `apps/` and `services/`.
- Keep reusable code in `packages/`.
- Keep long-lived architecture and product knowledge in `docs/`.
- Keep sketches, prompts, and temporary notes in `drafts/`.
- Keep mockups and design exports in `design/`.
- Keep infrastructure configs in `infra/`.
- Keep helper tools in `tools/`.
- Keep build/validation scripts in `scripts/`; every script starts by sourcing
  `scripts/lib/common.sh` (or dot-sourcing `scripts/lib/Common.ps1`), which
  switches to the repository root — see `docs/operations/dev-scripts.md`.

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
- **`drafts/init/` is the documented exception.** It holds the input material
  for a new app (description, notes, mockups, icons, resources) and is read
  by the template initializer — that is its purpose. It is still
  non-normative: only the specs derived from it are binding. It survives the
  cleanup that empties the rest of `drafts/`, and is deleted only when
  `drafts/init/processed.md` shows every entry processed. See
  `drafts/init/README.md`.

## Feature log (mandatory)

`docs/product/feature-log.md` answers **"which version brought which feature
or bugfix?"** at a glance. It is maintained continuously, not written at
release time:

- Every change that adds, fixes or alters something user-visible or
  developer-visible **adds its row in the same PR**. A change without a row
  is incomplete.
- One row per feature or fix, typed (✨ feature, 🐛 bugfix, ♻️ change,
  🧱 foundation), with the area and a reference to its spec, requirement id
  or ADR.
- It complements `CHANGELOG.md` rather than replacing it: the changelog
  explains *why* and *how* in prose, the feature log is the scannable
  *when*.
- Work still in progress gets its version heading with the rows it has so
  far, marked as in progress.

## Template feedback (mandatory during initialization)

`docs/template-feedback/` records everything about the **template** that got in the way — ambiguities, stale instructions, missing
steps, wrong classifications — written when it happens, including what was
worked around.

- The initializer fills it while generating an app.
- Anyone building features on a derived app appends to it.
- An empty register after a full initialization is a suspicious result, not
  a good one.
- Use the `capture-template-feedback` skill — synchronized from
  `lumbrecode-engineering`, so an entry has the same shape in every
  LumbreCode repository.

It is the input for the next template version. In a derived app,
`docs/operations/generated-from-template.md` records where the app came from
(template version, commit, date) and which template updates it has adopted
since — both files are never deleted.

## Working style

- Prefer small, targeted changes.
- Preserve the existing folder structure.
- Do not move files across top-level folders unless the task explicitly requires it.
- Update docs when behavior, architecture, or developer workflow changes.
- Add or update an ADR for decisions that affect architecture, packaging, runtime boundaries, or CI/CD.

## Quality gates

Before considering work complete, try to run the closest relevant checks:

- mobile: `flutter analyze`, `flutter test`
- api: `dart analyze`, `dart test`
- compact (agent-friendly): `scripts/dev/quality_gate.sh`
- full: `./scripts/validate.sh`
- dependency security: `scripts/deps/audit.sh`

If you could not run checks, state that clearly.

## Safety rules

- Never commit secrets, certificates, provisioning profiles, API keys, or passwords.
- Never hardcode production endpoints in example code.
- Prefer placeholders and documented secret names.
- Do not delete user-authored drafts or design assets unless explicitly asked.

## Writing rules

- Keep code and technical instructions in English.
- Product notes and architecture docs may be German when that matches the existing file.
- Prefer concise Markdown with stable headings.
- In `.sh` and `.ps1` scripts, use only ASCII characters in string literals. No embedded Unicode symbols or emoji — they break on Windows PowerShell and non-UTF-8 shells. Use `[char]0xNNNN` in PowerShell or `printf '\uNNNN'` in bash when a symbol is required.

## Architecture defaults

- Flutter app structure is feature-first (`apps/mobile_app/lib/features/`).
- Shared Flutter UI belongs in `packages/design_system`.
- Cross-app models belong in `packages/shared_models`.
- Backend contracts should be reflected in `docs/api/openapi.yaml`.
- Versioning follows SemVer (see `VERSION` file and ADR-0003).
- Commit messages follow Conventional Commits convention.

## Design artifacts

- Current versions live in `design/mockups/`, `design/screenshots/`, etc.
- Manifests in `design/manifests/` declare the current version per artifact.
- Archived versions in `design/archive/`.
- Always use the file with `status: current` in the manifest.
- See ADR-0004 for details.
- Designs pulled via the Google Stitch MCP server land in `design/`
  (screenshot + HTML export + manifest entry) and are design references
  only — re-implement them as Flutter widgets via `packages/design_system`,
  never port the generated HTML. Setup: `docs/operations/stitch-mcp.md`.

## Planned features (version targets)

Features marked with `(ab X.Y)` or `(Version X.Y)` in product docs are roadmap items.
- Do NOT implement them if the current `VERSION` is lower than X.Y.
- Exception: the user explicitly asks to implement a planned feature.

## Generated files

- `docs/architecture/arc42/12-glossary.md` — generated from `glossary.csv`
- `docs/architecture/generated/` — generated diagrams and PDFs
- `apps/mobile_app/assets/help/*.md` — generated from `docs/public-site/`
  (FAQ from `faq/<locale>.yaml`, manual from `guides/<locale>/`). Same source
  the public website publishes; see `docs/operations/help-content.md`.
- Do NOT edit generated files directly. Edit the source instead.

## Key ADRs

| ADR | Decision |
|-----|----------|
| 0001 | Monorepo structure |
| 0002 | Feature-first Flutter |
| 0003 | SemVer + Conventional Commits |
| 0004 | Design artifact versioning |
| 0005 | Drafts are non-normative |
| 0006 | Documentation source/target separation |
| 0007 | Diagram rendering pipeline |
| 0011 | Reference app (not a smoke test) |
| 0012 | Local notification boundary |
| 0013 | Android JSCalendar receive boundary |
| 0014 | `packages/task_interchange` (superseded in part by 0017) |
| 0015 | Purchase seam without a billing dependency |
| 0017 | Template depends on `flutter-libraries` (`task_interchange`), supersedes ADR-0014 in part |

---

## Development workflows

This repository supports two documentation-driven workflows. Both exist to ensure
that ideas are captured quickly but code only changes through explicit approval.

### Simple Idea Inbox

A lightweight Markdown-first workflow for spontaneous ideas (mobile, Obsidian, voice).

- Raw ideas live in `docs/ideas/simple/ideas.md`.
- Agents may read and triage raw ideas but MUST NOT implement code from them.
- Triage produces feature candidates (`docs/product/feature-candidates.md`) and roadmap updates.
- Processing status is tracked in `docs/ideas/simple/processed-index.yml`.

### Spec-first Feature Workflow

A structured workflow for larger features.

1. Feature candidate identified (from triage or directly).
2. Feature spec created under `docs/product/specs/<NNNN-feature-name>/`.
3. Architecture impact reviewed against arc42 and ADRs.
4. Implementation plan written in `docs/delivery/implementation-plans/`.
5. Small stories derived in `docs/delivery/stories/`.
6. Code changes only from an approved story or explicit Copilot task issue.
7. Pull request reviewed against spec, story, and acceptance criteria.
8. Post-implementation documentation and status updated.

### Core rule

> Raw ideas are input.
> Feature candidates are triage results.
> Specs are decisions.
> Stories are implementation units.
> Pull requests are the review boundary.
>
> Agents may triage and plan from raw ideas but may only implement code
> from approved stories or explicit Copilot task issues.

## Status model

Ideas and features progress through these states:

`raw` → `triaged` → `candidate` → `specified` → `planned` → `ready` → `implementing` → `implemented` → `archived`

Additional terminal state: `rejected`.

## Release lanes

| Lane | Meaning |
|------|---------|
| now | Actively in progress |
| next | Queued after current work |
| v1, v2, v3 | Tied to specific version targets |
| later | Confirmed direction, timing open |
| someday | Interesting but uncommitted |

## Idea-to-code boundaries

- Agents MUST NOT implement code directly from `docs/ideas/simple/ideas.md`.
- Agents MAY triage raw ideas into feature candidates and roadmap entries.
- Agents MAY create feature specs from candidates.
- Agents MAY create implementation plans from specs.
- Agents MAY create stories from implementation plans.
- Agents MAY implement code ONLY when an approved story or explicit Copilot task issue exists.
- Every implementation should be small, reviewable, and limited to one story.
- Every PR should reference a story, spec, or issue.

## Testing and validation

- Every code change should include tests.
- Every story must specify test requirements.
- Every Copilot task must describe expected tests.
- Every PR must document which tests were executed.
- If tests could not be run, the reason must be documented in the PR.
- Do not delete or weaken tests to make CI pass.

## Dependency management

- Do not add dependencies without justification.
- New dependencies require documentation in the PR and ideally a spec or ADR reference.

## Skills and agents

- Skills and agents may be added or extended if they support these workflows.
- Skills and agents MUST respect the approval boundary: no code from raw ideas.
- Existing agent definitions (`.github/agents/`) and skills (`.github/skills/`) take precedence.
- Workflow-supporting skills live under `.github/skills/`.
