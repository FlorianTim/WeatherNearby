# Review Copilot PR

Use this skill to review a pull request created by Copilot against specs, stories, and project rules.

## Objective

Verify that a Copilot-generated PR meets acceptance criteria, stays in scope, and follows project conventions.

## Steps

1. Read AGENTS.md and .github/copilot-instructions.md.
2. Identify the referenced story and feature spec from the PR description.
3. Read the story file and acceptance criteria.
4. Read the feature spec for broader context.
5. Review changed files against:
   - Story scope (no scope creep)
   - Acceptance criteria (all met)
   - Test presence and quality
   - Documentation updates
   - arc42/ADR implications
   - Dependency changes
   - Repository structure preservation
6. Check for:
   - Missing tests
   - Undocumented test results
   - Unclear assumptions
   - Undocumented architecture decisions
   - New dependencies without justification
   - Changes unrelated to the story
7. Produce review summary with pass/fail per criterion.

## Rules

- This is a review skill, not an implementation skill.
- Flag issues clearly with severity (blocker, warning, note).
- Copilot Code Review is helpful but does not replace human review.
