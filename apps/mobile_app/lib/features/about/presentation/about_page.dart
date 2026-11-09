import 'package:app_core/app_core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_identity.dart';
import '../../../core/errors/feedback_mail.dart';
import '../../../core/errors/last_error_buffer.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/platform/platform_seams.dart';

/// Mail subjects.
///
/// Deliberately **not** localized: the shared LumbreCode mailboxes are sorted
/// by the `[app:<slug>]` prefix plus this subject, and a per-locale mix would
/// break those filters. Only the UI labels are translated.
abstract final class _MailSubject {
  static const support = 'Support request';
  static const feedback = 'Feedback';
  static const bug = 'Bug report';
  static const privacy = 'Privacy enquiry';
  static const security = 'Security report';
}

/// About & help page: external links and support contacts.
///
/// All URLs are derived from [AppIdentity.links], so a derived app only has
/// to change its slug. Links open through the `urlLauncherProvider` seam,
/// which widget tests override — no real browser or mail client is launched.
class AboutPage extends ConsumerWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final links = AppIdentity.links;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.aboutTitle)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        children: [
          _SectionHeader(l10n.aboutSectionHelp),
          _LinkTile(
            icon: Icons.public,
            label: l10n.aboutWebsite,
            uri: links.website,
          ),
          _LinkTile(
            icon: Icons.help_outline,
            label: l10n.aboutFaq,
            uri: links.faq,
          ),
          _LinkTile(
            icon: Icons.support_agent,
            label: l10n.aboutSupport,
            uri: links.support,
          ),
          _LinkTile(
            icon: Icons.new_releases_outlined,
            label: l10n.aboutChangelog,
            uri: links.changelog,
          ),

          _SectionHeader(l10n.aboutSectionLegal),
          _LinkTile(
            icon: Icons.privacy_tip_outlined,
            label: l10n.aboutPrivacy,
            uri: links.privacyPolicy,
          ),
          _LinkTile(
            icon: Icons.delete_outline,
            label: l10n.aboutDataDeletion,
            uri: links.dataDeletion,
          ),
          // The bundled page comes FIRST and stays primary: it is generated
          // from Flutter's LicenseRegistry, so it lists what THIS build
          // actually contains, can never go stale like a hand-maintained
          // list, and works offline. The web page below is an addition, not
          // a replacement.
          const _OfflineLicensesTile(),
          _LinkTile(
            icon: Icons.public_outlined,
            label: l10n.aboutLicensesOnline,
            uri: links.licenses,
          ),

          _SectionHeader(l10n.aboutSectionContact),
          _MailTile(
            icon: Icons.mail_outline,
            label: l10n.aboutMailSupport,
            mailbox: SupportMailbox.support,
            subject: _MailSubject.support,
          ),
          _MailTile(
            icon: Icons.lightbulb_outline,
            label: l10n.aboutMailFeedback,
            mailbox: SupportMailbox.feedback,
            subject: _MailSubject.feedback,
          ),
          _MailTile(
            icon: Icons.bug_report_outlined,
            label: l10n.aboutMailBug,
            subtitle: l10n.aboutMailBugHint,
            mailbox: SupportMailbox.bugs,
            subject: _MailSubject.bug,
            withDiagnostics: true,
          ),
          _MailTile(
            icon: Icons.shield_outlined,
            label: l10n.aboutMailPrivacy,
            mailbox: SupportMailbox.privacy,
            subject: _MailSubject.privacy,
          ),
          _MailTile(
            icon: Icons.lock_outline,
            label: l10n.aboutMailSecurity,
            mailbox: SupportMailbox.security,
            subject: _MailSubject.security,
          ),

          const SizedBox(height: AppSpacing.xl),
          const _VersionFooter(),
        ],
      ),
    );
  }
}

/// Opens [uri] through the launcher seam and reports the outcome.
///
/// The launcher reports `failed` when no app can handle the URI (common for
/// `mailto:` on emulators and on web without a configured mail handler), so a
/// silent no-op would leave the user tapping a dead row.
///
/// [UrlPolicy.appAuthored] because every URI on this page is built by the app
/// from [AppIdentity.links] — a website, a repository, a prefilled support
/// mail. Anything that arrives from outside the app uses the default
/// [UrlPolicy.webOnly] instead.
Future<void> _open(BuildContext context, WidgetRef ref, Uri uri) async {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context);

  final outcome = await ref.read(urlLauncherProvider)(
    uri,
    policy: UrlPolicy.appAuthored,
  );

  final message = switch (outcome) {
    LaunchOutcome.launched => null,
    LaunchOutcome.failed => l10n.aboutOpenFailed,
    LaunchOutcome.schemeNotAllowed => l10n.linkSchemeNotSupported,
  };

  if (message != null) {
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }
}

