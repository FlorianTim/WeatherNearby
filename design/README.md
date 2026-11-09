# Design Artifacts

This folder contains versioned design artifacts for the project.

## Structure

```
design/
├── mockups/          Current mockup files (screens, wireframes)
├── screenshots/      Current screenshots
├── flows/            User flows
├── source/           Editable source files (Figma exports, Sketch, etc.)
├── archive/          Previous versions of artifacts
├── manifests/        Version manifests (YAML) per artifact group
└── README.md         This file
```

## Versioning Convention

Every design artifact group has a **manifest file** in `design/manifests/`.
The manifest declares which version is current and lists all historical versions.

### File naming

```
<artifact-name>-v<major>.<minor>.<ext>
```

Examples: `login-screen-v1.0.png`, `login-screen-v2.0.png`

### Manifest file

Each artifact group has a YAML manifest in `design/manifests/`:

```yaml
# design/manifests/login-screen.yaml
artifact: login-screen
description: Login screen mockup
current_version: "2.0"
files:
  - version: "2.0"
    path: mockups/login-screen-v2.0.png
    date: 2026-04-03
    status: current
    notes: Redesigned with new brand colors
  - version: "1.0"
    path: archive/login-screen-v1.0.png
    date: 2026-03-01
    status: archived
    notes: Initial design
```

### Rules

1. The **current** version lives in its category folder (`mockups/`, `screenshots/`, etc.).
2. When a new version replaces an old one, move the old file to `archive/`.
3. Update the manifest to reflect the new current version.
4. Never delete archived versions.
5. Agents should always use the file marked `status: current`.
6. If no manifest exists, the file in the category folder is assumed current.

### For agents

- To find the latest mockup: read `design/manifests/<name>.yaml`, use the `status: current` entry.
- Do not use files from `design/archive/` unless explicitly asked.
