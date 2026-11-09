# Split Plan into Stories

Use this skill to decompose an implementation plan into small, reviewable stories.

## Objective

Create individual story files from an implementation plan.

## Input

- Implementation plan: `docs/delivery/implementation-plans/<NNNN-feature>.md`
- Template: `docs/delivery/stories/_template.md`

## Steps

1. Read the implementation plan.
2. Identify logical implementation units (each should be one small PR).
3. Create folder `docs/delivery/stories/<NNNN-feature>/`.
4. For each story, create `story-NNN-<slug>.md` from template.
5. Each story must include:
   - Clear goal
   - Scope and out of scope
   - Acceptance criteria
   - Test requirements with expected test commands
   - Relevant files
6. Update the implementation plan's story breakdown table.

## Rules

- NEVER change product code.
- Each story must be independently implementable and reviewable.
- Each story must contain test requirements.
- Prefer smaller stories over larger ones.
