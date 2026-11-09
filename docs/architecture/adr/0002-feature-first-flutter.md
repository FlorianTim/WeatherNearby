# ADR 0002: Feature-first-Struktur in Flutter

## Status

Angenommen

## Kontext

Eine rein horizontale Layer-Struktur skaliert für Produktentwicklung oft schlechter als
eine fachlich geschnittene Struktur.

## Entscheidung

Die App organisiert Produktfunktionalität unter `lib/features/<feature>/`.

Jedes Feature kann intern nach `presentation`, `application`, `data`, `domain`
untergliedert werden.

## Konsequenzen

### Positiv

- bessere fachliche Bündelung
- Feature-Entwicklung mit klaren Grenzen
- kleinere, verständlichere Änderungen

### Negativ

- einige Querschnittskomponenten müssen bewusst im `shared/` oder Paketbereich landen
