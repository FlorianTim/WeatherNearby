# Workflows

Each workflow names the references it needs. Load nothing else.

Common preamble for every action:

1. **Identify the repository.** `git rev-parse --show-toplevel`, current branch,
   `git rev-parse HEAD`, remote URL, version file (`VERSION`, `pubspec.yaml`,
   `package.json`), `.lumbrecode/baseline.lock.json` (profile), the template
   marker (`GENERATED_FROM_TEMPLATE` or equivalent).
2. **Read the local manifest** (`docs/knowledge/manifest.yaml` or the
   repository's equivalent). It carries the app ID, the Drive file IDs of the
   app's central documents and the selected screenshots. Missing manifest →
   the app is not onboarded yet; say so.
3. **Probe Google Drive** once per session if the action reads central
   knowledge (`references/google-drive-publication.md`, "Capability probe").

---

## `start <feature>`

Goal: plan a major feature on top of what exists. **No Drive writes. No
application-code changes.**

References: `application-documentation.md` (baseline), `reuse-assessment.md`,
`templates/feature-knowledge-brief.md`.

1. **Application.** Preamble. Note the app's lifecycle, template, platforms.
2. **Baseline.** Read the current-state snapshot — the Drive copy if
   reachable, else the local one referenced by the manifest. Check freshness:
   compare its `revision` with `HEAD` (`git log --oneline <revision>..HEAD`).
   If commits since then touch product behavior, mark the snapshot *stale* and
   list what changed. If no snapshot exists, ask `knowledge-analyst` for a
   current-state scan (scope: whole app, summary depth) and keep the result as
   a local draft snapshot — **do not publish it**.
3. **Feature.** Establish business goal, functional requirements, workflows, UI,
   backend, persistence, platform constraints and reusable needs. Sources in
   order: the user's description, the repository's spec or plan for the
   feature (`docs/`, `openspec/`, `drafts/`), the issue or PR. Ask the user
   only for what none of them answers.
4. **Search.** Run the `search` procedure for each reusable need (step 2–4
   below), restricted to what the feature needs.
5. **Assess.** Build the Reuse Assessment Matrix (`reuse-assessment.md`). Every
   candidate carries its lifecycle *and* verification state.
6. **Brief.** Write the Feature Knowledge Brief from
   `templates/feature-knowledge-brief.md` into
   `docs/knowledge/drafts/<date>-start-<feature-slug>/brief.md`, unless the
   repository keeps plans elsewhere — then put it there and say where.
7. **Report** the brief's path and any documentation discrepancies found, each
   with the correction you would propose. Do not apply corrections.

---

## `finish <feature>`

Goal: the central knowledge base describes the **whole application as it is
after the feature**. Primary write workflow; Drive writes only after approval.

References: `application-documentation.md`, `screenshot-management.md`,
`reuse-assessment.md`, `google-drive-publication.md`, `knowledge-schema.md`,
`templates/publication-change-set.md`.

1. **Scope.** Determine the feature's full extent from the spec, plan, branch
   (`git log --oneline <merge-base>..HEAD`), PR, changelog and the user's
   description. Never assume the last commit is the feature.
2. **Materiality gate.** Classify the change set:

   ```bash
   python .lumbrecode/tooling/knowledge/validate_knowledge.py scope <base>..<head>
   ```

   The script sorts changed paths into product, documentation, screenshots,
   dependency, test-only, formatting/lockfile and tooling buckets. It is a
   hint, not a verdict. If only test, formatting, lockfile, CI or styling
   changes remain and no user-visible behavior, capability, library or
   standard changed, stop with: **"No material central knowledge update
   required."** and the reason. Create no files.
3. **Verify.** Send `knowledge-analyst` the scope (feature paths, spec, prior
   snapshot). Separate *completed* from *partial*, *disabled* (feature flag
   off), *experimental* and *planned*.
4. **Generated docs.** Locate new or changed app-generated artifacts (public
   site guides and FAQ, release notes, changelog, screenshots manifest,
   generated help) and diff them against the snapshot's `sources`.
5. **Full current state.** Update the local snapshot draft for the *entire*
   app (`application-documentation.md`, "Update after a major feature"). Keep
   unchanged sections byte-identical. Update metadata: `revision`,
   `app_version`, `last_verified`, `verification`.
6. **Screenshots.** Re-select representative screenshots
   (`screenshot-management.md`). Changed or new screens replace old entries;
   retired screens are marked `outdated`, not deleted.
7. **Reusable changes.** Decide whether the feature introduced a capability,
   extended one, created an extraction candidate, added or upgraded a library,
   changed a standard, added an adapter, resolved or created a known issue.
8. **Change set.** Write
   `docs/knowledge/drafts/<date>-finish-<feature-slug>/change-set.md` from
   `templates/publication-change-set.md`: one row per Drive document, content
   changes separated from structural changes (new file, move, rename).
9. **Validate.** Run the validator on the drafts and fix every error. Then
   check duplicates, ID stability, links, outdated screenshots, conflicting
   statuses, confidential content, missing evidence and the existing catalog
   conventions as listed in `google-drive-publication.md`.
10. **Approval.** Present a concise summary (≤ 15 lines) and ask for explicit
    approval. Partial approval is fine; publish only what was approved.
11. **Publish** per `google-drive-publication.md`, with readback.
12. **Report** what changed in the app, which documents were updated (with file
    IDs), which screenshots were added or only referenced, which capabilities
    and libraries changed, and — separately — what remains unpublished or
    unverified. Update the local manifest with any new Drive file IDs.

---

## `audit [target]`

Goal: onboard or re-audit an application, template, library or service.
**No application-code changes.** Drive writes only after separate approval.

References: all of them.

Target: default is the current repository. Another local path, a template
(`flutter-app-template`, `web-app-template`) or a library repository are
allowed; resolve it to a path first.

1. Preamble on the target.
2. **Existing knowledge.** Find matching central entries by app ID, aliases,
   repository URL and name (Drive search; then `portfolio/app-catalog.md` or
   its equivalent). An existing entry is the baseline to correct, not to
   replace.
3. **Analysis.** Give `knowledge-analyst` scope `whole` and the analysis areas
   A–J. For a large repository, split by area (product and features; baseline
   inventory and template inheritance; docs and screenshots; architecture,
   dependencies and libraries) and run the parts in parallel.
4. **Drafts.** Into `docs/knowledge/drafts/<date>-audit/` write, reusing
   existing IDs:
   1. `overview.md` — Application Overview
   2. `current-state.md` — Current-State Snapshot (includes the Baseline
      Feature Inventory and the Technical Stack Summary as sections)
   3. `features.md` — Application Feature Catalog
   4. `screenshots.yaml` — Screenshot Index
   5. `reusable-solutions.md` — Reusable Solutions Report, including the
      Library and Dependency Inventory
   6. `known-issues.md`
   7. `change-set.md` — Knowledge Base Publication Proposal

   For a template or library, use the template or library skeleton instead of
   1–3 and keep 5–7. If an equivalent document already exists centrally,
   draft a *diff against it*, not a parallel document.
5. **Manifest.** Propose `docs/knowledge/manifest.yaml` if the repository has
   none. Writing it is a local, reviewable change — tell the user it is the
   only file added outside the drafts folder.
6. **Validate**, then **report** the ten outputs with paths, the open
   uncertainties, and ask whether to publish (`finish` steps 10–12 apply).

---

## `search <topic>`

Goal: find existing solutions. **Read-only, everywhere.**

References: `knowledge-schema.md` (statuses), `reuse-assessment.md` (only for
the recommendation line).

1. **Expand the topic** into 3–6 search terms (synonyms, library names,
   German and English: "Kalender"/"calendar", "Packliste"/"packing list").
2. **Central.** If Drive is reachable: search `portfolio/solution-catalog.md`,
   `portfolio/library-catalog.md`, `shared-concepts/`, `foundations/` and
   `apps/*/features.md` (or their equivalents). Read the hits.
3. **Local workspace.** If sibling LumbreCode repositories exist next to the
   current one (the common parent directory), search their manifests,
   `docs/`, package manifests and, only if needed, source code. Use
   `knowledge-analyst` for anything beyond a grep.
4. **Classify** each hit: capability, implementation, library, standard,
   known issue or reuse candidate, with lifecycle and verification.
5. **Answer** in this order: matching capabilities; implementations (app,
   path, maturity); libraries (package, version, published or not); standards;
   known limitations; source links; recommended next step. State plainly when
   something is only specified, and when Drive could not be searched.

---

## `status`

Read-only. Report: app ID and whether a manifest exists; snapshot location,
`revision`, `last_verified` and commits since; Drive reachability and the
probed capabilities; open drafts under `docs/knowledge/drafts/`; validator
result. Five to ten lines.
