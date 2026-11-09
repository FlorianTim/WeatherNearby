# ADR 0008: Riverpod als State-Management- und DI-Schicht

## Status

Angenommen

## Kontext

Die App benötigt ein reaktives State-Management-Framework, das testbar, typsicher
und mit Feature-first-Architektur kompatibel ist. Bisherige Lösung war reines `setState`
im Root-Widget.

Riverpod bietet compile-time Safety, Code-Generierung, Provider-Scoping,
testbare Overrides und keine Abhängigkeit von BuildContext für Businesslogik.

## Entscheidung

Riverpod (flutter_riverpod + riverpod_annotation + riverpod_generator) wird als
State-Management- und Dependency-Injection-Lösung eingesetzt.

Neue Feature-Controller verwenden `AsyncNotifier` für asynchrone Daten und
`Notifier` für synchronen State. Infrastruktur (DB, API-Client) nutzt `@Riverpod(keepAlive: true)`.

Provider liegen feature-nah, nicht in globalen Sammelordnern.

## Konsequenzen

### Positiv

- AsyncValue modelliert Loading/Error/Data explizit
- Provider Overrides ermöglichen isolierte Tests ohne Mocks
- Code-Generierung reduziert Boilerplate
- riverpod_lint erkennt häufige Fehler zur Compile-Zeit

### Negativ

- Zusätzliche Code-Generierung erforderlich (build_runner)
- Lernkurve für das Notifier-Pattern
- Abhängigkeit von Riverpod als zentralem Framework
