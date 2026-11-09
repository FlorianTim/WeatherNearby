# api

Kleiner Dart-Service als Platzhalter für ein späteres Backend.

> **Optional.** Alternativ gibt es eine Node.js-Basis unter `backend/`.
> Pro App wird höchstens ein Backend gewählt; das ungenutzte Verzeichnis wird
> bei der App-Initialisierung entfernt (siehe
> `docs/operations/template-initialization.md`).

## Ziele

- Health-Check bereitstellen
- Konfigurations- und Info-Endpunkte vorbereiten
- als Beispiel zeigen, wie App und Backend im selben Repo koexistieren

## Start

```bash
dart pub get
dart run bin/server.dart
```

Dann:

- `GET /`
- `GET /health`
- `GET /v1/config`
