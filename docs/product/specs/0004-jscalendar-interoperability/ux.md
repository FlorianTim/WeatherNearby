# UX: JSCalendar interoperability

Two flows, and both are built around the same idea: **a payload is a proposal,
never a command**, and **nothing leaves the device unannounced**.

## Primary user flow — receiving

```text
another app's share sheet
      │  the user picks "LumbreCode To-do"
      ▼
(nothing is written yet)
      ▼
┌─ Importieren ─────────────────────────────────────┐
│  Aus: WasThereSomething 1.5                       │
│                                                   │
│  Neue Liste                                       │
│  [ Geburtstag von Mia - 14.03.2027            ]   │  ← editable
│                                                   │
│  4 Aufgaben                                       │
│    ☐ Schokokuchen backen          14. Mär, 10:00  │
│        ☐ Schokolade kaufen                        │
│        ☑ Sahne kaufen                             │
│    ☐ Pappteller mitbringen                        │
│                                                   │
│  ⚠️  Hinweise (1)                              ⌄  │
│     Eine Wiederholung wird nicht übernommen.      │
│                                                   │
│              [ Abbrechen ]  [ Importieren ]       │
└───────────────────────────────────────────────────┘
      │  Importieren
      ▼
one transaction → new list
      ▼
"4 Aufgaben importiert. 1 Wiederholung konnte nicht
 übernommen werden."
```

Five things this screen does deliberately:

1. **It exists at all, with no way around it** (INT-208). There is no
   auto-import setting, and adding one later needs a new ADR.
2. **It shows the tree**, because a flattened preview of a nested list is not
   a preview of what will be created.
3. **It names the losses before the import**, not only after. A user who does
   not want a list minus its repetition can cancel while cancelling is free.
4. **It shows provenance as a claim.** "Aus: WasThereSomething 1.5" is read
   from `prodId` and is displayed, never trusted, never a behaviour branch
   (INT-406).
5. **It always creates a new list.** Even for a document imported a minute
   ago. There is no "merge with existing" option, because a merge needs
   conflict rules this contract does not define (INT-201).

### The warnings section

Collapsed by default with a count, expanded on tap. Each entry is one
sentence naming the task and what was lost:

```text
⚠️  Hinweise (3)                                    ⌃
   „Blumen gießen": Die Wiederholung (alle 4 Tage,
   4-mal) wird nicht übernommen.
   „Sehr langer Titel …": Der Titel wurde auf 200
   Zeichen gekürzt.
   Ein Eintrag unbekannter Art wurde übersprungen.
```

Never a type name, never a code, never a stack trace. The warning *type* is a
stable enum internally and is localized only here.

### When the document cannot be imported at all

```text
┌─ Nicht importierbar ──────────────────────────────┐
│  Die Datei konnte nicht gelesen werden.           │
│  Sie ist beschädigt oder hat ein anderes Format.  │
│                                                   │
│                                    [ Schließen ]  │
└───────────────────────────────────────────────────┘
```

One sentence naming the category. **No parser message, no stack trace, no
byte offset.** The categories the user may see: beschädigt / falsches Format /
zu groß / leer.

## Primary user flow — sending

```text
Listendetail ⋮  →  "Teilen"
      ▼
┌─ Teilen ──────────────────────────────────────────┐
│  Was geteilt wird                                 │
│    6 Aufgaben, davon 2 Teilaufgaben               │
│    Titel, Notizen, Termine, Prioritäten,          │
│    Schlagwörter und Links                         │
│                                                   │
│  Format                                           │
│    (•) Als Datei teilen                           │
│        Standardformat, jede passende App          │
│    ( ) An LumbreCode-App senden                   │
│        (nur wenn eine Empfänger-App installiert   │
│         ist)                                      │
│                                                   │
│  ℹ️  Eine geteilte Kopie lässt sich nicht          │
│     zurückholen.                                  │
│                                                   │
│              [ Abbrechen ]  [ Teilen ]            │
└───────────────────────────────────────────────────┘
```

