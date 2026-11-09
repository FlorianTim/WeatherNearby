import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/storage/key_value_store.dart';

/// Debug-only view over the settings register.
///
/// This is what `AppSettings.all` was made enumerable for: "which settings
/// exist, and what is actually stored?" is answerable without grepping. A
/// hand-written list next to each notifier could not answer it.
///
/// **Read-only** (spec 0005, SET-052). A writable debug console is a
/// different feature with different risks — a value written here would not
/// go through the notifier that owns it, and the UI would then disagree with
/// storage until the next restart.
///
/// The route that reaches this page does not exist in release builds.
class SettingsDiagnosticsPage extends StatelessWidget {
  const SettingsDiagnosticsPage({super.key, required this.store});

  final KeyValueStore store;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.diagnosticsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(l10n.diagnosticsIntro, style: theme.textTheme.bodySmall),
          const SizedBox(height: AppSpacing.lg),
          for (final setting in AppSettings.all)
            Card(
              child: ListTile(
                title: Text(setting.key, style: theme.textTheme.bodyMedium),
                // Stored value first, because that is the one that explains
                // current behaviour; the default is context for it.
                subtitle: Text(
                  '${store.getString(setting.key) ?? l10n.diagnosticsUnset}\n'
                  '${l10n.diagnosticsDefault(setting.encodedDefault)}',
                ),
                isThreeLine: true,
              ),
            ),
        ],
      ),
    );
  }
}