/// Opens Flutter's built-in, offline open-source licence page.
///
/// Every package registers its licence with `LicenseRegistry` at build time,
/// so this list cannot drift from the actual dependency set — unlike any
/// manually maintained list. It inherits the app theme (including dark mode)
/// and needs no network.
class _OfflineLicensesTile extends ConsumerWidget {
  const _OfflineLicensesTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    // Version shown on the licence page: the REAL build value from the
    // platform, never a hand-maintained constant. Null until the plugin has
    // resolved, which simply omits the line.
    final version = ref.watch(packageInfoProvider).value?.version;

    return ListTile(
      leading: const Icon(Icons.description_outlined),
      title: Text(l10n.aboutLicensesOffline),
      subtitle: Text(l10n.aboutLicensesOfflineHint),
      trailing: const Icon(Icons.chevron_right, size: 18),
      onTap: () => showLicensePage(
        context: context,
        applicationName: AppIdentity.displayName,
        applicationVersion: version,
      ),
    );
  }
}

/// A row opening an external web page.
class _LinkTile extends ConsumerWidget {
  const _LinkTile({required this.icon, required this.label, required this.uri});

  final IconData icon;
  final String label;
  final Uri uri;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: const Icon(Icons.open_in_new, size: 18),
      onTap: () => _open(context, ref, uri),
    );
  }
}

/// A row opening a prefilled mail to one of the LumbreCode mailboxes.
///
/// With [withDiagnostics] the body carries app version, device and the last
/// uncaught error (see [FeedbackMailBuilder]); otherwise the mail is opened
/// with subject only so the user writes freely.
class _MailTile extends ConsumerWidget {
  const _MailTile({
    required this.icon,
    required this.label,
    required this.mailbox,
    required this.subject,
    this.subtitle,
    this.withDiagnostics = false,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final SupportMailbox mailbox;
  final String subject;
  final bool withDiagnostics;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text(subtitle ?? mailbox.address),
      onTap: () => _open(context, ref, _uri(ref)),
    );
  }

  Uri _uri(WidgetRef ref) {
    final links = AppIdentity.links;
    if (!withDiagnostics) {
      return links.mailto(mailbox, subject: subject);
    }

    // Diagnostics are best-effort: the plugins are async and may not have
    // resolved yet, so an unresolved value simply omits that block.
    return FeedbackMailBuilder(links: links).build(
      mailbox: mailbox,
      subject: subject,
      packageInfo: ref.read(packageInfoProvider).value,
      deviceInfo: ref.read(deviceInfoProvider).value,
      lastError: ref.read(lastErrorBufferProvider).last,
    );
  }
}

/// Section heading between two groups of rows.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.xs,
      ),
      child: Text(
        title,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// App version line; renders nothing until the package info has resolved.
/// The name of a flavor for the about page, or `null` for the release.
String? _channelName(AppLocalizations l10n, AppFlavor flavor) =>
    switch (flavor) {
      AppFlavor.prod => null,
      AppFlavor.dev => l10n.channelDev,
      AppFlavor.snapshot => l10n.channelSnapshot,
      AppFlavor.staging => l10n.channelStaging,
      AppFlavor.prerelease => l10n.channelPrerelease,
    };

class _VersionFooter extends ConsumerWidget {
  const _VersionFooter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = ref.watch(packageInfoProvider).value;
    if (info == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final channel = _channelName(l10n, AppFlavor.current);

    return Column(
      children: [
        Text(
          l10n.aboutVersion('${info.version}+${info.buildNumber}'),
          style: theme.textTheme.bodySmall,
        ),
        // Which stream this build belongs to; a release needs no mention.
        if (channel != null)
          Text(l10n.aboutChannel(channel), style: theme.textTheme.bodySmall),
      ],
    );
  }
}
