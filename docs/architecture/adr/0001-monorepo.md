# ADR 0001: Monorepo als Standard

## Status

Angenommen

## Kontext

Die Mobile App, mögliche Backend-Komponenten, Architektur-Dokumentation, Design-Artefakte
und Agent-Konfiguration sollen eng zusammenarbeiten.

## Entscheidung

Wir verwenden ein Monorepo mit klarer Top-Level-Struktur:

- `apps/`
- `packages/`
- `services/`
- `docs/`
- `design/`
- `drafts/`

## Konsequenzen

### Positiv

- ein gemeinsamer Kontext für Menschen und Agenten
- zentrale CI/CD-Konfiguration
- Doku und Code bleiben näher zusammen

### Negativ

- stärkere Notwendigkeit sauberer Konventionen
- CI-Filter und Ownership müssen bewusst gepflegt werden
