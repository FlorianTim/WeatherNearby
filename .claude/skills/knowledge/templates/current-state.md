---
type: application
id: app.<name>
app_id: app.<name>
title: <App name> — current state
description: <one sentence: what the app is and for whom>
tags: []
status: draft
generated: true
repository: <owner/name>
revision: <commit sha inspected>
app_version: <version or unknown>
lifecycle: <idea|specified|prototype|implemented|production|deprecated>
verification: <reported|documentation-reviewed|code-verified|test-verified|release-verified>
last_verified: <YYYY-MM-DD>
platforms: []
derived_from: <template.<name> or omit>
capabilities: []
screenshots: []
relationships: []
sources: []
drive_file_id: null
---

# <App name> — current state

> As-Is at revision `<sha>` (<branch>, <release tag or "development branch">).
> Planned work is not part of this document; see <link to roadmap/spec>.

## Product state

<What the app does today, in two or three user-language paragraphs.>

**Main workflows**

1. <workflow> — <one line> (`feat.<app>.<x>`)

**Business features** — see `features.md`; summary:

| Feature | ID | State | Evidence |
|---|---|---|---|

**Baseline capabilities**

| Item | State | Origin | Evidence |
|---|---|---|---|

**Platforms and maturity:** <platforms>; <lifecycle> · <verification>;
last release <tag/date or none>.

## Technical state

- Frameworks and architecture: <…>
- Internal libraries: <lib.* with version>
- External dependencies (relevant only): <…>
- Backend services: <… or none>
- Storage: <…>
- Template inheritance: <template id and version>; deviations below.
- Integrations: <…>

| Template feature | Inheritance | Note |
|---|---|---|

## Visual state

- Main screens: <…>
- Representative screenshots: see `screenshots.md` (`shot.*` IDs)
- Themes: <…>
- Localization: <languages, switching, fallback>
- Notable UI capabilities: <…>

## Known limitations

- <limitation> — <impact> (`issue.<app>.<x>` if tracked)

## Evidence and freshness

- Last verified: <date>, revision `<sha>`, branch `<branch>`
- Represents: <production release X | development branch>
- Documentation used: <paths>
- Screenshots reviewed: <count, profile, manifest path>
- Documentation/code discrepancies: <none | list with both sources>
- Unresolved uncertainty: <…>
