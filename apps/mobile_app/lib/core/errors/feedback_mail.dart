import 'package:app_core/app_core.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'last_error_buffer.dart';

/// Builds a prefilled `mailto:` URI for feedback / error reports.
///
/// Metadata (app version, device model, last uncaught error) comes from the
/// injectable seams (`packageInfoProvider`, `deviceInfoProvider`,
/// `lastErrorBufferProvider`) so the builder itself stays a pure function
/// and is trivially testable. Launch the result through the
/// `urlLauncherProvider` seam.
///
/// Recipient addresses and subject tagging come from [links] — the subject
/// is prefixed with `[app:<slug>]` so mail to the shared LumbreCode mailboxes
/// can be sorted per app.
class FeedbackMailBuilder {
  const FeedbackMailBuilder({required this.links, this.maxStackLines = 15});

  /// Links / mailboxes of the app this report is about.
  final AppLinks links;

  /// Stack traces are truncated to this many lines to keep mails readable.
  final int maxStackLines;

  /// Builds the `mailto:` URI for [mailbox] with a diagnostics body.
  Uri build({
    required SupportMailbox mailbox,
    required String subject,
    PackageInfo? packageInfo,
    BaseDeviceInfo? deviceInfo,
    AppError? lastError,
  }) {
    return links.mailto(
      mailbox,
      subject: subject,
      body: buildBody(
        packageInfo: packageInfo,
        deviceInfo: deviceInfo,
        lastError: lastError,
      ),
    );
  }

  /// The plain-text mail body: report template plus a diagnostics block.
  String buildBody({
    PackageInfo? packageInfo,
    BaseDeviceInfo? deviceInfo,
    AppError? lastError,
  }) {
    final buffer = StringBuffer()
      ..writeln('What happened?')
      ..writeln('(please describe)')
      ..writeln()
      ..writeln('What did you expect?')
      ..writeln('(please describe)')
      ..writeln()
      ..writeln('--- Diagnostic data (please keep) ---');

    if (packageInfo != null) {
      buffer
        ..writeln(
          'App: ${packageInfo.appName} ${packageInfo.version}'
          '+${packageInfo.buildNumber}',
        )
        ..writeln('Package: ${packageInfo.packageName}');
    }
    if (deviceInfo != null) {
      final data = deviceInfo.data;
      final model = data['model'] ?? data['name'] ?? data['prettyName'] ?? '';
      final version = data['version'] is Map
          ? (data['version'] as Map)['release']
          : '';
      buffer.writeln('Device: $model $version'.trim());
    }
    if (lastError != null) {
      buffer
        ..writeln(
          'Last error (${lastError.source}, '
          '${lastError.timestamp.toIso8601String()}):',
        )
        ..writeln(lastError.error.toString())
        ..writeln(_truncateStack(lastError.stackTrace));
    }

    return buffer.toString();
  }

  String _truncateStack(StackTrace? stackTrace) {
    if (stackTrace == null) return '';
    final lines = stackTrace.toString().trimRight().split('\n');
    if (lines.length <= maxStackLines) return lines.join('\n');
    final kept = lines.take(maxStackLines).join('\n');
    return '$kept\n... (${lines.length - maxStackLines} more frames)';
  }
}
