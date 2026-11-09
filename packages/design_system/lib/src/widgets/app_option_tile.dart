import 'package:flutter/material.dart';

import '../tokens/app_spacing.dart';

/// A selectable card for a set of mutually exclusive options.
///
/// The shape every LumbreCode "pick one" setting uses: language, appearance,
/// and whatever a derived app adds. It lives here rather than next to the
/// settings page because the app intro shows the same rows, and two copies of
/// an accessibility rule is one copy too many.
///
/// The selected state is carried by the radio icon **and** the container
/// colour — never by colour alone
/// (`docs/architecture/contracts/07-accessibility.md`, rule 9).
class AppOptionTile extends StatelessWidget {
  const AppOptionTile({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.trailing,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  /// Short visual shorthand shown at the end of the row, such as a language
  /// code. Excluded from semantics — see [build].
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Card(
        color: isSelected
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surface,
        child: ListTile(
          leading: Icon(
            isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
            color: isSelected ? theme.colorScheme.primary : null,
          ),
          title: Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          // Excluded from semantics on purpose: the trailing text is visual
          // shorthand for the label next to it. ListTile merges title and
          // trailing into ONE node, so without this a screen reader announces
          // "Deutsch DE" — the same information twice
          // (docs/architecture/contracts/07-accessibility.md, rule 3).
          trailing: trailing == null
              ? null
              : ExcludeSemantics(
                  child: Text(trailing!, style: theme.textTheme.bodySmall),
                ),
          selected: isSelected,
          onTap: onTap,
        ),
      ),
    );
  }
}
