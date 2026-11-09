import 'package:flutter/widgets.dart';

import 'permission_gateway.dart';
import 'permission_rationale_sheet.dart';

/// Runs the full just-in-time permission sequence and returns the outcome.
///
/// ```
/// Feature action
///    ↓ status()            ← the system, not a cache
/// granted? ─── yes ──→ done, no dialog, no interruption
///    ↓ no
/// permanentlyDenied? ─ yes ─→ blocked sheet → system settings
///    ↓ no
/// in-app rationale ── declined ──→ done, app stays usable
///    ↓ accepted
/// request()  →  granted | denied | permanentlyDenied
/// ```
///
/// This function exists because the order above is the part apps get wrong,
/// and getting it wrong is invisible until a user is stuck: asking without a
/// rationale, asking again when the system will no longer show a dialog, or
/// asking on screen entry instead of on the action that needs it.
///
/// Call it from the **feature action** — never from a screen's `initState`
/// and never during startup
/// (`docs/architecture/contracts/04-permissions.md`, rule 1 and 3).
///
/// The caller decides what a non-granted result means. It must not be
/// treated as a failure: the app stays usable and names what is limited.
Future<PermissionState> ensurePermission({
  required BuildContext context,
  required PermissionGateway gateway,
  required PermissionCopy copy,
}) async {
  final current = await gateway.status();
  if (current.isGranted) return current;

  if (!context.mounted) return current;

  if (current == PermissionState.permanentlyDenied) {
    // Showing a rationale here would be a lie: the system dialog will not
    // appear, so "Allow" could not do anything.
    final openSettings = await showPermissionBlocked(context, copy);
    if (openSettings) await gateway.openAppSettings();

    // The user may or may not have changed it over there; re-read instead of
    // assuming either way.
    return gateway.status();
  }

  final proceed = await showPermissionRationale(context, copy);
  if (!proceed) return current;

  return gateway.request();
}
