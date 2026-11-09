# Architecture Impact Review

Use this skill to assess whether a feature spec has architecture implications.

## Objective

Review a feature spec against arc42 and ADRs, document impact or confirm no impact.

## Input

- Feature spec path: `docs/product/specs/<NNNN-feature>/`
- Architecture docs: `docs/architecture/arc42/`, `docs/architecture/adr/`

## Steps

1. Read the feature spec (all files in the spec folder).
2. Read relevant arc42 chapters.
3. Read existing ADRs.
4. Assess whether the feature affects:
   - Building blocks (05)
   - Runtime behavior (06)
   - Deployment (07)
   - Crosscutting concepts (08)
   - Quality requirements (10)
5. Document findings:
   - If impact: suggest arc42 updates, suggest ADRs, document risks and test implications.
   - If no impact: document why briefly.

## Rules

- NEVER change product code.
- May suggest documentation changes but do not execute unless explicitly asked.
- Be specific about which arc42 sections and why.
