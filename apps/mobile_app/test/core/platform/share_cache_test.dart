import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/core/platform/platform_seams.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Documents queued for sharing are personal free text sitting in a cache
/// directory. [clearShareCache] bounds how long a copy survives after the
/// user has finished with it.
void main() {
  late Directory cacheRoot;
  late Directory shareDir;

  setUp(() {
    cacheRoot = Directory.systemTemp.createTempSync('share_cache_test');
    shareDir = Directory('${cacheRoot.path}/$kShareCacheDirName');
    PathProviderPlatform.instance = _FakePathProvider(cacheRoot.path);
  });

  tearDown(() {
    if (cacheRoot.existsSync()) cacheRoot.deleteSync(recursive: true);
  });

  test('deletes documents left over from a previous session', () async {
    shareDir.createSync(recursive: true);
    File(
      '${shareDir.path}/list.jscalendar.json',
    ).writeAsStringSync('{"@type":"Group"}');
    File(
      '${shareDir.path}/task.jscalendar.json',
    ).writeAsStringSync('{"@type":"Task"}');

    expect(shareDir.listSync(), hasLength(2));

    await clearShareCache();

    expect(shareDir.existsSync(), isFalse);
  });

  test('is a no-op when nothing was ever shared', () async {
    expect(shareDir.existsSync(), isFalse);

    // Must not throw: this runs as a fireAndForget startup task on every
    // start, including the very first one.
    await clearShareCache();

    expect(shareDir.existsSync(), isFalse);
  });

  test('is idempotent', () async {
    shareDir.createSync(recursive: true);
    File('${shareDir.path}/a.json').writeAsStringSync('{}');

    await clearShareCache();
    await clearShareCache();

    expect(shareDir.existsSync(), isFalse);
  });

  test('touches nothing outside the share subdirectory', () async {
    shareDir.createSync(recursive: true);
    File('${shareDir.path}/a.json').writeAsStringSync('{}');

    // A sibling in the same cache root — e.g. an image cache — must survive.
    final sibling = Directory('${cacheRoot.path}/other')
      ..createSync(recursive: true);
    File('${sibling.path}/keep.bin').writeAsStringSync('keep me');

    await clearShareCache();

    expect(shareDir.existsSync(), isFalse);
    expect(File('${sibling.path}/keep.bin').existsSync(), isTrue);
  });
}

class _FakePathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  _FakePathProvider(this.root);

  final String root;

  @override
  Future<String?> getApplicationCachePath() async => root;

  @override
  Future<String?> getTemporaryPath() async => root;
}
