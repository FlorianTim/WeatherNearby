import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';

/// The per-permission wording an app supplies.
///
/// Deliberately passed in rather than looked up here: the template cannot
/// know what an app needs a permission *for*, and a generic "This app needs
/// access to your contacts" is exactly the sentence users decline. Only the
/// buttons are generic enough to live in the template's own ARB files.
class PermissionCopy {
  const PermissionCopy({
    required this.title,
    required this.rationale,
    required this.icon,
    required this.blockedHint,
  });

  /// Short headline, e.g. "Access to your calendar".
  final String title;

  /// Why the app needs it and **what happens if the user says no**. Naming
  /// the limitation is what turns a demand into an explanation.
  final String rationale;

  final IconData icon;

  /// Shown once the permission is permanently denied: names what stays
  /// unavailable and points at the system settings.
  final String blockedHint;
}

/// In-app rationale shown **before** the system dialog.
///
/// Returns `true` when the user wants to continue to the system dialog.
/// Declining must stay free of consequences — the caller keeps the app
/// usable either way.
Future<bool> showPermissionRationale(
  BuildContext context,
  PermissionCopy copy,
) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => _RationaleSheet(copy: copy),
  );
  return result ?? false;
}

/// Shown when the system will not ask again: explains the consequence and
/// offers the only route that can still change it.
///
/// Returns `true` when the user wants to open the system settings.
Future<bool> showPermissionBlocked(
  BuildContext context,
  PermissionCopy copy,
) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => _RationaleSheet(copy: copy, blocked: true),
  );
  return result ?? false;
}

class _RationaleSheet extends StatelessWidget {
  const _RationaleSheet({required this.copy, this.blocked = false});

  final PermissionCopy copy;
  final bool blocked;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(copy.icon, size: 48, color: theme.colorScheme.primary),
            const SizedBox(height: AppSpacing.md),
            Text(
              copy.title,
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              blocked ? copy.blockedHint : copy.rationale,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                blocked ? l10n.permissionOpenSettings : l10n.permissionAllow,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.permissionNotNow),
            ),
          ],
        ),
      ),
    );
  }
}
