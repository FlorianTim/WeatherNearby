# Architektur-Verträge

Ein **Vertrag** ist eine kurze Liste verbindlicher Regeln für einen
Querschnittsbereich. Er beantwortet nicht „wie baue ich X", sondern
„woran erkenne ich, dass X richtig gebaut ist".

Abgrenzung zu den Nachbardokumenten:

| Dokument | Beantwortet |
|---|---|
| **ADR** (`../adr/`) | Warum wurde *diese eine* Entscheidung so getroffen? |
| **arc42** (`../arc42/`) | Wie ist das System aufgebaut? |
| **Vertrag** (hier) | Welche Regeln muss jede App aus diesem Template einhalten? |
| **`docs/known-issues.md`** | Welche Falle hat schon einmal Zeit gekostet? |

## Verwendung

- Beim Ableiten einer neuen App: die Verträge sind die Abnahmeliste.
- Im Review: eine Regelverletzung ist ein Änderungswunsch, keine Meinung.
- Wenn eine App bewusst abweicht, gehört das in eine **ADR der App** —
  nicht in eine stille Ausnahme.

Die Verträge sind aus der ersten produktiv abgeleiteten App
(*WasThereSomething*, 1.0 → 1.3.1) destilliert. Regeln, die dort real Zeit
gekostet haben, sind mit dem zugehörigen `KI-xxx`-Eintrag verlinkt.

## Verträge

| Vertrag | Gilt für |
|---|---|
| [Startup](01-startup.md) | Prozessstart, Splash, Initialisierung, Recovery |
| [Datenbank](02-database.md) | Schema, Migrationen, IDs, Zeit- und Datumssemantik |
| [Lokalisierung](03-localization.md) | Sprachen, Formate, Barrierefreiheitstexte |
| [Berechtigungen](04-permissions.md) | Anfragezeitpunkt, Rationale, Ablehnung |
| [Externe Datenhoheit](05-external-data-ownership.md) | Fremde Quellen lesen, in fremde Systeme schreiben |
| [Bibliotheksauswahl](06-library-evaluation.md) | Bevor eine Abhängigkeit Standard wird |
| [Barrierefreiheit](07-accessibility.md) | Bedienbarkeit, Screenreader, Textskalierung |

## Status der Verträge in diesem Template

Nicht jede Regel ist im Template selbst schon vorgelegt — einige beschreiben,
was eine *App* tun muss, andere warten auf ein Capability-Modul. Der
jeweilige Stand steht am Ende jedes Vertrags unter „Stand im Template".
