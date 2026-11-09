import 'package:app_core/app_core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../../app/app_identity.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/permissions/permission_gateway.dart';

/// One permission, as the privacy page renders it.
///
/// The page does **not** query permissions itself. It renders what it is
/// given, so it needs no gateway, no plugin and no platform channel — which
/// is what lets it be a template page rather than an app-specific one
/// (spec 0005, data contract).
class PermissionOverviewEntry {
  const PermissionOverviewEntry({
    required this.icon,
    required this.label,
    required this.state,
  });

  final IconData icon;

  /// Already localized by the caller — the app knows which permissions it
  /// declares, this page does not.
  final String label;

  final PermissionState state;
}

/// Privacy and data: what is stored, which permissions are held, the
/// published documents, and the two ways to take it all back.
///
/// This page exists because the template's most reassuring property — that
/// everything stays on the device — was, until 3.2.1, stated nowhere in the
/// app. It is also the store-review answer to "where can a user delete their
/// data from inside the app?".
///
/// It owns **both** destructive actions, and they are deliberately separate:
/// one clears content and keeps settings, the other clears settings and
/// keeps content. A shared dialog is how a user ends up deleting the wrong
/// thing.
class PrivacyPage extends StatelessWidget {
  const PrivacyPage({
    super.key,
    required this.onOpenUrl,
    required this.onContactPrivacy,
    required this.onDeleteAllData,
    required this.onResetSettings,
    this.permissions = const [],
  });

  /// Opens a published document. Routed through the launcher seam by the
  /// caller, so this page never touches `url_launcher`.
  final ValueChanged<Uri> onOpenUrl;

  final VoidCallback onContactPrivacy;

  /// Clears the content database. Only called after the user confirmed.
  final Future<void> Function() onDeleteAllData;

  /// Clears every registered setting. Only called after the user confirmed.
  final Future<void> Function() onResetSettings;

  /// Empty in the template: it declares no runtime permission yet. An empty
  /// list removes the whole section, heading included (SET-032).
  final List<PermissionOverviewEntry> permissions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final links = AppIdentity.links;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.privacyTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.storage_outlined,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          l10n.privacyLocalTitle,
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(l10n.privacyLocalBody),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          AppSettingsSection(
            title: l10n.privacyPermissionsSection,
            children: [
              for (final permission in permissions)
                ListTile(
                  leading: Icon(permission.icon),
                  title: Text(permission.label),
                  trailing: Text(_permissionLabel(l10n, permission.state)),
                ),
            ],
          ),

          AppSettingsSection(
            title: l10n.privacyDocumentsSection,
            children: [
              AppSettingsTile(
                icon: Icons.privacy_tip_outlined,
                title: l10n.aboutPrivacy,
                onTap: () => onOpenUrl(links.privacyPolicy),
              ),
              AppSettingsTile(
                icon: Icons.delete_sweep_outlined,
                title: l10n.aboutDataDeletion,
                onTap: () => onOpenUrl(links.dataDeletion),
              ),
              AppSettingsTile(
                icon: Icons.alternate_email_outlined,
                title: l10n.privacyContact,
                subtitle: SupportMailbox.privacy.address,
                onTap: onContactPrivacy,
              ),
            ],
          ),

          Text(
            l10n.privacyDangerSection,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.error,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                AppSettingsTile(
                  icon: Icons.delete_outline,
                  title: l10n.settingsDeleteData,
                  // The subtitle states the exact scope. "Delete all data"
                  // would be a promise this action does not keep: the
                  // settings store is not touched.
                  subtitle: l10n.settingsDeleteDataHint,
                  destructive: true,
                  onTap: () => _confirm(
                    context,
                    title: l10n.settingsDeleteDataConfirmTitle,
                    body: l10n.settingsDeleteDataConfirmBody,
                    confirmLabel: l10n.commonDelete,
                    action: onDeleteAllData,
                    done: l10n.settingsDeleteDataDone,
                  ),
                ),
                AppSettingsTile(
                  icon: Icons.settings_backup_restore_outlined,
                  title: l10n.settingsResetSettings,
                  subtitle: l10n.settingsResetSettingsHint,
                  destructive: true,
                  onTap: () => _confirm(
                    context,
                    title: l10n.settingsResetSettingsConfirmTitle,
                    body: l10n.settingsResetSettingsConfirmBody,
                    confirmLabel: l10n.commonReset,
                    action: onResetSettings,
                    done: l10n.settingsResetSettingsDone,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Destructive actions always confirm, and the dialog names the
  /// consequence instead of asking "are you sure?".
  ///
  /// One helper, two callers, but never one shared dialog **text**: each
  /// action brings its own title, body and confirmation, because the two
  /// differ in exactly the way a user needs to notice.
  static Future<void> _confirm(
    BuildContext context, {
    required String title,
    required String body,
    required String confirmLabel,
    required Future<void> Function() action,
    required String done,
  }) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await action();
    messenger.showSnackBar(SnackBar(content: Text(done)));
  }

  static String _permissionLabel(
    AppLocalizations l10n,
    PermissionState state,
  ) => switch (state) {
    PermissionState.granted => l10n.privacyPermissionGranted,
    PermissionState.denied => l10n.privacyPermissionDenied,
    PermissionState.permanentlyDenied =>
      l10n.privacyPermissionPermanentlyDenied,
    PermissionState.notRequested => l10n.privacyPermissionNotRequested,
  };
}
