// Regenerates the two files drift needs to run sqlite3 in a browser:
//
//   web/sqlite3.wasm     the sqlite3 WebAssembly build drift loads
//   web/drift_worker.js  the compiled worker from tool/drift_worker_entrypoint.dart
//
// Run it from `apps/mobile_app` after every drift upgrade:
//
//   dart run tool/sync_web_database_assets.dart
//
// See `docs/operations/build-web.md` for the whole picture.
//
// Both files are build outputs that are committed anyway, because
// `flutter run -d chrome` serves `web/` as-is and has no build step that
// could produce them. A stale pair fails only at runtime, in the browser,
// with an error that does not mention drift — hence this script instead of
// a note in a README.
import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  final appDir = _appDirectory();
  final webDir = Directory('${appDir.path}/web');
  if (!webDir.existsSync()) {
    _fail('No web/ folder in ${appDir.path} — nothing to do.');
  }

  final driftRoot = _packageRoot('drift', appDir);
  final wasm = File('${driftRoot.path}/extension/devtools/build/sqlite3.wasm');
  if (!wasm.existsSync()) {
    // Older or newer drift releases may drop the devtools bundle. The
    // upstream download is the documented fallback.
    _fail(
      'sqlite3.wasm not found in the resolved drift package '
      '(${wasm.path}).\n'
      'Download it manually from '
      'https://github.com/simolus3/sqlite3.dart/releases and save it as '
      'web/sqlite3.wasm.',
    );
  }

  wasm.copySync('${webDir.path}/sqlite3.wasm');
  stdout.writeln('web/sqlite3.wasm  <- ${_shorten(wasm.path)}');

  final result = await Process.run('dart', [
    'compile',
    'js',
    '-O4',
    '-o',
    '${webDir.path}/drift_worker.js',
    '${appDir.path}/tool/drift_worker_entrypoint.dart',
  ], workingDirectory: appDir.path);
  if (result.exitCode != 0) {
    _fail('dart compile js failed:\n${result.stdout}\n${result.stderr}');
  }

  // dart2js writes bookkeeping files next to the output that must not be
  // served.
  for (final extra in ['.deps', '.map']) {
    final file = File('${webDir.path}/drift_worker.js$extra');
    if (file.existsSync()) file.deleteSync();
  }
  stdout.writeln('web/drift_worker.js  <- tool/drift_worker_entrypoint.dart');
}

/// The `apps/mobile_app` directory, no matter where the script was started.
Directory _appDirectory() =>
    File.fromUri(Platform.script).parent.parent.absolute;

/// Resolves [package] through the (possibly workspace-wide) package config.
Directory _packageRoot(String package, Directory from) {
  for (var dir = from; ; dir = dir.parent) {
    final config = File('${dir.path}/.dart_tool/package_config.json');
    if (config.existsSync()) {
      final packages =
          (jsonDecode(config.readAsStringSync())
                  as Map<String, dynamic>)['packages']
              as List<dynamic>;
      for (final entry in packages.cast<Map<String, dynamic>>()) {
        if (entry['name'] != package) continue;
        final root = Uri.parse(entry['rootUri'] as String);
        return Directory.fromUri(
          root.isAbsolute ? root : config.parent.uri.resolveUri(root),
        );
      }
    }
    if (dir.path == dir.parent.path) break;
  }
  _fail('Package "$package" not resolved. Run `flutter pub get` first.');
}

String _shorten(String path) =>
    path.split(RegExp(r'[\/]')).reversed.take(4).toList().reversed.join('/');

Never _fail(String message) {
  stderr.writeln(message);
  exit(1);
}
