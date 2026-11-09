---
applyTo: "**"
---

# Repository-wide Copilot instructions

## Structure rules

- Respect the existing monorepo layout and avoid creating new top-level folders.
- Put Flutter app code in `apps/mobile_app`.
- Put reusable packages in `packages`.
- Put Dart backend code in `services/api`, Node.js backend code in `backend`
  (both optional — do not add a second backend without an explicit task).
- The Todo example app (`apps/mobile_app/lib/features/todos/` + tests) is a
  deliberate template component. Never delete it during general maintenance;
  it is replaced only via the template initializer with an explicit app spec
  (see `AGENTS.md` and `openspec/`).
- The **app shell** — `lib/features/{settings,onboarding,help,privacy,
  monetization,about}/`, everything under `lib/core/`, `assets/help/` and
  `packages/feature_flags` — is template surface and is **never** deleted,
  not even when the example app is replaced. Only its content is per-app
  (help Markdown, `intro*` l10n keys, `privacyLocalBody`, the `PrivacyPage`
  permission list). See "App shell — preservation rule" in `AGENTS.md`.
- Put durable documentation in `docs` and informal work in `drafts`.
  `drafts/init/` is the exception: it holds a new app's input material, is
  read by the template initializer, and is not deleted with the rest of
  `drafts/`.
- Every change that adds, fixes or alters something visible adds a row to
  `docs/product/feature-log.md` in the same PR — version, type, area,
  reference. See "Feature log" in `AGENTS.md`.
- Put infrastructure configs in `infra`.
- Put helper tools in `tools`.
- Put build/validation scripts in `scripts`.
- Prefer updating existing files instead of creating near-duplicates.

## Architecture and documentation

- For architecture-impacting changes, update `docs/architecture/adr/`.
- For mobile changes, prefer feature-first structure under `lib/features`.
- For backend changes, keep API contracts aligned with `docs/api/openapi.yaml`.
- When adding workflows, prefer official GitHub actions where possible.

## Script authoring

- In `.sh` and `.ps1` scripts, use only ASCII characters in string literals.
- Do NOT embed Unicode symbols (e.g. `✓`, `✗`, emoji) directly in strings — they cause encoding errors on Windows PowerShell and non-UTF-8 shells.
- In PowerShell, express Unicode via `[char]0xNNNN` (e.g. `[char]0x2713` for ✓).
- In bash, use plain ASCII text or `printf '\u2713'` at runtime if a symbol is truly necessary.

## Safety

- Never commit secrets or real signing material.
- Prefer placeholders and documented secret names.

## Drafts are non-normative

- Content under `drafts/` is exploratory and unfinished.
- Do NOT use drafts for implementation, decisions, or answers.
- Exception: the user explicitly points to a specific draft file.

## Versioning

- The current version is in the `VERSION` file at the repository root.
- Commit messages follow Conventional Commits (`feat:`, `fix:`, `docs:`, etc.).
- Features marked `(ab X.Y)` or `(Version X.Y)` in docs are planned for that version — do not implement if current VERSION is lower.

## Design artifacts

- Use the file marked `status: current` in `design/manifests/` YAML files.
- Do not use files from `design/archive/` unless explicitly asked.

## Generated files

- `docs/architecture/arc42/12-glossary.md` is generated from `glossary.csv` — edit the CSV.
- Files under `docs/architecture/generated/` are build outputs — do not edit directly.

---

## Development workflow modes

This repository uses a Markdown-first, documentation-driven development process with two modes.

### Simple Idea Inbox

- Raw ideas are captured in `docs/ideas/simple/ideas.md`.
- Copilot MAY read and triage raw ideas into feature candidates and roadmap entries.
- Copilot MUST NOT implement code from raw ideas.
- Processing status is tracked in `docs/ideas/simple/processed-index.yml`.

### Spec-first Feature Workflow

- Larger features go through: candidate → spec → architecture review → plan → stories → implementation.
- Feature specs live under `docs/product/specs/<NNNN-feature-name>/`.
- Implementation plans live under `docs/delivery/implementation-plans/`.
- Stories live under `docs/delivery/stories/`.
- Code changes require an approved story or explicit Copilot task issue.

### Implementation rules

- Before changing code, read: AGENTS.md, this file, relevant path-specific instructions,
  the relevant feature spec, the story, arc42, and ADRs.
- Produce small, focused PRs limited to one story.
- Fulfill acceptance criteria and describe them in the PR.
- Add or update tests for code changes. Document which tests were executed.
- If tests could not be run, document why in the PR.
- Do not introduce dependencies without justification.
- Do not expand scope beyond the story.
- Do not use raw ideas as a status store. Use `docs/ideas/simple/processed-index.yml`.
- Document assumptions and open questions rather than making broad decisions silently.

### Skills and agents

- Skills and agents under `.github/skills/` and `.github/agents/` may be used.
- They must respect the boundary: triage from ideas, implement only from approved stories.
