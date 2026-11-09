---
name: knowledge
description: >-
  LumbreCode knowledge management at development milestones. `start` prepares a
  major feature from the app's current-state snapshot and the central knowledge
  base (reuse assessment, read-only); `finish` updates the app's complete
  current state after a major feature and proposes a selective, approved Google
  Drive publication; `audit` onboards or re-audits an app, template or library;
  `search` finds existing solutions across LumbreCode projects; `status` reports
  what is documented for the current repository.
argument-hint: "start <feature> | finish <feature> | audit [target] | search <topic> | status"
disable-model-invocation: true
---

# LumbreCode knowledge

Arguments: `$ARGUMENTS`

The first word of the arguments is the **action**; everything after it is the
**subject** (feature name, audit target or search topic). Match the action
case-insensitively. If it is missing or not one of the actions below, print the
help block at the end of this file and stop — do not guess an action.

| Action | Subject | Writes locally | Writes to Google Drive |
|---|---|---|---|
| `start` | feature name or description | Feature Knowledge Brief (draft) | never |
| `finish` | feature name or description | current-state draft, change set | only after explicit approval |
| `audit` | optional: repo path, template or library | audit drafts, change set | only after explicit approval |
| `search` | topic | nothing | never |
| `status` | — | nothing | never |

## Non-negotiable rules

1. **Evidence over claims.** A feature is `implemented` only with code
   evidence. A specification, README, roadmap or branch name proves at most
   `specified`. Lifecycle and verification are separate attributes
   (`references/knowledge-schema.md`).
2. **As-Is, To-Be and Delta stay separate.** A planned feature never enters a
   current-state document.
3. **Reuse before writing.** Reference, then reuse, then summarize the app's own
   documentation and screenshots. Never generate screenshots; never rewrite text
   only to change its wording.
4. **Read-only on application code.** No workflow of this skill edits source
   code, dependencies, build files, CI, `.lumbrecode/` or releases.
5. **Google Drive is milestone-based.** No continuous sync, no hooks, no writes
   without the user's explicit approval of a concrete change set in this
   session. Never claim an upload or update that was not verified by readback.
6. **Stable IDs.** Reuse existing IDs from the knowledge base or the local
   manifest; never regenerate them.
7. **Privacy.** Never publish credentials, tokens, personal or customer data, or
   screenshots that may contain them.

## Where things are

- Central knowledge base: Google Drive folder `lumbrecode-product-knowledge`
  (folder ID `1tnuWjLzCwxxEpkVaGgAk11CALdDNEHTS`), top level `apps/`,
  `foundations/`, `shared-concepts/`, `portfolio/`, `references/`.
- Local manifest of the current repository: `docs/knowledge/manifest.yaml`
  (or the location the repository already uses — see
  `references/application-documentation.md`). It references, it does not copy.
- Local drafts: `docs/knowledge/drafts/<YYYY-MM-DD>-<action>-<slug>/`, unless
  the repository has an established drafts location (for example `drafts/`).
- Validator: `.lumbrecode/tooling/knowledge/validate_knowledge.py` in a
  consumer repository, `tooling/knowledge/validate_knowledge.py` in
  `lumbrecode-engineering`.

## Delegation

Repository exploration and evidence collection go to the `knowledge-analyst`
subagent. Give it the target path, the scope (whole app, one feature, one
library, or a search topic) and the existing baseline (snapshot, manifest) so
it verifies instead of rediscovering. It returns evidence records; this skill
decides what to write and what to propose.

If the `knowledge-analyst` agent is not available in this session, use a
read-only exploration agent and pass it the contents of
`../../agents/knowledge-analyst.md` (relative to this file) as its brief.

## Google Drive access

Before the first Drive operation in a session, run the capability probe in
`references/google-drive-publication.md`: find the Drive tools that are
actually connected, test read operations, and record which of search, read,
metadata, create, update, image upload and readback are available. If none is
connected, continue locally and say so — that is the fallback, not a failure.

## Workflows

Read `references/workflows.md` for the step-by-step procedure of the selected
action, and only the further references that step names:

| Need | Reference |
|---|---|
| procedures for every action | `references/workflows.md` |
| entities, IDs, frontmatter, statuses, relationships | `references/knowledge-schema.md` |
| current-state snapshot, baseline inventory, template inheritance, doc reuse | `references/application-documentation.md` |
| screenshot discovery, selection, privacy, copy vs. reference | `references/screenshot-management.md` |
| reuse matrix and REUSE/CONFIGURE/EXTEND/EXTRACT/ADAPT/BUILD | `references/reuse-assessment.md` |
| Drive probe, change set, approval, publish, readback | `references/google-drive-publication.md` |
| document skeletons | `templates/` |

Validate every local artifact before presenting it:

```bash
python .lumbrecode/tooling/knowledge/validate_knowledge.py docs/knowledge
```

## Help

When the action is missing or unknown, print exactly this and stop:

```text
/knowledge — LumbreCode knowledge management (milestones only)

  /knowledge start <feature>    Before a major feature: current-state baseline,
                                search for existing solutions, reuse matrix,
                                Feature Knowledge Brief. Read-only on Drive.
  /knowledge finish <feature>   After a major feature: verify what was built,
                                update the app's complete current state,
                                propose a change set; publish only on approval.
  /knowledge audit [target]     Full audit of an app, template or library;
                                produces drafts and a publication proposal.
  /knowledge search <topic>     Find capabilities, implementations, libraries
                                and standards across LumbreCode. Read-only.
  /knowledge status             What is documented for this repository, and
                                how fresh it is. Read-only.

Not for routine commits, small fixes or styling changes.
```
