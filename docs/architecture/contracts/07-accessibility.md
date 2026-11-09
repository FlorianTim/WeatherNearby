# Accessibility Contract

Ein Mindeststandard, der **prüfbar** ist. Jede Regel hat eine
Verifikationsform — Prosa allein erodiert.

## Regeln

| # | Regel | Verifikation |
|---|---|---|
| 1 | **Touch-Targets ≥ 48 × 48 dp** für alle primären Aktionen | Widget-Test: `tester.getSize(find.byType(X))` |
| 2 | **Jedes Bedienelement ohne Text hat ein Label** (Semantics oder Tooltip) | Widget-Test: `find.bySemanticsLabel(...)` |
| 3 | **Zusammengesetzte Zeilen liefern eine sinnvolle Gesamtbeschreibung**, nicht fünf Fragmente | `MergeSemantics` bzw. ein Label aus dem Mapper |
| 4 | **Tooltips auf jedem Icon-Only-Button**, lokalisiert | Review + Lint der ARB-Schlüssel |
| 5 | **Textskalierung bis 2.0 ohne Overflow** | Widget-Test mit `MediaQuery(textScaler: TextScaler.linear(2))` auf den zentralen Screens |
| 6 | **Screenreader-Texte sind vollständige Aussagen** mit allem nötigen Kontext, nicht nur der Rohwert | Unit-Test des Label-Mappers |
| 7 | **Dialoge fangen den Fokus**, Formulare haben eine sinnvolle Reihenfolge | manuelle Prüfung im Testplan |
| 8 | **Kontrast über `ColorScheme.fromSeed`** in Hell *und* Dunkel; keine hartkodierte Farbe außerhalb des Schemas | Review; dokumentierte Ausnahmen (z. B. Splash-Hintergrund) |
| 9 | **Information nie nur über Farbe** — jeder Statusfarbe steht ein Icon oder Text zur Seite | Review |
| 10 | **Wischgesten haben immer eine alternative Bedienung** (Menü, Button) | Widget-Test der Alternative |
| 11 | **Dynamische Inhalte werden als verständlicher Text angesagt** — „3 offene Aufgaben", nicht „3" | ARB mit Platzhalter, Unit-Test |

## Mindestumfang je App

- Ein Textskalierungs-Test (Regel 5) pro Hauptscreen.
- Ein Semantics-Test für die wichtigste Liste bzw. Karte.
- Ein Test der Nicht-Gesten-Alternative, sobald es eine Wischaktion gibt.

Diese drei sind bewusst klein gehalten: sie kosten wenig und fangen genau
die Regressionen, die sonst erst auf einem Gerät auffallen.

## Stand im Template

| Regel | Stand |
|---|---|
| 1 Touch-Targets | ✅ `test/a11y/accessibility_test.dart` misst jede `ListTile` und die Primäraktion |
| 2 Labels | ✅ jede Option ist per `find.bySemanticsLabel` erreichbar |
| 3 Zusammengesetzte Zeilen | ✅ das Sprachkürzel ist per `ExcludeSemantics` ausgenommen — sonst liest der Screenreader „Deutsch DE" |
| 4 Tooltips | ✅ Material 3, keine Icon-Only-Buttons ohne Label |
| 5 Textskalierung 2.0 | ✅ Test auf telefongroßer Fläche; Overflow wirft im Testbuild und ist damit die Zusicherung |
| 6 Screenreader-Aussagen | ✅ die Löschzeile sagt ihren Umfang mit, nicht nur ihren Namen |
| 7 Fokus | 🟡 Dialoge fangen den Fokus über Flutters Default; kein eigener Test |
| 8 Kontrast | ✅ `ColorScheme.fromSeed` in Hell und Dunkel |
| 9 Nicht nur Farbe | ✅ Auswahl trägt ein Radio-Icon zusätzlich zur Einfärbung, per Test geprüft |
| 10 Gesten-Alternative | ✅ Test stellt sicher, dass keine Interaktion an einem Wisch hängt |
| 11 Dynamische Inhalte | 🟡 kein Beispiel im Template |

Die Tests liegen bewusst auf der Settings-Seite: sie ist der interaktivste
Screen des Templates. Eine abgeleitete App richtet dieselben Prüfungen auf
ihre eigenen Hauptscreens.

## Test profile scope

One focused 2x test per main screen remains mandatory. This does not require
a width x locale x theme cross product for every functional test. Prefer
standard phone interaction tests and retain named regression profiles.
See [UI test profiles](../../operations/ui-test-profiles.md).
