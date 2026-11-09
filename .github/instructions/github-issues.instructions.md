---
name: GitHub Issues conventions
description: Rules for writing issues suitable for Copilot Coding Agent
applyTo: ".github/ISSUE_TEMPLATE/**"
---
# GitHub Issues conventions

Issues intended for Copilot Coding Agent must be written as precise prompts.

## Structure of a Copilot task issue

- **Goal**: one clear sentence describing the outcome.
- **Context**: background the agent needs (feature, spec, constraints).
- **Story/Spec reference**: link to the story or spec file.
- **Relevant files**: paths the agent should read or modify.
- **Acceptance criteria**: testable conditions that define done.
- **Out of scope**: explicit boundaries to prevent scope creep.
- **Tests required**: what tests to write, run, or verify.
- **Test commands**: exact commands (e.g. `flutter test`, `dart analyze`).
- **Forbidden changes**: files or areas the agent must not touch.
- **Expected PR summary**: what the resulting PR should look like.

## Rules

- Do not give large, multi-feature issues to Copilot.
- If an issue is unclear, clarify or split into smaller stories first.
- Every Copilot task issue must contain test requirements.
- If no tests are expected, the reason must be explicitly stated.
- A Copilot task issue must reference an approved story or explicit task assignment.
- Raw ideas are never valid Copilot task issues.
