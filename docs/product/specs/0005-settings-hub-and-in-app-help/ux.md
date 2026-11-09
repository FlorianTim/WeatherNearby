# UX: Settings hub, in-app help and privacy page

## Entry point

The main screen's app bar keeps its settings action. It no longer means
"change the language" — it opens the hub.

## The hub

```text
+--------------------------------------------------+
| <-  Einstellungen                                 |
+--------------------------------------------------+
| SPRACHE                                           |
|  (o) Systemsprache                                |
|  ( ) Deutsch                                DE    |
|  ( ) English                                EN    |
|                                                   |
| ERSCHEINUNGSBILD                                  |
|  (o) Systemeinstellung                            |
|  ( ) Hell                                         |
|  ( ) Dunkel                                       |
|                                                   |
| HILFE                                             |
|  [?] Anleitung                                >   |
|  [?] Haeufige Fragen                          >   |
|  [>] App-Einleitung erneut anzeigen           >   |
|                                                   |
| DATEN UND DATENSCHUTZ                             |
|  [#] Datenschutz und Daten                    >   |
|      Was gespeichert wird, und wie man es loescht |
|                                                   |
| PRO                                               |
|  [*] Pro-Status                               >   |
|      Alle Funktionen sind derzeit kostenlos       |
|                                                   |
| UNTERSTUETZUNG                                    |
|  [i] Ueber die App und Hilfe                  >   |
|  [!] Letzten Fehler melden                        |
|                                                   |
| ENTWICKLUNG                       (nur Debug)     |
|  [~] Einstellungen-Diagnose                   >   |
+--------------------------------------------------+
```

Why the frequently-changed options sit inline and everything else navigates:
a language switch is a two-tap job on a hub, a five-tap job behind a
sub-page — and it is the single most-used setting in a bilingual app.

## Privacy and data

```text
+--------------------------------------------------+
| <-  Datenschutz und Daten                         |
+--------------------------------------------------+
| +----------------------------------------------+ |
| | [db] Deine Daten bleiben auf diesem Geraet    | |
| |      Die App speichert alles lokal ...        | |
| +----------------------------------------------+ |
|                                                   |
| BERECHTIGUNGEN            (nur wenn vorhanden)    |
|  [b] Benachrichtigungen              Erteilt      |
|                                                   |
| VEROEFFENTLICHTE DOKUMENTE                        |
|  [p] Datenschutzerklaerung                    ^   |
|  [d] Datenloeschung                           ^   |
|  [@] Datenschutz-Anfrage senden               ^   |
|                                                   |
| GEFAHRENBEREICH                                   |
|  [x] App-Daten loeschen                           |
|      Loescht alle Inhalte. Einstellungen bleiben. |
|  [x] Einstellungen zuruecksetzen                  |
|      Sprache und Erscheinungsbild zurueck auf     |
|      Systemeinstellung. Inhalte bleiben.          |
+--------------------------------------------------+
```

The danger section is last, has its own heading in the error colour, and
each row states its exact blast radius in the subtitle. A user must be able
to tell the two actions apart *before* tapping, not from the dialog.

## Help documents

A plain scrolling Markdown page with the document's title in the app bar.
No table of contents, no search — a template manual that needs either is too
long.

While the asset loads: a centred progress indicator. On failure: the
localized error text, centred, with no retry button — a bundled asset that
is missing will not appear on a retry.

## Copy rules

- Destructive dialogs name the consequence: "Alle lokal gespeicherten
  Inhalte werden endgueltig geloescht." — never "Bist du sicher?".
- Subtitles state scope, not reassurance.
- The Pro row says that everything is currently free, so the row does not
  read as a locked feature.

## Accessibility

- Every row is a `ListTile`, so it is one semantics node with a tap target of
  at least 48 dp.
- Selection state is icon + container colour (rule 9).
- The language code in the trailing slot is `ExcludeSemantics` — it is visual
  shorthand for the label beside it and would otherwise be read twice
  (rule 3).
- The danger rows use the error colour **and** an explicit icon; colour alone
  never carries the warning.
