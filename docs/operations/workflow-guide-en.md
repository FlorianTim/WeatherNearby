# Workflow Guide: From Idea to Code

This guide describes the complete development process in this repository —
from initial idea to merged pull request.

---

## Table of Contents

1. [Overview](#overview)
2. [Simple Idea Inbox](#simple-idea-inbox)
3. [Triage: Sorting Ideas](#triage-sorting-ideas)
4. [Feature Candidates](#feature-candidates)
5. [Creating a Feature Specification](#creating-a-feature-specification)
6. [Architecture Review](#architecture-review)
7. [Implementation Plan](#implementation-plan)
8. [Creating Stories](#creating-stories)
9. [Implementation (Writing Code)](#implementation-writing-code)
10. [Creating a Pull Request](#creating-a-pull-request)
11. [Review](#review)
12. [After Implementation](#after-implementation)
13. [Using Skills and Agents](#using-skills-and-agents)
14. [Assigning Copilot Coding Agent](#assigning-copilot-coding-agent)
15. [Common Mistakes to Avoid](#common-mistakes-to-avoid)

---

## Overview

This repository supports two working modes:

| Mode | When? | Result |
|------|-------|--------|
| **Simple Idea Inbox** | Quick ideas on the go, via phone, Obsidian, dictation | Documented, triaged ideas |
| **Spec-first Workflow** | Larger features that need planning | Spec → Plan → Stories → Code |

### Core Rule

```
Raw ideas       → read and sort only, NO code
Feature candidate → evaluate and prioritize, NO code
Specification   → clarify requirements, NO code
Plan            → design technical approach, NO code
Story           → HERE code may be written (when status: ready)
```

### Status Model

An idea progresses through these states:

```
raw → triaged → candidate → specified → planned → ready → implementing → implemented → archived
```

Additional terminal state: `rejected`

### Release Lanes

| Lane | Meaning |
|------|---------|
| now | Actively in progress |
| next | Queued after current work |
| v1, v2, v3 | Tied to specific version targets |
| later | Direction confirmed, timing open |
| someday | Interesting but uncommitted |

---

## Simple Idea Inbox

### What is it?

A simple Markdown file where you can jot down ideas at any time.
No formalism, no required fields — just write it down.

### Where?

```
docs/ideas/simple/ideas.md
```

### How to use?

Open the file and write your idea under the current date heading:

```markdown
### 2026-06-15

- [v2] Push notifications for appointments
- [ux] Onboarding screen is too long, reduce to 3 steps
- [tech] Check SQLite instead of SharedPreferences for offline data
- [question] Do we need dark mode for v1?
- [bug] Calendar doesn't scroll back to today
```

### Tags (optional)

Tags help during later triage:

- `[now]`, `[next]`, `[v1]`, `[v2]`, `[v3]`, `[later]`, `[someday]` — release lane
- `[ux]`, `[tech]`, `[bug]` — category
- `[question]` — open question, not a feature
- `[discard?]` — probably not relevant

### Attachments

Images, sketches, or screenshots go to:

```
docs/ideas/simple/attachments/
```

### Important

- This file is ONLY an inbox.
- Code is NEVER written directly from this file.
- Copilot may read and triage this file but must not implement from it.

---

## Triage: Sorting Ideas

### What happens during triage?

New ideas are read, evaluated, and categorized:

- Duplicates are merged
- Open questions are collected
- Promising ideas become feature candidates
- The roadmap is updated as needed

### How?

**Option A: Manual**

1. Open `docs/ideas/simple/ideas.md`
2. Read new entries
3. Evaluate: Is this a real feature? A question? A bug?
4. Record results in `docs/ideas/triage/idea-triage.md`
5. Create feature candidates in `docs/product/feature-candidates.md`
6. Update `docs/ideas/simple/processed-index.yml`

**Option B: With Copilot / Agent**

Use the triage prompt from `docs/delivery/agent-prompts.md` (Section A):

```
Read docs/ideas/simple/ideas.md and docs/ideas/simple/processed-index.yml.
Process only new or changed ideas.
Do NOT modify the raw ideas file.
Update: triage results, feature candidates, roadmap, processed-index.
Implement NOTHING.
```

Or use the skill: `.github/skills/simple-idea-triage/SKILL.md`

### Example: Triage Result

After triage, `docs/ideas/triage/idea-triage.md` might look like:

```markdown
## Last Triage

Date: 2026-06-15
Commit: abc1234

## New Ideas Identified

1. Push notifications for appointments → Feature candidate (v2)
2. Shorten onboarding → Feature candidate (next)
3. Check SQLite → Architecture question, ADR needed
4. Dark mode → Open question: priority unclear
5. Calendar bug → Create bug issue directly

## Open Questions

- Dark mode: Is this v1 or later?
- SQLite: Do we need offline sync or just local cache?

## Recommended Next Steps

1. Create bug issue for calendar scroll
2. Further specify "shorten onboarding" candidate
3. Clarify ADR need for SQLite
```

---

## Feature Candidates

### What is a feature candidate?

A feature candidate is an idea that has been assessed as promising
but is not yet detailed enough for implementation.

### Where?

```
docs/product/feature-candidates.md
```

### Example

```markdown
### Push Notifications for Appointments

- **Status:** candidate
- **Source:** docs/ideas/simple/ideas.md (2026-06-15)
- **Target release:** v2
- **Priority:** medium
- **Confidence:** low

#### Raw input

"Push notifications for appointments"

#### Interpreted intent

Users should receive push reminders before upcoming appointments.

#### User value

Users won't miss appointments even when the app is closed.

#### Possible scope

- Local notifications (no backend needed)
- Configurable lead time (e.g., 15min, 1h, 1 day)
- On/off per appointment

#### Out of scope

- Server-side push
- Notification grouping
- Rich notifications with images

#### Open questions

- What lead times make sense?
- Should notifications come through in Do Not Disturb mode?
- Do we need to design iOS permission dialogs specifically?

#### Architecture impact

- New package for local notifications needed (flutter_local_notifications?)
- Background scheduling differs on Android/iOS
- Possible ADR for notification strategy

#### Test considerations

- Unit tests for scheduling logic
- Widget tests for settings UI
- Manual test on real device (emulator doesn't show push)

#### Recommendation

Address in v2. Write ADR for notification strategy first.
```

---

## Creating a Feature Specification

### When?

When a feature candidate is mature enough and will actually be implemented.

### How?

1. Create a new folder: `docs/product/specs/NNNN-feature-name/`
2. Copy templates from `docs/product/specs/_template/`
3. Fill in the files

### Example: Folder Structure

```
docs/product/specs/0001-shorten-onboarding/
├── feature.md
├── requirements.md
├── acceptance-criteria.md
├── open-questions.md
├── out-of-scope.md
├── ux.md
├── data-contract.md
└── release-plan.md
```

### Example: feature.md (filled in)

```markdown
# Feature: Shorten Onboarding

## Metadata

- **Status:** specified
- **Target release:** next
- **Source:** docs/product/feature-candidates.md
- **Created:** 2026-06-15

## Summary

Reduce onboarding from 7 screens to 3 screens.

## Problem

New users abandon onboarding because it's too long.
Only 40% of users complete it.

## Goals

- Reduce onboarding to maximum 3 screens
- Increase completion rate to >70%
- Keep all critical information

## Non-goals

- Gamification
- A/B testing framework
- Analytics integration (comes separately)

## Users / Actors

- New users opening the app for the first time

## Assumptions

- The current drop-off rate is due to length, not content
- 3 screens are sufficient for essential information
- Optional info can be accessible later in the app menu
```

### Example: acceptance-criteria.md (filled in)

```markdown
# Acceptance Criteria: Shorten Onboarding

## Criteria

- [ ] Onboarding consists of exactly 3 screens
- [ ] Screen 1: Welcome + core value (max 2 sentences)
- [ ] Screen 2: Permissions (Calendar, Notifications)
- [ ] Screen 3: Done + CTA to main view
- [ ] "Skip" button visible on every screen
- [ ] Existing users do NOT see the new onboarding again
- [ ] Language follows device language (DE/EN)
- [ ] Screens usable on small devices (320dp width) without scrolling

## Manual verification steps

1. Fresh install → onboarding starts
2. Go through all 3 screens → reach main view
3. Close and reopen app → no onboarding
4. Switch language to EN → verify English text
5. Test on small device (SE size) → no overflow
```

### Creating with Copilot

Use the promotion prompt from `docs/delivery/agent-prompts.md` (Section B)
or the skill `.github/skills/promote-idea-to-spec/SKILL.md`.

---

## Architecture Review

### When?

After specification, before writing the implementation plan.

### What is checked?

- Does the feature affect overall architecture?
- Do arc42 chapters need updating?
- Do we need a new ADR?
- Are there risks?

### How?

**Option A: Manual**

1. Read the feature spec
2. Read relevant arc42 chapters (especially 05, 06, 08)
3. Read existing ADRs
4. Document the result

**Option B: With Agent**

Use the prompt from `docs/delivery/agent-prompts.md` (Section D)
or the skill `.github/skills/architecture-impact-review/SKILL.md`.

### Example: No Impact

```markdown
## Architecture Review: Shorten Onboarding

### Result: No significant architecture impact

**Reasoning:**
- Pure UI change within the existing onboarding feature
- No new packages needed
- No data model changes
- No API changes
- Existing feature-first structure maintained

**Affected areas:**
- apps/mobile_app/lib/features/onboarding/ (only here)

**ADR needed?** No.
**arc42 update needed?** No.
```

### Example: With Impact

```markdown
## Architecture Review: Push Notifications

### Result: Significant architecture impact

**Affected arc42 chapters:**
- 05 (Building Block View): New notification package
- 06 (Runtime View): Background scheduling
- 08 (Crosscutting Concepts): Permission model

**Required ADRs:**
- ADR-0008: Notification strategy (local vs. remote, package choice)

**Risks:**
- Platform-specific behavior (Android vs. iOS background limits)
- Battery optimization can delay notifications

**Test implications:**
- Integration tests on real devices needed
- Emulator tests limited
```

---

## Implementation Plan

### When?

When the spec is mature and the architecture review is complete.

### Where?

```
docs/delivery/implementation-plans/NNNN-feature-name.md
```

### Example

```markdown
# Implementation Plan: Shorten Onboarding

## Metadata

- **Status:** approved
- **Feature spec:** docs/product/specs/0001-shorten-onboarding/
- **Target release:** next
- **Created:** 2026-06-16

## Scope

- Create 3 new onboarding screens
- Remove old 7 screens
- Keep onboarding state logic (seen once = done)

## Non-scope

- Analytics
- A/B tests
- Animations (can come in separate story)

## Proposed technical approach

1. Replace existing onboarding widgets with 3 new ones
2. Keep PageView controller (just fewer pages)
3. SharedPreferences flag "onboarding_complete" stays the same
4. Texts in ARB files (i18n)

## Components affected

- `apps/mobile_app/lib/features/onboarding/` — completely reworked
- `apps/mobile_app/lib/l10n/` — new/changed strings

## Tests and validation

- Widget tests for each of the 3 screens
- Widget test for "Skip" navigation
- Widget test for "don't show again" logic
- Manual test on small device
- Commands: `cd apps/mobile_app && flutter test`

## Story breakdown

| # | Story | Status |
|---|-------|--------|
| 1 | Replace onboarding screens with 3 new ones | draft |
| 2 | i18n strings for new screens | draft |
| 3 | Widget tests for new onboarding | draft |
```

---

## Creating Stories

### What is a story?

The smallest meaningful implementation unit. One story = one small PR.

### Where?

```
docs/delivery/stories/NNNN-feature-name/story-NNN-slug.md
```

### Example: Complete Story

```markdown
# Story: Replace onboarding screens with 3 new ones

## Metadata

- **Status:** ready
- **Feature:** docs/product/specs/0001-shorten-onboarding/
- **Target release:** next
- **Related issue:** —
- **Related PR:** —

## Goal

Replace the 7 existing onboarding screens with 3 new, shorter screens.

## Context

The current onboarding completion rate is too low (40%).
The feature spec defines exactly 3 screens with clear content.

## Scope

- 3 new widgets: WelcomeScreen, PermissionsScreen, DoneScreen
- PageView with 3 pages instead of 7
- "Skip" button on every screen
- Keep existing "onboarding_complete" logic

## Out of scope

- i18n (separate story)
- Tests (separate story)
- Animations
- Analytics

## Relevant files

- `apps/mobile_app/lib/features/onboarding/presentation/`
- `apps/mobile_app/lib/features/onboarding/application/`

## Acceptance criteria

- [ ] Onboarding shows exactly 3 screens
- [ ] Screen 1: Welcome + core value
- [ ] Screen 2: Permission request
- [ ] Screen 3: Done message + start button
- [ ] "Skip" button on every screen
- [ ] After completion, "onboarding_complete" is set
- [ ] Existing users (flag set) don't see onboarding

## Test requirements

- Widget test: 3 screens are rendered
- Widget test: "Skip" navigates to end
- Widget test: "onboarding_complete" is set
- Commands: `cd apps/mobile_app && flutter test test/features/onboarding/`
- `cd apps/mobile_app && flutter analyze`

## Implementation notes

- Old screen widgets can be deleted (no longer referenced)
- PageController.jumpToPage(2) for "Skip"
- Texts hardcoded for now (i18n comes in next story)

## Review checklist

- [ ] Exactly 3 screens
- [ ] No new dependencies
- [ ] Old screens removed
- [ ] Tests present
- [ ] No scope creep
```

---

## Implementation (Writing Code)

### Prerequisites

- Story has status `ready`
- Acceptance criteria are clear
- Test requirements are defined

### Process

1. **Read before coding:**
   - AGENTS.md
   - .github/copilot-instructions.md
   - Relevant feature spec
   - The story
   - Relevant ADRs

2. **Implement:**
   - ONLY what the story says
   - Do NOT expand scope
   - Respect existing structure

3. **Tests:**
   - Write tests as specified in the story
   - Run tests
   - Document results

4. **Create PR:**
   - Fill in PR template
   - Link story and spec
   - Record test results

### Example: Workflow in Practice

```bash
# 1. Read and understand the story
cat docs/delivery/stories/0001-shorten-onboarding/story-001-new-screens.md

# 2. Write code (in apps/mobile_app/lib/features/onboarding/)
# ...

# 3. Write and run tests
cd apps/mobile_app
flutter analyze
flutter test test/features/onboarding/

# 4. Commit + PR
git add -A
git commit -m "feat(onboarding): replace 7 screens with 3 shorter ones

Implements story-001 from spec 0001-shorten-onboarding.
Acceptance criteria: all met."
```

---

## Creating a Pull Request

### Fill in the Template

The PR template (`.github/PULL_REQUEST_TEMPLATE.md`) has these sections:

```markdown
## Summary
Reduced onboarding from 7 to 3 screens.

## Why
Completion rate too low (40%). Spec defines shorter onboarding.

## Related issue / story / spec
- Story: docs/delivery/stories/0001-shorten-onboarding/story-001-new-screens.md
- Spec: docs/product/specs/0001-shorten-onboarding/

## Scope
- 3 new screen widgets
- PageView adjusted
- Old screens removed

## Out of scope confirmation
- No i18n (separate story)
- No animations
- No analytics

## Tests executed
- `flutter analyze` — 0 issues
- `flutter test test/features/onboarding/` — 3 tests passed

## Tests not executed and reason
- Integration test on real device: No physical device available in CI.
  Manually tested on Pixel 7.
```

---

## Review

### What to look for?

1. **Scope:** Does the PR match the story?
2. **Acceptance criteria:** All met?
3. **Tests:** Present? Meaningful? Documented?
4. **Dependencies:** New packages without justification?
5. **Architecture:** Unexpected structural changes?
6. **Documentation:** Updates needed?

### Using Copilot Code Review

Copilot Code Review can serve as a first review layer.
It does NOT replace human review.

### Review Prompt for Agents

See `docs/delivery/agent-prompts.md` (Section H)
or skill `.github/skills/review-copilot-pr/SKILL.md`.

---

## After Implementation

1. Set story status to `implemented`
2. Update feature spec status (when all stories are done)
3. Update roadmap
4. Optional: Create review protocol under `docs/delivery/reviews/`

---

## Using Skills and Agents

### Available Workflow Skills

| Skill | Purpose | Changes Code? |
|-------|---------|:---:|
| `simple-idea-triage` | Sort new ideas | No |
| `promote-idea-to-spec` | Candidate → Spec | No |
| `architecture-impact-review` | Architecture check | No |
| `create-implementation-plan` | Plan from spec | No |
| `split-plan-into-stories` | Plan → Stories | No |
| `implement-approved-story` | Implement story | **Yes** |
| `review-copilot-pr` | Review PR | No |

Skills are located under `.github/skills/<name>/SKILL.md`.

### Agents

| Agent | Role |
|-------|------|
| `planner.agent.md` | Analyzes, plans, breaks into steps |
| `implementer.agent.md` | Writes code, respects structure |
| `reviewer.agent.md` | Checks architecture, tests, hygiene |

Agents are located under `.github/agents/`.

---

## Assigning Copilot Coding Agent

### Step by Step

1. **Story must exist** with status `ready`
2. **Create GitHub Issue** using the "Copilot Task" template
3. **Fill in the issue:**
   - Goal, Context, Story File, Relevant Files
   - Acceptance Criteria, Out of Scope
   - Tests Required, Test Commands
   - Forbidden Changes
4. **Assign Copilot Coding Agent** (label `copilot-task` or directly)

### Example: Copilot Task Issue

```yaml
Goal: Replace the 7 onboarding screens with 3 new short screens

Context: |
  Feature spec: docs/product/specs/0001-shorten-onboarding/
  Completion rate is too low. Spec defines exactly 3 screens.

Story file: docs/delivery/stories/0001-shorten-onboarding/story-001-new-screens.md

Relevant files: |
  - apps/mobile_app/lib/features/onboarding/presentation/
  - apps/mobile_app/lib/features/onboarding/application/
  - apps/mobile_app/test/features/onboarding/

Acceptance criteria: |
  - Onboarding shows exactly 3 screens
  - "Skip" button on every screen
  - "onboarding_complete" flag is set
  - Existing users don't see onboarding again

Out of scope: |
  - i18n (separate story)
  - Animations
  - Analytics
  - Other features

Tests required: |
  - Widget tests for all 3 screens
  - Test for "Skip" navigation
  - Test for flag logic
  - Commands: flutter test, flutter analyze

Forbidden changes: |
  - packages/ (no reason to change there)
  - services/ (backend not affected)
  - .github/workflows/ (don't change CI)
  - docs/architecture/ (no architecture impact)

Expected PR summary: |
  feat(onboarding): reduce onboarding from 7 to 3 screens
  - Added WelcomeScreen, PermissionsScreen, DoneScreen
  - Removed old onboarding screens
  - Added widget tests
```

---

## Common Mistakes to Avoid

| Mistake | Correct Approach |
|---------|-----------------|
| Code directly from an idea | Triage → Candidate → Spec → Story first |
| Huge PR with 20 files | One story = one small PR |
| Forget tests | Every story has test requirements |
| Expand scope | Only implement what the story says |
| New dependency without reason | Justify, ideally with ADR |
| Use arc42 as backlog | arc42 = architecture docs, not ideas |
| Mark raw ideas | Status goes in processed-index.yml, not ideas.md |
| Restructure existing code | Extend yes, replace no |

---

## Quick Reference: File Paths

| What | Where |
|------|-------|
| Raw ideas | `docs/ideas/simple/ideas.md` |
| Processing status | `docs/ideas/simple/processed-index.yml` |
| Triage results | `docs/ideas/triage/idea-triage.md` |
| Feature candidates | `docs/product/feature-candidates.md` |
| Roadmap | `docs/product/roadmap.md` |
| Feature specs | `docs/product/specs/<NNNN-name>/` |
| Spec templates | `docs/product/specs/_template/` |
| Implementation plans | `docs/delivery/implementation-plans/` |
| Stories | `docs/delivery/stories/<NNNN-name>/` |
| Reviews | `docs/delivery/reviews/` |
| Agent prompts | `docs/delivery/agent-prompts.md` |
| arc42 | `docs/architecture/arc42/` |
| ADRs | `docs/architecture/adr/` |
| Skills | `.github/skills/` |
| Agents | `.github/agents/` |
| Issue templates | `.github/ISSUE_TEMPLATE/` |
| PR template | `.github/PULL_REQUEST_TEMPLATE.md` |
| Copilot instructions | `.github/copilot-instructions.md` |
| Agent instructions | `AGENTS.md` |

---

## Complete Example: From Idea to PR

### 1. Write down the idea

```markdown
### 2026-06-20

- [v1] Export: Users should be able to export their appointments as JSON
```

### 2. Triage

→ Feature candidate: "Appointment Export as JSON"
→ Roadmap: v1
→ processed-index.yml updated

### 3. Evaluate the candidate

→ User Value: high (data sovereignty)
→ Architecture Impact: medium (new export module)
→ Recommendation: Write spec

### 4. Create spec

```
docs/product/specs/0002-appointment-export/
├── feature.md          → Goals, non-goals, assumptions
├── requirements.md     → JSON format, versioning
├── acceptance-criteria.md → Testable criteria
├── open-questions.md   → Encryption needed? Maximum size?
├── out-of-scope.md     → No import, no cloud sync
├── data-contract.md    → JSON schema, version field
└── release-plan.md     → v1, Phase 1: JSON only
```

### 5. Architecture review

→ New package? No, `packages/shared_models` is sufficient.
→ ADR needed? Yes → ADR-0008: Export format (JSON + version field)
→ arc42 update? Yes → 05 (new building block: ExportService)

### 6. Implementation plan

```
docs/delivery/implementation-plans/0002-appointment-export.md
```
→ 3 stories identified

### 7. Create stories

```
docs/delivery/stories/0002-appointment-export/
├── story-001-define-export-format.md
├── story-002-implement-export-service.md
└── story-003-add-export-button-ui.md
```

### 8. Implement story 001

- Set status to `ready`
- Create Copilot task issue (or code manually)
- Write and run tests
- Create PR

### 9. Review + Merge

- Story status: `implemented`
- Next story: story-002
- When all stories done: spec status `implemented`

---

## Workflow Diagram

```
┌─────────────┐
│  Raw Idea   │  docs/ideas/simple/ideas.md
└──────┬──────┘
       │ triage (no code)
       ▼
┌─────────────┐
│  Candidate  │  docs/product/feature-candidates.md
└──────┬──────┘
       │ promote (no code)
       ▼
┌─────────────┐
│    Spec     │  docs/product/specs/NNNN-name/
└──────┬──────┘
       │ architecture review (no code)
       ▼
┌─────────────┐
│    Plan     │  docs/delivery/implementation-plans/
└──────┬──────┘
       │ split (no code)
       ▼
┌─────────────┐
│   Stories   │  docs/delivery/stories/NNNN-name/
└──────┬──────┘
       │ implement (CODE ALLOWED when status: ready)
       ▼
┌─────────────┐
│ Pull Request│  Small, focused, tested
└──────┬──────┘
       │ review
       ▼
┌─────────────┐
│   Merged    │  Update status, roadmap, docs
└─────────────┘
```

---

> This guide is documentation, not code.
> It can be updated or adjusted at any time.
