import 'package:app_core/app_core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_identity.dart';
import '../../../core/errors/feedback_mail.dart';
import '../../../core/errors/last_error_buffer.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/platform/platform_seams.dart';
import '../../../core/startup/startup_providers.dart';
import '../../../core/startup/startup_task.dart';

/// Shown when a **blocking** startup task failed and the app cannot continue.
///
/// Rule 10 of `docs/architecture/contracts/01-startup.md`: an unrecoverable
/// startup error leads to a defined state with a next action — never to a
/// frozen splash or a crash the user cannot interpret.
///
/// What it deliberately does **not** show: the exception message or a stack
/// trace. Those go into the report mail, where the user chooses to send them.
/// On screen there is only the technical task name, which is one of our own
/// stable identifiers and carries no personal data.
class StartupErrorPage extends ConsumerWidget {
  const StartupErrorPage({super.key, required this.onRetry});

  /// Re-runs the startup pipeline. Must reset whatever failed — see the
  /// wiring in `lib/app/router/app_router.dart`.
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final failedTask = ref.watch(startupOutcomeProvider)?.fatal?.taskName;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  l10n.startupErrorTitle,
                  style: theme.textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.startupErrorBody,
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                if (failedTask != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    l10n.startupErrorTask(failedTask),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.startupErrorRetry),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextButton.icon(
                  onPressed: () => _report(context, ref),
                  icon: const Icon(Icons.bug_report_outlined),
                  label: Text(l10n.startupErrorReport),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Opens a prefilled bug report. Best-effort: the diagnostics seams are
  /// async and may not have resolved on a failed start, which simply omits
  /// those blocks instead of blocking the only escape route the user has.
  Future<void> _report(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final failedMessage = AppLocalizations.of(context).aboutOpenFailed;
    final outcome = ref.read(startupOutcomeProvider);

    final uri = FeedbackMailBuilder(links: AppIdentity.links).build(
      mailbox: SupportMailbox.bugs,
      subject: 'Startup failure: ${outcome?.fatal?.taskName ?? 'unknown'}',
      packageInfo: ref.read(packageInfoProvider).value,
      deviceInfo: ref.read(deviceInfoProvider).value,
      lastError: _asAppError(outcome?.fatal),
    );

    // appAuthored: this `mailto:` URI is built by FeedbackMailBuilder from
    // AppIdentity.links, not by anything outside the app.
    final launchOutcome = await ref.read(urlLauncherProvider)(
      uri,
      policy: UrlPolicy.appAuthored,
    );

    if (launchOutcome != LaunchOutcome.launched) {
      messenger.showSnackBar(SnackBar(content: Text(failedMessage)));
    }
  }

  static AppError? _asAppError(StartupFailure? failure) {
    if (failure == null) return null;
    return AppError(
      error: failure.error,
      stackTrace: failure.stackTrace,
      source: 'startup',
    );
  }
}