- **The preview is unskippable** (INT-507). There is no code path from the
  share action to the seam that bypasses it.
- **It names what travels**, including that notes travel — the field most
  likely to hold something the user forgot was personal.
- **It states the irreversibility plainly** (INT-508) rather than implying a
  guarantee the app cannot make.
- **The plain standard is the default.** The envelope is the special case and
  appears only when a receiver is actually installed (INT-503) — a dead share
  entry is worse than no entry.

## Screens

| Screen | Route | Contents |
|---|---|---|
| **Import-Prüfung** | `/import/review` | Provenance, editable list name, the task tree, the warnings section, cancel/confirm |
| **Import-Fehler** | `/import/error` | One-sentence category, close |
| **Teilen-Vorschau** | modal on the source screen | Scope summary, format choice, irreversibility note, cancel/confirm |
| **Import-Bericht** | snackbar + an expandable summary | What was imported, what was lost |

The import review is a **route, not an anonymous dialog** (INT-309): a process
restart during review must not leave the app in an unreachable state.

## Empty and edge states

| Situation | What the user sees |
|---|---|
| A `Group` with zero entries | Rejected before the review — the schema requires 1..500 |
| A single `Task` document | The review shows a list picker defaulting to the Inbox, not a new-list field (INT-204) |
| A batch of three events | Three reviews, presented one after another, never stacked (INT-307, INT-408) |
| A second payload arrives during review | Queued silently; presented when the first is resolved |
| A list with the same name was imported before | An optional inline note: "Am 25. August hast du eine Liste mit diesem Namen importiert." A note — never automatic behaviour (INT-206) |
| Sharing a list with no tasks | The share action is disabled with a tooltip |
| No receiver app installed | The envelope option is hidden entirely, not shown greyed |

## Error states

| Situation | What happens |
|---|---|
| Malformed JSON | "beschädigt" category screen; nothing written |
| Wrong top-level `@type` | "falsches Format"; nothing written |
| Over 256 KiB | "zu groß"; reading stopped at the cap |
| Envelope with an unknown `type` or missing `dataschema` | "falsches Format" |
| A repository invariant refuses part of the document | The rest imports; a `RejectedTreeViolation` warning names what was flattened |
| The share file cannot be written | "Teilen fehlgeschlagen" with a reason code; the seam is not called |
| Import transaction fails | Nothing is written; a reason code; the review stays open so the user can retry |

No raw exception and no stack trace ever reaches the user (guide §5.5).

## Links inside an imported task

```text
Links
  🔗  Rezept                     example.invalid/rezept
  🚫  vertrag.pdf                nicht zu öffnen (file:)
```

- **Nothing is fetched.** No favicon, no preview, no size check — not even to
  render this row (spec 0001, TLD-706).
- Only `http:` and `https:` open, only on an explicit tap.
- Other schemes are **shown and not launched**, with a tooltip saying why.
- An `enclosure` link says that the file itself was not transferred.

## Accessibility considerations

The import review and the share preview are ordinary screens under
`docs/architecture/contracts/07-accessibility.md`:

- **Rule 3** — a review row is one merged node including its nesting:
  "Schokolade kaufen, Teilaufgabe von Schokokuchen backen, offen".
- **Rule 5** — both screens are tested at `TextScaler.linear(2.0)`. The review
  is a scrolling list by construction, so a long document at large text is the
  normal case rather than an edge case.
- **Rule 9** — the warnings section is marked by an icon **and** the word
  "Hinweise" with a count, never by colour alone.
- **Rule 11** — the summary is a sentence with placeholders ("4 Aufgaben
  importiert, 1 Wiederholung nicht übernommen"), not a pair of numbers.
- Confirm and cancel are ordinary buttons at 48 dp. Nothing here depends on a
  gesture.

## Localization

German and English for every warning, every category message, every review
label and the summary. Warning types are **stable enums**, localized at
display time only — an English string is never stored, logged or persisted
(INT-114). The list name proposed from `Group.title` is taken verbatim from
the document and is **not** translated.
