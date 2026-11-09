import 'package:flutter/material.dart';

import '../tokens/app_spacing.dart';

/// A titled group of rows on a settings surface.
///
/// Renders **nothing** when [children] is empty — including its heading. A
/// section whose rows are all unavailable (a debug-only entry in a release
/// build, a permission the app does not hold) must not leave a heading
/// hanging over empty space.
class AppSettingsSection extends StatelessWidget {
  const AppSettingsSection({
    super.key,
    required this.title,
    required this.children,
  });

  /// Section heading. Shown above the card.
  final String title;

  /// The rows. An empty list makes the whole section disappear.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(
              title,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Card(
            margin: EdgeInsets.zero,
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

/// One row inside an [AppSettingsSection].
///
/// Two jobs, and only two: open something ([showChevron]), or run something
/// ([destructive] when that something cannot be undone). Anything that needs
/// a switch, a slider or a value picker is a different widget — this one
/// stays a row you tap.
class AppSettingsTile extends StatelessWidget {
  const AppSettingsTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.showChevron = false,
    this.destructive = false,
  });

  final IconData icon;
  final String title;

  /// States the row's scope or consequence. On a destructive row this is not
  /// decoration: it is where the blast radius is named, so a user can tell
  /// two similar-looking actions apart *before* tapping.
  final String? subtitle;

  final VoidCallback onTap;

  /// Shows the "opens a page" affordance. Off for rows that act in place.
  final bool showChevron;

  /// Renders icon and title in the error colour. The icon stays, so the
  /// warning never depends on colour alone
  /// (`docs/architecture/contracts/07-accessibility.md`, rule 9).
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = destructive ? theme.colorScheme.error : null;

    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color)),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: showChevron ? const Icon(Icons.chevron_right, size: 18) : null,
      onTap: onTap,
    );
  }
}
