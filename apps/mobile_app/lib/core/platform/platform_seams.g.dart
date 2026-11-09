// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'platform_seams.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Opens [Uri] in the external browser / matching app, if [UrlPolicy] permits.
///
/// The scheme is checked **before** the plugin is called, so a refused URI
/// never reaches the platform. Enforcing this at each call site instead is
/// how it gets forgotten — and the app is about to acquire call sites that
/// render foreign documents.

@ProviderFor(urlLauncher)
const urlLauncherProvider = UrlLauncherProvider._();

/// Opens [Uri] in the external browser / matching app, if [UrlPolicy] permits.
///
/// The scheme is checked **before** the plugin is called, so a refused URI
/// never reaches the platform. Enforcing this at each call site instead is
/// how it gets forgotten — and the app is about to acquire call sites that
/// render foreign documents.

final class UrlLauncherProvider
    extends $FunctionalProvider<LaunchUrl, LaunchUrl, LaunchUrl>
    with $Provider<LaunchUrl> {
  /// Opens [Uri] in the external browser / matching app, if [UrlPolicy] permits.
  ///
  /// The scheme is checked **before** the plugin is called, so a refused URI
  /// never reaches the platform. Enforcing this at each call site instead is
  /// how it gets forgotten — and the app is about to acquire call sites that
  /// render foreign documents.
  const UrlLauncherProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'urlLauncherProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$urlLauncherHash();

  @$internal
  @override
  $ProviderElement<LaunchUrl> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LaunchUrl create(Ref ref) {
    return urlLauncher(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LaunchUrl value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LaunchUrl>(value),
    );
  }
}

String _$urlLauncherHash() => r'f62f44987189a89160eed690fe5254bc1f8fe9cd';

/// Opens the platform share sheet with plain text.

@ProviderFor(shareText)
const shareTextProvider = ShareTextProvider._();

/// Opens the platform share sheet with plain text.

final class ShareTextProvider
    extends $FunctionalProvider<ShareText, ShareText, ShareText>
    with $Provider<ShareText> {
  /// Opens the platform share sheet with plain text.
  const ShareTextProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shareTextProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$shareTextHash();

  @$internal
  @override
  $ProviderElement<ShareText> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ShareText create(Ref ref) {
    return shareText(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ShareText value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ShareText>(value),
    );
  }
}

String _$shareTextHash() => r'ff5ed2448df3be509675b8b7b0a95449122fda5d';

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

@ProviderFor(shareDocument)
const shareDocumentProvider = ShareDocumentProvider._();

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

final class ShareDocumentProvider
    extends $FunctionalProvider<ShareDocument, ShareDocument, ShareDocument>
    with $Provider<ShareDocument> {
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
  const ShareDocumentProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shareDocumentProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$shareDocumentHash();

  @$internal
  @override
  $ProviderElement<ShareDocument> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ShareDocument create(Ref ref) {
    return shareDocument(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ShareDocument value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ShareDocument>(value),
    );
  }
}

String _$shareDocumentHash() => r'60f2c73f85bf4470a81ab86e96ef98161b5aa832';

/// Copies plain text to the system clipboard.

@ProviderFor(copyToClipboard)
const copyToClipboardProvider = CopyToClipboardProvider._();

/// Copies plain text to the system clipboard.

final class CopyToClipboardProvider
    extends
        $FunctionalProvider<CopyToClipboard, CopyToClipboard, CopyToClipboard>
    with $Provider<CopyToClipboard> {
  /// Copies plain text to the system clipboard.
  const CopyToClipboardProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'copyToClipboardProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$copyToClipboardHash();

  @$internal
  @override
  $ProviderElement<CopyToClipboard> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CopyToClipboard create(Ref ref) {
    return copyToClipboard(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CopyToClipboard value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CopyToClipboard>(value),
    );
  }
}

String _$copyToClipboardHash() => r'07782a2e9047c075fea9899294a3e1767a589497';

/// App package metadata (version, build number, ...).

@ProviderFor(packageInfo)
const packageInfoProvider = PackageInfoProvider._();

/// App package metadata (version, build number, ...).

final class PackageInfoProvider
    extends
        $FunctionalProvider<
          AsyncValue<PackageInfo>,
          PackageInfo,
          FutureOr<PackageInfo>
        >
    with $FutureModifier<PackageInfo>, $FutureProvider<PackageInfo> {
  /// App package metadata (version, build number, ...).
  const PackageInfoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'packageInfoProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$packageInfoHash();

  @$internal
  @override
  $FutureProviderElement<PackageInfo> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PackageInfo> create(Ref ref) {
    return packageInfo(ref);
  }
}

String _$packageInfoHash() => r'854bbb0e381edfdddbd736229351d6cc918a2ad1';

/// Device metadata (model, OS version, ...).

@ProviderFor(deviceInfo)
const deviceInfoProvider = DeviceInfoProvider._();

/// Device metadata (model, OS version, ...).

final class DeviceInfoProvider
    extends
        $FunctionalProvider<
          AsyncValue<BaseDeviceInfo>,
          BaseDeviceInfo,
          FutureOr<BaseDeviceInfo>
        >
    with $FutureModifier<BaseDeviceInfo>, $FutureProvider<BaseDeviceInfo> {
  /// Device metadata (model, OS version, ...).
  const DeviceInfoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deviceInfoProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deviceInfoHash();

  @$internal
  @override
  $FutureProviderElement<BaseDeviceInfo> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<BaseDeviceInfo> create(Ref ref) {
    return deviceInfo(ref);
  }
}

String _$deviceInfoHash() => r'acaefb8c0f9643335014b9cef13786637bccde66';
