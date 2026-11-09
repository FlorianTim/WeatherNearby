# Agent Entrypoints

This document helps coding agents (Copilot, Codex, Claude, etc.) quickly orient themselves
in the repository.

## First files to read

1. `AGENTS.md` — Repository-wide rules and structure
2. `README.md` — Project overview and setup
3. `.github/copilot-instructions.md` — Copilot-specific instructions
4. `docs/architecture/arc42/01-introduction-and-goals.md` — Architecture context

## Normative sources (authoritative for decisions)

| Path | Content |
|------|---------|
| `docs/architecture/arc42/` | Architecture documentation (arc42) |
| `docs/architecture/adr/` | Architecture Decision Records |
| `docs/api/openapi.yaml` | API contract |
| `docs/operations/` | Runbooks, signing, release checklists |
| `AGENTS.md` | Agent behavior rules |
| `.github/copilot-instructions.md` | Copilot instructions |
| `.github/instructions/` | Domain-specific instructions |

## Non-normative (do NOT use unless explicitly asked)

| Path | Content |
|------|---------|
| `drafts/` | Sketches, prompts, experiments |

## Where things live

| What | Where |
|------|-------|
| Flutter app code | `apps/mobile_app/lib/` |
| Shared packages | `packages/` |
| Backend service | `services/api/` |
| Architecture docs | `docs/architecture/` |
| Product docs | `docs/product/` |
| Design mockups | `design/mockups/` (check `design/manifests/` for current version) |
| CI workflows | `.github/workflows/` |
| Build scripts | `scripts/` |

## Current version

Read the `VERSION` file in the repository root.

## Planned features

Features marked with `(ab X.Y)` or `(Version X.Y)` in product docs are planned for
that version. Do not implement them if the current VERSION is lower unless explicitly asked.

## Quality checks

```bash
# Mobile
cd apps/mobile_app && flutter analyze && flutter test

# Backend
cd services/api && dart analyze && dart test

# Full validation
./scripts/validate.sh
```
