# Implement Approved Story

Use this skill when a story has status "ready" and implementation is explicitly requested.

## Objective

Implement exactly one approved story, produce tests, and create a small PR.

## Prerequisites

- Story file exists and has status: ready
- Story references a feature spec
- Acceptance criteria are defined
- Test requirements are specified

## Steps

1. Read AGENTS.md and .github/copilot-instructions.md.
2. Read relevant path-specific instructions.
3. Read the story file completely.
4. Read the referenced feature spec.
5. Read relevant ADRs and arc42 chapters.
6. Read existing tests in affected areas.
7. Implement changes within the story's scope ONLY.
8. Add or update tests as specified in test requirements.
9. Run available test commands (flutter test, dart analyze, etc.).
10. Document test results.
11. Create a PR following the PR template.

## Rules

- ONLY implement what the story specifies.
- Do NOT expand scope.
- Do NOT implement other stories.
- Do NOT add dependencies without justification.
- Do NOT modify files outside the story's relevant files unless necessary.
- Preserve existing repository structure.
- If tests fail, fix or document — do not delete tests.
