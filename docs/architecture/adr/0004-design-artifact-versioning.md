# ADR 0004: Design-Artefakte mit Manifest-Versionierung

## Status

Angenommen

## Kontext

Mockups, Screenshots und andere Design-Artefakte müssen versioniert werden, damit
alte Versionen nachvollziehbar bleiben und Agents die aktuelle Version erkennen.

## Entscheidung

- Jede Artefaktgruppe erhält ein YAML-Manifest unter `design/manifests/`
- Das Manifest deklariert die aktuelle Version (`status: current`) und archivierte Versionen
- Aktuelle Dateien liegen in ihren Kategorieordnern (`mockups/`, `screenshots/`, etc.)
- Archivierte Dateien werden nach `design/archive/` verschoben
- Dateinamen folgen dem Schema: `<name>-v<major>.<minor>.<ext>`

### Regeln für Agents

- Immer die Datei mit `status: current` im Manifest verwenden
- Dateien aus `design/archive/` nicht verwenden, es sei denn explizit angewiesen
- Bei fehlender Manifest-Datei ist die Datei im Kategorieordner die aktuelle

## Konsequenzen

### Positiv

- nachvollziehbare Versionshistorie
- Agents können die aktuelle Version maschinenlesbar ermitteln
- alte Versionen gehen nicht verloren

### Negativ

- erfordert Pflege der Manifest-Dateien
- leichter Overhead bei jeder Designänderung
