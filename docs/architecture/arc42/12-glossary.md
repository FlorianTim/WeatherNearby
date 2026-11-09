# 12. Glossar

> **Hinweis:** Diese Datei wird automatisch aus `docs/architecture/glossary.csv` generiert.
> Bearbeite die CSV-Datei, nicht dieses Markdown.


### Monorepo {#glossary-monorepo}

A single repository containing multiple projects, packages, and services.

**Kontext:** Architecture  |  **Quelle:** ADR-0001

### ADR {#glossary-adr}

Architecture Decision Record – a document capturing a significant architectural decision.

**Kontext:** Documentation  |  **Quelle:** arc42

### Feature-first {#glossary-feature-first}

Code organization pattern where top-level directories represent product features rather than technical layers.

**Kontext:** Flutter  |  **Quelle:** ADR-0002

### Flavor {#glossary-flavor}

A build variant (dev, staging, prod) configured via dart-define.

**Kontext:** Flutter  |  **Quelle:** packages/app_core

### Design System {#glossary-design-system}

Shared UI components, theme, and spacing constants used across the app.

**Kontext:** Flutter  |  **Quelle:** packages/design_system

### Copilot Setup Steps {#glossary-copilot-setup-steps}

A GitHub Actions workflow that pre-loads SDK and dependencies for GitHub Copilot agents.

**Kontext:** CI  |  **Quelle:** .github/workflows/copilot-setup-steps.yml

### arc42 {#glossary-arc42}

A template for architecture documentation with 12 standardized sections.

**Kontext:** Documentation  |  **Quelle:** https://arc42.org

### Conventional Commits {#glossary-conventional-commits}

A commit message convention that enables automated versioning and changelog generation.

**Kontext:** Versioning  |  **Quelle:** https://conventionalcommits.org

### SemVer {#glossary-semver}

Semantic Versioning (major.minor.patch) – versioning scheme used for this project.

**Kontext:** Versioning  |  **Quelle:** https://semver.org

### Normative {#glossary-normative}

Authoritative source for decisions. Only docs/, AGENTS.md, and agent config files are normative.

**Kontext:** Agents  |  **Quelle:** AGENTS.md

### Draft {#glossary-draft}

Non-normative, exploratory content. Never used for implementation unless explicitly requested.

**Kontext:** Agents  |  **Quelle:** drafts/README.md

---

*Generiert am 2026-05-14 aus `docs/architecture/glossary.csv`.*
