// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'last_error_buffer.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Overridden in `bootstrap()` with the buffer wired to the zone handlers.

@ProviderFor(lastErrorBuffer)
const lastErrorBufferProvider = LastErrorBufferProvider._();

/// Overridden in `bootstrap()` with the buffer wired to the zone handlers.

final class LastErrorBufferProvider
    extends
        $FunctionalProvider<LastErrorBuffer, LastErrorBuffer, LastErrorBuffer>
    with $Provider<LastErrorBuffer> {
  /// Overridden in `bootstrap()` with the buffer wired to the zone handlers.
  const LastErrorBufferProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'lastErrorBufferProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$lastErrorBufferHash();

  @$internal
  @override
  $ProviderElement<LastErrorBuffer> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LastErrorBuffer create(Ref ref) {
    return lastErrorBuffer(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LastErrorBuffer value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LastErrorBuffer>(value),
    );
  }
}

String _$lastErrorBufferHash() => r'6b6b56d41116e0a7ae13af5e39ae21482ef843d2';
