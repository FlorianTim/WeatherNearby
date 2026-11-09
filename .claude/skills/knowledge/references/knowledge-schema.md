# Knowledge schema

Portable conventions for the central knowledge base and the local drafts.
Markdown with YAML frontmatter; YAML for indexes. Readable by Claude Code,
Codex and ChatGPT alike — nothing essential lives in tool-specific memory.

The machine-readable form of this page is
`schemas/knowledge/v1/frontmatter.schema.json` (delivered to consumers as
`.lumbrecode/schemas/knowledge/v1/`). The validator enforces it.

## Frontmatter

Existing fields stay as they are and keep their meaning:

| Field | Meaning |
|---|---|
| `type` | entity type, see below |
| `title` | human title |
| `description` | one sentence |
| `tags` | free tags |
| `status` | document status: `draft`, `review`, `current`, `outdated`, `archived` |
| `generated` | `true` when the text was produced by an agent and not yet reviewed |
| `sources` | list of evidence references (see "Provenance") |

Added fields, used only where they apply:

| Field | Applies to | Meaning |
|---|---|---|
| `id` | all | stable entity ID |
| `app_id` | app documents | owning application |
| `repository` | app, template, library | repository URL or `owner/name` |
| `revision` | app, template, library | inspected commit SHA |
| `app_version` | app | version string from the version file |
| `lifecycle` | entity | `idea`, `specified`, `prototype`, `implemented`, `production`, `deprecated` |
| `verification` | entity | `reported`, `documentation-reviewed`, `code-verified`, `test-verified`, `release-verified` |
| `last_verified` | entity | ISO date of the last verification |
| `platforms` | app, template, library | `android`, `ios`, `web`, `windows`, `macos`, `linux` |
| `derived_from` | app | template ID |
| `capabilities` | app, library | capability IDs it implements or provides |
| `implementations` | capability | implementation IDs |
| `related_documents` | all | Drive file IDs or relative paths |
| `screenshots` | app | screenshot IDs |
| `relationships` | all | typed relationships, see below |
| `drive_file_id` | all | the Drive file this document is published as |

`status` is about the **document**; `lifecycle` and `verification` are about the
**thing described**. A `current` document may describe a `prototype`.

## Entity types and IDs

IDs are lowercase kebab-case, prefixed by type, and never regenerated.

| `type` | ID pattern | Example |
|---|---|---|
| `application` | `app.<name>` | `app.packzeit` |
| `template` | `template.<name>` | `template.flutter-app-template` |
| `capability` | `cap.<name>` | `cap.calendar-management` |
| `implementation` | `impl.<owner>.<name>` | `impl.packzeit.calendar` |
| `library` | `lib.<package-name>` | `lib.lumbrecode-markdown` |
| `standard` | `std.<name>` | `std.jscalendar-task-interop` |
| `known-issue` | `issue.<owner>.<name>` | `issue.packzeit.timezone-dst` |
| `reuse-candidate` | `candidate.<owner>.<name>` | `candidate.packzeit.calendar-grid` |
| `feature` | `feat.<app>.<name>` | `feat.packzeit.packing-lists` |
| `screenshot` | `shot.<app>.<shot-id>` | `shot.packzeit.01-home` |

`<owner>` is the app or library ID suffix that holds the code. A feature is
an app-level entity; a capability is app-independent.

**Matching before creating.** Before assigning a new ID, search existing IDs,
`aliases`, repository URLs and titles. Two names for one thing get one ID and
an `aliases` list; two similar things get two IDs and a `similar_to`
relationship.

**Reuse candidates are not libraries.** `candidate.*` must never carry
`lifecycle: production` or a package version.

## Lifecycle versus verification

Two independent attributes. Record both, in frontmatter *and* prose.

- *Implemented, not tested*: `lifecycle: implemented`, `verification: code-verified`.
- *Library implemented, never released*: `lifecycle: implemented`, no release,
  `verification: test-verified` at most.
- *Specified in Drive, absent in code*: `lifecycle: specified`,
  `verification: documentation-reviewed`.

Evidence levels, lowest to highest:

| `verification` | Requires |
|---|---|
| `reported` | someone said so (user, README, issue) |
| `documentation-reviewed` | a spec or doc was read; no code check |
| `code-verified` | source code located and read |
| `test-verified` | tests exercising the behavior exist and were located |
| `release-verified` | present in a tagged release or store build |

`lifecycle: implemented` or `production` requires at least `code-verified`.
The validator rejects anything weaker.

## Relationships

```yaml
relationships:
  - type: derived_from
    target: template.flutter-app-template
    evidence: GENERATED_FROM_TEMPLATE
  - type: implements
    target: cap.calendar-management
    via: impl.packzeit.calendar
    evidence: apps/mobile_app/lib/features/calendar/
```

| `type` | Meaning |
|---|---|
| `implements` | entity realizes a capability (use `via` for the implementation ID) |
| `uses` | depends on a library, service or standard |
| `derived_from` | created from a template |
| `extends` | builds on another implementation or library |
| `similar_to` | comparable, not identical — never implies shared code |
| `replaces` | supersedes another entity |
| `blocked_by` | waits on a known issue or missing capability |
| `candidate_for_extraction` | code that may become a library (`target` is a `candidate.*`) |

Every `target` is a stable ID. The validator checks that targets exist when
the referenced entity is part of the validated set, and warns otherwise.

## Provenance

`sources` entries:

```yaml
sources:
  - kind: code            # code | test | manifest | release | doc | spec | screenshot | knowledge
    ref: apps/mobile_app/lib/features/calendar/calendar_page.dart
    revision: bda390a
  - kind: doc
    ref: docs/public-site/guides/en/calendar.md
```

In prose, mark analytical conclusions as such ("Assessment: …") and keep them
apart from facts with direct evidence. Never invent paths, versions,
capabilities or release states; write `unknown` instead.

## Documentation levels

| Level | Content | Where |
|---|---|---|
| 1 Product | what the app does, baseline features, screenshots | central (`apps/`) |
| 2 Solution | capabilities, libraries, relationships, reuse | central (`shared-concepts/`, `foundations/`, `portfolio/`) |
| 3 Engineering | specs, ADRs, API docs, tests, code | the repository — reference it, do not copy it |

## Central layout (logical roles)

These are document *roles*. Map each to the existing document that already
plays it before creating anything:

```text
apps/<app-id>/overview.md | current-state.md | features.md | screenshots.md
             technical-overview.md | known-issues.md
foundations/templates/<template-id>/
foundations/libraries/<library-id>/
shared-concepts/<capability-id>.md
portfolio/app-catalog.md | solution-catalog.md | library-catalog.md
references/knowledge-schema.md
```

`<app-id>` in a path is the ID without its prefix (`apps/packzeit/`).
