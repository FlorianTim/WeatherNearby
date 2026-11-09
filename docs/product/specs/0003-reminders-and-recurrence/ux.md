# UX: Reminders and recurrence

## Primary user flow — setting the first reminder

```text
Aufgabendetail
      │  "Erinnerung hinzufügen"
      ▼
  is there a due date with a time?
      │ no ──► "Eine Erinnerung braucht eine Uhrzeit."
      │        [ Uhrzeit festlegen ]  ← opens the due-time picker inline
      │ yes
      ▼
  lead-time picker:  zur Fälligkeit · 10 Min · 1 Std · 1 Tag · 1 Woche · eigene
      │  choose
      ▼
  permission granted?
      │ no ──► in-app rationale sheet (why, what for, what happens if not)
      │           │ declined ──► reminder is SAVED, banner: "wird nicht angezeigt"
      │           │ accepted ──► system dialog
      │           └ permanently denied ──► blocked sheet ──► system settings
      ▼
  reminder saved and scheduled
```

Two things this flow refuses to do:

- **Ask at startup.** The permission is requested at the moment it earns its
  keep, with the rationale already on screen (RRC-101).
- **Treat a refusal as an error.** The reminder is stored either way. The app
  says what is limited and stays fully usable (RRC-103).

## Primary user flow — acting on a notification

```text
🔔  Blumen gießen
    fällig um 10:00
    [ Erledigt ]   [ Später ▾ ]

  Erledigt  ──►  notification disappears immediately
                 the task is completed when the app is next opened

  Später ▾  ──►  1 Stunde · heute Abend · morgen
                 the reminder moves; the DEADLINE does not
```

The second line of "Erledigt" is the honest part. The action is recorded and
applied on the next foreground run (ADR-0012, decision 4). The notification
disappears at once, so nothing feels stuck — but where a user could be misled,
the app says so (RRC-408). For example, opening the app immediately after
tapping "Erledigt" shows the task already completed, because the drain runs
on resume.

**Snooze moves the reminder, never the due date** (RRC-409). Postponing a
nudge is not the same decision as moving a deadline, and conflating them
silently rewrites the user's commitments.

## Screens and controls

### Reminder section (task detail)

```text
Erinnerungen                                        +
─────────────────────────────────────────────────────
  🔔  1 Stunde vorher          → 25. Aug, 09:00    ✕
  🔔  zur Fälligkeit           → 25. Aug, 10:00    ✕

  ⚠️  Erinnerungen sind deaktiviert.   [ Einstellungen ]
```

- Each row shows the **lead time and the resulting moment**, because "1 hour
  before" alone forces the user to do arithmetic.
- A moment in the past is shown greyed with "Zeitpunkt liegt in der
  Vergangenheit" and is not scheduled (RRC-206).
- The warning banner appears only when the permission is missing (RRC-107),
  is dismissible, and routes to the system settings.
- Copy never promises a precise minute — scheduling is inexact by design
  (ADR-0012, decision 3). "gegen 09:00", not "exakt um 09:00".

### Recurrence editor

```text
Wiederholung
─────────────────────────────────────────────────────
  ( ) keine
  (•) täglich        alle [ 3 ] Tage
  ( ) wöchentlich    [Mo] Di [Mi] Do Fr Sa So
  ( ) monatlich      am [ 15. ]  ·  oder: [1.] [Samstag]
  ( ) jährlich

  Nächste Fälligkeit ab
  (•) Fälligkeitsdatum      "der 1. bleibt der 1."
  ( ) Erledigung            "3 Tage nachdem du sie abhakst"

  Vorschau:  28. Aug · 31. Aug · 3. Sep
```

- **The completion-mode choice is worded, not jargon** (RRC-704). Each option
  carries a one-line example, because the difference is invisible until it
  bites — a rent reminder that drifts, or a plant watered on March's schedule.
- **A live preview of the next three instances.** This is the cheapest
  possible defence against a rule that does not mean what the user thought,
  and it is where a skipped 31 February becomes visible rather than
  surprising.
- The preview is presentation only. The rendered German or English string is
  **never** persisted or parsed (RRC-503).

### Recurring task in a list

```text
[ ] Blumen gießen            ↻  25. Aug
```

The `↻` is accompanied by text in the semantic label ("wiederholt sich alle
3 Tage"), never by the icon alone — accessibility rule 9.

## Empty states

| Where | What the user sees |
|---|---|
| Reminder section, none set | "Keine Erinnerung." + "Erinnerung hinzufügen" |
| Reminder section, no due time | "Eine Erinnerung braucht eine Uhrzeit." + a button that sets one |
| Recurrence editor, "keine" | The frequency options, with the preview area empty rather than hidden — so its existence is discoverable |
| Web build | "Erinnerungen können auf dieser Plattform nicht angezeigt werden." The reminder is still stored (RRC-007) |

## Error states

| Situation | What happens |
|---|---|
| Permission denied | Reminder saved; banner naming what is limited; app fully usable |
| Permission permanently denied | Blocked sheet with a route to the system settings; the system dialog is not attempted |
| Reminder moment already passed | Row greyed with a reason; not scheduled |
| Scheduling fails for one reminder | That row shows a retry; the others are unaffected; a reason code, never an exception message (RRC-306) |
| A rule is set on a task with no date | Save refused: "Eine Wiederholung braucht ein Datum." (RRC-507) |
| An imported rule uses `count` or `until` | Task imported **without** recurrence, and the import report names the loss (RRC-502) |
| Drain finds a deleted task | Silently counted as skipped; nothing is shown, because the user already deleted it (RRC-406) |

No raw exception and no stack trace ever reaches the user.

## Destructive actions

| Action | Guard |
|---|---|
| Remove a reminder | Immediate, with undo — it is cheap to recreate |
| Turn off recurrence on a task with completed instances | Confirmation naming how many instance records will be dropped |
| Complete a recurring instance | No confirmation. It advances; an undo restores the previous instance state |
| "Alle Inhalte löschen" | Cancels every scheduled notification, and says so in the confirmation |

## Accessibility considerations

Against `docs/architecture/contracts/07-accessibility.md`:

- **Rule 1** — the weekday toggles in the recurrence editor are the tightest
  targets in the app. Seven of them must still be 48 dp; on a narrow screen
  they wrap to two rows rather than shrink.
- **Rule 2 / 4** — every icon-only control (add reminder, remove reminder,
  the `↻` badge) carries a localized label and tooltip.
- **Rule 3** — a reminder row is one merged node: "Erinnerung 1 Stunde vorher,
  25. August um 9 Uhr".
- **Rule 5** — the reminder section and the recurrence editor are tested at
  `TextScaler.linear(2.0)`. The editor is the densest surface in the app and
  is where overflow will appear first.
- **Rule 9** — `↻` is never the only signal; the repetition is in the text.
- **Rule 11** — the preview reads as sentences ("nächste Fälligkeit am 28.
  August"), from ARB placeholders.

Nothing in this spec depends on a gesture: reminders and recurrence are set
through buttons and pickers only.

## Localization

German and English, including:

- Lead-time labels and the resulting moments, formatted through `intl` for the
  active locale.
- The human-readable rendering of a recurrence rule. One formatter feeds both
  the visible preview and the semantic label, so they cannot drift apart.
- Notification title and body, resolved at **schedule** time from the active
  locale. A language change re-runs reconciliation so already-scheduled
  notifications are re-rendered — otherwise a user who switches to English
  keeps receiving German notifications until each fires.
