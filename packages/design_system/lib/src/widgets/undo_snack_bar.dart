import 'package:flutter/material.dart';

/// Text scale at and above which the undo action moves below the message.
///
/// Material's `SnackBar` lays the message and the action out in a **row**. At
/// large text scales on a phone-width screen the action's own minimum width
/// no longer fits beside the message, and the row overflows — measured at
/// 17 px with a two-line German message at 2.0 on a 360 dp surface.
///
/// Above this threshold the action is rendered below the message instead.
/// That keeps rule 5 of the accessibility contract (no overflow up to 200 %)
/// without capping anybody's text size, which would defeat the point.
const kUndoSnackBarStackThreshold = 1.5;

/// Shows "done — undo?" the same way in every LumbreCode app.
///
/// **Why a helper rather than a `SnackBar` per call site.** "Nothing the user
/// created vanishes on one tap" is a cross-app product rule, and the parts
/// that get it wrong are always the same five:
///
///  - a previous snackbar is still queued, so the new one appears seconds
///    late and undoes the wrong thing;
///  - [SnackBarAction.onPressed] fires more than once before the snackbar
///    closes, so the undo runs twice;
///  - the action has no semantic label, so a screen-reader user cannot find
///    the only way back;
///  - the row overflows at large text scales (see
///    [kUndoSnackBarStackThreshold]);
///  - the window is a different length on every screen.
///
/// Solving them once is the point.
///
/// **Strings arrive already localized.** This package must not depend on any
/// one app's `AppLocalizations`, or it stops being reusable — so the caller
/// resolves the text and passes it in.
///
/// The 5-second default deliberately matches the window a completed item
/// stays visible before collapsing, so the two agree rather than the undo
/// expiring while the item is still on screen.
///
/// ## The `persist` default, and why this helper overrides Flutter's
///
/// `SnackBar` computes `persist = persist ?? action != null`. So **any**
/// snackbar with an action — every undo snackbar — never dismisses itself; it
/// waits for the user. That default is there for a good reason: somebody who
/// needs longer than five seconds should not lose the chance to act.
///
/// This helper still passes `persist: false` by default, for two reasons
/// specific to how undo is used here:
///
///  - **The snackbar is not the safety net; the trash is.** A deleted item
///    goes to the trash for 30 days, so a window that expires costs the user
///    a few extra taps, never their data.
///  - A snackbar that waits indefinitely sits over the bottom of the list
///    after *every* completion, covering the navigation bar and the next row
///    the user wants to tap.
///
/// Pass `persist: true` where the action genuinely is the only way back.
///
/// It is set **explicitly** rather than left to the framework so that a
/// Flutter upgrade cannot quietly change undo behaviour in every app at once.
Future<void> showUndoSnackBar(
  BuildContext context, {
  required String message,
  required String undoLabel,
  required Future<void> Function() onUndo,
  Duration duration = const Duration(seconds: 5),
  bool persist = false,
}) async {
  final messenger = ScaffoldMessenger.of(context);

  // Without this, a rapid sequence queues: the second snackbar waits for the
  // first to time out, and the user sees an undo for something they did
  // several actions ago.
  messenger.hideCurrentSnackBar();

  // SnackBarAction can fire again before the snackbar finishes closing, and
  // an undo that runs twice is worse than one that never runs.
  var undoTriggered = false;
  void handleUndo() {
    if (undoTriggered) return;
    undoTriggered = true;
    onUndo();
  }

  final stacked =
      MediaQuery.textScalerOf(context).scale(1) >= kUndoSnackBarStackThreshold;

  messenger.showSnackBar(
    SnackBar(
      duration: duration,
      // Explicit: SnackBar would otherwise default this to `action != null`,
      // i.e. true for every undo snackbar. See the doc comment above.
      persist: persist,
      content: stacked
          ? _StackedUndoContent(
              message: message,
              undoLabel: undoLabel,
              onUndo: () {
                handleUndo();
                messenger.hideCurrentSnackBar();
              },
            )
          : Text(message),
      action: stacked
          ? null
          : SnackBarAction(label: undoLabel, onPressed: handleUndo),
    ),
  );
}

/// Message above, action below — the large-text-scale layout.
class _StackedUndoContent extends StatelessWidget {
  const _StackedUndoContent({
    required this.message,
    required this.undoLabel,
    required this.onUndo,
  });

  final String message;
  final String undoLabel;
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(message),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: TextButton(
            onPressed: onUndo,
            style: TextButton.styleFrom(
              // Matches SnackBarAction's colour so the two layouts do not
              // look like different components.
              foregroundColor: Theme.of(context).snackBarTheme.actionTextColor,
            ),
            child: Text(undoLabel),
          ),
        ),
      ],
    );
  }
}
