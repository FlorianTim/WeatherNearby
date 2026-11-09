import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

part 'platform_seams.g.dart';

/// Injectable seams for platform plugins.
///
/// Convention: widgets and services never call a plugin directly — they read
/// one of these providers. Widget tests override the provider with a fake so
/// no real platform channel is ever hit:
///
///   ProviderScope(overrides: [
///     shareTextProvider.overrideWithValue((text) async => shared = text),
///   ], child: ...)
///
/// The same pattern applies to any new plugin: define a typedef for the
/// operation, expose it as a keepAlive provider, wire the real plugin call
/// in the provider body.

/// What happened when a URI was handed to the launcher.
///
/// A three-way outcome rather than a `bool`, because "we refused to open
/// this" and "the system had nothing to open it with" are different facts and
/// the UI has to say different things about them.
enum LaunchOutcome {
  /// Handed to the system successfully.
  launched,

  /// The scheme is not permitted under the requested [UrlPolicy]. The plugin
  /// was **not** called.
  schemeNotAllowed,

  /// Permitted, attempted, and the system could not handle it.
  failed,
}

/// Which URI schemes a launch may use.
///
/// This is a **security boundary**, not a convenience. Link targets that
/// arrive in an imported document are user-entered URLs from an untrusted
/// source; the interop contract requires that only `https:` and `http:` are
/// ever opened, and only on an explicit tap
/// (`lumbrecode-engineering/docs/JSCALENDAR_TASK_INTEROP.md`, sections 2.7
/// and 10.7).
///
/// Do not widen these sets. A new scheme means a new decision, and it belongs
/// in a new policy value with its own justification.
enum UrlPolicy {
  /// `http` and `https` only. **The default, and the right choice whenever
  /// the app did not author the URI itself** — imported documents, links a
  /// user typed, anything that arrived through a share.
  webOnly({'http', 'https'}),

  /// `http`, `https` and `mailto`. Only for URIs the app **constructed
  /// itself**, such as the prefilled feedback mail from
  /// `FeedbackMailBuilder`. Never for content that came from outside.
  appAuthored({'http', 'https', 'mailto'});

  const UrlPolicy(this.allowedSchemes);

  final Set<String> allowedSchemes;

  /// Scheme comparison is case-insensitive: `HTTPS://` is still `https`.
  bool allows(Uri uri) => allowedSchemes.contains(uri.scheme.toLowerCase());
}

/// A document to hand to the platform share sheet.
///
/// A **file**, not `EXTRA_TEXT`. Text carriers have size limits, no media
/// type, and land in targets the document was not meant for
/// (`JSCALENDAR_TASK_INTEROP.md`, section 6.1).
class SharePayload {
  const SharePayload({
    required this.fileName,
    required this.mediaType,
    required this.bytesUtf8,
  });

  /// Including the extension, e.g. `geburtstag.jscalendar.json`.
  final String fileName;

  /// e.g. `application/jscalendar+json;type=group`.
  final String mediaType;

  /// The document itself. Written as UTF-8.
  final String bytesUtf8;
}

typedef LaunchUrl = Future<LaunchOutcome> Function(Uri uri, {UrlPolicy policy});
typedef ShareText = Future<void> Function(String text);
typedef ShareDocument = Future<void> Function(SharePayload payload);
typedef CopyToClipboard = Future<void> Function(String text);

/// Subdirectory of the app cache holding documents queued for sharing.
const kShareCacheDirName = 'share';

/// Opens [Uri] in the external browser / matching app, if [UrlPolicy] permits.
///
/// The scheme is checked **before** the plugin is called, so a refused URI
/// never reaches the platform. Enforcing this at each call site instead is
/// how it gets forgotten — and the app is about to acquire call sites that
/// render foreign documents.
@Riverpod(keepAlive: true)
LaunchUrl urlLauncher(Ref ref) {
  return (uri, {UrlPolicy policy = UrlPolicy.webOnly}) async {
    if (!policy.allows(uri)) return LaunchOutcome.schemeNotAllowed;

    try {
      final launched = await url_launcher.launchUrl(
        uri,
        mode: url_launcher.LaunchMode.externalApplication,
      );
      return launched ? LaunchOutcome.launched : LaunchOutcome.failed;
    } on Exception {
      return LaunchOutcome.failed;
    }
  };
}

/// Opens the platform share sheet with plain text.
@Riverpod(keepAlive: true)
ShareText shareText(Ref ref) {
  return (text) async {
    await SharePlus.instance.share(ShareParams(text: text));
  };
}

/// Opens the platform share sheet with a typed document **file**.
///
/// The file is written to the app-private cache — never to Downloads or
/// shared storage — and is cleaned up by [clearShareCache] at the next start
/// (`JSCALENDAR_TASK_INTEROP.md`, section 6.1).
///
/// API note: `share_plus` replaced the static `Share.shareXFiles(...)` entry
/// point during its 11.x line. This targets the resolved **12.x** instance
/// API; snippets written for 10.x do not compile here. `XFile` is re-exported
/// by `package:share_plus/share_plus.dart`, so no `cross_file` dependency is
/// needed.
@Riverpod(keepAlive: true)
ShareDocument shareDocument(Ref ref) {
  return (payload) async {
    final dir = Directory(
      '${(await getApplicationCacheDirectory()).path}/$kShareCacheDirName',
    );
    await dir.create(recursive: true);

    final file = File('${dir.path}/${payload.fileName}');
    await file.writeAsString(payload.bytesUtf8, flush: true);

    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path, mimeType: payload.mediaType)]),
    );
  };
}

/// Deletes everything queued for sharing in a previous session.
///
/// Shared documents are personal free text sitting in a cache directory.
/// Clearing them at startup bounds how long a copy survives after the user
/// has finished with it. Safe to call when the directory does not exist.
Future<void> clearShareCache() async {
  final dir = Directory(
    '${(await getApplicationCacheDirectory()).path}/$kShareCacheDirName',
  );
  if (await dir.exists()) {
    await dir.delete(recursive: true);
  }
}

/// Copies plain text to the system clipboard.
@Riverpod(keepAlive: true)
CopyToClipboard copyToClipboard(Ref ref) {
  return (text) => Clipboard.setData(ClipboardData(text: text));
}

/// App package metadata (version, build number, ...).
@Riverpod(keepAlive: true)
Future<PackageInfo> packageInfo(Ref ref) => PackageInfo.fromPlatform();

/// Device metadata (model, OS version, ...).
@Riverpod(keepAlive: true)
Future<BaseDeviceInfo> deviceInfo(Ref ref) => DeviceInfoPlugin().deviceInfo;
