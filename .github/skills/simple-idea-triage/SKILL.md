# Simple Idea Triage

Use this skill to process new raw ideas from the Simple Idea Inbox.

## Objective

Read raw ideas, identify new entries, and produce triage output without changing code.

## Input

- `docs/ideas/simple/ideas.md`
- `docs/ideas/simple/processed-index.yml`

## Steps

1. Read `ideas.md` and `processed-index.yml`.
2. Identify ideas not yet in `processed-index.yml`.
3. For each new idea: classify, assess user value, suggest release lane.
4. Update `docs/ideas/triage/idea-triage.md` with results.
5. Update `docs/product/feature-candidates.md` if candidates emerge.
6. Update `docs/product/roadmap.md` if appropriate.
7. Update `docs/ideas/simple/processed-index.yml` with processed items.

## Rules

- NEVER change product code.
- NEVER implement features from raw ideas.
- NEVER modify the raw ideas file itself.
- Only produce documentation and triage output.
