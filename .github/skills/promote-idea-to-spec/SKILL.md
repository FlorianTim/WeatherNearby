# Promote Idea to Spec

Use this skill to promote a feature candidate into a full feature specification.

## Objective

Create a structured feature spec folder from a feature candidate.

## Input

- Feature candidate name from `docs/product/feature-candidates.md`
- Templates from `docs/product/specs/_template/`

## Steps

1. Read the candidate entry from `docs/product/feature-candidates.md`.
2. Determine the next feature ID (NNNN scheme).
3. Create folder `docs/product/specs/<NNNN-feature-name>/`.
4. Copy and fill templates: feature.md, requirements.md, acceptance-criteria.md, open-questions.md, out-of-scope.md, release-plan.md.
5. Document all assumptions explicitly.
6. Add test and validation considerations.
7. Update candidate status in `feature-candidates.md`.

## Rules

- NEVER change product code.
- NEVER implement features.
- Document assumptions and open questions honestly.
- Use existing templates.
