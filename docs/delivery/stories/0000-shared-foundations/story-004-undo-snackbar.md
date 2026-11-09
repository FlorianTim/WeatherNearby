# Story: Undo snackbar helper in `packages/design_system`

## Metadata

- **Status:** ready
- **Feature:** none — template surface. Plan:
  `docs/delivery/implementation-plans/0000-shared-foundations.md`, component 5
- **Target release:** 3.1.0 (`now`)

## Goal

One shared way to say "done — undo?", so every LumbreCode app handles risky
quick actions identically.

## Context

"Nothing the user created vanishes on one tap" is a cross-app product rule,
not a task feature. The reference app needs it for complete, delete, move and
archive (spec 0001, TLD-901), and the completed-task linger in spec 0002
(VSN-201) is timed against it.

The parts that always get subtly wrong are always the same: dismissing a
previous snackbar before showing a new one, firing `onUndo` twice on a double
tap, surviving a rebuild, and keeping the action reachable for a screen
reader. Solving them once is the whole point.

## Scope

- `packages/design_system/lib/src/widgets/undo_snack_bar.dart` —
  `showUndoSnackBar(...)`.
- Export from `packages/design_system/lib/design_system.dart`.
- Tests under `packages/design_system/test/`.

## Out of scope

- Any caller. Spec 0001's slice 3 is the first.
- A queue of pending undos. One at a time; a new call replaces the previous.
- Persisting an undo across a restart. In-memory, for the snackbar's lifetime
  only.
- Localization. The caller passes already-localized strings — see below.

## Relevant files

- `packages/design_system/lib/design_system.dart` — the export barrel
- `packages/design_system/lib/src/tokens/app_spacing.dart` — spacing tokens
- `docs/architecture/contracts/07-accessibility.md` rules 2 and 4

## Two things found during implementation

Both were invisible from the outside and are now guarded by tests.

1. **`SnackBar.persist` defaults to `action != null`.** In the resolved
   Flutter version, *every* snackbar carrying an action — that is, every undo
   snackbar — never dismisses itself. The specified 5-second window would
   simply not have happened.

   The helper therefore passes `persist: false` **explicitly**: the trash is
   the real safety net (a lapsed window costs taps, not data), and a snackbar
   that waits indefinitely covers the navigation bar after every completion.
   `persist: true` remains available for callers where the action really is
   the only way back. Explicit, so a Flutter upgrade cannot silently change
   undo behaviour across every app at once.

2. **Material's row overflows at large text scales.** Message and action sit
   in a row; at 2.0 on a 360 dp surface the action no longer fits — measured
   at 17 px. Above `kUndoSnackBarStackThreshold` (1.5) the action renders
   below the message instead, which keeps accessibility rule 5 without
   capping anybody's text size.

## Acceptance criteria

- [ ] `showUndoSnackBar` shows a snackbar with the message and an action
      labelled with `undoLabel`.
- [ ] `persist` is passed explicitly and defaults to `false`, so the timed
      window actually applies.
- [ ] `persist: true` holds the snackbar until the user acts.
- [ ] No overflow at `TextScaler.linear(2.0)` on a phone-sized surface; the
      action stacks below the message above the threshold.
- [ ] Tapping the action runs `onUndo` **exactly once**, even when tapped
      twice rapidly.
- [ ] Letting it time out does not run `onUndo`.
- [ ] A second call while one is visible replaces the first; the first
      snackbar's `onUndo` does **not** fire as a side effect.
- [ ] The default duration is 5 seconds, and it is overridable.
- [ ] The action carries a semantic label and meets the 48 dp minimum.
- [ ] `packages/design_system` gains **no** dependency on the app's
      `AppLocalizations`, and a test asserts it.
- [ ] `packages/design_system` gains no new package dependency at all.

## Test requirements

- `packages/design_system/test/undo_snack_bar_test.dart`:
  - shows, and dismisses after the duration
  - `onUndo` fires once on a single tap and once on a rapid double tap
  - timing out does not fire `onUndo`
  - a second call replaces the first without firing the first's callback
  - the action is findable by semantic label and is at least 48 dp
- A package-hygiene test asserting no `flutter_gen`/app-l10n import in
  `packages/design_system/lib/`.
- Commands: `melos run test:flutter`, `flutter analyze`,
  `scripts/dev/quality_gate.sh`.

## Documentation requirements

- Doc comment stating that strings arrive **already localized**, and why:
  `design_system` must not depend on any one app's l10n or it stops being
  reusable.
- Note that the 5-second default deliberately matches the completed-task
  linger window (spec 0002, VSN-201) so the two agree.

## Implementation notes

- Signature:

  ```dart
  Future<void> showUndoSnackBar(
    BuildContext context, {
    required String message,
    required String undoLabel,
    required Future<void> Function() onUndo,
    Duration duration = const Duration(seconds: 5),
  });
  ```

- Guard `onUndo` with a `bool` captured in the closure — `SnackBarAction`
  can fire more than once before the snackbar closes.
- `ScaffoldMessenger.of(context).hideCurrentSnackBar()` before showing, so a
  rapid sequence does not queue up.
- **KI-005:** these tests must pump deliberately. `pumpAndSettle` on a surface
  with a live 5-second snackbar either hangs or hides the behaviour, and a
  test that leaves the timer pending fails flutter_test's invariant.

## Review checklist

- [ ] Scope maintained — no caller wired
- [ ] Acceptance criteria fulfilled
- [ ] Tests present and passing
- [ ] No new dependency; no app-l10n import
- [ ] `features/todos/` untouched
