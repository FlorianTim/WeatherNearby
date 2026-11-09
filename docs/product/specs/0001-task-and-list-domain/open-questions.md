# Open questions: Task and list domain

Answered questions are kept and marked, with the answer folded into the
relevant spec file.

## Product

- **Q-01 (carried, app-wide) — the product name.** `todo` /
  `de.lumbre.code.todo` is a deliberate placeholder, used consistently so it
  can be replaced in one find-and-replace pass. A real name is a
  product-owner decision and low urgency: publishing is undecided (ADR-0011)
  and the template does not care what its reference app is called.
  **Status: open, deliberately.**

- **Q-1a — does deleting a list take its tasks, or move them to the Inbox?**
  **Answered 2026-08-25: it takes them** (TLD-506). Moving five tasks to the
  Inbox silently is a bigger surprise than deleting them with a counted
  confirmation and an undoable trash. The confirmation names the count so the
  decision is informed.

- **Q-1b — should completing a parent complete its subtasks?**
  **Answered 2026-08-25: no** (TLD-209). Any rollup is a product decision with
  its own edge cases (what does un-completing do?), and every app in the
  category that does it also offers a way to turn it off. Deferred, not
  rejected.

- **Q-1c — trash retention.** 30 days, as a documented constant (TLD-904).
  Open only in the sense that nobody has argued for a different number; it is
  one constant to change.

## UX

- **Q-1d — should the detail open with the notes editor expanded?** Proposal:
  no, a preview until tapped, so the detail does not open as editor chrome.
  Revisit after the first real use.

- **Q-1e — which swipe direction completes and which deletes?** Proposal:
  right completes, left deletes, matching the category convention. Both have
  menu equivalents regardless, so the cost of being wrong is low.

- **Q-1f — is a fourth priority level ("keine") a level or the absence of
  one?** Stored as `0` either way (TLD-701). The UI presents it as a choice
  called "keine". No further decision needed unless sorting by priority
  should place undefined first or last — see spec 0002.

## Technical

- **Q-1g — where do the epoch-day and minute-of-day converters live?**
  **Answered 2026-08-25: `core/domain/time/` in the app, extracted in slice 0**
  (shared-foundations plan). They are template surface: any app with dates
  needs them, and the database contract's rule 6 is currently marked partial
  precisely because they do not exist yet. Promoting them to a package can
  happen when a second app wants them.

- **Q-1h — does `recurrence_mode` travel?** Only as the vendor extension
  `lumbrecode.de:recurrenceMode`, and only if it is ever needed. It changes
  nothing about the standard rule. Decision deferred to spec 0003 and to the
  contract owner; the column exists either way.

- **Q-1i — should `tags` reuse a normalized generated column or a trigger for
  case-insensitive uniqueness?** Proposal: a generated lowercase column plus a
  unique index, because it is declarative and survives a bulk import. Confirm
  against the Drift version in the tree during slice 2.

## Architecture

- **Q-1j — does the repository return domain models or Drift rows?** Domain
  models, per ADR-0009: DAOs encapsulate access, mappers convert, and the
  domain layer knows no Drift. Recorded here because the composed-stream rule
  (KI-003) makes the mapping boundary less obvious than usual — the *query*
  must join everything the emitted object depends on, even though the
  *mapper* is what assembles it.

- **Q-1k — one repository or one per aggregate?** Proposal: `TaskRepository`
  and `ListRepository`, with tag assignment on `TaskRepository` because it is
  always a property of a task. `TagRepository` owns tag definitions only.

## Privacy / Security

- **Q-1l — does the app need a "clear all content" action?** The template
  already has `wipeAllData()`. Proposal: expose it in settings, labelled as
  "Alle Inhalte löschen" rather than "Zurücksetzen", since it does not clear
  the settings store. Follow the doc comment on the existing method.
  **Status: open.**

## Testing

- **Q-1m — how are 200 % text-scale tests kept from becoming a maintenance
  tax?** Proposal: three tests only (row, detail, list overview), matching the
  contract's stated minimum scope, rather than one per screen.

## Release

- **Q-1n — does slice 2 ship behind a flag?** Proposal: no. Slices 2 to 12
  build beside the demo without being routed into the app's main navigation
  until slice 3 has something to show. `packages/feature_flags` exists but
  adding a flag for scaffolding would be ceremony.
