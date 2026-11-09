# Agent Prompts

Reusable prompts for Copilot Coding Agent, manual agent use, or issue creation.

---

## A. Triage raw ideas

```
Read docs/ideas/simple/ideas.md and docs/ideas/simple/processed-index.yml.
Process only new or changed ideas (compare with processed-index).
Do NOT modify the raw ideas file.

Update:
- docs/ideas/triage/idea-triage.md (triage results)
- docs/product/feature-candidates.md (new candidates)
- docs/product/roadmap.md (if appropriate)
- docs/ideas/simple/processed-index.yml (processing status)

Implement NOTHING. Do not change product code.
Produce a short summary of identified ideas and open questions.
```

---

## B. Promote idea to feature spec

```
Take the feature candidate "<name>" from docs/product/feature-candidates.md.
Create a feature spec folder under docs/product/specs/<NNNN-feature-name>/.
Use the templates from docs/product/specs/_template/.

Fill in:
- feature.md
- requirements.md
- acceptance-criteria.md
- open-questions.md
- out-of-scope.md
- release-plan.md

Document assumptions explicitly.
Add test and validation considerations.
Implement NOTHING. Do not change product code.
```

---

## C. Collect clarification questions

```
Analyze the feature spec at docs/product/specs/<NNNN-feature>/.
Create or update open-questions.md.

Group open questions by:
- Product
- UX
- Technical
- Architecture
- Privacy / Security
- Testing
- Release

Do not move open questions into requirements until they are answered.
Implement NOTHING.
```

---

## D. Architecture impact review

```
Review the feature spec docs/product/specs/<NNNN-feature>/ against:
- docs/architecture/arc42/
- docs/architecture/adr/

Assess whether the feature has architecture implications.

If yes:
- Suggest affected arc42 chapters
- Suggest needed ADRs
- Document risks
- Document test/validation implications

If no:
- Document briefly why no architecture change is needed

Implement NOTHING. Do not change code.
```

---

## E. Create implementation plan

```
Create an implementation plan from the feature spec docs/product/specs/<NNNN-feature>/.
Place it at docs/delivery/implementation-plans/<NNNN-feature>.md.
Use the template docs/delivery/implementation-plans/_template.md.

Consider:
- Existing architecture and ADRs
- Existing project structure
- Existing tests

Add a concrete test and validation strategy.
Do NOT decompose into code changes yet.
Implement NOTHING.
```

---

## F. Create stories from plan

```
Decompose the implementation plan docs/delivery/implementation-plans/<NNNN-feature>.md
into small stories under docs/delivery/stories/<NNNN-feature>/.
Use the template docs/delivery/stories/_template.md.

Each story must be independently reviewable and contain:
- Goal
- Scope
- Out of scope
- Acceptance criteria
- Test requirements
- Expected test commands or manual verification steps
- Relevant files

Implement NOTHING.
```

---

## G. Copilot Coding Agent — implement story

```
Implement exactly this story: docs/delivery/stories/<feature>/<story>.md

Read first:
- AGENTS.md
- .github/copilot-instructions.md
- Relevant .github/instructions/*.instructions.md
- The relevant feature spec under docs/product/specs/
- Relevant ADRs under docs/architecture/adr/
- Relevant arc42 chapters
- Existing tests

Rules:
- Work ONLY within the story's scope.
- Fulfill ALL acceptance criteria.
- Create or update tests.
- Run available tests or document why they could not be run.
- Do not add new dependencies without justification.
- Produce a small pull request.
- Do NOT expand scope.
- Do NOT implement other stories.
- Preserve the existing repository structure.
```

---

## H. Review prompt

```
Review this pull request against:
- AGENTS.md
- .github/copilot-instructions.md
- Relevant feature spec
- Relevant story
- Acceptance criteria
- Tests
- Documentation rules
- arc42/ADR implications

Pay special attention to:
- Scope creep
- Missing tests
- Undocumented test results
- Unclear assumptions
- Undocumented architecture decisions
- New dependencies without justification
- Changes unrelated to the story
- Unnecessary changes to the existing repository structure
```

---

## Example: Export Data — Define Export Format

See `docs/delivery/examples/export-data-story-example.md` for a complete example
of a Copilot task issue with story reference.
