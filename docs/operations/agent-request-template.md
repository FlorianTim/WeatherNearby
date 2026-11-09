# Agent Request Template

Use this template when creating structured tasks for coding agents.

---

## Task: [Kurze Beschreibung]

### Kontext

- Betroffener Bereich: `apps/mobile_app` | `packages/*` | `services/api` | `docs/` | `design/`
- Aktuelle Version: (siehe `VERSION`)
- Zielversion: (optional, z. B. `ab 1.2`)

### Anforderung

[Beschreibe präzise, was getan werden soll.]

### Akzeptanzkriterien

- [ ] ...
- [ ] ...
- [ ] Tests vorhanden oder aktualisiert
- [ ] Dokumentation aktualisiert (wenn nötig)
- [ ] ADR angelegt (wenn architekturrelevant)

### Normative Quellen

- Relevante ADRs: `docs/architecture/adr/0001-monorepo.md`, ...
- arc42-Kapitel: `docs/architecture/arc42/05-building-block-view.md`, ...
- API-Vertrag: `docs/api/openapi.yaml`

### Ausschlüsse

- Inhalte aus `drafts/` sind NICHT zu verwenden (es sei denn, hier explizit referenziert)
- Design-Artefakte: nur aktuelle Version laut `design/manifests/` verwenden

### Prüfung

```bash
cd apps/mobile_app && flutter analyze && flutter test
cd services/api && dart analyze && dart test
```
