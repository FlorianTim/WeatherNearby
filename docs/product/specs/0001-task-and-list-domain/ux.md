# UX: Task and list domain

Navigation and the view screens are spec 0002. This file covers the surfaces
that create, edit and organize a task or a list.

## Primary user flow — capture

```text
any screen showing tasks
      │  [+]  or the inline "Aufgabe hinzufügen" row
      ▼
one-line field, keyboard already up
      │  type a title, press Enter
      ▼
task exists in the current list (Inbox if none)
      │  field stays open for the next one
```

**Add is always one tap and one line.** No mandatory second screen, ever.
Everything else about a task is an edit, not a precondition. Pressing Enter
keeps the field open so three items in a row cost three lines, not three
round trips.

## Primary user flow — the row

```text
[ ] Schokokuchen backen                  14. Mär, 10:00  !
      2 Teilaufgaben · Einkauf
```

- **Tapping the checkbox completes.** It never opens anything.
- **Tapping the row opens the detail.** It never completes anything.
- Swipe right completes, swipe left deletes — and **both have a visible
  equivalent** in the row's overflow menu, because accessibility rule 10 is
  not a later slice.
- Every destructive result shows an undo snackbar through the shared helper.

## Screens

| Screen | Contents |
|---|---|
| **Listendetail** | The tasks of one list; sort/group control; add row; share action |
| **Aufgabendetail** | Title, notes (Markdown), list, start, due, priority, recurrence, reminders, tags, subtasks, links, and a footer with created/updated |
| **Listen** | All lists with open counts; Inbox pinned first; drag to reorder; archive and delete in the overflow |
| **Tags** | Rename, recolour, delete; each with its usage count |
| **Papierkorb** | Deleted tasks and lists; restore; delete permanently; a note that items are removed after 30 days |
| **Archiv** | Archived lists; restore |

## Task detail — order and reasoning

1. **Title** — always focused first on a new task, never on an existing one.
2. **Notes** — the shared `MarkdownEditor`, collapsed to a preview until
   tapped, so the detail does not open as a wall of editor chrome.
3. **List** — a picker showing the Inbox first.
4. **Dates** — `start` and `due` as two clearly separate controls, each with
   its own "mit Uhrzeit" toggle. They are labelled by what they mean
   ("Beginn", "Fällig"), never as a range.
5. **Priority** — four choices; the stored inversion is never shown.
6. **Recurrence** — spec 0003.
7. **Reminders** — spec 0003.
8. **Tags** — chips, add by typing, existing tags offered as you type.
9. **Subtasks** — an inline checklist with its own one-line add row.
10. **Links** — `href` plus optional title; a scheme that cannot be opened is
    shown greyed with a tooltip explaining why.
11. **Progress** — the five-value picker, placed below the fold. The checkbox
    covers the two everyday values; this exists so the vocabulary is not
    decorative.
12. **Footer** — created and updated. Never the uid.

## Empty states

| Where | What the user sees |
|---|---|
| Inbox, no tasks | "Nichts zu tun." plus the add row, already focused |
| A user list, no tasks | The list name, an illustration-free line, and the add row |
| Listen, only the Inbox | The Inbox with its count, and "Liste erstellen" |
| Papierkorb | "Der Papierkorb ist leer." plus the 30-day note |
| Tags, none yet | "Noch keine Schlagwörter." plus how they are created (from a task) |
| Archiv | "Kein Archiv." |

An empty state never shows a spinner-shaped placeholder. If data is loading,
the previous content stays and the add row stays usable.

## Error states

| Situation | What happens |
|---|---|
| Title empty or whitespace | Save disabled, with a hint under the field. Not a dialog. |
| Body over 20 000 characters | Save refused with a readable message and a character count. **Nothing is truncated.** |
| `start` after `due` | The offending field is marked and the save is refused, naming which two values conflict |
| Nesting deeper than two levels | The drop is refused where it happened, with "Teilaufgaben können keine weiteren Teilaufgaben haben" |
| A cycle would be created | Same treatment; the tree is never left inconsistent |
| Database write fails | A snackbar with a reason code, the previous state restored, and the error recorded in the last-error buffer — never a stack trace |
| A link with a scheme the app will not open | Shown, not launched, with a tooltip saying so |

No raw exception and no stack trace ever reaches the user.

## Destructive actions

| Action | Guard |
|---|---|
| Complete a task | Undo snackbar |
| Delete a task (no subtasks) | Undo snackbar, then trash |
| Delete a parent task | Confirmation naming the subtask count, then trash |
| Delete a list | Confirmation naming the task count, then trash — the tasks go with it, not silently to the Inbox |
| Archive a list | Undo snackbar |
| Permanent delete from the trash | Confirmation, and it says the word "endgültig" |
| Delete a tag | Confirmation naming how many tasks carry it |

The rule behind the table: **nothing the user created vanishes on one tap**,
and every confirmation states the *size* of what is about to happen, not just
its name.

## Accessibility considerations

Against `docs/architecture/contracts/07-accessibility.md`:

- **Rule 1** — checkbox, add button and every row action are at least
  48 × 48 dp, asserted in a widget test.
- **Rule 2** — every icon-only control (add, overflow, priority, tag remove)
  carries a localized semantic label.
- **Rule 3** — a task row is one merged semantic node: "Schokokuchen backen,
  offen, fällig 14. März 10 Uhr, hohe Priorität, 2 Teilaufgaben". Not five
  fragments; the date is not read as a bare number.
- **Rule 5** — the row, the detail and the list overview are tested at
  `TextScaler.linear(2.0)` on a phone-sized surface. Overflow throws in the
  test build, which is the assertion.
- **Rule 9** — priority and progress always carry an icon or text beside
  their colour; a list's colour token is never its only identifier.
- **Rule 10** — **every swipe action has a menu equivalent.** This is the
  template's first real swipe surface, so this is the first time the rule is
  non-trivially satisfied.
- **Rule 11** — counts are announced as sentences ("3 offene Aufgaben"), from
  ARB placeholders, unit-tested on the label mapper.

## Localization

German and English for every user-visible string, including confirmations,
error messages, empty states and semantic labels. `app_de.arb` remains the
template ARB. Widget tests use `wrapWithL10n`, which defaults to `de` — a test
without an explicit locale would otherwise resolve to `en` (KI-005).
