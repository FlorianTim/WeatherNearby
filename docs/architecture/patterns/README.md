# Architekturmuster

Wiederkehrende Bauformen mit Beispielcode. Abgrenzung:

| Dokument | Beantwortet |
|---|---|
| **ADR** (`../adr/`) | Warum wurde *diese eine* Entscheidung so getroffen? |
| **Vertrag** (`../contracts/`) | Welche Regel muss jede App einhalten? |
| **Muster** (hier) | Wie baut man das konkret? |

## Muster

| Muster | Wofür |
|---|---|
| [Platform Gateways](platform-gateways.md) | Plugins und riskante Abhängigkeiten hinter app-eigene Schnittstellen legen |
| [Capability-Module](capability-modules.md) | Wann eine Fähigkeit Code im Template wird und wann ein Rezept — plus Katalog |
| [Permissions](permissions.md) | Eine konkrete Berechtigung an `core/permissions/` anbinden |
| [External Source & Sync](external-source-sync.md) | Fremde Quellen lesen, in fremde Systeme schreiben, Läufe protokollieren |
| [Backup & Restore](backup-restore.md) | Lokales Backup mit versioniertem Manifest und validiertem Import |
