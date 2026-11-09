# Application documentation

> IDs, paths and values in the examples on this page are illustrative. They
> are not facts about the named application.

Every documented application has **one authoritative current-state snapshot**.
It describes the app as it actually is at the last documented milestone — not
its roadmap, not its architecture intentions.

## Three states, never mixed

| Concept | Content | Lives in |
|---|---|---|
| **Current State / As-Is** | behavior present in the app, with evidence | `current-state.md`, `features.md` |
| **Target State / To-Be** | planned features, improvements, requirements | the app's specs, roadmap; referenced, not copied |
| **Implementation Delta** | what one feature or release changed | change set, changelog, release notes |

A To-Be item enters the current state only when `finish` has verified it in
code. Features behind a disabled flag are listed as `disabled`, not as
available.

## Local manifest

One small file per repository, committed, referencing rather than copying:
`docs/knowledge/manifest.yaml`, validated against
`schemas/knowledge/v1/manifest.schema.json`. If the repository already keeps
an equivalent index (for example under `docs/product/`), extend that instead
and record its path under `manifest_path` in the central overview.

```yaml
schemaVersion: 1
app_id: app.packzeit
aliases: [packzeit]
repository: FlorianTim/Packzeit
central:
  folder: apps/packzeit
  documents:            # Drive file IDs once published; empty before
    current-state: null
sources:                # app-generated documentation the snapshot draws on
  - path: README.md
    role: overview
  - path: docs/public-site/guides/
    role: user-guide
screenshots:
  manifest: docs/public-site/screenshots.yaml
  directory: design/screenshots/
  selected:             # the 5–10 representative shots, by stable ID
    - id: shot.packzeit.01-home
      file: design/screenshots/phone-portrait/01-home.png
      feature: feat.packzeit.packing-lists
snapshot:
  revision: bda390a
  last_verified: 2026-10-16
```

## Discovering app-generated documentation

Inspect, do not assume. Typical locations — each may or may not exist:

```text
README.md  CHANGELOG.md  VERSION
docs/  documentation/  docs/product/  docs/architecture/  docs/known-issues.md
docs/public-site/ (manifest.yaml, faq/, guides/, changelog.yaml, roadmap.yaml,
                   screenshots.yaml, screenshot-profiles.json)
docs/generated/  build/docs/  apps/*/assets/help/  src/presentation/help/
design/screenshots/<profile>/  assets/screenshots/  docs/screenshots/
openspec/  drafts/  docs/ideas/   (To-Be material — never As-Is evidence)
scripts/ and tool configs that generate docs (render_app_help.py, capture tests)
```

`docs/public-site/` is the LumbreCode content contract
(`docs/PUBLIC_SITE_CONTENT_CONTRACT.md` upstream): the app is its source of
truth for FAQ, guides and changelog. Prefer it for user-facing wording.

## Reuse policy

In this order, and stop at the first that suffices:

1. **Reference** the authoritative document (path + revision, or Drive ID).
2. **Reuse** a relevant section verbatim, with its source.
3. **Summarize** it for the central overview.
4. **Copy** selectively when the central catalog needs an independent snapshot
   (for example a release that must stay readable after the repo moves on).
5. **Write new text** only for a genuine gap, and mark it `generated: true`.

Do not reword existing text for style. Do not copy documentation trees.

**Verify critical claims** against code, tests, package manifests and
releases. When documentation and code disagree, record the discrepancy in
the snapshot's "Evidence and freshness" section with both sources. Never
silently pick the documentation.

## Application overview fields

Record what is available; write `unknown` for what is not.

- **Identity:** name, internal project name, short name, `app_id`, category,
  short description, primary purpose, audience, main use cases, related apps.
- **Development:** lifecycle, maturity, repository, branch, revision, version,
  last release (tag), platforms, languages, frameworks, backend, hosting,
  `derived_from`, `last_verified`.
- **Functional overview:** user-language capability descriptions, each backed
  by evidence. "The app offers day, week and month calendar views; users
  navigate dates and create, edit and delete events, which persist locally" —
  not "uses a calendar widget".

