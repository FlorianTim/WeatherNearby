# Open questions: Reminders and recurrence

Answered questions are kept and marked, with the answer folded into the
relevant spec file.

## Product

- **Q-3a — does the app support `count` and `until` in recurrence?**
  *(This is draft Q-02, carried here as the spec that owns it.)*

  **Decided for 3.1.0: no** (RRC-502). The reasoning, so it can be revisited
  honestly:

  | | Support them | Stay at the contract subset |
  |---|---|---|
  | User value | "jeden Montag, viermal" is a normal request | one fewer thing that works |
  | Interop | a task using them, shared **to** WasThereSomething, imports as non-recurring with a reported loss | every rule this app emits is readable everywhere in the family |
  | Contract | requires a v1.1 of the shared contract, agreed with the owner of `lumbrecode-engineering` and implemented on both sides | nothing to negotiate |

  The draft proposed supporting them, arguing that the tolerance rules exist
  precisely for this and that it beats pretending a to-do app does not need
  them. That argument is good, and it is still the likely eventual answer.
  It is not taken in 3.1.0 for one reason: **this app is the second
  implementation of a contract whose first implementation ships without
  them.** Shipping a wider emitter than the contract defines makes the
  reference app the source of incompatibility in the family it exists to
  validate.

  **The right path is a contract change, not a unilateral extension** — raise
  `count`/`until` with the owner of `lumbrecode-engineering` for contract v1.1,
  implement on both sides, then enable here. The parser is structured so the
  two parts are a rejection rule, not a redesign.

  **Status: open as a contract question, closed for 3.1.0.**

- **Q-3b — how many snooze presets, and which?** 1 Stunde / heute Abend /
  morgen (RRC-401). "heute Abend" needs a definition — proposal: 18:00 local,
  and if it is already past 18:00, tomorrow 18:00. **Status: open**, one
  constant.

- **Q-04 (carried, app-wide) — notification content on the lock screen.**
  **Answered 2026-08-25 as proposed: the title is shown by default**, with a
  setting for a generic form ("1 Aufgabe fällig"). A shared device is the case
  the alternative exists for. Recorded in the OpenSpec privacy block.

- **Q-3c — should completing a recurring instance be undoable to the previous
  instance, or only to "not completed"?** Proposal: undo restores the exact
  previous state including the task's dates, since advancing is one
  transaction. Confirm during slice 7.

## UX

- **Q-3e — should the recurrence preview show three instances or five?**
  Three fits without scrolling at 200 % text scale. Open, cosmetic.

- **Q-3f — where does the "applied when you next open the app" wording go?**
  RRC-408 requires it "where a user could otherwise be misled". Proposal: not
  on the notification itself (no room, and it reads as an apology), but in the
  reminder section's help text and in the manual. **Status: open.**

- **Q-3g — do the seven weekday toggles fit at 200 % text scale on a small
  phone?** They wrap to two rows by design, but this needs one real check —
  it is the tightest target in the app (accessibility rule 1).

## Technical

- **Q-3d — where does the pending-action store live?** Two options: a
  separate small Drift database file, or a plain append-only file (JSON lines)
  read at drain time.

  | | Separate Drift file | Append-only file |
  |---|---|---|
  | Background isolate cost | opens a second Drift connection, but to a *different* file | no database machinery at all |
  | Robustness | transactional | a torn last line must be tolerated on read |
  | Test cost | needs a database in a unit test | trivial |

  Proposal: **the plain file**, because the whole point of ADR-0012 decision 4
  is that the background half does as little as possible. What is **not** open
  is that it must not be the domain database and must not need the domain
  schema. **Status: open — decide in slice 6 and record it.**

- **Q-3h — how is `BOOT_COMPLETED` wired given that `android/` is not
  committed?** The receiver and its permission are a manifest change, so they
  go through the bootstrap patcher exactly like the intent filter (ADR-0013,
  decision 2). Open: whether to extend `_apply_receive_intent_filter` or add a
  second, separately named function. Proposal: separate, because the two are
  independent features and a combined patcher makes each harder to remove.

- **Q-3i — is a 60-day scheduling horizon right?** (RRC-305) It must be
  bounded, because Android caps concurrent alarms and an unbounded schedule
  loses the tail silently. Sixty days is a guess informed by nothing in
  particular. Open: measure how many reminders a realistic database produces
  inside it.

- **Q-3j — does the recurrence expander belong in `task_interchange` (`flutter-libraries`, ADR-0017)
  or in `core/domain/time/`?** **Answered 2026-08-25: `task_interchange`**
  (RRC-504, ADR-0014). The subset *is* an interop contract, so parser,
  encoder and expander are one body of code with one set of tests. Putting the
  expander elsewhere would create a second place where "what does this rule
  mean" is answered.

- **Q-3k — how does `completion` mode interact with `BYDAY`?**
  `data-contract.md` 1.7 states the rule (advance by interval, then snap
  forward to the next matching weekday) and requires it to be documented in
  the editor rather than inferred. Open: whether to instead **disable**
  `completion` mode when the rule carries `BYDAY`/`BYMONTHDAY`, which is
  simpler to explain. **Status: open — worth a product-owner opinion.**

## Architecture

- **Q-3l — is the pending-action queue template surface or app surface?**
  Proposal: `core/notifications/` in the app, because any app with a
  notification action faces the identical isolate boundary — so it is a
  candidate for promotion to a package once a second app wants it. Recorded
  in ADR-0012's follow-ups.

- **Q-3m — does the reconciliation task belong in the startup coordinator or
  behind an app-lifecycle observer?** Both: a `guarded` startup task (never
  blocking — a missing reminder must not stop the app starting) plus a
  re-run on resume after a locale or time-zone change.

## Privacy / Security

- **Q-3n — should `fired_at` exist at all?** It is diagnostics only and never
  drives behaviour (RRC-208), but it is a per-task timestamp of when the user
  was interrupted. Proposal: keep it, exclude it from any diagnostics export,
  and clear it with "Alle Inhalte löschen". **Status: open** — it would also
  be defensible to drop the column.

## Testing

- **Q-3o — how are DST cases tested without a real device clock?**
  `timezone`'s database plus injected components make AC-16 and AC-17 pure
  unit tests. Open: whether to pin a `timezone` database version in the test
  fixture so an IANA update cannot silently change an expected value.

- **Q-3p — can reconciliation be integration-tested at all in CI?** Only
  against the fake gateway. Real delivery, reboot survival and time-zone
  changes are manual test-plan entries, and the plan says so rather than
  pretending coverage exists.

## Release

- **Q-3q — does recurrence ship before or after reminders?** Reminders first
  (slice 6), recurrence second (slice 7). Reminders are the more valuable
  half and the harder boundary; recurrence without reminders is still useful,
  reminders without recurrence more so.
