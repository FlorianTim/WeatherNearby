# UX: Views, search and navigation

## Primary user flow

```text
Splash (LumbreCode -> App)
      │  startup coordinator
      ▼
Heute                          ← the landing screen, always
      │
      ├── task row tap ──────► Aufgabendetail   (spec 0001)
      ├── checkbox ──────────► completed, lingers, undo available
      ├── add row ───────────► new task in the Inbox
      ├── "Demnächst" ───────► Demnächst
      │
      ├── [Listen] ──────────► Listenübersicht ──► Listendetail
      ├── [Suche]  ──────────► Suche
      └── [Mehr]   ──────────► Einstellungen · Schlagwörter · Papierkorb
                                Archiv · Über · Lizenzen
```

## Navigation shell

```text
┌───────────────────────────────────────────────────┐
│                                                   │
│                  (view content)                   │
│                                                   │
├───────────────────────────────────────────────────┤
│   Heute      Listen      Suche      Mehr          │
└───────────────────────────────────────────────────┘
```

Four destinations, no more. Alle and Erledigt are reached from Heute's
overflow rather than occupying a fifth tab — a five-tab bar on a phone means
none of them gets a readable label at 200 % text scale.

Each destination keeps its own navigation state while the app runs
(VSN-407), so switching to Suche and back does not lose a scroll position.

## Screens

### Heute — the default landing screen

```text
Heute                                          ⋮
─────────────────────────────────────────────────
  Überfällig                                   2
    [ ] Rechnung bezahlen        fällig gestern
    [ ] Rückruf Werkstatt        fällig 21. Aug
  Heute                                        3
    [ ] Milch kaufen
    [ ] Schokokuchen backen           10:00   !
          in: Geburtstag Mia
    [ ] Blumen gießen                   ↻
  Ohne Datum                                   7  ⌄
─────────────────────────────────────────────────
  + Aufgabe hinzufügen
```

- Sections in a fixed order: Überfällig, Heute, Ohne Datum.
- "Ohne Datum" is collapsible and its state persists (VSN-006).
- A subtask shown here names its parent ("in: …"), because a flat row without
  that context is a task the user cannot place.
- The overflow (⋮) holds Alle, Erledigt, and the sort/group control.
- The add row creates in the Inbox and stays open for the next entry.

### Demnächst

Grouped by day, each header a weekday plus a date ("Mittwoch, 27. August"),
formatted through `intl` for the active locale — never a hand-built string.
Seven days, then nothing: an eighth-day section would make the window look
arbitrary rather than deliberate.

### Listenübersicht

```text
Listen                                         +
─────────────────────────────────────────────────
  📥  Eingang                                   4
  🛒  Einkauf                                  12
  🎂  Geburtstag Mia - 14.03.2027               6
          importiert aus WasThereSomething
─────────────────────────────────────────────────
```

- Inbox pinned first, outside the reorderable range (spec 0001, TLD-509).
- Counts are **open** tasks, and the count is part of the row's semantic
  label ("Einkauf, 12 offene Aufgaben"), not a bare number.
- An imported list shows its provenance as a subtitle. Provenance is
  displayed, never acted on.
- Long-press or overflow: umbenennen, Farbe, archivieren, löschen, teilen.

### Suche

```text
Suche
─────────────────────────────────────────────────
  🔍 milch                                    ✕
  [Liste: Einkauf ✕]  [Schlagwort: dringend ✕]
─────────────────────────────────────────────────
  Milch kaufen                          Einkauf
  Nachtisch planen                      Einkauf
      … Milchreis mit Zimt …
```

- Results update as you type, debounced; the field never blocks (VSN-305).
- A notes match shows an excerpt around the hit so the user can see why it
  matched (VSN-302).
- Completed matches appear struck through and marked.
- An empty query shows the filter chips and recent searches — not the whole
  database (VSN-306).
- **Recent searches live in memory only.** They are gone on restart, and that
  is deliberate: search terms are personal free text (VSN-307).

### Mehr

A hub, not a screen with its own content (VSN-409): Einstellungen,
Schlagwörter, Papierkorb, Archiv, Über, Lizenzen.

## Empty states

| Where | What the user sees |
|---|---|
| Heute, nothing due, tasks elsewhere | "Nichts für heute." + "12 Aufgaben ohne Datum" as a tappable line |
| Heute, database empty | "Nichts zu tun." + the add row, focused |
| Demnächst | "In den nächsten 7 Tagen ist nichts fällig." |
| Alle | "Keine offenen Aufgaben." |
| Erledigt | "Noch nichts erledigt." |
| Listenübersicht (only Inbox) | The Inbox row + "Liste erstellen" |
| Suche, no query | Filter chips + recent searches |
| Suche, no results | "Keine Treffer für „milch"." + a hint that completed tasks are included and trashed ones are not |

VSN-502 is the one that matters: an empty Heute while twelve tasks exist
elsewhere must say so, or the user concludes the app lost their data.

## Error states

| Situation | What happens |
|---|---|
| A view query fails | Reason code + retry, the error recorded in the last-error buffer, no stack trace (VSN-504) |
| A deep link points at a deleted task | "Diese Aufgabe gibt es nicht mehr." + a way back to Heute (VSN-408) |
| Search query fails | The field stays usable; an inline message replaces the result list |
| Data is loading on a populated surface | Previous content stays; **no** full-screen spinner; the add row stays usable (VSN-503) |

## Loading and progress

A surface that has shown content before never blanks. First load of a cold
surface may show a lightweight placeholder; a re-query never does. This is
the difference between an app that feels stable and one that flickers on
every write.

## Accessibility considerations

Against `docs/architecture/contracts/07-accessibility.md`:

- **Rule 2 / 4** — bottom navigation destinations, the sort/group control and
  the collapse chevron all carry localized labels and tooltips.
- **Rule 3** — a task row is one merged semantic node. In a flat view it
  includes the parent context: "Schokolade kaufen, Teilaufgabe von
  Schokokuchen backen, offen, fällig heute".
- **Rule 5** — Heute, a list detail and search are tested at
  `TextScaler.linear(2.0)` on a phone-sized surface. Four tabs stay legible
  where five would not.
- **Rule 9** — overdue is marked with an icon and the word "überfällig", never
  with red alone.
- **Rule 11** — group headers are announced as sentences with their counts
  ("Überfällig, 2 Aufgaben"), from ARB placeholders, unit-tested on the label
  mapper.

Sort, group and collapse are all reachable without a gesture, so nothing in
this spec depends on a swipe.

## Localization

German and English throughout, including weekday and date formatting via
`intl` for the active locale. Dates in group headers, in row subtitles and in
semantic labels all come from one formatter, so "fällig gestern" and "fällig
21. Aug" cannot drift apart between the visual and the spoken form.
