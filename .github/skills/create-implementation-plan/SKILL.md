# Create Implementation Plan

Use this skill to create an implementation plan from a mature feature spec.

## Objective

Produce a technical implementation plan with test strategy and story breakdown outline.

## Input

- Feature spec: `docs/product/specs/<NNNN-feature>/`
- Template: `docs/delivery/implementation-plans/_template.md`
- Existing architecture and ADRs

## Steps

1. Read the complete feature spec.
2. Read relevant arc42 chapters and ADRs.
3. Assess affected components, data changes, API changes, UI changes.
4. Create `docs/delivery/implementation-plans/<NNNN-feature>.md` from template.
5. Fill in technical approach, components, risks.
6. Add concrete test and validation strategy.
7. Outline story breakdown (high-level, not full stories yet).

## Rules

- NEVER change product code.
- The plan is not an implementation order — it enables story creation.
- Include test strategy for each major component.
