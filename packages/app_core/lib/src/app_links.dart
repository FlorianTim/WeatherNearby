import 'app_branding.dart';

/// Company-wide support mailboxes.
///
/// The addresses are LumbreCode-wide and identical for every app — apps are
/// told apart by the `[app:<slug>]` subject prefix that [AppLinks.mailto]
/// adds, so incoming mail can be filtered per app.
enum SupportMailbox {
  /// General in-app help; the public support address.
  support('support@lumbrecode.de'),

  /// Improvement suggestions and ideas.
  feedback('feedback@lumbrecode.de'),

  /// Technical bug reports.
  bugs('bugs@lumbrecode.de'),

  /// Data protection questions.
  privacy('privacy@lumbrecode.de'),

  /// Confidential security reports (see `SECURITY.md`).
  security('security@lumbrecode.de'),

  /// General business enquiries.
  contact('contact@lumbrecode.de'),

  /// Legal enquiries.
  legal('legal@lumbrecode.de');

  const SupportMailbox(this.address);

  /// The mail address, e.g. `support@lumbrecode.de`.
  final String address;
}

/// External web links and support mail addresses for one app.
///
/// Every LumbreCode app publishes the same set of pages under
/// `https://lumbrecode.de/apps/<slug>/`, so all links are derived from a
/// single [slug] instead of being listed one by one:
///
/// ```dart
/// const links = AppLinks(slug: 'todo-app');
/// links.privacyPolicy; // https://lumbrecode.de/apps/todo-app/privacy/
/// ```
///
/// [slug] is the **web** slug in kebab-case (`was-there-something`). It is
/// deliberately separate from the package slug used for the Android/iOS
/// application id (`de.lumbre.code.<PROJECT_NAME>`), which may not contain
/// hyphens. Both are declared in `project.env`.
///
/// Open the resulting [Uri]s through the `urlLauncherProvider` seam so widget
/// tests never hit a real platform channel.
class AppLinks {
  const AppLinks({required this.slug})
    : assert(slug != '', 'slug must not be empty');

  /// Web slug of the app, kebab-case — e.g. `was-there-something`.
  final String slug;

  /// Landing page of the app.
  Uri get website => _page(null);

  /// Support / help page.
  Uri get support => _page('support');

  /// Frequently asked questions.
  Uri get faq => _page('faq');

  /// Privacy policy. Store listings link here.
  Uri get privacyPolicy => _page('privacy');

  /// Account / data deletion request page. Required by the app stores.
  Uri get dataDeletion => _page('data-deletion');

  /// Public release notes.
  Uri get changelog => _page('changelog');

  /// Third-party licenses of the bundled dependencies.
  Uri get licenses => _page('licenses');

  /// All web links keyed by a stable identifier — useful for building a
  /// link list in the UI without repeating each getter.
  Map<String, Uri> get all => {
    'website': website,
    'support': support,
    'faq': faq,
    'privacy': privacyPolicy,
    'data-deletion': dataDeletion,
    'changelog': changelog,
    'licenses': licenses,
  };

  /// Prefixes [subject] with `[app:<slug>]` so mail to the shared LumbreCode
  /// mailboxes can be sorted per app.
  String mailSubject(String subject) => '[app:$slug] $subject';

  /// Builds a `mailto:` URI for [mailbox] with an app-tagged subject.
  ///
  /// Spaces are encoded as `%20` rather than `+` — several mail clients show
  /// a literal `+` otherwise.
  Uri mailto(SupportMailbox mailbox, {required String subject, String? body}) {
    final params = {'subject': mailSubject(subject), 'body': ?body};
    return Uri(
      scheme: 'mailto',
      path: mailbox.address,
      query: params.entries
          .map(
            (e) =>
                '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
          )
          .join('&'),
    );
  }

  /// `<appsBaseUrl>/<slug>/` for [page] `null`, else `.../<slug>/<page>/`.
  ///
  /// The trailing slash is part of the canonical URL — without it the site
  /// answers with a redirect.
  Uri _page(String? page) {
    final path = page == null ? '$slug/' : '$slug/$page/';
    return Uri.parse('${AppBranding.appsBaseUrl}/$path');
  }

  @override
  bool operator ==(Object other) => other is AppLinks && other.slug == slug;

  @override
  int get hashCode => slug.hashCode;

  @override
  String toString() => 'AppLinks(slug: $slug)';
}
