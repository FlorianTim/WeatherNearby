# ADR 0005: Drafts als nicht-normative Quelle

## Status

Angenommen

## Kontext

Das Verzeichnis `/drafts` enthält unfertige, explorative Inhalte. Es besteht das Risiko,
dass Agents oder Entwickler Drafts versehentlich als verbindliche Grundlage verwenden.

## Entscheidung

- Alles unter `/drafts` ist **nicht-normativ**
- Drafts dürfen nicht automatisch in Entscheidungen, Implementierungen oder Antworten einfließen
- Ausnahme: Der Nutzer weist explizit auf einen Draft hin
- Normative Quellen sind ausschließlich: `docs/`, `AGENTS.md`, `.github/copilot-instructions.md`, `.github/instructions/`

### Drafts sind Obsidian-kompatibel

- Markdown-first Format
- Saubere interne Verlinkung (Wikilinks oder relative Links)
- Keine Spezialformate, die außerhalb von Obsidian nicht lesbar sind
- Ordnerstruktur bleibt flach und navigierbar

## Konsequenzen

### Positiv

- klare Trennung zwischen explorativ und verbindlich
- kein Risiko, dass halbfertige Ideen in Produktcode einfließen
- Drafts bleiben flexibler Arbeitsbereich

### Negativ

- erfordert expliziten Verweis, wenn ein Draft als Quelle dienen soll