Lifecycle reflects the **verified** state: tags, store config, release
workflows, a `VERSION` ≥ 1.0 *with* release evidence. A README saying
"production-ready" is `reported`.

## Baseline feature inventory

Investigate each category; these are discovery targets, not assumptions.

| Area | Items |
|---|---|
| Infrastructure | startup/init, navigation/routing, error handling, logging, lifecycle, settings, DI, state management, configuration, feature flags, environments |
| UI/UX | theme switching, light/dark, design system, responsive layout, platform-specific UI, reusable widgets, dialogs/notifications, form validation, accessibility, loading/empty states, error presentation |
| Localization | languages, switching, framework, resource management, locale formatting, fallback, runtime change |
| Accounts | authentication, guest use, profiles, account management, authorization, roles, sign-in providers, sessions |
| Data | local and remote persistence, offline, sync, import/export, backup/restore, migrations, caching, search/filter |
| Device | camera, file picking, media, notifications, background work, sharing, QR, Bluetooth, location, permissions |
| DevOps | tests, codegen, CI/CD, release automation, crash reporting, monitoring, analytics, distribution |

Record each item as a row:

```markdown
| Item | State | Origin | Evidence |
|---|---|---|---|
| Light/dark mode | available | template: inherited-configured | lib/app/theme/… |
| Authentication | absent | — | no auth package in pubspec.yaml |
```

`State`: `available`, `partial`, `disabled`, `absent`, `unknown`.
`absent` needs negative evidence (searched where it would be, not found).

## Template inheritance

When `derived_from` is set, classify each baseline item that the template
provides:

`inherited-unchanged`, `inherited-configured`, `inherited-extended`,
`replaced`, `disabled`, `removed`, `not-integrated`.

Link the template's own documentation (`foundations/templates/<id>/`) and
record only the **deviations** in the app's snapshot. Do not repeat the
template's documentation. Evidence for inheritance: the template marker, the
template's version at generation, a diff of the template-owned paths
(`git diff` against the template revision when the template repository is
local).

## Feature catalog

Group features into functional areas. Per major feature, one or two short
paragraphs plus a fact block:

```markdown
### Packing lists — `feat.packzeit.packing-lists`

Users create packing lists per trip, group items by category or person and
tick them off…

- Operations: create, rename, duplicate, delete, check/uncheck, reorder
- Status: implemented · code-verified (tests: test/features/packing/…)
- Screens: shot.packzeit.03-packing-list
- Libraries: lib.drift (persistence)
- Persistence: local SQLite via drift; no remote sync
- Limitations: no sharing between devices
- Code: apps/mobile_app/lib/features/packing/
- Related capabilities: cap.checklist-management
```

For complex features, reference the detailed spec instead of expanding.

## Current-state snapshot

Skeleton: `templates/current-state.md`. Required sections:

1. **Product state** — what the app does, main workflows, business features,
   baseline capabilities (inventory), platforms, maturity and release state.
2. **Technical state** — frameworks and architecture, internal libraries,
   external dependencies, backend, storage, template inheritance, integrations.
3. **Visual state** — main screens, representative screenshots, themes,
   localization behavior, notable UI capabilities.
4. **Known limitations** — incomplete features, impactful defects, technical
   restrictions, missing integrations, compatibility concerns.
5. **Evidence and freshness** — `last_verified`, inspected revision,
   documentation artifacts used, screenshots reviewed, release vs. development
   branch, unresolved uncertainty, doc/code discrepancies.

## Update after a major feature

1. Read the existing snapshot; it is the baseline.
2. Re-verify the sections the feature touches **and** any section whose
   evidence paths changed since `revision` (`git diff --stat <revision>..HEAD`).
3. Rewrite only what changed. Unchanged sections stay identical, so the Drive
   diff stays reviewable.
4. Update metadata and the "Evidence and freshness" section.
5. The result must describe the whole app — a reader who never saw the
   previous snapshot gets the complete picture.

Before the next major feature, `start` reads this snapshot and checks its
freshness. If it is stale or missing, prepare a local correction; never
publish intermediate states automatically.
