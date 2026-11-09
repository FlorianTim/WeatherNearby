import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/platform/platform_seams.dart';

/// The help documents this app bundles.
///
/// Adding one is an asset plus an enum value plus a title — deliberately no
/// registry, because a help document that nothing links to is a document
/// nobody reads.
enum HelpDocument {
  manual('manual'),
  faq('faq');

  const HelpDocument(this.assetBaseName);

  /// Base name of the asset: `assets/help/<base>_<language>.md`.
  final String assetBaseName;
}

/// Renders a bundled, localized help document.
///
/// **Offline by construction.** The document is an app asset, so it works on
/// a plane, before the website exists, and for a store reviewer who does not
/// want to leave the app. The About page's link to the hosted FAQ stays as
/// the online counterpart — one can be corrected without a release, the
/// other cannot go missing.
///
/// The asset variant follows the **rendered** locale, not the stored
/// setting: the stored value may be `null` ("follow the system"), and a
/// manual in a different language than the surrounding UI is a bug that is
/// hard to notice and embarrassing to ship.
class HelpDocumentPage extends ConsumerWidget {
  const HelpDocumentPage({super.key, required this.document});

  final HelpDocument document;

  /// Languages that have their own asset variant. Everything else falls back
  /// to English rather than failing (spec 0005, SET-022).
  static const _variants = {'de', 'en'};

  static String assetPathFor(HelpDocument document, String languageCode) {
    final language = _variants.contains(languageCode) ? languageCode : 'en';
    return 'assets/help/${document.assetBaseName}_$language.md';
  }

  String _title(AppLocalizations l10n) => switch (document) {
    HelpDocument.manual => l10n.helpManualTitle,
    HelpDocument.faq => l10n.helpFaqTitle,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final path = assetPathFor(
      document,
      Localizations.localeOf(context).languageCode,
    );

    return Scaffold(
      appBar: AppBar(title: Text(_title(l10n))),
      body: FutureBuilder<String>(
        future: DefaultAssetBundle.of(context).loadString(path),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text(l10n.helpLoadError));
          }

          final source = snapshot.data;
          if (source == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: AppMarkdownView(
              source: source,
              selectable: true,
              onLinkTap: (uri) => _openLink(context, ref, uri),
            ),
          );
        },
      ),
    );
  }

  /// Opens a link found inside a help document.
  ///
  /// [UrlPolicy.webOnly], not `appAuthored`, although the document ships with
  /// the app: a help text is prose, and prose gets edited by translators and
  /// by whoever writes the next release's manual. Only `http`/`https` may
  /// escape it — a `mailto:` or a custom scheme in a document is a mistake,
  /// and this is where that mistake stops.
  Future<void> _openLink(BuildContext context, WidgetRef ref, Uri uri) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);

    final outcome = await ref.read(urlLauncherProvider)(uri);

    final message = switch (outcome) {
      LaunchOutcome.launched => null,
      LaunchOutcome.failed => l10n.aboutOpenFailed,
      LaunchOutcome.schemeNotAllowed => l10n.linkSchemeNotSupported,
    };

    if (message != null) {
      messenger.showSnackBar(SnackBar(content: Text(message)));
    }
  }
}
