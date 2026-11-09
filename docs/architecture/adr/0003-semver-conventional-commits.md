# ADR 0003: Semantic Versioning und Conventional Commits

## Status

Angenommen

## Kontext

Das Projekt benötigt eine klare Versionierungsstrategie, die von Menschen und Agents
verstanden wird und sich in CI/CD-Workflows integrieren lässt.

## Entscheidung

- Versionierung nach [Semantic Versioning](https://semver.org): `major.minor.patch`
- Commit-Nachrichten folgen [Conventional Commits](https://conventionalcommits.org)
- Die aktuelle Version steht in der Datei `VERSION` im Repository-Root

### Versionsanhebung

| Commit-Präfix | Versionseffekt | Beispiel |
|---------------|---------------|---------|
| `feat:` | minor | Neues Feature |
| `fix:` | patch | Bugfix |
| `docs:` | patch (optional) | Dokumentation |
| `refactor:` | patch | Refactoring |
| `BREAKING CHANGE:` (Footer) | major | Breaking Change |
| `feat!:` oder `fix!:` | major | Breaking Change (Kurzform) |

### Geplante Features (Zielversion)

Features können in Produktdokumenten mit `(Version X.Y)` oder `(ab X.Y)` markiert werden.
Das bedeutet:
- Das Feature ist frühestens ab dieser Version vorgesehen
- Es ist nicht zwingend Teil der aktuellen Version
- Agents sollen solche Features nicht implementieren, sofern die aktuelle VERSION niedriger ist

Beispiel in einem Produktdokument:
```
## Login mit Biometrie (ab 2.0)
Nutzer sollen sich per Fingerabdruck anmelden können.
```

## Konsequenzen

### Positiv

- klare, automatisierbare Regeln
- gängiger Standard in der Community
- Agents können Versionsänderungen aus Commit-Nachrichten ableiten

### Negativ

- erfordert Disziplin bei Commit-Nachrichten
- Conventional Commits sind keine Pflicht, sondern Konvention
